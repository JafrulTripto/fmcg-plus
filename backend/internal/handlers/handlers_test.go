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
	h := handlers.NewHandlers(repo, storage, jwtService, otpProvider, nil)
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

	payReq := models.RecordPaymentRequest{
		Amount: 170.0,
		Method: "bkash",
		Notes:  "Settled via bKash",
	}
	body, _ := json.Marshal(payReq)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/customers/"+cust.ID+"/payments", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for customer payment, got %d: %s", w.Code, w.Body.String())
	}
}

func TestThreeStateBarcodeResolution(t *testing.T) {
	r, repo := setupTestRouter(t)

	// Onboard Radhuni Falooda Mix so it is stocked on shelf in store
	_, err := repo.OnboardMasterProduct(&models.OnboardMasterProductRequest{
		StoreID:         "store_default",
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
		StoreID:         "store_default",
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

