package models

import "time"

// Category represents a top-level FMCG product category
type Category struct {
	ID     string `json:"id" gorm:"primaryKey"`
	Name   string `json:"name" binding:"required"`
	NameBn string `json:"name_bn"`
	Icon   string `json:"icon"`
}

// Subcategory represents a granular FMCG aisle classification
type Subcategory struct {
	ID         string `json:"id" gorm:"primaryKey"`
	CategoryID string `json:"category_id" binding:"required" gorm:"index"`
	Name       string `json:"name" binding:"required"`
	NameBn     string `json:"name_bn"`
}

// Manufacturer represents an FMCG conglomerate or producer
type Manufacturer struct {
	ID      string `json:"id" gorm:"primaryKey"`
	Name    string `json:"name" binding:"required"`
	Country string `json:"country"`
}

// Brand represents an FMCG commercial trademark
type Brand struct {
	ID             string `json:"id" gorm:"primaryKey"`
	ManufacturerID string `json:"manufacturer_id" gorm:"index"`
	Name           string `json:"name" binding:"required"`
}

// MasterProduct represents canonical Bangladesh FMCG product specifications
type MasterProduct struct {
	ID            string    `json:"id" gorm:"primaryKey"`
	Barcode       string    `json:"barcode" binding:"required" gorm:"uniqueIndex"`
	ProductName   string    `json:"product_name" binding:"required" gorm:"index"`
	ProductNameBn string    `json:"product_name_bn"`
	BrandID       string    `json:"brand_id" gorm:"index"`
	CategoryID    string    `json:"category_id" gorm:"index"`
	SubcategoryID string    `json:"subcategory_id" gorm:"index"`
	PackSize      string    `json:"pack_size"`
	Unit          string    `json:"unit" binding:"required"`
	SuggestedMRP  float64   `json:"suggested_mrp"`
	SuggestedCost float64   `json:"suggested_cost"`
	SKU           string    `json:"sku"`
	ImageURL      string    `json:"image_url"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// Store represents an independent retail merchant / dokan tenant
type Store struct {
	ID         string    `json:"id" gorm:"primaryKey"`
	Name       string    `json:"name" binding:"required"`
	OwnerName  string    `json:"owner_name"`
	OwnerPhone string    `json:"owner_phone" binding:"required"`
	Address    string    `json:"address"`
	CreatedAt  time.Time `json:"created_at"`
}

// StoreInventory represents a dokan's on-shelf stock & pricing
type StoreInventory struct {
	ID              string    `json:"id" gorm:"primaryKey"`
	StoreID         string    `json:"store_id" binding:"required" gorm:"index"`
	MasterProductID string    `json:"master_product_id" gorm:"index"`
	Barcode         string    `json:"barcode" binding:"required" gorm:"index"`
	CustomName      string    `json:"custom_name" binding:"required"`
	CustomNameBn    string    `json:"custom_name_bn"`
	CostPrice       float64   `json:"cost_price" binding:"required"`
	SellingPrice    float64   `json:"selling_price" binding:"required"`
	CurrentStock    int       `json:"current_stock"`
	MinThreshold    int       `json:"min_threshold"`
	ShelfLocation   string    `json:"shelf_location"`
	IsActive        bool      `json:"is_active" gorm:"default:true"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// Product represents a retail item (combining store inventory + master catalog info for POS UI)
type Product struct {
	ID            string    `json:"id" gorm:"primaryKey"`
	StoreID       string    `json:"store_id,omitempty"`
	Name          string    `json:"name" binding:"required" gorm:"index"`
	Category      string    `json:"category" binding:"required" gorm:"index"`
	Brand         string    `json:"brand"`
	PackSize      string    `json:"pack_size"`
	Unit          string    `json:"unit" binding:"required"`
	CostPrice     float64   `json:"cost_price" binding:"required"`
	SellingPrice  float64   `json:"selling_price" binding:"required"`
	Stock         int       `json:"stock"`
	MinThreshold  int       `json:"min_threshold"`
	Barcode       string    `json:"barcode" gorm:"index"`
	SKU           string    `json:"sku" gorm:"index"`
	ImageURL      string    `json:"image_url"`
	ShelfLocation string    `json:"shelf_location,omitempty"`
	IsStocked     bool      `json:"is_stocked"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// Customer represents a retail customer with digital Khata credit account
type Customer struct {
	ID                string       `json:"id" gorm:"primaryKey"`
	StoreID           string       `json:"store_id,omitempty" gorm:"index"`
	Name              string       `json:"name" binding:"required"`
	NameBn            string       `json:"name_bn"`
	Phone             string       `json:"phone" binding:"required" gorm:"uniqueIndex"`
	Address           string       `json:"address"`
	CreditLimit       float64      `json:"credit_limit"`
	CurrentDue        float64      `json:"current_due"`
	LifetimePurchases float64      `json:"lifetime_purchases"`
	Status            string       `json:"status"` // "clear", "normal", "warning"
	StatusLabel       string       `json:"status_label"`
	PromiseDate       string       `json:"promise_date"`
	CreatedAt         time.Time    `json:"created_at"`
	UpdatedAt         time.Time    `json:"updated_at"`
	Ledger            []KhataEntry `json:"ledger,omitempty" gorm:"foreignKey:CustomerID"`
}

// TransactionItem represents an itemized product within a sale
type TransactionItem struct {
	ID               string  `json:"id,omitempty" gorm:"primaryKey"`
	TransactionID    string  `json:"transaction_id,omitempty" gorm:"index"`
	StoreID          string  `json:"store_id,omitempty"`
	StoreInventoryID string  `json:"store_inventory_id,omitempty"`
	ProductID        string  `json:"product_id" binding:"required"`
	Barcode          string  `json:"barcode,omitempty"`
	Name             string  `json:"name"`
	Quantity         int     `json:"quantity" binding:"required,gt=0"`
	UnitPrice        float64 `json:"unit_price"`
	CostPrice        float64 `json:"cost_price,omitempty"`
	Unit             string  `json:"unit"`
	TotalPrice       float64 `json:"total_price"`
	Subtotal         float64 `json:"subtotal,omitempty"`
}

// Transaction represents a completed order / cash memo
type Transaction struct {
	ID            string            `json:"id" gorm:"primaryKey"`
	StoreID       string            `json:"store_id,omitempty" gorm:"index"`
	OrderNumber   string            `json:"order_number" gorm:"index"`
	CustomerID    string            `json:"customer_id" gorm:"index"`
	CustomerName  string            `json:"customer_name"`
	Items         []TransactionItem `json:"items" binding:"required,dive" gorm:"serializer:json"`
	Subtotal      float64           `json:"subtotal"`
	Discount      float64           `json:"discount"`
	Total         float64           `json:"total"`
	PaidAmount    float64           `json:"paid_amount"`
	RemainingDue  float64           `json:"remaining_due"`
	PaymentMethod string            `json:"payment_method"` // "cash", "partial", "credit", "mfs"
	CashierName   string            `json:"cashier_name"`
	Counter       string            `json:"counter"`
	AuthCode      string            `json:"auth_code"`
	CreatedAt     time.Time         `json:"created_at" gorm:"index"`
}

// KhataEntry represents a chronological record in the customer running ledger
type KhataEntry struct {
	ID             string    `json:"id" gorm:"primaryKey"`
	StoreID        string    `json:"store_id,omitempty" gorm:"index"`
	CustomerID     string    `json:"customer_id" gorm:"index"`
	TransactionID  string    `json:"transaction_id"`
	Type           string    `json:"type"` // "sale_credit", "payment_received"
	Label          string    `json:"label"`
	Description    string    `json:"description"`
	OrderTotal     float64   `json:"order_total,omitempty"`
	PaidAmount     float64   `json:"paid_amount"`
	CreditChange   float64   `json:"credit_change"` // positive for debt increased, negative for payment made
	RunningBalance float64   `json:"running_balance"`
	CreatedAt      time.Time `json:"created_at" gorm:"index"`
}

// StockAdjustment represents a manual stock reconciliation record
type StockAdjustment struct {
	ID          string    `json:"id" gorm:"primaryKey"`
	ProductID   string    `json:"product_id" binding:"required" gorm:"index"`
	ProductName string    `json:"product_name"`
	OldStock    int       `json:"old_stock"`
	NewStock    int       `json:"new_stock"`
	AdjustedQty int       `json:"adjusted_qty" binding:"required"`
	Reason      string    `json:"reason" binding:"required"` // "restock", "damaged", "return", "correction"
	Notes       string    `json:"notes"`
	CreatedAt   time.Time `json:"created_at" gorm:"index"`
}

// StockMovement represents an immutable inventory movement ledger record
type StockMovement struct {
	ID               string    `json:"id" gorm:"primaryKey"`
	StoreID          string    `json:"store_id" gorm:"index"`
	StoreInventoryID string    `json:"store_inventory_id" gorm:"index"`
	ProductName      string    `json:"product_name"`
	ChangeQty        int       `json:"change_qty"`
	BalanceAfter     int       `json:"balance_after"`
	Reason           string    `json:"reason"` // "initial_stock", "pos_sale", "restock", "damaged", "return"
	ReferenceID      string    `json:"reference_id,omitempty"`
	Notes            string    `json:"notes"`
	CreatedAt        time.Time `json:"created_at" gorm:"index"`
}

// ScanResult represents the 3-state barcode scan resolution pipeline
type ScanResult struct {
	Status        string         `json:"status"` // "FOUND_IN_STORE", "FOUND_IN_CATALOG", "UNKNOWN_BARCODE"
	Barcode       string         `json:"barcode"`
	StoreProduct  *Product       `json:"store_product,omitempty"`
	MasterProduct *MasterProduct `json:"master_product,omitempty"`
	Message       string         `json:"message"`
	CanRegister   bool           `json:"can_register"`
}

// OnboardMasterProductRequest represents payload to stock a master catalog item into store inventory
type OnboardMasterProductRequest struct {
	StoreID         string  `json:"store_id"`
	MasterProductID string  `json:"master_product_id" binding:"required"`
	CostPrice       float64 `json:"cost_price" binding:"required"`
	SellingPrice    float64 `json:"selling_price" binding:"required"`
	InitialStock    int     `json:"initial_stock"`
	MinThreshold    int     `json:"min_threshold"`
	ShelfLocation   string  `json:"shelf_location"`
	CustomName      string  `json:"custom_name"`
}

// DashboardSummary represents the high-level merchant KPI bento
type DashboardSummary struct {
	TodaySales         float64       `json:"today_sales"`
	YesterdaySales     float64       `json:"yesterday_sales"`
	GrowthPercent      float64       `json:"growth_percent"`
	TodayOrders        int           `json:"today_orders"`
	KhataDues          float64       `json:"khata_dues"`
	PendingDebtors     int           `json:"pending_debtors"`
	LowStockCount      int           `json:"low_stock_count"`
	EstProfit          float64       `json:"est_profit"`
	NetMarginPercent   float64       `json:"net_margin_percent"`
	RecentTransactions []Transaction `json:"recent_transactions"`
}

// CheckoutRequest represents the payload from POS terminal
type CheckoutRequest struct {
	StoreID       string            `json:"store_id"`
	CustomerID    string            `json:"customer_id"` // can be empty for walk-in
	CustomerName  string            `json:"customer_name"`
	Items         []TransactionItem `json:"items" binding:"required,min=1,dive"`
	Discount      float64           `json:"discount"`
	PaidAmount    float64           `json:"paid_amount"`
	PaymentMethod string            `json:"payment_method" binding:"required"` // "cash", "partial", "credit"
}

// RecordPaymentRequest represents incoming money for settling customer khata
type RecordPaymentRequest struct {
	StoreID string  `json:"store_id"`
	Amount  float64 `json:"amount" binding:"required,gt=0"`
	Method  string  `json:"method"` // "cash", "bkash", "nagad", "bank"
	Notes   string  `json:"notes"`
}
