package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"fmcg-pos-backend/internal/models"
	"fmcg-pos-backend/internal/repository"
	"fmcg-pos-backend/internal/services"
)

type Handlers struct {
	repo        repository.Repository
	storage     services.StorageService
	JWTService  *services.JWTService
	OTPProvider services.OTPProvider
	Nishchit    *services.NishchitClient
	Auth        *AuthHandler
}

func NewHandlers(repo repository.Repository, storage services.StorageService, jwtService *services.JWTService, otpProvider services.OTPProvider, nishchit *services.NishchitClient) *Handlers {
	return &Handlers{
		repo:        repo,
		storage:     storage,
		JWTService:  jwtService,
		OTPProvider: otpProvider,
		Nishchit:    nishchit,
		Auth:        NewAuthHandler(repo, jwtService, otpProvider),
	}
}

// Health check
func (h *Handlers) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "FMCG+ Retail POS API (Go Gin)",
		"version": "v2.5",
	})
}

// Dashboard
func (h *Handlers) GetDashboard(c *gin.Context) {
	summary, err := h.repo.GetDashboardSummary()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, summary)
}

// Products
func (h *Handlers) GetProducts(c *gin.Context) {
	search := c.Query("search")
	category := c.Query("category")
	stockFilter := c.Query("stock_filter")

	products, err := h.repo.GetProducts(search, category, stockFilter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"products": products, "count": len(products)})
}

func (h *Handlers) GetProductByID(c *gin.Context) {
	id := c.Param("id")
	product, err := h.repo.GetProductByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, product)
}

// ScanBarcode handles the 3-state barcode scanning pipeline
func (h *Handlers) ScanBarcode(c *gin.Context) {
	barcode := strings.TrimSpace(c.Param("barcode"))
	storeID := strings.TrimSpace(c.Query("store_id"))
	if barcode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "barcode parameter is required"})
		return
	}

	result, err := h.repo.ScanBarcode(storeID, barcode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	switch result.Status {
	case "FOUND_IN_STORE":
		c.JSON(http.StatusOK, gin.H{
			"status":        "FOUND_IN_STORE",
			"product":       result.StoreProduct,
			"store_product": result.StoreProduct,
			"barcode":       result.Barcode,
			"message":       result.Message,
		})
	case "FOUND_IN_CATALOG":
		c.JSON(http.StatusOK, gin.H{
			"status":         "FOUND_IN_CATALOG",
			"barcode":        result.Barcode,
			"master_product": result.MasterProduct,
			"suggested_mrp":  result.MasterProduct.SuggestedMRP,
			"suggested_cost": result.MasterProduct.SuggestedCost,
			"message":        result.Message,
			"can_register":   true,
			"can_onboard":    true,
		})
	default:
		c.JSON(http.StatusNotFound, gin.H{
			"status":       "UNKNOWN_BARCODE",
			"error":        "PRODUCT_NOT_FOUND",
			"message":      "Barcode is not registered in the inventory or master catalog",
			"barcode":      barcode,
			"can_register": true,
		})
	}
}

// Master Catalog Endpoints
func (h *Handlers) GetMasterProducts(c *gin.Context) {
	search := c.Query("search")
	category := c.Query("category")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	items, total, err := h.repo.GetMasterProducts(search, category, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"master_products": items,
		"total":           total,
		"limit":           limit,
		"offset":          offset,
	})
}

func (h *Handlers) GetMasterProductByBarcode(c *gin.Context) {
	barcode := strings.TrimSpace(c.Param("barcode"))
	mp, err := h.repo.GetMasterProductByBarcode(barcode)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, mp)
}

func (h *Handlers) OnboardMasterProduct(c *gin.Context) {
	var req models.OnboardMasterProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	product, err := h.repo.OnboardMasterProduct(&req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Product onboarded to store shelf inventory successfully",
		"product": product,
	})
}

func (h *Handlers) CreateProduct(c *gin.Context) {
	var req models.Product
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	created, err := h.repo.CreateProduct(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, created)
}

func (h *Handlers) UpdateProduct(c *gin.Context) {
	id := c.Param("id")
	var req models.Product
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updated, err := h.repo.UpdateProduct(id, &req)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, updated)
}

func (h *Handlers) DeleteProduct(c *gin.Context) {
	id := c.Param("id")
	if err := h.repo.DeleteProduct(id); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Product archived successfully", "id": id})
}

func (h *Handlers) AdjustStock(c *gin.Context) {
	id := c.Param("id")
	var req models.StockAdjustment
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	req.ProductID = id
	updatedProduct, err := h.repo.AdjustStock(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Stock adjusted successfully",
		"product": updatedProduct,
	})
}

// Customers
func (h *Handlers) GetCustomers(c *gin.Context) {
	search := c.Query("search")
	filter := c.Query("filter")

	customers, err := h.repo.GetCustomers(search, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"customers": customers, "count": len(customers)})
}

func (h *Handlers) GetCustomerByID(c *gin.Context) {
	id := c.Param("id")
	customer, err := h.repo.GetCustomerByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, customer)
}

func (h *Handlers) CreateCustomer(c *gin.Context) {
	var req models.Customer
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	created, err := h.repo.CreateCustomer(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, created)
}

func (h *Handlers) RecordCustomerPayment(c *gin.Context) {
	id := c.Param("id")
	var req models.RecordPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Method == "" {
		req.Method = "cash"
	}

	cust, entry, err := h.repo.RecordCustomerPayment(id, req.Amount, req.Method, req.Notes)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":     "Payment recorded successfully",
		"customer":    cust,
		"khata_entry": entry,
	})
}

// Transactions / Checkout Flow
func (h *Handlers) Checkout(c *gin.Context) {
	var req models.CheckoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate items and calculate subtotal
	var subtotal float64
	var itemSummaries []string

	for i := range req.Items {
		item := &req.Items[i]
		prod, err := h.repo.GetProductByID(item.ProductID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("invalid product ID: %s", item.ProductID)})
			return
		}
		item.Name = prod.Name
		if item.UnitPrice <= 0 {
			item.UnitPrice = prod.SellingPrice
		}
		item.Unit = prod.Unit
		item.CostPrice = prod.CostPrice
		item.TotalPrice = item.UnitPrice * float64(item.Quantity)
		subtotal += item.TotalPrice
		itemSummaries = append(itemSummaries, fmt.Sprintf("%s × %d", prod.Name, item.Quantity))

		// Decrement inventory stock
		_ = h.repo.DecrementStock(prod.ID, item.Quantity)
	}

	total := subtotal - req.Discount
	if total < 0 {
		total = 0
	}

	paid := req.PaidAmount
	if req.PaymentMethod == "cash" {
		paid = total
	} else if req.PaymentMethod == "credit" {
		paid = 0
	}

	if paid > total {
		paid = total
	}
	remainingDue := total - paid

	// Customer resolution
	customerName := req.CustomerName
	if customerName == "" {
		customerName = "Walk-in Cash Customer"
	}
	if req.CustomerID != "" {
		cust, err := h.repo.GetCustomerByID(req.CustomerID)
		if err == nil {
			customerName = cust.Name
		}
	}

	tx := &models.Transaction{
		StoreID:       req.StoreID,
		CustomerID:    req.CustomerID,
		CustomerName:  customerName,
		Items:         req.Items,
		Subtotal:      subtotal,
		Discount:      req.Discount,
		Total:         total,
		PaidAmount:    paid,
		RemainingDue:  remainingDue,
		PaymentMethod: req.PaymentMethod,
	}

	createdTx, err := h.repo.CreateTransaction(tx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// If customer credit due > 0, update Khata ledger
	if req.CustomerID != "" && remainingDue > 0 {
		desc := strings.Join(itemSummaries, ", ")
		_, _, _ = h.repo.AddCustomerCredit(req.CustomerID, createdTx.OrderNumber, total, paid, remainingDue, desc)
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":     "Transaction completed successfully",
		"transaction": createdTx,
		"receipt":     formatReceipt(createdTx),
	})
}

func (h *Handlers) GetRecentTransactions(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "20")
	limit := 20
	if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
		limit = l
	}

	txs, err := h.repo.GetRecentTransactions(limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	receipts := make([]gin.H, 0, len(txs))
	for i := range txs {
		receipts = append(receipts, formatReceipt(&txs[i]))
	}

	c.JSON(http.StatusOK, gin.H{
		"transactions": txs,
		"receipts":     receipts,
	})
}

func (h *Handlers) GetReceipt(c *gin.Context) {
	id := c.Param("id")
	tx, err := h.repo.GetTransactionByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, formatReceipt(tx))
}

func formatReceipt(tx *models.Transaction) gin.H {
	formattedItems := make([]gin.H, 0, len(tx.Items))
	for _, it := range tx.Items {
		formattedItems = append(formattedItems, gin.H{
			"product_id":  it.ProductID,
			"name":        it.Name,
			"quantity":    it.Quantity,
			"unit_price":  it.UnitPrice,
			"total_price": it.TotalPrice,
			"unit":        it.Unit,
			"formatted":   fmt.Sprintf("%s × %d = ৳%.0f", it.Name, it.Quantity, it.TotalPrice),
		})
	}

	return gin.H{
		"store_name":     "My Store",
		"store_name_bn":  "আমার দোকান",
		"store_branch":   "Dhaka, Bangladesh",
		"owner_phone":    "+880 1700-000000",
		"order_number":   tx.OrderNumber,
		"date_time":      tx.CreatedAt.Format("02 Jan 2006, 03:04 PM"),
		"created_at":     tx.CreatedAt.Format("02 Jan 2006, 03:04 PM"),
		"customer_name":  tx.CustomerName,
		"cashier_name":   tx.CashierName,
		"cashier":        tx.CashierName,
		"counter":        tx.Counter,
		"items":          formattedItems,
		"subtotal":       tx.Subtotal,
		"discount":       tx.Discount,
		"total":          tx.Total,
		"paid_amount":    tx.PaidAmount,
		"remaining_due":  tx.RemainingDue,
		"payment_method": tx.PaymentMethod,
		"auth_code":      tx.AuthCode,
		"footer_message": "ধন্যবাদ, আবার আসবেন! (Thank you, visit again)",
	}
}

// Storage
func (h *Handlers) UploadImage(c *gin.Context) {
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image provided"})
		return
	}

	url, err := h.storage.UploadImage(c.Request.Context(), file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("failed to upload image: %v", err)})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Image uploaded successfully",
		"image_url": url,
	})
}

func (h *Handlers) GetPresignedUploadURL(c *gin.Context) {
	filename := c.Query("filename")
	if filename == "" {
		filename = "unnamed.jpg"
	}

	uploadURL, fileURL, err := h.storage.GeneratePresignedUploadURL(c.Request.Context(), filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"upload_url":   uploadURL,
		"file_url":     fileURL,
		"expires_mins": 15,
	})
}

// ---------------------------------------------------------------------
// SMS Management via Nishchit Infrastructure
// ---------------------------------------------------------------------

// POST /api/v1/sms/send
func (h *Handlers) SendSMS(c *gin.Context) {
	if h.Nishchit == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Nishchit SMS service is not configured. Please set NISHCHIT_API_KEY"})
		return
	}

	var req struct {
		To        string `json:"to" binding:"required"`
		Body      string `json:"body" binding:"required"`
		From      string `json:"from,omitempty"`
		Reference string `json:"reference,omitempty"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	msg, err := h.Nishchit.SendMessage(c.Request.Context(), services.SendSMSRequest{
		To:        req.To,
		Body:      req.Body,
		From:      req.From,
		Reference: req.Reference,
	})
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": msg,
	})
}

// POST /api/v1/customers/:id/send-reminder-sms
func (h *Handlers) SendKhataReminderSMS(c *gin.Context) {
	if h.Nishchit == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Nishchit SMS service is not configured. Please set NISHCHIT_API_KEY"})
		return
	}

	id := c.Param("id")
	customer, err := h.repo.GetCustomerByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Customer not found"})
		return
	}

	if customer.CurrentDue <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Customer has zero balance; no reminder required"})
		return
	}

	// Keep message within GSM-7 single segment (write BDT rather than ৳ to avoid UCS-2 70-char penalty)
	body := fmt.Sprintf("Dear %s, your outstanding Khata balance at FMCG+ Store is BDT %.2f. Please clear at your convenience. Thank you!",
		customer.Name, customer.CurrentDue)

	msg, err := h.Nishchit.SendTransactionalSMS(c.Request.Context(), customer.Phone, body, fmt.Sprintf("khata-%s", customer.ID))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Failed to send SMS reminder: %v", err)})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": fmt.Sprintf("Khata payment reminder SMS sent to %s", customer.Phone),
		"sms":     msg,
	})
}

