package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"fmcg-pos-backend/internal/config"
	"fmcg-pos-backend/internal/handlers"
	"fmcg-pos-backend/internal/models"
	"fmcg-pos-backend/internal/repository"
	"fmcg-pos-backend/internal/router"
	"fmcg-pos-backend/internal/services"
)

func setupTestRouter(t *testing.T) (http.Handler, repository.Repository) {
	cfg := config.LoadConfig()
	repo, err := repository.NewMemoryRepository(cfg.DataFilePath)
	if err != nil {
		t.Fatalf("failed to init repository: %v", err)
	}
	storage := services.NewStorageService(cfg)
	jwtService := services.NewJWTService(cfg)
	otpProvider := services.NewOTPProvider(cfg)
	h := handlers.NewHandlers(repo, storage, jwtService, otpProvider, nil, nil)
	return router.SetupRouter(cfg, h), repo
}

func TestHealthCheck(t *testing.T) {
	r, _ := setupTestRouter(t)
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/health", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}
}

func TestDashboard(t *testing.T) {
	r, _ := setupTestRouter(t)
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}

	var summary models.DashboardSummary
	if err := json.Unmarshal(w.Body.Bytes(), &summary); err != nil {
		t.Fatalf("failed to decode json: %v", err)
	}
	if summary.TodaySales < 0 {
		t.Fatalf("today sales invalid")
	}
}

func TestBarcodeScan(t *testing.T) {
	r, _ := setupTestRouter(t)

	// 1. Scan catalog product (Radhuni Falooda Mix)
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/products/scan/8941100511862", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 for existing barcode, got %d", w.Code)
	}

	// 2. Scan unknown barcode
	reqUnknown, _ := http.NewRequest(http.MethodGet, "/api/v1/products/scan/9999999999999", nil)
	wUnknown := httptest.NewRecorder()
	r.ServeHTTP(wUnknown, reqUnknown)

	if wUnknown.Code != http.StatusNotFound {
		t.Fatalf("expected 404 for unknown barcode, got %d", wUnknown.Code)
	}
}

func TestCheckoutPromptScenario(t *testing.T) {
	r, repo := setupTestRouter(t)

	cust, err := repo.CreateCustomer(&models.Customer{
		Name:  "Rafiqul Islam",
		Phone: "+8801711000001",
	})
	if err != nil {
		t.Fatalf("failed to create customer: %v", err)
	}

	p1, _ := repo.CreateProduct(&models.Product{
		Name:         "Aarong Pure Liquid Milk 1L",
		SellingPrice: 80.0,
		CostPrice:    70.0,
		Stock:        20,
	})
	p2, _ := repo.CreateProduct(&models.Product{
		Name:         "Dan Cake Sliced White Bread 400g",
		SellingPrice: 80.0,
		CostPrice:    65.0,
		Stock:        20,
	})
	p3, _ := repo.CreateProduct(&models.Product{
		Name:         "Farm Fresh Eggs White (Dozen)",
		SellingPrice: 150.0,
		CostPrice:    130.0,
		Stock:        20,
	})

	// Scenario from prompt:
	// Milk x 2 = 160
	// Bread x 1 = 80
	// Egg x 12 = 150
	// Subtotal = 390
	// Discount = 20
	// Total = 370
	// Paid = 200
	// Remaining Due = 170
	checkoutReq := models.CheckoutRequest{
		CustomerID:    cust.ID,
		CustomerName:  cust.Name,
		PaymentMethod: "partial",
		Discount:      20.0,
		PaidAmount:    200.0,
		Items: []models.TransactionItem{
			{
				ProductID:  p1.ID,
				Name:       p1.Name,
				UnitPrice:  80.0,
				Quantity:   2,
				TotalPrice: 160.0,
			},
			{
				ProductID:  p2.ID,
				Name:       p2.Name,
				UnitPrice:  80.0,
				Quantity:   1,
				TotalPrice: 80.0,
			},
			{
				ProductID:  p3.ID,
				Name:       p3.Name,
				UnitPrice:  150.0,
				Quantity:   1,
				TotalPrice: 150.0,
			},
		},
	}

	body, _ := json.Marshal(checkoutReq)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/transactions/checkout", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201 Created for checkout, got %d: %s", w.Code, w.Body.String())
	}

	var resp struct {
		Transaction models.Transaction `json:"transaction"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode checkout response: %v", err)
	}

	tx := resp.Transaction
	if tx.Subtotal != 390.0 {
		t.Errorf("expected subtotal 390, got %f", tx.Subtotal)
	}
	if tx.Discount != 20.0 {
		t.Errorf("expected discount 20, got %f", tx.Discount)
	}
	if tx.Total != 370.0 {
		t.Errorf("expected total 370, got %f", tx.Total)
	}
	if tx.PaidAmount != 200.0 {
		t.Errorf("expected paid 200, got %f", tx.PaidAmount)
	}
	if tx.RemainingDue != 170.0 {
		t.Errorf("expected remaining due 170, got %f", tx.RemainingDue)
	}
}

func TestWalkInCheckout(t *testing.T) {
	r, _ := setupTestRouter(t)

	// Walk-in customer with empty CustomerID and an on-the-fly item
	checkoutReq := models.CheckoutRequest{
		CustomerID:    "",
		CustomerName:  "Walk-in Cash Customer",
		PaymentMethod: "cash",
		Discount:      0.0,
		PaidAmount:    0.0,
		Items: []models.TransactionItem{
			{
				ProductID:  "prod-walkin-1",
				Barcode:    "8941100511862",
				Name:       "Radhuni Falooda Mix",
				UnitPrice:  110.0,
				Quantity:   2,
				TotalPrice: 220.0,
			},
		},
	}

	body, _ := json.Marshal(checkoutReq)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/transactions/checkout", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201 Created for walk-in checkout, got %d: %s", w.Code, w.Body.String())
	}

	var resp struct {
		Transaction models.Transaction `json:"transaction"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode walk-in checkout response: %v", err)
	}

	if resp.Transaction.CustomerID != nil {
		t.Errorf("expected nil CustomerID for walk-in customer, got %v", *resp.Transaction.CustomerID)
	}
	if resp.Transaction.Total != 220.0 {
		t.Errorf("expected total 220.0, got %f", resp.Transaction.Total)
	}
	if resp.Transaction.PaidAmount != 220.0 {
		t.Errorf("expected paid 220.0 for cash payment, got %f", resp.Transaction.PaidAmount)
	}
	if resp.Transaction.RemainingDue != 0.0 {
		t.Errorf("expected remaining due 0.0, got %f", resp.Transaction.RemainingDue)
	}
}

func TestStockAdjustment(t *testing.T) {
	r, repo := setupTestRouter(t)

	p, err := repo.CreateProduct(&models.Product{
		Name:         "Aarong Pure Liquid Milk 1L",
		SellingPrice: 80.0,
		CostPrice:    70.0,
		Stock:        10,
	})
	if err != nil {
		t.Fatalf("failed to create product: %v", err)
	}

	adjustReq := models.StockAdjustment{
		ProductID:   p.ID,
		AdjustedQty: 10,
		Reason:      "restock",
		Notes:       "New batch shipment",
	}
	body, _ := json.Marshal(adjustReq)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/products/"+p.ID+"/adjust-stock", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for stock adjust, got %d: %s", w.Code, w.Body.String())
	}
}

func TestRecordCustomerPayment(t *testing.T) {
	r, repo := setupTestRouter(t)

	cust, err := repo.CreateCustomer(&models.Customer{
		Name:       "Rafiqul Islam",
		Phone:      "+8801711000001",
		CurrentDue: 170.0,
		Status:     "warning",
	})
	if err != nil {
		t.Fatalf("failed to create customer: %v", err)
	}

	// 1. Partial payment: pay 70 out of 170
	payReq := models.RecordPaymentRequest{
		Amount: 70.0,
		Method: "bkash",
		Notes:  "Partial settlement via bKash",
	}
	body, _ := json.Marshal(payReq)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/customers/"+cust.ID+"/payments", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for customer payment, got %d: %s", w.Code, w.Body.String())
	}

	var res struct {
		Customer   *models.Customer   `json:"customer"`
		KhataEntry *models.KhataEntry `json:"khata_entry"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
		t.Fatalf("failed to unmarshal response: %v", err)
	}

	if res.Customer.CurrentDue != 100.0 {
		t.Fatalf("expected remaining due 100.0 after partial payment of 70, got %.2f", res.Customer.CurrentDue)
	}
	if res.Customer.Status != "warning" {
		t.Fatalf("expected customer status 'warning' for partial balance, got '%s'", res.Customer.Status)
	}
	if res.KhataEntry.RunningBalance != 100.0 {
		t.Fatalf("expected running balance 100.0 in khata entry, got %.2f", res.KhataEntry.RunningBalance)
	}

	// 2. Full settlement of remaining 100
	payReq2 := models.RecordPaymentRequest{
		Amount: 100.0,
		Method: "cash",
		Notes:  "Final clearance",
	}
	body2, _ := json.Marshal(payReq2)
	req2, _ := http.NewRequest(http.MethodPost, "/api/v1/customers/"+cust.ID+"/payments", bytes.NewReader(body2))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	if w2.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", w2.Code)
	}
	var res2 struct {
		Customer *models.Customer `json:"customer"`
	}
	_ = json.Unmarshal(w2.Body.Bytes(), &res2)
	if res2.Customer.CurrentDue != 0.0 {
		t.Fatalf("expected remaining due 0.0 after full payment, got %.2f", res2.Customer.CurrentDue)
	}
	if res2.Customer.Status != "clear" {
		t.Fatalf("expected customer status 'clear' after full payment, got '%s'", res2.Customer.Status)
	}
}

func TestThreeStateBarcodeResolution(t *testing.T) {
	r, repo := setupTestRouter(t)

	// Onboard Radhuni Falooda Mix so it is stocked on shelf in store
	_, err := repo.OnboardMasterProduct(&models.OnboardMasterProductRequest{
		StoreID:         models.DefaultStoreID,
		MasterProductID: "8941100511862",
		CostPrice:       60.0,
		SellingPrice:    75.0,
		InitialStock:    15,
	})
	if err != nil {
		t.Fatalf("failed to onboard master product: %v", err)
	}

	// State 1: FOUND_IN_STORE (Radhuni Falooda Mix is stocked on shelf in store)
	reqStore, _ := http.NewRequest(http.MethodGet, "/api/v1/products/scan/8941100511862", nil)
	wStore := httptest.NewRecorder()
	r.ServeHTTP(wStore, reqStore)

	if wStore.Code != http.StatusOK {
		t.Fatalf("expected 200 for store barcode, got %d", wStore.Code)
	}
	var resStore map[string]interface{}
	json.Unmarshal(wStore.Body.Bytes(), &resStore)
	if resStore["status"] != "FOUND_IN_STORE" {
		t.Errorf("expected FOUND_IN_STORE status, got %v", resStore["status"])
	}

	// State 2: FOUND_IN_CATALOG (Master catalog item not stocked on shelf: Quick Bite Dry Cake)
	reqCatalog, _ := http.NewRequest(http.MethodGet, "/api/v1/products/scan/8941197131806", nil)
	wCatalog := httptest.NewRecorder()
	r.ServeHTTP(wCatalog, reqCatalog)

	if wCatalog.Code != http.StatusOK {
		t.Fatalf("expected 200 for catalog barcode, got %d", wCatalog.Code)
	}
	var resCat map[string]interface{}
	json.Unmarshal(wCatalog.Body.Bytes(), &resCat)
	if resCat["status"] != "FOUND_IN_CATALOG" {
		t.Errorf("expected FOUND_IN_CATALOG, got %v", resCat["status"])
	}

	// State 3: UNKNOWN_BARCODE
	reqUnknown, _ := http.NewRequest(http.MethodGet, "/api/v1/products/scan/0000000000000", nil)
	wUnknown := httptest.NewRecorder()
	r.ServeHTTP(wUnknown, reqUnknown)

	if wUnknown.Code != http.StatusNotFound {
		t.Fatalf("expected 404 for unknown barcode, got %d", wUnknown.Code)
	}
	var resUnknown map[string]interface{}
	json.Unmarshal(wUnknown.Body.Bytes(), &resUnknown)
	if resUnknown["status"] != "UNKNOWN_BARCODE" {
		t.Errorf("expected UNKNOWN_BARCODE status, got %v", resUnknown["status"])
	}
}

func TestMasterCatalogAndOnboarding(t *testing.T) {
	r, _ := setupTestRouter(t)

	// Test GET /api/v1/master-catalog
	reqCat, _ := http.NewRequest(http.MethodGet, "/api/v1/master-catalog?limit=10", nil)
	wCat := httptest.NewRecorder()
	r.ServeHTTP(wCat, reqCat)

	if wCat.Code != http.StatusOK {
		t.Fatalf("expected 200 for master catalog, got %d", wCat.Code)
	}

	// Test POST /api/v1/products/onboard
	onboardReq := models.OnboardMasterProductRequest{
		StoreID:         models.DefaultStoreID,
		MasterProductID: "8941197131806",
		CostPrice:       90.0,
		SellingPrice:    110.0,
		InitialStock:    20,
		MinThreshold:    5,
		ShelfLocation:   "Aisle 2 - Spices",
	}
	body, _ := json.Marshal(onboardReq)
	reqOnboard, _ := http.NewRequest(http.MethodPost, "/api/v1/products/onboard", bytes.NewReader(body))
	reqOnboard.Header.Set("Content-Type", "application/json")
	wOnboard := httptest.NewRecorder()
	r.ServeHTTP(wOnboard, reqOnboard)

	if wOnboard.Code != http.StatusCreated && wOnboard.Code != http.StatusOK {
		t.Fatalf("expected 201 Created for onboard, got %d: %s", wOnboard.Code, wOnboard.Body.String())
	}
}

func TestCustomerCreationAndLedger(t *testing.T) {
	r, repo := setupTestRouter(t)

	// Create customer with initial due
	cust, err := repo.CreateCustomer(&models.Customer{
		Name:       "Kamal Ahmed",
		Phone:      "+8801811223344",
		CurrentDue: 250.0,
	})
	if err != nil {
		t.Fatalf("failed to create customer: %v", err)
	}

	if len(cust.Ledger) == 0 {
		t.Fatalf("expected initial ledger entry for customer with initial due")
	}
	if cust.Ledger[0].CreditChange != 250.0 {
		t.Fatalf("expected 250.0 credit change in initial ledger entry, got %.2f", cust.Ledger[0].CreditChange)
	}

	// GET /api/v1/customers/:id
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/customers/"+cust.ID, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", w.Code)
	}
	var fetched models.Customer
	if err := json.Unmarshal(w.Body.Bytes(), &fetched); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if len(fetched.Ledger) != 1 {
		t.Fatalf("expected 1 ledger record, got %d", len(fetched.Ledger))
	}
}

func TestGroceryRequests(t *testing.T) {
	r, repo := setupTestRouter(t)

	// Create customer
	cust, _ := repo.CreateCustomer(&models.Customer{
		Name:  "Tahmid Hassan",
		Phone: "+8801912345678",
	})

	// 1. Submit Grocery Request
	reqBody := models.CreateGroceryRequestInput{
		StoreID:       models.DefaultStoreID,
		StoreName:     "Test Store",
		CustomerID:    cust.ID,
		CustomerName:  cust.Name,
		CustomerPhone: cust.Phone,
		ItemsText:     "1kg sugar, 2L soybean oil",
		DeliveryType:  "delivery",
		Address:       "House 10, Road 5, Dhanmondi",
		Notes:         "Please deliver before 5 PM",
	}
	body, _ := json.Marshal(reqBody)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/grocery-requests", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201 Created for grocery request, got %d: %s", w.Code, w.Body.String())
	}

	var res struct {
		GroceryRequest *models.GroceryRequest `json:"grocery_request"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
		t.Fatalf("failed to unmarshal grocery request response: %v", err)
	}
	if res.GroceryRequest == nil || res.GroceryRequest.ID == "" {
		t.Fatalf("expected non-empty grocery request ID")
	}
	if res.GroceryRequest.Status != "pending" {
		t.Fatalf("expected status 'pending', got '%s'", res.GroceryRequest.Status)
	}

	// 2. Fetch Grocery Requests for customer
	reqGet, _ := http.NewRequest(http.MethodGet, "/api/v1/grocery-requests?customer_phone="+cust.Phone, nil)
	wGet := httptest.NewRecorder()
	r.ServeHTTP(wGet, reqGet)

	if wGet.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", wGet.Code)
	}
	var getRes struct {
		Requests []*models.GroceryRequest `json:"grocery_requests"`
	}
	json.Unmarshal(wGet.Body.Bytes(), &getRes)
	if len(getRes.Requests) != 1 {
		t.Fatalf("expected 1 grocery request for customer, got %d", len(getRes.Requests))
	}

	// 3. Update status to 'accepted'
	updateBody, _ := json.Marshal(models.UpdateGroceryStatusRequest{Status: "accepted"})
	reqPut, _ := http.NewRequest(http.MethodPut, "/api/v1/grocery-requests/"+res.GroceryRequest.ID+"/status", bytes.NewReader(updateBody))
	reqPut.Header.Set("Content-Type", "application/json")
	wPut := httptest.NewRecorder()
	r.ServeHTTP(wPut, reqPut)

	if wPut.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for status update, got %d", wPut.Code)
	}
	var putRes struct {
		GroceryRequest *models.GroceryRequest `json:"grocery_request"`
	}
	json.Unmarshal(wPut.Body.Bytes(), &putRes)
	if putRes.GroceryRequest.Status != "accepted" {
		t.Fatalf("expected status 'accepted', got '%s'", putRes.GroceryRequest.Status)
	}
}

