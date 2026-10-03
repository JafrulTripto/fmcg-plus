package repository

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"

	"fmcg-pos-backend/internal/models"
)

type Repository interface {
	// Products & Store Inventory
	GetProducts(search, category, stockFilter string) ([]*models.Product, error)
	GetProductByID(id string) (*models.Product, error)
	GetProductByBarcode(barcode string) (*models.Product, error)
	CreateProduct(product *models.Product) (*models.Product, error)
	UpdateProduct(id string, update *models.Product) (*models.Product, error)
	DeleteProduct(id string) error
	AdjustStock(adj *models.StockAdjustment) (*models.Product, error)
	DecrementStock(productID string, qty int) error

	// Master Catalog & 3-State Barcode Resolution
	ScanBarcode(storeID, barcode string) (*models.ScanResult, error)
	GetMasterProducts(search, category string, limit, offset int) ([]*models.MasterProduct, int64, error)
	GetMasterProductByBarcode(barcode string) (*models.MasterProduct, error)
	OnboardMasterProduct(req *models.OnboardMasterProductRequest) (*models.Product, error)

	// Customers
	GetCustomers(search, filter string) ([]*models.Customer, error)
	GetCustomerByID(id string) (*models.Customer, error)
	CreateCustomer(customer *models.Customer) (*models.Customer, error)
	RecordCustomerPayment(customerID string, amount float64, method, notes string) (*models.Customer, *models.KhataEntry, error)
	AddCustomerCredit(customerID, transactionID string, orderTotal, paidAmount, creditAmount float64, desc string) (*models.Customer, *models.KhataEntry, error)

	// Transactions
	CreateTransaction(tx *models.Transaction) (*models.Transaction, error)
	GetTransactionByID(id string) (*models.Transaction, error)
	GetRecentTransactions(limit int) ([]models.Transaction, error)
	GetCustomerTransactions(customerID, phone string, limit int) ([]models.Transaction, error)

	// Dashboard
	GetDashboardSummary() (*models.DashboardSummary, error)

	// Grocery Requests
	CreateGroceryRequest(req *models.GroceryRequest) (*models.GroceryRequest, error)
	GetGroceryRequests(storeID, customerPhone, customerID, status string) ([]*models.GroceryRequest, error)
	GetGroceryRequestByID(id string) (*models.GroceryRequest, error)
	UpdateGroceryRequestStatus(id string, status string) (*models.GroceryRequest, error)

	// Device Tokens
	UpsertDeviceToken(token *models.DeviceToken) error
	GetDeviceTokensByStoreID(storeID string, role string) ([]*models.DeviceToken, error)
	DeactivateDeviceToken(tokenStr string) error

	// User Authentication & Tenancy
	CreateUser(user *models.User) (*models.User, error)
	GetUserByID(id string) (*models.User, error)
	GetUserByPhone(phone string) (*models.User, error)
	UpdateUser(id string, user *models.User) (*models.User, error)

	CreateStore(store *models.Store) (*models.Store, error)
	GetStoreByID(id string) (*models.Store, error)
	GetStores() ([]*models.Store, error)
	GetStoresByUserID(userID string) ([]*models.Store, error)

	CreateStoreMember(member *models.StoreMember) (*models.StoreMember, error)
	GetStoreMember(storeID, userID string) (*models.StoreMember, error)

	StoreRefreshToken(token *models.RefreshToken) error
	GetRefreshToken(tokenHash string) (*models.RefreshToken, error)
	RevokeRefreshToken(tokenHash string) error
	RevokeAllUserRefreshTokens(userID string) error
}

type memoryRepo struct {
	mu               sync.RWMutex
	products         map[string]*models.Product
	productsByBar    map[string]*models.Product
	masterProducts   map[string]*models.MasterProduct
	masterByBar      map[string]*models.MasterProduct
	customers        map[string]*models.Customer
	transactions     map[string]*models.Transaction
	recentTxIDs      []string
	stockAdjustments []*models.StockAdjustment

	users         map[string]*models.User
	usersByPhone  map[string]*models.User
	stores        map[string]*models.Store
	storeMembers  map[string]*models.StoreMember // key: storeID + ":" + userID
	refreshTokens map[string]*models.RefreshToken // key: tokenHash
	groceryRequests map[string]*models.GroceryRequest
	deviceTokens    map[string]*models.DeviceToken
}

func NewMemoryRepository(dataFilePath string) (Repository, error) {
	repo := &memoryRepo{
		products:         make(map[string]*models.Product),
		productsByBar:    make(map[string]*models.Product),
		masterProducts:   make(map[string]*models.MasterProduct),
		masterByBar:      make(map[string]*models.MasterProduct),
		customers:        make(map[string]*models.Customer),
		transactions:     make(map[string]*models.Transaction),
		recentTxIDs:      make([]string, 0),
		stockAdjustments: make([]*models.StockAdjustment, 0),
		users:            make(map[string]*models.User),
		usersByPhone:     make(map[string]*models.User),
		stores:           make(map[string]*models.Store),
		storeMembers:     make(map[string]*models.StoreMember),
		refreshTokens:    make(map[string]*models.RefreshToken),
		groceryRequests:  make(map[string]*models.GroceryRequest),
		deviceTokens:     make(map[string]*models.DeviceToken),
	}

	repo.seedInitialData(dataFilePath)
	return repo, nil
}

func (r *memoryRepo) seedInitialData(dataFilePath string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Load products from JSON file
	rawBytes, err := os.ReadFile(dataFilePath)
	if err != nil || len(rawBytes) == 0 {
		candidates := []string{
			"bangladesh_fmcg_products.json",
			"../bangladesh_fmcg_products.json",
			"../../bangladesh_fmcg_products.json",
			"../../../bangladesh_fmcg_products.json",
			"mobile/assets/data/master_products.json",
			"../mobile/assets/data/master_products.json",
			"../../mobile/assets/data/master_products.json",
			"../../../mobile/assets/data/master_products.json",
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
			count := 0
			for _, item := range rawList {
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
				sku := fmt.Sprintf("SKU-%s-%03d", catCode, count+1)

				// Register in Master Products catalog with deterministic UUID v5
				mpID := uuid.NewSHA1(uuid.NameSpaceDNS, []byte("fmcg:product:"+item.Barcode)).String()
				brandVal := item.Brand
				catVal := item.Category
				subcatVal := item.Subcategory
				mp := &models.MasterProduct{
					ID:            mpID,
					Barcode:       item.Barcode,
					ProductName:   item.ProductName,
					BrandID:       &brandVal,
					CategoryID:    &catVal,
					SubcategoryID: &subcatVal,
					BrandName:     item.Brand,
					CategoryName:  item.Category,
					PackSize:      packStr,
					Unit:          item.Unit,
					SuggestedMRP:  price,
					SuggestedCost: cost,
					SKU:           sku,
					ImageURL:      item.ImageURL,
					CreatedAt:     time.Now(),
					UpdatedAt:     time.Now(),
				}
				r.masterProducts[mpID] = mp
				r.masterByBar[item.Barcode] = mp
			}
		}
	}
}

// Products
func (r *memoryRepo) GetProducts(search, category, stockFilter string) ([]*models.Product, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.Product
	searchLower := strings.ToLower(search)

	for _, p := range r.products {
		if search != "" {
			nameMatch := strings.Contains(strings.ToLower(p.Name), searchLower)
			barcodeMatch := strings.Contains(strings.ToLower(p.Barcode), searchLower)
			skuMatch := strings.Contains(strings.ToLower(p.SKU), searchLower)
			if !nameMatch && !barcodeMatch && !skuMatch {
				continue
			}
		}

		if category != "" && category != "All" {
			if !strings.EqualFold(p.Category, category) {
				continue
			}
		}

		if stockFilter == "low" && p.Stock > p.MinThreshold {
			continue
		}
		if stockFilter == "out" && p.Stock > 0 {
			continue
		}

		result = append(result, p)
	}

	return result, nil
}

func (r *memoryRepo) GetProductByID(id string) (*models.Product, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	p, ok := r.products[id]
	if !ok {
		return nil, fmt.Errorf("product not found: %s", id)
	}
	return p, nil
}

func (r *memoryRepo) GetProductByBarcode(barcode string) (*models.Product, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	p, ok := r.productsByBar[barcode]
	if !ok {
		return nil, fmt.Errorf("product not found for barcode: %s", barcode)
	}
	return p, nil
}

// 3-State Barcode Resolution Pipeline
func (r *memoryRepo) ScanBarcode(storeID, barcode string) (*models.ScanResult, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	barcode = strings.TrimSpace(barcode)

	// State 1: Check store shelf inventory
	if prod, ok := r.productsByBar[barcode]; ok {
		return &models.ScanResult{
			Status:       "FOUND_IN_STORE",
			Barcode:      barcode,
			StoreProduct: prod,
			Message:      fmt.Sprintf("Product '%s' found in store inventory", prod.Name),
		}, nil
	}

	// State 2: Check global canonical FMCG master catalog
	if mp, ok := r.masterByBar[barcode]; ok {
		return &models.ScanResult{
			Status:        "FOUND_IN_CATALOG",
			Barcode:       barcode,
			MasterProduct: mp,
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

// Master Products queries
func (r *memoryRepo) GetMasterProducts(search, category string, limit, offset int) ([]*models.MasterProduct, int64, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var matched []*models.MasterProduct
	sLower := strings.ToLower(search)

	for _, mp := range r.masterProducts {
		if search != "" {
			nameMatch := strings.Contains(strings.ToLower(mp.ProductName), sLower)
			barcodeMatch := strings.Contains(strings.ToLower(mp.Barcode), sLower)
			if !nameMatch && !barcodeMatch {
				continue
			}
		}
		if category != "" && category != "All" {
			cat := ""
			if mp.CategoryID != nil {
				cat = *mp.CategoryID
			}
			if !strings.EqualFold(cat, category) && !strings.EqualFold(mp.CategoryName, category) {
				continue
			}
		}
		matched = append(matched, mp)
	}

	total := int64(len(matched))
	if offset >= len(matched) {
		return []*models.MasterProduct{}, total, nil
	}
	end := offset + limit
	if limit <= 0 || end > len(matched) {
		end = len(matched)
	}

	return matched[offset:end], total, nil
}

func (r *memoryRepo) GetMasterProductByBarcode(barcode string) (*models.MasterProduct, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	mp, ok := r.masterByBar[barcode]
	if !ok {
		return nil, fmt.Errorf("master product not found: %s", barcode)
	}
	return mp, nil
}

// OnboardMasterProduct stocks a canonical FMCG item into a store's shelf inventory
func (r *memoryRepo) OnboardMasterProduct(req *models.OnboardMasterProductRequest) (*models.Product, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	mp, ok := r.masterProducts[req.MasterProductID]
	if !ok {
		// Try finding by barcode
		mp, ok = r.masterByBar[req.MasterProductID]
		if !ok {
			return nil, fmt.Errorf("master product not found: %s", req.MasterProductID)
		}
	}

	name := mp.ProductName
	if req.CustomName != "" {
		name = req.CustomName
	}

	cat := "Food"
	if mp.CategoryID != nil {
		cat = *mp.CategoryID
	} else if mp.CategoryName != "" {
		cat = mp.CategoryName
	}

	brand := ""
	if mp.BrandID != nil {
		brand = *mp.BrandID
	} else if mp.BrandName != "" {
		brand = mp.BrandName
	}

	pID := uuid.New().String()
	newProduct := &models.Product{
		ID:            pID,
		StoreID:       req.StoreID,
		Name:          name,
		Category:      cat,
		Brand:         brand,
		PackSize:      mp.PackSize,
		Unit:          mp.Unit,
		CostPrice:     req.CostPrice,
		SellingPrice:  req.SellingPrice,
		Stock:         req.InitialStock,
		MinThreshold:  req.MinThreshold,
		Barcode:       mp.Barcode,
		SKU:           mp.SKU,
		ImageURL:      mp.ImageURL,
		ShelfLocation: req.ShelfLocation,
		IsStocked:     true,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	if newProduct.MinThreshold == 0 {
		newProduct.MinThreshold = 5
	}
	if newProduct.StoreID == "" {
		newProduct.StoreID = models.DefaultStoreID
	}

	r.products[pID] = newProduct
	r.productsByBar[mp.Barcode] = newProduct

	return newProduct, nil
}

func (r *memoryRepo) CreateProduct(product *models.Product) (*models.Product, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if product.ID == "" {
		product.ID = uuid.New().String()
	}
	product.CreatedAt = time.Now()
	product.UpdatedAt = time.Now()
	product.IsStocked = true

	r.products[product.ID] = product
	if product.Barcode != "" {
		r.productsByBar[product.Barcode] = product
	}
	return product, nil
}

func (r *memoryRepo) UpdateProduct(id string, update *models.Product) (*models.Product, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	p, ok := r.products[id]
	if !ok {
		return nil, fmt.Errorf("product not found: %s", id)
	}

	if update.Name != "" {
		p.Name = update.Name
	}
	if update.Category != "" {
		p.Category = update.Category
	}
	if update.CostPrice > 0 {
		p.CostPrice = update.CostPrice
	}
	if update.SellingPrice > 0 {
		p.SellingPrice = update.SellingPrice
	}
	if update.Stock >= 0 {
		p.Stock = update.Stock
	}
	if update.MinThreshold > 0 {
		p.MinThreshold = update.MinThreshold
	}
	if update.Barcode != "" {
		p.Barcode = update.Barcode
		r.productsByBar[p.Barcode] = p
	}
	if update.SKU != "" {
		p.SKU = update.SKU
	}
	if update.ImageURL != "" {
		p.ImageURL = update.ImageURL
	}
	if update.ShelfLocation != "" {
		p.ShelfLocation = update.ShelfLocation
	}
	p.UpdatedAt = time.Now()

	return p, nil
}

func (r *memoryRepo) DeleteProduct(id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	p, ok := r.products[id]
	if !ok {
		return fmt.Errorf("product not found: %s", id)
	}

	if p.Barcode != "" {
		delete(r.productsByBar, p.Barcode)
	}
	delete(r.products, id)
	return nil
}

func (r *memoryRepo) AdjustStock(adj *models.StockAdjustment) (*models.Product, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	p, ok := r.products[adj.ProductID]
	if !ok {
		return nil, fmt.Errorf("product not found: %s", adj.ProductID)
	}

	adj.OldStock = p.Stock
	adj.ProductName = p.Name
	adj.ID = uuid.New().String()
	adj.CreatedAt = time.Now()

	switch adj.Reason {
	case "restock", "return":
		p.Stock += adj.AdjustedQty
	case "damaged":
		p.Stock -= adj.AdjustedQty
		if p.Stock < 0 {
			p.Stock = 0
		}
	case "correction":
		p.Stock = adj.AdjustedQty
	default:
		p.Stock += adj.AdjustedQty
	}

	adj.NewStock = p.Stock
	p.UpdatedAt = time.Now()

	r.stockAdjustments = append(r.stockAdjustments, adj)
	return p, nil
}

func (r *memoryRepo) DecrementStock(productID string, qty int) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	p, ok := r.products[productID]
	if !ok {
		return fmt.Errorf("product not found: %s", productID)
	}
	p.Stock -= qty
	if p.Stock < 0 {
		p.Stock = 0
	}
	p.UpdatedAt = time.Now()
	return nil
}

// Customers
func (r *memoryRepo) GetCustomers(search, filter string) ([]*models.Customer, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.Customer
	sLower := strings.ToLower(search)

	for _, c := range r.customers {
		if search != "" {
			nameMatch := strings.Contains(strings.ToLower(c.Name), sLower)
			phoneMatch := strings.Contains(c.Phone, search)
			if !nameMatch && !phoneMatch {
				continue
			}
		}

		if filter == "due" && c.CurrentDue <= 0 {
			continue
		}
		if filter == "zero" && c.CurrentDue > 0 {
			continue
		}

		result = append(result, c)
	}

	return result, nil
}

func (r *memoryRepo) GetCustomerByID(id string) (*models.Customer, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	c, ok := r.customers[id]
	if !ok {
		return nil, fmt.Errorf("customer not found: %s", id)
	}
	return c, nil
}

func (r *memoryRepo) CreateCustomer(customer *models.Customer) (*models.Customer, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if customer.ID == "" {
		customer.ID = uuid.New().String()
	}
	customer.CreatedAt = time.Now()
	customer.UpdatedAt = time.Now()
	if customer.CurrentDue > 0 {
		customer.Status = "warning"
		customer.StatusLabel = "Active Balance"
		if customer.LifetimePurchases == 0 {
			customer.LifetimePurchases = customer.CurrentDue
		}
		entry := models.KhataEntry{
			ID:             uuid.New().String(),
			StoreID:        customer.StoreID,
			CustomerID:     customer.ID,
			Type:           "initial_due",
			Label:          "Opening Balance Due",
			Description:    "Initial balance carried over",
			OrderTotal:     customer.CurrentDue,
			PaidAmount:     0,
			CreditChange:   customer.CurrentDue,
			RunningBalance: customer.CurrentDue,
			CreatedAt:      time.Now(),
		}
		customer.Ledger = []models.KhataEntry{entry}
	} else if customer.Status == "" {
		customer.Status = "clear"
		customer.StatusLabel = "Zero Balance"
	}

	r.customers[customer.ID] = customer
	return customer, nil
}

func (r *memoryRepo) RecordCustomerPayment(customerID string, amount float64, method, notes string) (*models.Customer, *models.KhataEntry, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	c, ok := r.customers[customerID]
	if !ok {
		return nil, nil, fmt.Errorf("customer not found: %s", customerID)
	}

	c.CurrentDue -= amount
	if c.CurrentDue < 0 {
		c.CurrentDue = 0
	}

	if c.CurrentDue == 0 {
		c.Status = "clear"
		c.StatusLabel = "All Dues Cleared"
		c.PromiseDate = ""
	} else {
		c.Status = "warning"
		c.StatusLabel = "Active Balance"
	}
	c.UpdatedAt = time.Now()

	entry := &models.KhataEntry{
		ID:             uuid.New().String(),
		StoreID:        c.StoreID,
		CustomerID:     c.ID,
		Type:           "payment_received",
		Label:          fmt.Sprintf("%s Payment Received", strings.ToUpper(method)),
		Description:    notes,
		PaidAmount:     amount,
		CreditChange:   -amount,
		RunningBalance: c.CurrentDue,
		CreatedAt:      time.Now(),
	}

	c.Ledger = append([]models.KhataEntry{*entry}, c.Ledger...)
	return c, entry, nil
}

func (r *memoryRepo) AddCustomerCredit(customerID, transactionID string, orderTotal, paidAmount, creditAmount float64, desc string) (*models.Customer, *models.KhataEntry, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	c, ok := r.customers[customerID]
	if !ok {
		return nil, nil, fmt.Errorf("customer not found: %s", customerID)
	}

	c.CurrentDue += creditAmount
	c.LifetimePurchases += orderTotal
	c.Status = "warning"
	c.StatusLabel = "Active Balance"
	c.UpdatedAt = time.Now()

	entry := &models.KhataEntry{
		ID:             uuid.New().String(),
		StoreID:        c.StoreID,
		CustomerID:     c.ID,
		TransactionID:  transactionID,
		Type:           "sale_credit",
		Label:          fmt.Sprintf("POS Store Sale Memo (%s)", transactionID),
		Description:    desc,
		OrderTotal:     orderTotal,
		PaidAmount:     paidAmount,
		CreditChange:   creditAmount,
		RunningBalance: c.CurrentDue,
		CreatedAt:      time.Now(),
	}

	c.Ledger = append([]models.KhataEntry{*entry}, c.Ledger...)
	return c, entry, nil
}

// Transactions
func (r *memoryRepo) CreateTransaction(tx *models.Transaction) (*models.Transaction, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if tx.ID == "" {
		tx.ID = uuid.New().String()
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

	r.transactions[tx.ID] = tx
	r.recentTxIDs = append([]string{tx.ID}, r.recentTxIDs...)

	return tx, nil
}

func (r *memoryRepo) GetTransactionByID(id string) (*models.Transaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	tx, ok := r.transactions[id]
	if !ok {
		return nil, fmt.Errorf("transaction not found: %s", id)
	}
	return tx, nil
}

func (r *memoryRepo) GetRecentTransactions(limit int) ([]models.Transaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []models.Transaction
	for i, id := range r.recentTxIDs {
		if limit > 0 && i >= limit {
			break
		}
		if tx, ok := r.transactions[id]; ok {
			result = append(result, *tx)
		}
	}
	return result, nil
}

func (r *memoryRepo) GetCustomerTransactions(customerID, phone string, limit int) ([]models.Transaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []models.Transaction
	for _, id := range r.recentTxIDs {
		if tx, ok := r.transactions[id]; ok {
			matches := false
			if customerID != "" && tx.CustomerID != nil && *tx.CustomerID == customerID {
				matches = true
			} else if phone != "" {
				for _, c := range r.customers {
					if c.Phone == phone && tx.CustomerID != nil && *tx.CustomerID == c.ID {
						matches = true
						break
					}
				}
			}
			if matches {
				result = append(result, *tx)
				if limit > 0 && len(result) >= limit {
					break
				}
			}
		}
	}
	return result, nil
}

// Dashboard
func (r *memoryRepo) GetDashboardSummary() (*models.DashboardSummary, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var totalDues float64
	var pendingDebtors int
	for _, c := range r.customers {
		if c.CurrentDue > 0 {
			totalDues += c.CurrentDue
			pendingDebtors++
		}
	}

	var lowStock int
	for _, p := range r.products {
		if p.Stock <= p.MinThreshold {
			lowStock++
		}
	}

	recent, _ := r.GetRecentTransactions(5)

	var todaySales float64
	var todayOrders int
	now := time.Now()
	for _, tx := range r.transactions {
		if tx.CreatedAt.Year() == now.Year() && tx.CreatedAt.YearDay() == now.YearDay() {
			todaySales += tx.Total
			todayOrders++
		}
	}

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
		TodayOrders:        todayOrders,
		KhataDues:          totalDues,
		PendingDebtors:     pendingDebtors,
		LowStockCount:      lowStock,
		EstProfit:          estProfit,
		NetMarginPercent:   margin,
		RecentTransactions: recent,
	}, nil
}

// ---------------------------------------------------------------------
// Auth & Tenancy Methods (memoryRepo)
// ---------------------------------------------------------------------

func (r *memoryRepo) CreateUser(user *models.User) (*models.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	normPhone := strings.TrimSpace(user.Phone)
	if _, exists := r.usersByPhone[normPhone]; exists {
		return nil, fmt.Errorf("user with phone %s already exists", normPhone)
	}

	if user.ID == "" {
		user.ID = uuid.NewString()
	}
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	uCopy := *user
	r.users[user.ID] = &uCopy
	r.usersByPhone[normPhone] = &uCopy

	return &uCopy, nil
}

func (r *memoryRepo) GetUserByID(id string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	user, exists := r.users[id]
	if !exists {
		return nil, fmt.Errorf("user not found with ID %s", id)
	}
	uCopy := *user
	return &uCopy, nil
}

func PhoneVariants(phone string) []string {
	norm := strings.TrimSpace(phone)
	norm = strings.ReplaceAll(norm, " ", "")
	norm = strings.ReplaceAll(norm, "-", "")
	if norm == "" {
		return nil
	}
	seen := make(map[string]bool)
	var variants []string
	add := func(v string) {
		if v != "" && !seen[v] {
			seen[v] = true
			variants = append(variants, v)
		}
	}
	add(norm)
	if strings.HasPrefix(norm, "+88") {
		withoutPrefix := strings.TrimPrefix(norm, "+88")
		add(withoutPrefix)
		add(strings.TrimPrefix(norm, "+"))
	} else if strings.HasPrefix(norm, "88") {
		add(strings.TrimPrefix(norm, "88"))
		add("+" + norm)
	} else if strings.HasPrefix(norm, "01") {
		add("+88" + norm)
		add("88" + norm)
	}
	return variants
}

func (r *memoryRepo) GetUserByPhone(phone string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	variants := PhoneVariants(phone)
	for _, v := range variants {
		if user, exists := r.usersByPhone[v]; exists {
			uCopy := *user
			return &uCopy, nil
		}
	}
	return nil, fmt.Errorf("user not found with phone %s", phone)
}

func (r *memoryRepo) UpdateUser(id string, update *models.User) (*models.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.users[id]
	if !exists {
		return nil, fmt.Errorf("user not found with ID %s", id)
	}

	if update.Name != "" {
		existing.Name = update.Name
	}
	if update.NameBn != "" {
		existing.NameBn = update.NameBn
	}
	if update.PasswordHash != "" {
		existing.PasswordHash = update.PasswordHash
	}
	if update.Role != "" {
		existing.Role = update.Role
	}
	existing.IsActive = update.IsActive
	existing.PhoneVerified = update.PhoneVerified
	existing.UpdatedAt = time.Now()

	uCopy := *existing
	return &uCopy, nil
}

func (r *memoryRepo) CreateStore(store *models.Store) (*models.Store, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if store.ID == "" {
		store.ID = uuid.NewString()
	}
	store.CreatedAt = time.Now()

	sCopy := *store
	r.stores[store.ID] = &sCopy
	return &sCopy, nil
}

func (r *memoryRepo) GetStoreByID(id string) (*models.Store, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	store, exists := r.stores[id]
	if !exists {
		return nil, fmt.Errorf("store not found with ID %s", id)
	}
	sCopy := *store
	return &sCopy, nil
}

func (r *memoryRepo) GetStores() ([]*models.Store, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.Store
	for _, store := range r.stores {
		sCopy := *store
		result = append(result, &sCopy)
	}
	return result, nil
}

func (r *memoryRepo) GetStoresByUserID(userID string) ([]*models.Store, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.Store
	for _, member := range r.storeMembers {
		if member.UserID == userID && member.IsActive {
			if store, ok := r.stores[member.StoreID]; ok {
				sCopy := *store
				result = append(result, &sCopy)
			}
		}
	}
	return result, nil
}

func (r *memoryRepo) CreateStoreMember(member *models.StoreMember) (*models.StoreMember, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := member.StoreID + ":" + member.UserID
	if member.ID == "" {
		member.ID = uuid.NewString()
	}
	member.CreatedAt = time.Now()

	mCopy := *member
	r.storeMembers[key] = &mCopy
	return &mCopy, nil
}

func (r *memoryRepo) GetStoreMember(storeID, userID string) (*models.StoreMember, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := storeID + ":" + userID
	member, exists := r.storeMembers[key]
	if !exists {
		return nil, fmt.Errorf("store membership not found")
	}
	mCopy := *member
	return &mCopy, nil
}

func (r *memoryRepo) StoreRefreshToken(token *models.RefreshToken) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if token.ID == "" {
		token.ID = uuid.NewString()
	}
	token.CreatedAt = time.Now()

	tCopy := *token
	r.refreshTokens[token.TokenHash] = &tCopy
	return nil
}

func (r *memoryRepo) GetRefreshToken(tokenHash string) (*models.RefreshToken, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	token, exists := r.refreshTokens[tokenHash]
	if !exists {
		return nil, errors.New("refresh token not found")
	}
	tCopy := *token
	return &tCopy, nil
}

func (r *memoryRepo) RevokeRefreshToken(tokenHash string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	token, exists := r.refreshTokens[tokenHash]
	if !exists {
		return errors.New("refresh token not found")
	}
	token.IsRevoked = true
	return nil
}

func (r *memoryRepo) RevokeAllUserRefreshTokens(userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, token := range r.refreshTokens {
		if token.UserID == userID {
			token.IsRevoked = true
		}
	}
	return nil
}

// ---------------------------------------------------------------------
// Grocery Requests (memoryRepo)
// ---------------------------------------------------------------------

func (r *memoryRepo) CreateGroceryRequest(req *models.GroceryRequest) (*models.GroceryRequest, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if req.ID == "" {
		req.ID = uuid.New().String()
	}
	if req.StoreID == "" {
		req.StoreID = models.DefaultStoreID
	}
	if req.Status == "" {
		req.Status = "pending"
	}
	if req.DeliveryType == "" {
		req.DeliveryType = "pickup"
	}
	now := time.Now()
	req.CreatedAt = now
	req.UpdatedAt = now

	r.groceryRequests[req.ID] = req
	return req, nil
}

func (r *memoryRepo) GetGroceryRequests(storeID, customerPhone, customerID, status string) ([]*models.GroceryRequest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.GroceryRequest
	for _, gr := range r.groceryRequests {
		if storeID != "" && gr.StoreID != storeID {
			continue
		}
		if customerPhone != "" {
			variants := PhoneVariants(customerPhone)
			matched := false
			for _, v := range variants {
				if gr.CustomerPhone == v {
					matched = true
					break
				}
			}
			if !matched && gr.CustomerPhone != customerPhone {
				continue
			}
		}
		if customerID != "" && gr.CustomerID != customerID {
			continue
		}
		if status != "" && gr.Status != status {
			continue
		}
		result = append(result, gr)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].CreatedAt.After(result[j].CreatedAt)
	})

	return result, nil
}

func (r *memoryRepo) GetGroceryRequestByID(id string) (*models.GroceryRequest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	gr, ok := r.groceryRequests[id]
	if !ok {
		return nil, fmt.Errorf("grocery request not found: %s", id)
	}
	return gr, nil
}

func (r *memoryRepo) UpdateGroceryRequestStatus(id string, status string) (*models.GroceryRequest, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	gr, ok := r.groceryRequests[id]
	if !ok {
		return nil, fmt.Errorf("grocery request not found: %s", id)
	}
	gr.Status = status
	gr.UpdatedAt = time.Now()
	return gr, nil
}

// Device Tokens (memoryRepo)

func (r *memoryRepo) UpsertDeviceToken(token *models.DeviceToken) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if token.ID == "" {
		token.ID = uuid.New().String()
	}
	token.Active = true
	token.UpdatedAt = time.Now()
	// Remove any existing entry with same token string
	for id, existing := range r.deviceTokens {
		if existing.Token == token.Token {
			delete(r.deviceTokens, id)
		}
	}
	r.deviceTokens[token.ID] = token
	return nil
}

func (r *memoryRepo) GetDeviceTokensByStoreID(storeID string, role string) ([]*models.DeviceToken, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var result []*models.DeviceToken
	for _, dt := range r.deviceTokens {
		if dt.StoreID == storeID && dt.Active {
			if role == "" || dt.Role == role {
				result = append(result, dt)
			}
		}
	}
	return result, nil
}

func (r *memoryRepo) DeactivateDeviceToken(tokenStr string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, dt := range r.deviceTokens {
		if dt.Token == tokenStr {
			dt.Active = false
			dt.UpdatedAt = time.Now()
		}
	}
	return nil
}



