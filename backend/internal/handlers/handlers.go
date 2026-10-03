package handlers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"fmcg-pos-backend/internal/middleware"
	"fmcg-pos-backend/internal/models"
	"fmcg-pos-backend/internal/repository"
	"fmcg-pos-backend/internal/services"
)

type Handlers struct {
	repo            repository.Repository
	storage         services.StorageService
	JWTService      *services.JWTService
	OTPProvider     services.OTPProvider
	Nishchit        *services.NishchitClient
	fcmService      *services.FCMService
	Auth            *AuthHandler
	CheckoutService services.CheckoutService
}

func NewHandlers(repo repository.Repository, storage services.StorageService, jwtService *services.JWTService, otpProvider services.OTPProvider, nishchit *services.NishchitClient, fcmService *services.FCMService) *Handlers {
	return &Handlers{
		repo:            repo,
		storage:         storage,
		JWTService:      jwtService,
		OTPProvider:     otpProvider,
		Nishchit:        nishchit,
		fcmService:      fcmService,
		Auth:            NewAuthHandler(repo, jwtService, otpProvider),
		CheckoutService: services.NewCheckoutService(repo),
	}
}

// resolveStoreID extracts the active store ID with precedence:
// 1. Explicit storeID argument if non-empty and != models.DefaultStoreID
// 2. Gin context "store_id" (set by AuthMiddleware)
// 3. "X-Store-ID" header
// 4. Authorization Bearer token claims if provided
// 5. Query param "store_id" if non-empty and != models.DefaultStoreID
// 6. Explicit storeID argument if models.DefaultStoreID
// 7. Fallback to models.DefaultStoreID
func (h *Handlers) resolveStoreID(c *gin.Context, explicitStoreID string) string {
	explicitStoreID = strings.TrimSpace(explicitStoreID)
	if explicitStoreID != "" && explicitStoreID != models.DefaultStoreID {
		return explicitStoreID
	}

	// 1. From context (AuthMiddleware)
	if ctxStore := middleware.GetContextStoreID(c); ctxStore != "" && ctxStore != models.DefaultStoreID {
		return ctxStore
	}

	// 2. From Authorization header if Bearer token present
	if authHeader := c.GetHeader("Authorization"); authHeader != "" {
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) == 2 && strings.EqualFold(parts[0], "bearer") {
			if claims, err := h.JWTService.ValidateAccessToken(strings.TrimSpace(parts[1])); err == nil && claims != nil {
				if claims.StoreID != "" && claims.StoreID != models.DefaultStoreID {
					return claims.StoreID
				}
			}
		}
	}

	// 3. From X-Store-ID header directly
	if headerStore := strings.TrimSpace(c.GetHeader("X-Store-ID")); headerStore != "" && headerStore != models.DefaultStoreID {
		return headerStore
	}

	// 4. Fallback to explicit storeID if provided
	if explicitStoreID != "" {
		return explicitStoreID
	}

	return models.DefaultStoreID
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
	storeID := strings.TrimSpace(c.Query("store_id"))

	products, err := h.repo.GetProducts(search, category, stockFilter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if storeID != "" {
		storeSpecific := make([]*models.Product, 0)
		for _, p := range products {
			if p.StoreID == storeID || (storeID == models.DefaultStoreID && p.StoreID == "") {
				storeSpecific = append(storeSpecific, p)
			}
		}
		products = storeSpecific
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

	req.StoreID = h.resolveStoreID(c, req.StoreID)

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

	req.StoreID = h.resolveStoreID(c, req.StoreID)

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

	req.StoreID = h.resolveStoreID(c, req.StoreID)

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

	storeID := h.resolveStoreID(c, req.StoreID)

	createdTx, err := h.CheckoutService.ProcessCheckout(&req, storeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":     "Transaction completed successfully",
		"transaction": createdTx,
		"receipt":     h.formatReceipt(createdTx),
	})
}

func (h *Handlers) GetRecentTransactions(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "20")
	limit := 20
	if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
		limit = l
	}

	customerID := strings.TrimSpace(c.Query("customer_id"))
	phone := strings.TrimSpace(c.Query("phone"))
	storeID := h.resolveStoreID(c, c.Query("store_id"))

	var txs []models.Transaction
	var err error

	if customerID != "" || phone != "" {
		txs, err = h.repo.GetCustomerTransactions(customerID, phone, limit)
	} else if storeID != "" && storeID != models.DefaultStoreID {
		txs, err = h.repo.GetRecentTransactions(limit * 3)
		if err == nil {
			var filtered []models.Transaction
			for _, t := range txs {
				if t.StoreID == storeID {
					filtered = append(filtered, t)
				}
				if len(filtered) >= limit {
					break
				}
			}
			if len(filtered) > 0 {
				txs = filtered
			}
		}
	} else {
		txs, err = h.repo.GetRecentTransactions(limit)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	receipts := make([]gin.H, 0, len(txs))
	for i := range txs {
		receipts = append(receipts, h.formatReceipt(&txs[i]))
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

	c.JSON(http.StatusOK, h.formatReceipt(tx))
}

func (h *Handlers) formatReceipt(tx *models.Transaction) gin.H {
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

	storeName := models.DefaultStoreName
	storeAddress := models.DefaultStoreAddress
	storePhone := models.DefaultStorePhone

	if tx.StoreID != "" && tx.StoreID != models.DefaultStoreID {
		if store, err := h.repo.GetStoreByID(tx.StoreID); err == nil && store != nil {
			if store.Name != "" {
				storeName = store.Name
			}
			if store.Address != "" {
				storeAddress = store.Address
			}
			if store.OwnerPhone != "" {
				storePhone = store.OwnerPhone
			}
		}
	} else if store, err := h.repo.GetStoreByID(models.DefaultStoreID); err == nil && store != nil {
		if store.Name != "" {
			storeName = store.Name
		}
		if store.Address != "" {
			storeAddress = store.Address
		}
		if store.OwnerPhone != "" {
			storePhone = store.OwnerPhone
		}
	}

	return gin.H{
		"store_id":       tx.StoreID,
		"store_name":     storeName,
		"store_name_bn":  storeName,
		"store_branch":   storeAddress,
		"store_address":  storeAddress,
		"owner_phone":    storePhone,
		"store_phone":    storePhone,
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

// ---------------------------------------------------------------------
// Grocery Requests
// ---------------------------------------------------------------------

// POST /api/v1/grocery-requests
func (h *Handlers) CreateGroceryRequest(c *gin.Context) {
	var input models.CreateGroceryRequestInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	storeID := h.resolveStoreID(c, input.StoreID)
	if storeID == "" {
		storeID = "store_default"
	}
	storeName := input.StoreName
	if storeName == "" {
		if store, err := h.repo.GetStoreByID(storeID); err == nil && store != nil {
			storeName = store.Name
		} else {
			storeName = "আমার দোকান"
		}
	}

	custID := input.CustomerID
	custName := input.CustomerName
	if custID == "" && input.CustomerPhone != "" {
		if custs, err := h.repo.GetCustomers(input.CustomerPhone, ""); err == nil && len(custs) > 0 {
			custID = custs[0].ID
			if custName == "" {
				custName = custs[0].Name
			}
		}
	}

	estimatedTotal := input.EstimatedTotal
	if estimatedTotal <= 0 && input.ItemsText != "" {
		re := regexp.MustCompile(`(?i)(?:মোট|Total|Subtotal)[:\s]*[৳Tk\s]*([0-9]+(?:\.[0-9]+)?)`)
		matches := re.FindStringSubmatch(input.ItemsText)
		if len(matches) > 1 {
			if val, err := strconv.ParseFloat(matches[1], 64); err == nil {
				estimatedTotal = val
			}
		}
	}

	req := &models.GroceryRequest{
		StoreID:        storeID,
		StoreName:      storeName,
		CustomerID:     custID,
		CustomerName:   custName,
		CustomerPhone:  input.CustomerPhone,
		ItemsText:      input.ItemsText,
		Items:          input.Items,
		DeliveryType:   input.DeliveryType,
		Address:        input.Address,
		Notes:          input.Notes,
		EstimatedTotal: estimatedTotal,
		Status:         "pending",
	}

	created, err := h.repo.CreateGroceryRequest(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Async push notification to store merchants
	go func() {
		if h.fcmService == nil {
			return
		}
		tokens, err := h.repo.GetDeviceTokensByStoreID(storeID, "merchant")
		if err != nil || len(tokens) == 0 {
			// Fallback: check all active tokens for this store in case role was registered as owner/shopkeeper
			tokens, err = h.repo.GetDeviceTokensByStoreID(storeID, "")
		}
		if err != nil || len(tokens) == 0 {
			log.Printf("[FCM] No merchant tokens for store %s: %v", storeID, err)
			return
		}

		tokenStrings := make([]string, len(tokens))
		for i, t := range tokens {
			tokenStrings[i] = t.Token
		}

		title := "🛒 নতুন অর্ডার এসেছে!"
		body := fmt.Sprintf("%s থেকে ৳%.0f এর অর্ডার", custName, estimatedTotal)
		data := map[string]string{
			"type":               "grocery_request",
			"grocery_request_id": created.ID,
			"store_id":           storeID,
			"customer_name":      custName,
			"estimated_total":    fmt.Sprintf("%.2f", estimatedTotal),
		}

		h.fcmService.SendToMultiple(context.Background(), tokenStrings, title, body, data)
	}()

	c.JSON(http.StatusCreated, gin.H{
		"message":         "Grocery request submitted successfully",
		"grocery_request": created,
	})
}

// GET /api/v1/grocery-requests
func (h *Handlers) GetGroceryRequests(c *gin.Context) {
	storeID := c.Query("store_id")
	customerPhone := c.Query("customer_phone")
	customerID := c.Query("customer_id")
	status := c.Query("status")

	requests, err := h.repo.GetGroceryRequests(storeID, customerPhone, customerID, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Enrich estimated total if missing from older records
	for i := range requests {
		if requests[i].EstimatedTotal <= 0 && requests[i].ItemsText != "" {
			re := regexp.MustCompile(`(?i)(?:মোট|Total|Subtotal)[:\s]*[৳Tk\s]*([0-9]+(?:\.[0-9]+)?)`)
			matches := re.FindStringSubmatch(requests[i].ItemsText)
			if len(matches) > 1 {
				if val, err := strconv.ParseFloat(matches[1], 64); err == nil {
					requests[i].EstimatedTotal = val
				}
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"grocery_requests": requests,
	})
}

// GET /api/v1/grocery-requests/:id
func (h *Handlers) GetGroceryRequestByID(c *gin.Context) {
	id := c.Param("id")
	req, err := h.repo.GetGroceryRequestByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, req)
}

// PUT /api/v1/grocery-requests/:id/status
func (h *Handlers) UpdateGroceryRequestStatus(c *gin.Context) {
	id := c.Param("id")
	var req models.UpdateGroceryStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updated, err := h.repo.UpdateGroceryRequestStatus(id, req.Status)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":         "Grocery request status updated",
		"grocery_request": updated,
	})
}

// POST /api/v1/devices/register
func (h *Handlers) RegisterDeviceToken(c *gin.Context) {
	var input models.RegisterDeviceTokenInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	storeID := h.resolveStoreID(c, input.StoreID)
	role := strings.ToLower(strings.TrimSpace(input.Role))
	if role == "owner" || role == "shopkeeper" || role == "admin" || role == "cashier" || role == "" {
		role = "merchant"
	}

	token := &models.DeviceToken{
		UserID:   input.UserID,
		StoreID:  storeID,
		Token:    input.Token,
		Platform: input.Platform,
		Role:     role,
	}

	if err := h.repo.UpsertDeviceToken(token); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to register device token"})
		return
	}

	log.Printf("[FCM] Registered device token for user '%s', store '%s', role '%s'", input.UserID, storeID, role)
	c.JSON(http.StatusOK, gin.H{"message": "Device token registered successfully"})
}

// DELETE /api/v1/devices/unregister
func (h *Handlers) UnregisterDeviceToken(c *gin.Context) {
	var input struct {
		Token string `json:"token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.repo.DeactivateDeviceToken(input.Token); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unregister device token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Device token unregistered"})
}

// GET /api/v1/stores
func (h *Handlers) GetStores(c *gin.Context) {
	stores, err := h.repo.GetStores()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"stores": stores,
	})
}
