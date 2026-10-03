package services_test

import (
	"testing"

	"fmcg-pos-backend/internal/config"
	"fmcg-pos-backend/internal/models"
	"fmcg-pos-backend/internal/repository"
	"fmcg-pos-backend/internal/services"
)

func setupTestService(t *testing.T) (services.CheckoutService, repository.Repository) {
	cfg := config.LoadConfig()
	repo, err := repository.NewMemoryRepository(cfg.DataFilePath)
	if err != nil {
		t.Fatalf("failed to init repository: %v", err)
	}
	return services.NewCheckoutService(repo), repo
}

func TestProcessCheckout_Success(t *testing.T) {
	svc, repo := setupTestService(t)

	prod, err := repo.CreateProduct(&models.Product{
		Name:         "Teer Fortified Soyabean Oil 1L",
		SellingPrice: 175.0,
		CostPrice:    160.0,
		Stock:        50,
	})
	if err != nil {
		t.Fatalf("failed to create product: %v", err)
	}

	req := &models.CheckoutRequest{
		PaymentMethod: "cash",
		Discount:      15.0,
		Items: []models.TransactionItem{
			{
				ProductID: prod.ID,
				Quantity:  2,
			},
		},
	}

	tx, err := svc.ProcessCheckout(req, models.DefaultStoreID)
	if err != nil {
		t.Fatalf("unexpected checkout error: %v", err)
	}

	if tx.Subtotal != 350.0 {
		t.Errorf("expected subtotal 350, got %f", tx.Subtotal)
	}
	if tx.Discount != 15.0 {
		t.Errorf("expected discount 15, got %f", tx.Discount)
	}
	if tx.Total != 335.0 {
		t.Errorf("expected total 335, got %f", tx.Total)
	}
	if tx.PaidAmount != 335.0 {
		t.Errorf("expected paid 335, got %f", tx.PaidAmount)
	}
	if tx.RemainingDue != 0.0 {
		t.Errorf("expected remaining due 0, got %f", tx.RemainingDue)
	}

	// Verify inventory decremented
	updatedProd, _ := repo.GetProductByID(prod.ID)
	if updatedProd.Stock != 48 {
		t.Errorf("expected stock 48, got %d", updatedProd.Stock)
	}
}

func TestProcessCheckout_CreditSaleKhataUpdate(t *testing.T) {
	svc, repo := setupTestService(t)

	cust, err := repo.CreateCustomer(&models.Customer{
		Name:  "Kabir Hossain",
		Phone: "+8801811223344",
	})
	if err != nil {
		t.Fatalf("failed to create customer: %v", err)
	}

	prod, _ := repo.CreateProduct(&models.Product{
		Name:         "ACI Pure Salt 1kg",
		SellingPrice: 40.0,
		CostPrice:    32.0,
		Stock:        100,
	})

	req := &models.CheckoutRequest{
		CustomerID:    cust.ID,
		PaymentMethod: "credit",
		Items: []models.TransactionItem{
			{
				ProductID: prod.ID,
				Quantity:  3,
			},
		},
	}

	tx, err := svc.ProcessCheckout(req, models.DefaultStoreID)
	if err != nil {
		t.Fatalf("unexpected checkout error: %v", err)
	}

	if tx.Total != 120.0 {
		t.Errorf("expected total 120, got %f", tx.Total)
	}
	if tx.PaidAmount != 0.0 {
		t.Errorf("expected paid 0 for credit sale, got %f", tx.PaidAmount)
	}
	if tx.RemainingDue != 120.0 {
		t.Errorf("expected remaining due 120, got %f", tx.RemainingDue)
	}

	// Verify Customer Khata balance updated
	updatedCust, _ := repo.GetCustomerByID(cust.ID)
	if updatedCust.CurrentDue != 120.0 {
		t.Errorf("expected customer due 120, got %f", updatedCust.CurrentDue)
	}
	if len(updatedCust.Ledger) == 0 {
		t.Errorf("expected customer ledger entry created")
	}
}

func TestProcessCheckout_EmptyItemsValidation(t *testing.T) {
	svc, _ := setupTestService(t)

	req := &models.CheckoutRequest{
		PaymentMethod: "cash",
		Items:         []models.TransactionItem{},
	}

	_, err := svc.ProcessCheckout(req, models.DefaultStoreID)
	if err == nil {
		t.Errorf("expected error for empty items, got nil")
	}
}

func TestProcessCheckout_OverpaidClamp(t *testing.T) {
	svc, repo := setupTestService(t)

	prod, _ := repo.CreateProduct(&models.Product{
		Name:         "Pran Frooto 250ml",
		SellingPrice: 30.0,
		Stock:        20,
	})

	req := &models.CheckoutRequest{
		PaymentMethod: "cash",
		PaidAmount:    100.0, // Customer handed 100 for 60 tk bill
		Items: []models.TransactionItem{
			{
				ProductID: prod.ID,
				Quantity:  2,
			},
		},
	}

	tx, err := svc.ProcessCheckout(req, models.DefaultStoreID)
	if err != nil {
		t.Fatalf("unexpected checkout error: %v", err)
	}

	if tx.Total != 60.0 {
		t.Errorf("expected total 60, got %f", tx.Total)
	}
	if tx.PaidAmount != 60.0 {
		t.Errorf("expected paid amount clamped to total 60, got %f", tx.PaidAmount)
	}
	if tx.RemainingDue != 0.0 {
		t.Errorf("expected remaining due 0, got %f", tx.RemainingDue)
	}
}
