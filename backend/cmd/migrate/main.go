package main

import (
	"fmt"
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"fmcg-pos-backend/internal/config"
	"fmcg-pos-backend/internal/models"
)

func main() {
	cfg := config.LoadConfig()

	fmt.Println("==================================================")
	fmt.Println("🚀 FMCG+ PostgreSQL Database Migration Tool")
	fmt.Printf("🎯 Host: %s:%s | DB: %s | User: %s\n", cfg.DBHost, cfg.DBPort, cfg.DBName, cfg.DBUser)
	fmt.Println("==================================================")

	dsn := cfg.GetPostgresDSN()
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		log.Fatalf("❌ Database connection failed: %v\n\nTip: Ensure PostgreSQL is running. E.g.:\n  cd backend && docker compose up -d", err)
	}

	tables := []struct {
		name  string
		model interface{}
	}{
		{"categories", &models.Category{}},
		{"subcategories", &models.Subcategory{}},
		{"manufacturers", &models.Manufacturer{}},
		{"brands", &models.Brand{}},
		{"master_products", &models.MasterProduct{}},
		{"users", &models.User{}},
		{"stores", &models.Store{}},
		{"store_members", &models.StoreMember{}},
		{"refresh_tokens", &models.RefreshToken{}},
		{"store_inventory", &models.StoreInventory{}},
		{"customers", &models.Customer{}},
		{"transactions", &models.Transaction{}},
		{"transaction_items", &models.TransactionItem{}},
		{"khata_entries", &models.KhataEntry{}},
		{"stock_adjustments", &models.StockAdjustment{}},
		{"stock_movements", &models.StockMovement{}},
	}

	// Drop dependent view if exists so column types can be synced safely
	db.Exec("DROP VIEW IF EXISTS products CASCADE;")
	// Clean up raw SQL constraints that conflict with GORM index management
	db.Exec("ALTER TABLE master_products DROP CONSTRAINT IF EXISTS master_products_barcode_key CASCADE;")
	db.Exec("ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_phone_key CASCADE;")

	fmt.Println("\n📦 Running auto-migrations for 3NF normalized POS schema...")
	for _, t := range tables {
		fmt.Printf("   • Migrating '%s'...", t.name)
		if err := db.AutoMigrate(t.model); err != nil {
			log.Fatalf("\n❌ Failed to migrate '%s': %v", t.name, err)
		}
		fmt.Println(" ✅ Done")
	}

	// Recreate products view
	fmt.Print("   • Recreating view 'products'...")
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
		log.Fatalf("\n❌ Failed to create view 'products': %v", err)
	}
	fmt.Println(" ✅ Done")

	fmt.Println("\n🔍 Verifying schema:")
	for _, t := range tables {
		var count int64
		db.Table(t.name).Count(&count)
		fmt.Printf("   • Table: %-20s (Current Rows: %d)\n", t.name, count)
	}

	fmt.Println("\n==================================================")
	fmt.Println("✨ All 3NF normalized tables migrated successfully!")
	fmt.Println("==================================================")
}
