package services

import (
	"errors"
	"fmt"
	"strings"

	"fmcg-pos-backend/internal/models"
	"fmcg-pos-backend/internal/repository"
)

// CheckoutService encapsulates retail checkout and POS transaction business logic.
type CheckoutService interface {
	ProcessCheckout(req *models.CheckoutRequest, resolvedStoreID string) (*models.Transaction, error)
}

type checkoutService struct {
	repo repository.Repository
}

// NewCheckoutService creates a new instance of CheckoutService.
func NewCheckoutService(repo repository.Repository) CheckoutService {
	return &checkoutService{
		repo: repo,
	}
}

// ProcessCheckout executes the full end-to-end POS checkout lifecycle:
// 1. Validates transaction items
// 2. Resolves and updates catalog item details (prices, units, barcodes) & decrements inventory
// 3. Calculates subtotal, discounts, applied payments, and remaining khata dues
// 4. Resolves customer profile and store association
// 5. Persists the transaction
// 6. Synchronizes customer Khata credit balance and passbook if due remains
func (s *checkoutService) ProcessCheckout(req *models.CheckoutRequest, resolvedStoreID string) (*models.Transaction, error) {
	if req == nil {
		return nil, errors.New("checkout request cannot be nil")
	}
	if len(req.Items) == 0 {
		return nil, errors.New("checkout items list cannot be empty")
	}

	// 1. Resolve item attributes and decrement inventory
	resolvedItems, subtotal, itemSummaries := s.resolveAndDeductItems(req.Items)

	// 2. Calculate totals and payment breakdown
	total, paid, remainingDue := s.calculateTotals(subtotal, req.Discount, req.PaidAmount, req.PaymentMethod)

	// 3. Resolve customer identity and store routing
	custID, customerName, finalStoreID := s.resolveCustomerAndStore(req.CustomerID, req.CustomerName, resolvedStoreID)

	// 4. Construct transaction record
	tx := &models.Transaction{
		StoreID:       finalStoreID,
		CustomerID:    custID,
		CustomerName:  customerName,
		Items:         resolvedItems,
		Subtotal:      subtotal,
		Discount:      req.Discount,
		Total:         total,
		PaidAmount:    paid,
		RemainingDue:  remainingDue,
		PaymentMethod: req.PaymentMethod,
	}

	// 5. Persist transaction
	createdTx, err := s.repo.CreateTransaction(tx)
	if err != nil {
		return nil, fmt.Errorf("failed to persist transaction: %w", err)
	}

	// 6. Update Khata ledger if credit balance is outstanding
	if custID != nil && remainingDue > 0 {
		_ = s.recordKhataCredit(*custID, createdTx.OrderNumber, total, paid, remainingDue, itemSummaries)
	}

	return createdTx, nil
}

// resolveAndDeductItems enriches each transaction item with store/master product metadata,
// decrements store inventory, and accumulates subtotal and item summaries.
func (s *checkoutService) resolveAndDeductItems(rawItems []models.TransactionItem) ([]models.TransactionItem, float64, []string) {
	var subtotal float64
	var summaries []string
	items := make([]models.TransactionItem, len(rawItems))
	copy(items, rawItems)

	for i := range items {
		item := &items[i]
		s.resolveItemDetails(item)

		item.TotalPrice = item.UnitPrice * float64(item.Quantity)
		subtotal += item.TotalPrice
		summaries = append(summaries, fmt.Sprintf("%s × %d", item.Name, item.Quantity))
	}

	return items, subtotal, summaries
}

// resolveItemDetails looks up product catalog details by ID/barcode and decrements stock.
func (s *checkoutService) resolveItemDetails(item *models.TransactionItem) {
	prod, err := s.repo.GetProductByID(item.ProductID)
	if err != nil && item.Barcode != "" {
		prod, _ = s.repo.GetProductByBarcode(item.Barcode)
	}
	if err != nil && prod == nil && item.ProductID != "" {
		prod, _ = s.repo.GetProductByBarcode(item.ProductID)
	}

	if prod != nil {
		item.ProductID = prod.ID
		if item.Name == "" {
			item.Name = prod.Name
		}
		if item.Barcode == "" {
			item.Barcode = prod.Barcode
		}
		if item.UnitPrice <= 0 {
			item.UnitPrice = prod.SellingPrice
		}
		if item.Unit == "" {
			item.Unit = prod.Unit
		}
		item.CostPrice = prod.CostPrice
		_ = s.repo.DecrementStock(prod.ID, item.Quantity)
		return
	}

	// Fallback: Check master FMCG product catalog by barcode
	if item.Barcode != "" {
		if mp, _ := s.repo.GetMasterProductByBarcode(item.Barcode); mp != nil {
			if item.Name == "" {
				item.Name = mp.ProductName
			}
			if item.UnitPrice <= 0 {
				item.UnitPrice = mp.SuggestedMRP
			}
			if item.CostPrice <= 0 {
				item.CostPrice = mp.SuggestedCost
			}
			if item.Unit == "" {
				item.Unit = mp.Unit
			}
		}
	}

	// Safe default fallbacks for uncataloged walk-in items
	if item.Name == "" {
		item.Name = "Item"
	}
	if item.Barcode == "" {
		item.Barcode = "N/A"
	}
	if item.Unit == "" {
		item.Unit = "pcs"
	}
	if item.UnitPrice <= 0 {
		item.UnitPrice = 10.0
	}
}

// calculateTotals applies discounts and calculates payment amounts and remaining dues.
func (s *checkoutService) calculateTotals(subtotal, discount, paidAmount float64, paymentMethod string) (total, paid, remainingDue float64) {
	total = subtotal - discount
	if total < 0 {
		total = 0
	}

	paid = paidAmount
	switch paymentMethod {
	case "cash", "bkash", "nagad", "card":
		if paid <= 0 {
			paid = total
		}
	case "credit":
		paid = 0
	}

	if paid > total {
		paid = total
	}

	remainingDue = total - paid
	return total, paid, remainingDue
}

// resolveCustomerAndStore resolves the customer name and ID, and resolves the store ID.
func (s *checkoutService) resolveCustomerAndStore(customerID, customerName, resolvedStoreID string) (*string, string, string) {
	name := customerName
	if name == "" {
		name = "Walk-in Cash Customer"
	}

	var custID *string
	if customerID != "" {
		cust, err := s.repo.GetCustomerByID(customerID)
		if err == nil && cust != nil {
			name = cust.Name
			custID = &customerID

			// Fallback store ID from customer record if not explicitly determined
			if (resolvedStoreID == "" || resolvedStoreID == models.DefaultStoreID) && cust.StoreID != "" && cust.StoreID != models.DefaultStoreID {
				resolvedStoreID = cust.StoreID
			}
		}
	}

	if resolvedStoreID == "" {
		resolvedStoreID = models.DefaultStoreID
	}

	return custID, name, resolvedStoreID
}

// recordKhataCredit registers a new credit entry in the customer's digital Khata passbook.
func (s *checkoutService) recordKhataCredit(customerID, orderNumber string, total, paid, remainingDue float64, itemSummaries []string) error {
	desc := strings.Join(itemSummaries, ", ")
	_, _, err := s.repo.AddCustomerCredit(customerID, orderNumber, total, paid, remainingDue, desc)
	return err
}
