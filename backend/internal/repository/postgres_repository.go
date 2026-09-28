package repository

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"fmcg-pos-backend/internal/models"
)

type postgresRepo struct {
	db *gorm.DB
}

// NewPostgresRepository initializes PostgreSQL connection, runs auto-migration, and seeds dataset if empty.
func NewPostgresRepository(dsn, dataFilePath string) (Repository, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to PostgreSQL: %w", err)
	}

	// Temporarily drop dependent view if exists so GORM can sync column types safely
	db.Exec("DROP VIEW IF EXISTS products CASCADE;")
	db.Exec("ALTER TABLE master_products DROP CONSTRAINT IF EXISTS master_products_barcode_key CASCADE;")
	db.Exec("ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_phone_key CASCADE;")

	// Auto-migrate PostgreSQL schema
	err = db.AutoMigrate(
		&models.Category{},
		&models.Subcategory{},
		&models.Manufacturer{},
		&models.Brand{},
		&models.MasterProduct{},
		&models.User{},
		&models.Store{},
		&models.StoreMember{},
		&models.RefreshToken{},
		&models.StoreInventory{},
		&models.Customer{},
		&models.Transaction{},
		&models.TransactionItem{},
		&models.KhataEntry{},
		&models.StockAdjustment{},
		&models.StockMovement{},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to run PostgreSQL migrations: %w", err)
	}

	// Recreate products view
	viewSQL := `CREATE OR REPLACE VIEW products AS
SELECT 
    si.id,
    si.store_id,
    si.custom_name AS name,
    COALESCE(c.name, 'General') AS category,
    COALESCE(b.name, '') AS brand,
    COALESCE(mp.pack_size, '') AS pack_size,
    COALESCE(mp.unit, 'pcs') AS unit,
    si.cost_price,
    si.selling_price,
    si.current_stock AS stock,
    si.min_threshold,
    si.barcode,
    COALESCE(mp.sku, CONCAT('SKU-GEN-', SUBSTRING(si.id, 1, 8))) AS sku,
    mp.image_url,
    si.shelf_location,
    si.is_active,
    si.created_at,
    si.updated_at
FROM store_inventory si
LEFT JOIN master_products mp ON si.master_product_id = mp.id
LEFT JOIN categories c ON mp.category_id = c.id
LEFT JOIN brands b ON mp.brand_id = b.id;`
	if err := db.Exec(viewSQL).Error; err != nil {
		return nil, fmt.Errorf("failed to create products view: %w", err)
	}

	repo := &postgresRepo{db: db}
	repo.seedInitialDataIfEmpty(dataFilePath)

	return repo, nil
}

func (r *postgresRepo) seedInitialDataIfEmpty(dataFilePath string) {
	var masterCount int64
	r.db.Model(&models.MasterProduct{}).Count(&masterCount)
	if masterCount < 600 {
		rawBytes, err := os.ReadFile(dataFilePath)
		if err != nil || len(rawBytes) == 0 {
			candidates := []string{
				"bangladesh_fmcg_products.json",
				"../bangladesh_fmcg_products.json",
				"../../bangladesh_fmcg_products.json",
				"../../../bangladesh_fmcg_products.json",
			}
			for _, c := range candidates {
				b, err := os.ReadFile(c)
				if err == nil && len(b) > 0 {
					rawBytes = b
					break
				}
			}
		}

		if len(rawBytes) > 0 {
			var rawList []struct {
				Barcode      string      `json:"barcode"`
				ProductName  string      `json:"product_name"`
				Brand        string      `json:"brand"`
				Manufacturer string      `json:"manufacturer"`
				Category     string      `json:"category"`
				Subcategory  string      `json:"subcategory"`
				PackSize     interface{} `json:"pack_size"`
				Unit         string      `json:"unit"`
				ImageURL     string      `json:"image_url"`
			}
			if err := json.Unmarshal(rawBytes, &rawList); err == nil {
				for i, item := range rawList {
					if item.Barcode == "" {
						continue
					}
					price := 60.0
					switch item.Category {
					case "Food":
						price = 90.0
						if strings.Contains(strings.ToLower(item.ProductName), "biscuit") || strings.Contains(strings.ToLower(item.ProductName), "noodle") {
							price = 45.0
						}
					case "Beverages":
						price = 35.0
					case "Household":
						price = 85.0
					case "Personal Care":
						price = 145.0
					case "Baby Products":
						price = 220.0
					}
					cost := price * 0.82
					packStr := fmt.Sprintf("%v %s", item.PackSize, item.Unit)

					catCode := "GEN"
					if len(item.Category) >= 3 {
						catCode = strings.ToUpper(item.Category[:3])
					}
					sku := fmt.Sprintf("SKU-%s-%04d", catCode, i+1)
					mpID := uuid.NewSHA1(uuid.NameSpaceDNS, []byte("fmcg:product:"+item.Barcode)).String()

					mp := &models.MasterProduct{
						ID:            mpID,
						Barcode:       item.Barcode,
						ProductName:   item.ProductName,
						BrandID:       item.Brand,
						CategoryID:    item.Category,
						SubcategoryID: item.Subcategory,
						PackSize:      packStr,
						Unit:          item.Unit,
						SuggestedMRP:  price,
						SuggestedCost: cost,
						SKU:           sku,
						ImageURL:      item.ImageURL,
						CreatedAt:     time.Now(),
						UpdatedAt:     time.Now(),
					}
					r.db.Where(models.MasterProduct{Barcode: item.Barcode}).FirstOrCreate(mp)
				}
			}
		}
	}
}

// Products
func (r *postgresRepo) GetProducts(search, category, stockFilter string) ([]*models.Product, error) {
	var items []models.StoreInventory
	query := r.db.Model(&models.StoreInventory{}).Where("is_active = ?", true)

	if search != "" {
		s := "%" + strings.ToLower(search) + "%"
		query = query.Where("LOWER(custom_name) LIKE ? OR barcode LIKE ?", s, s)
	}
	if stockFilter == "low" {
		query = query.Where("current_stock <= min_threshold")
	} else if stockFilter == "out" {
		query = query.Where("current_stock = 0")
	}

	if err := query.Order("created_at desc").Find(&items).Error; err != nil {
		return nil, err
	}

	var products []*models.Product
	for _, it := range items {
		// Fetch master product details if available
		var mp models.MasterProduct
		categoryName := "Food"
		brandName := ""
		packSize := ""
		unit := "pcs"
		sku := ""
		imageURL := ""

		if it.MasterProductID != "" {
			if err := r.db.First(&mp, "id = ?", it.MasterProductID).Error; err == nil {
				categoryName = mp.CategoryID
				brandName = mp.BrandID
				packSize = mp.PackSize
				unit = mp.Unit
				sku = mp.SKU
				imageURL = mp.ImageURL
			}
		}

		if category != "" && category != "All" && !strings.EqualFold(categoryName, category) {
			continue
		}

		p := &models.Product{
			ID:            it.ID,
			StoreID:       it.StoreID,
			Name:          it.CustomName,
			Category:      categoryName,
			Brand:         brandName,
			PackSize:      packSize,
			Unit:          unit,
			CostPrice:     it.CostPrice,
			SellingPrice:  it.SellingPrice,
			Stock:         it.CurrentStock,
			MinThreshold:  it.MinThreshold,
			Barcode:       it.Barcode,
			SKU:           sku,
			ImageURL:      imageURL,
			ShelfLocation: it.ShelfLocation,
			IsStocked:     true,
			CreatedAt:     it.CreatedAt,
			UpdatedAt:     it.UpdatedAt,
		}
		products = append(products, p)
	}

	return products, nil
}

func (r *postgresRepo) GetProductByID(id string) (*models.Product, error) {
	var it models.StoreInventory
	if err := r.db.First(&it, "id = ?", id).Error; err != nil {
		return nil, fmt.Errorf("product not found: %s", id)
	}

	var mp models.MasterProduct
	categoryName := "Food"
	brandName := ""
	packSize := ""
	unit := "pcs"
	sku := ""
	imageURL := ""

	if it.MasterProductID != "" {
		if err := r.db.First(&mp, "id = ?", it.MasterProductID).Error; err == nil {
			categoryName = mp.CategoryID
			brandName = mp.BrandID
			packSize = mp.PackSize
			unit = mp.Unit
			sku = mp.SKU
			imageURL = mp.ImageURL
		}
	}

	return &models.Product{
		ID:            it.ID,
		StoreID:       it.StoreID,
		Name:          it.CustomName,
		Category:      categoryName,
		Brand:         brandName,
		PackSize:      packSize,
		Unit:          unit,
		CostPrice:     it.CostPrice,
		SellingPrice:  it.SellingPrice,
		Stock:         it.CurrentStock,
		MinThreshold:  it.MinThreshold,
		Barcode:       it.Barcode,
		SKU:           sku,
		ImageURL:      imageURL,
		ShelfLocation: it.ShelfLocation,
		IsStocked:     true,
		CreatedAt:     it.CreatedAt,
		UpdatedAt:     it.UpdatedAt,
	}, nil
}

func (r *postgresRepo) GetProductByBarcode(barcode string) (*models.Product, error) {
	var it models.StoreInventory
	if err := r.db.First(&it, "barcode = ?", barcode).Error; err != nil {
		return nil, fmt.Errorf("barcode not found in store: %s", barcode)
	}
	return r.GetProductByID(it.ID)
}

// 3-State Barcode Resolution Pipeline
func (r *postgresRepo) ScanBarcode(storeID, barcode string) (*models.ScanResult, error) {
	barcode = strings.TrimSpace(barcode)

	// State 1: Search in store_inventory
	var it models.StoreInventory
	invQuery := r.db.Where("barcode = ?", barcode)
	if storeID != "" {
		invQuery = invQuery.Where("store_id = ? OR store_id = 'store_default'", storeID)
	}
	if err := invQuery.First(&it).Error; err == nil {
		prod, err := r.GetProductByID(it.ID)
		if err == nil {
			return &models.ScanResult{
				Status:       "FOUND_IN_STORE",
				Barcode:      barcode,
				StoreProduct: prod,
				Message:      fmt.Sprintf("Product '%s' found in store inventory", prod.Name),
			}, nil
		}
	}

	// State 2: Search in master_products catalog
	var mp models.MasterProduct
	if err := r.db.First(&mp, "barcode = ?", barcode).Error; err == nil {
		return &models.ScanResult{
			Status:        "FOUND_IN_CATALOG",
			Barcode:       barcode,
			MasterProduct: &mp,
			Message:       fmt.Sprintf("Product '%s' recognized in Bangladesh Master Catalog", mp.ProductName),
			CanRegister:   true,
		}, nil
	}

	// State 3: Unknown barcode
	return &models.ScanResult{
		Status:      "UNKNOWN_BARCODE",
		Barcode:     barcode,
		Message:     "Barcode not registered in store or master catalog",
		CanRegister: true,
	}, nil
}

// Master Products
func (r *postgresRepo) GetMasterProducts(search, category string, limit, offset int) ([]*models.MasterProduct, int64, error) {
	var mps []*models.MasterProduct
	var total int64

	query := r.db.Model(&models.MasterProduct{})
	if search != "" {
		s := "%" + strings.ToLower(search) + "%"
		query = query.Where("LOWER(product_name) LIKE ? OR barcode LIKE ?", s, s)
	}
	if category != "" && category != "All" {
		query = query.Where("category_id = ?", category)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if limit > 0 {
		query = query.Limit(limit).Offset(offset)
	}
	if err := query.Order("product_name asc").Find(&mps).Error; err != nil {
		return nil, 0, err
	}

	return mps, total, nil
}

func (r *postgresRepo) GetMasterProductByBarcode(barcode string) (*models.MasterProduct, error) {
	var mp models.MasterProduct
	if err := r.db.First(&mp, "barcode = ?", barcode).Error; err != nil {
		return nil, fmt.Errorf("master product not found: %s", barcode)
	}
	return &mp, nil
}

func (r *postgresRepo) OnboardMasterProduct(req *models.OnboardMasterProductRequest) (*models.Product, error) {
	var mp models.MasterProduct
	if err := r.db.First(&mp, "id = ? OR barcode = ?", req.MasterProductID, req.MasterProductID).Error; err != nil {
		return nil, fmt.Errorf("master product not found: %s", req.MasterProductID)
	}

	storeID := req.StoreID
	if storeID == "" {
		storeID = "store_default"
	}
	customName := mp.ProductName
	if req.CustomName != "" {
		customName = req.CustomName
	}
	minThresh := req.MinThreshold
	if minThresh <= 0 {
		minThresh = 5
	}

	invID := uuid.New().String()
	inv := &models.StoreInventory{
		ID:              invID,
		StoreID:         storeID,
		MasterProductID: mp.ID,
		Barcode:         mp.Barcode,
		CustomName:      customName,
		CostPrice:       req.CostPrice,
		SellingPrice:    req.SellingPrice,
		CurrentStock:    req.InitialStock,
		MinThreshold:    minThresh,
		ShelfLocation:   req.ShelfLocation,
		IsActive:        true,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	err := r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(inv).Error; err != nil {
			return err
		}
		// Record initial movement
		mv := &models.StockMovement{
			ID:               uuid.New().String(),
			StoreID:          storeID,
			StoreInventoryID: invID,
			ProductName:      customName,
			ChangeQty:        req.InitialStock,
			BalanceAfter:     req.InitialStock,
			Reason:           "initial_stock",
			Notes:            "Master catalog onboarding",
			CreatedAt:        time.Now(),
		}
		return tx.Create(mv).Error
	})
	if err != nil {
		return nil, err
	}

	return r.GetProductByID(invID)
}

func (r *postgresRepo) CreateProduct(product *models.Product) (*models.Product, error) {
	if product.ID == "" {
		product.ID = uuid.New().String()
	}
	if product.StoreID == "" {
		product.StoreID = "store_default"
	}
	product.CreatedAt = time.Now()
	product.UpdatedAt = time.Now()
	product.IsStocked = true

	inv := &models.StoreInventory{
		ID:            product.ID,
		StoreID:       product.StoreID,
		Barcode:       product.Barcode,
		CustomName:    product.Name,
		CostPrice:     product.CostPrice,
		SellingPrice:  product.SellingPrice,
		CurrentStock:  product.Stock,
		MinThreshold:  product.MinThreshold,
		ShelfLocation: product.ShelfLocation,
		IsActive:      true,
		CreatedAt:     product.CreatedAt,
		UpdatedAt:     product.UpdatedAt,
	}

	if err := r.db.Create(inv).Error; err != nil {
		return nil, err
	}
	return product, nil
}

func (r *postgresRepo) UpdateProduct(id string, update *models.Product) (*models.Product, error) {
	updateMap := map[string]interface{}{
		"updated_at": time.Now(),
	}
	if update.Name != "" {
		updateMap["custom_name"] = update.Name
	}
	if update.CostPrice > 0 {
		updateMap["cost_price"] = update.CostPrice
	}
	if update.SellingPrice > 0 {
		updateMap["selling_price"] = update.SellingPrice
	}
	if update.Stock >= 0 {
		updateMap["current_stock"] = update.Stock
	}
	if update.MinThreshold > 0 {
		updateMap["min_threshold"] = update.MinThreshold
	}
	if update.ShelfLocation != "" {
		updateMap["shelf_location"] = update.ShelfLocation
	}

	if err := r.db.Model(&models.StoreInventory{}).Where("id = ?", id).Updates(updateMap).Error; err != nil {
		return nil, err
	}
	return r.GetProductByID(id)
}

func (r *postgresRepo) DeleteProduct(id string) error {
	return r.db.Model(&models.StoreInventory{}).Where("id = ?", id).Update("is_active", false).Error
}

func (r *postgresRepo) AdjustStock(adj *models.StockAdjustment) (*models.Product, error) {
	var inv models.StoreInventory
	err := r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.First(&inv, "id = ?", adj.ProductID).Error; err != nil {
			return fmt.Errorf("inventory not found: %s", adj.ProductID)
		}

		adj.OldStock = inv.CurrentStock
		adj.ProductName = inv.CustomName
		adj.ID = uuid.New().String()
		adj.CreatedAt = time.Now()

		switch adj.Reason {
		case "restock", "return":
			inv.CurrentStock += adj.AdjustedQty
		case "damaged":
			inv.CurrentStock -= adj.AdjustedQty
			if inv.CurrentStock < 0 {
				inv.CurrentStock = 0
			}
		case "correction":
			inv.CurrentStock = adj.AdjustedQty
		default:
			inv.CurrentStock += adj.AdjustedQty
		}

		adj.NewStock = inv.CurrentStock
		inv.UpdatedAt = time.Now()

		if err := tx.Create(adj).Error; err != nil {
			return err
		}

		// Log movement
		mv := &models.StockMovement{
			ID:               uuid.New().String(),
			StoreID:          inv.StoreID,
			StoreInventoryID: inv.ID,
			ProductName:      inv.CustomName,
			ChangeQty:        adj.AdjustedQty,
			BalanceAfter:     inv.CurrentStock,
			Reason:           adj.Reason,
			Notes:            adj.Notes,
			CreatedAt:        time.Now(),
		}
		if err := tx.Create(mv).Error; err != nil {
			return err
		}

		return tx.Model(&inv).Update("current_stock", inv.CurrentStock).Error
	})

	if err != nil {
		return nil, err
	}
	return r.GetProductByID(adj.ProductID)
}

func (r *postgresRepo) DecrementStock(productID string, qty int) error {
	var inv models.StoreInventory
	if err := r.db.First(&inv, "id = ?", productID).Error; err != nil {
		return fmt.Errorf("inventory item not found: %s", productID)
	}
	newStock := inv.CurrentStock - qty
	if newStock < 0 {
		newStock = 0
	}
	return r.db.Model(&inv).Updates(map[string]interface{}{
		"current_stock": newStock,
		"updated_at":    time.Now(),
	}).Error
}

// Customers
func (r *postgresRepo) GetCustomers(search, filter string) ([]*models.Customer, error) {
	var customers []*models.Customer
	query := r.db.Model(&models.Customer{})

	if search != "" {
		s := "%" + strings.ToLower(search) + "%"
		query = query.Where("LOWER(name) LIKE ? OR phone LIKE ?", s, s)
	}
	if filter == "due" {
		query = query.Where("current_due > 0")
	} else if filter == "zero" {
		query = query.Where("current_due = 0")
	}

	err := query.Order("current_due desc").Find(&customers).Error
	return customers, err
}

func (r *postgresRepo) GetCustomerByID(id string) (*models.Customer, error) {
	var customer models.Customer
	if err := r.db.First(&customer, "id = ?", id).Error; err != nil {
		return nil, fmt.Errorf("customer not found: %s", id)
	}

	var ledger []models.KhataEntry
	r.db.Where("customer_id = ?", id).Order("created_at desc").Find(&ledger)
	customer.Ledger = ledger

	return &customer, nil
}

func (r *postgresRepo) CreateCustomer(customer *models.Customer) (*models.Customer, error) {
	if customer.ID == "" {
		customer.ID = uuid.New().String()
	}
	if customer.StoreID == "" {
		customer.StoreID = "store_default"
	}
	customer.CreatedAt = time.Now()
	customer.UpdatedAt = time.Now()
	if customer.Status == "" {
		customer.Status = "clear"
		customer.StatusLabel = "Zero Balance"
	}

	if err := r.db.Create(customer).Error; err != nil {
		return nil, err
	}
	return customer, nil
}

func (r *postgresRepo) RecordCustomerPayment(customerID string, amount float64, method, notes string) (*models.Customer, *models.KhataEntry, error) {
	var customer models.Customer
	var entry models.KhataEntry

	err := r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.First(&customer, "id = ?", customerID).Error; err != nil {
			return fmt.Errorf("customer not found: %s", customerID)
		}

		customer.CurrentDue -= amount
		if customer.CurrentDue < 0 {
			customer.CurrentDue = 0
		}

		if customer.CurrentDue == 0 {
			customer.Status = "clear"
			customer.StatusLabel = "All Dues Cleared"
			customer.PromiseDate = ""
		} else {
			customer.Status = "warning"
			customer.StatusLabel = "Active Balance"
		}
		customer.UpdatedAt = time.Now()

		entry = models.KhataEntry{
			ID:             uuid.New().String(),
			StoreID:        customer.StoreID,
			CustomerID:     customer.ID,
			Type:           "payment_received",
			Label:          fmt.Sprintf("%s Payment Received", strings.ToUpper(method)),
			Description:    notes,
			PaidAmount:     amount,
			CreditChange:   -amount,
			RunningBalance: customer.CurrentDue,
			CreatedAt:      time.Now(),
		}

		if err := tx.Create(&entry).Error; err != nil {
			return err
		}

		return tx.Save(&customer).Error
	})

	if err != nil {
		return nil, nil, err
	}
	return &customer, &entry, nil
}

func (r *postgresRepo) AddCustomerCredit(customerID, transactionID string, orderTotal, paidAmount, creditAmount float64, desc string) (*models.Customer, *models.KhataEntry, error) {
	var customer models.Customer
	var entry models.KhataEntry

	err := r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.First(&customer, "id = ?", customerID).Error; err != nil {
			return fmt.Errorf("customer not found: %s", customerID)
		}

		customer.CurrentDue += creditAmount
		customer.LifetimePurchases += orderTotal
		customer.Status = "warning"
		customer.StatusLabel = "Active Balance"
		customer.UpdatedAt = time.Now()

		entry = models.KhataEntry{
			ID:             uuid.New().String(),
			StoreID:        customer.StoreID,
			CustomerID:     customer.ID,
			TransactionID:  transactionID,
			Type:           "sale_credit",
			Label:          fmt.Sprintf("POS Store Sale Memo (%s)", transactionID),
			Description:    desc,
			OrderTotal:     orderTotal,
			PaidAmount:     paidAmount,
			CreditChange:   creditAmount,
			RunningBalance: customer.CurrentDue,
			CreatedAt:      time.Now(),
		}

		if err := tx.Create(&entry).Error; err != nil {
			return err
		}

		return tx.Save(&customer).Error
	})

	if err != nil {
		return nil, nil, err
	}
	return &customer, &entry, nil
}

// Transactions
func (r *postgresRepo) CreateTransaction(tx *models.Transaction) (*models.Transaction, error) {
	if tx.ID == "" {
		tx.ID = uuid.New().String()
	}
	if tx.StoreID == "" {
		tx.StoreID = "store_default"
	}
	if tx.OrderNumber == "" {
		tx.OrderNumber = fmt.Sprintf("Order #%s", strings.ToUpper(tx.ID[:8]))
	}
	if tx.Counter == "" {
		tx.Counter = "Counter 01"
	}
	if tx.CashierName == "" {
		tx.CashierName = "Tanvir (Manager)"
	}
	if tx.AuthCode == "" {
		tx.AuthCode = fmt.Sprintf("TR-%s", strings.ToUpper(tx.ID[:8]))
	}
	tx.CreatedAt = time.Now()

	err := r.db.Transaction(func(dbTx *gorm.DB) error {
		if err := dbTx.Create(tx).Error; err != nil {
			return err
		}

		// Insert normalized transaction items
		for _, it := range tx.Items {
			txi := &models.TransactionItem{
				ID:               uuid.New().String(),
				TransactionID:    tx.ID,
				StoreID:          tx.StoreID,
				StoreInventoryID: it.ProductID,
				Barcode:          it.Barcode,
				Name:             it.Name,
				Quantity:         it.Quantity,
				UnitPrice:        it.UnitPrice,
				CostPrice:        it.CostPrice,
				Subtotal:         it.TotalPrice,
			}
			if err := dbTx.Create(txi).Error; err != nil {
				return err
			}
		}
		return nil
	})

	if err != nil {
		return nil, err
	}
	return tx, nil
}

func (r *postgresRepo) GetTransactionByID(id string) (*models.Transaction, error) {
	var tx models.Transaction
	if err := r.db.First(&tx, "id = ?", id).Error; err != nil {
		return nil, fmt.Errorf("transaction not found: %s", id)
	}
	return &tx, nil
}

func (r *postgresRepo) GetRecentTransactions(limit int) ([]models.Transaction, error) {
	var txs []models.Transaction
	query := r.db.Order("created_at desc")
	if limit > 0 {
		query = query.Limit(limit)
	}
	err := query.Find(&txs).Error
	return txs, err
}

// Dashboard
func (r *postgresRepo) GetDashboardSummary() (*models.DashboardSummary, error) {
	var totalDues float64
	var pendingDebtors int64
	r.db.Model(&models.Customer{}).Where("current_due > 0").Select("COALESCE(SUM(current_due), 0)").Scan(&totalDues)
	r.db.Model(&models.Customer{}).Where("current_due > 0").Count(&pendingDebtors)

	var lowStockCount int64
	r.db.Model(&models.StoreInventory{}).Where("current_stock <= min_threshold").Count(&lowStockCount)

	recent, _ := r.GetRecentTransactions(5)

	var todaySales float64
	var todayOrders int64
	todayStart := time.Now().Truncate(24 * time.Hour)
	r.db.Model(&models.Transaction{}).Where("created_at >= ?", todayStart).Select("COALESCE(SUM(total), 0)").Scan(&todaySales)
	r.db.Model(&models.Transaction{}).Where("created_at >= ?", todayStart).Count(&todayOrders)

	var estProfit float64
	var margin float64
	if todaySales > 0 {
		estProfit = todaySales * 0.18
		margin = 18.0
	}

	return &models.DashboardSummary{
		TodaySales:         todaySales,
		YesterdaySales:     0.0,
		GrowthPercent:      0.0,
		TodayOrders:        int(todayOrders),
		KhataDues:          totalDues,
		PendingDebtors:     int(pendingDebtors),
		LowStockCount:      int(lowStockCount),
		EstProfit:          estProfit,
		NetMarginPercent:   margin,
		RecentTransactions: recent,
	}, nil
}

// ---------------------------------------------------------------------
// Auth & Tenancy Methods (postgresRepo)
// ---------------------------------------------------------------------

func (r *postgresRepo) CreateUser(user *models.User) (*models.User, error) {
	if user.ID == "" {
		user.ID = uuid.NewString()
	}
	user.Phone = strings.TrimSpace(user.Phone)
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	if err := r.db.Create(user).Error; err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}
	return user, nil
}

func (r *postgresRepo) GetUserByID(id string) (*models.User, error) {
	var user models.User
	if err := r.db.Where("id = ?", id).First(&user).Error; err != nil {
		return nil, fmt.Errorf("user not found with ID %s: %w", id, err)
	}
	return &user, nil
}

func (r *postgresRepo) GetUserByPhone(phone string) (*models.User, error) {
	var user models.User
	variants := PhoneVariants(phone)
	if len(variants) == 0 {
		return nil, fmt.Errorf("invalid phone number")
	}
	if err := r.db.Where("phone IN ? OR REPLACE(REPLACE(phone, ' ', ''), '-', '') IN ?", variants, variants).First(&user).Error; err != nil {
		return nil, fmt.Errorf("user not found with phone %s: %w", phone, err)
	}
	return &user, nil
}

func (r *postgresRepo) UpdateUser(id string, update *models.User) (*models.User, error) {
	update.UpdatedAt = time.Now()
	if err := r.db.Model(&models.User{}).Where("id = ?", id).Updates(map[string]interface{}{
		"name":           update.Name,
		"name_bn":        update.NameBn,
		"password_hash":  update.PasswordHash,
		"role":           update.Role,
		"is_active":      update.IsActive,
		"phone_verified": update.PhoneVerified,
		"updated_at":     update.UpdatedAt,
	}).Error; err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}
	return r.GetUserByID(id)
}

func (r *postgresRepo) CreateStore(store *models.Store) (*models.Store, error) {
	if store.ID == "" {
		store.ID = uuid.NewString()
	}
	store.CreatedAt = time.Now()

	if err := r.db.Create(store).Error; err != nil {
		return nil, fmt.Errorf("failed to create store: %w", err)
	}
	return store, nil
}

func (r *postgresRepo) GetStoreByID(id string) (*models.Store, error) {
	var store models.Store
	if err := r.db.Where("id = ?", id).First(&store).Error; err != nil {
		return nil, fmt.Errorf("store not found with ID %s: %w", id, err)
	}
	return &store, nil
}

func (r *postgresRepo) GetStoresByUserID(userID string) ([]*models.Store, error) {
	var stores []*models.Store
	err := r.db.Table("stores").
		Joins("JOIN store_members ON store_members.store_id = stores.id").
		Where("store_members.user_id = ? AND store_members.is_active = ?", userID, true).
		Find(&stores).Error
	if err != nil {
		return nil, fmt.Errorf("failed to query stores for user: %w", err)
	}
	return stores, nil
}

func (r *postgresRepo) CreateStoreMember(member *models.StoreMember) (*models.StoreMember, error) {
	if member.ID == "" {
		member.ID = uuid.NewString()
	}
	member.CreatedAt = time.Now()

	if err := r.db.Create(member).Error; err != nil {
		return nil, fmt.Errorf("failed to create store membership: %w", err)
	}
	return member, nil
}

func (r *postgresRepo) GetStoreMember(storeID, userID string) (*models.StoreMember, error) {
	var member models.StoreMember
	if err := r.db.Where("store_id = ? AND user_id = ?", storeID, userID).First(&member).Error; err != nil {
		return nil, fmt.Errorf("store membership not found: %w", err)
	}
	return &member, nil
}

func (r *postgresRepo) StoreRefreshToken(token *models.RefreshToken) error {
	if token.ID == "" {
		token.ID = uuid.NewString()
	}
	token.CreatedAt = time.Now()

	if err := r.db.Create(token).Error; err != nil {
		return fmt.Errorf("failed to store refresh token: %w", err)
	}
	return nil
}

func (r *postgresRepo) GetRefreshToken(tokenHash string) (*models.RefreshToken, error) {
	var token models.RefreshToken
	if err := r.db.Where("token_hash = ?", tokenHash).First(&token).Error; err != nil {
		return nil, fmt.Errorf("refresh token not found: %w", err)
	}
	return &token, nil
}

func (r *postgresRepo) RevokeRefreshToken(tokenHash string) error {
	if err := r.db.Model(&models.RefreshToken{}).Where("token_hash = ?", tokenHash).Update("is_revoked", true).Error; err != nil {
		return fmt.Errorf("failed to revoke refresh token: %w", err)
	}
	return nil
}

func (r *postgresRepo) RevokeAllUserRefreshTokens(userID string) error {
	if err := r.db.Model(&models.RefreshToken{}).Where("user_id = ?", userID).Update("is_revoked", true).Error; err != nil {
		return fmt.Errorf("failed to revoke user refresh tokens: %w", err)
	}
	return nil
}

