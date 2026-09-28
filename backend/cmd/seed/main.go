package main

import (
	"fmt"
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"fmcg-pos-backend/internal/config"
	"fmcg-pos-backend/internal/models"
)

func main() {
	cfg := config.LoadConfig()

	fmt.Println("==================================================")
	fmt.Println("🌱 FMCG+ 3NF Database Seeder CLI")
	fmt.Printf("🎯 Target Database: PostgreSQL %s:%s/%s\n", cfg.DBHost, cfg.DBPort, cfg.DBName)
	fmt.Println("==================================================")

	dsn := cfg.GetPostgresDSN()
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		log.Fatalf("❌ Failed to connect to PostgreSQL: %v\nCheck that Docker/PostgreSQL is running (e.g. 'docker compose up -d')", err)
	}

	// Try reading seed.sql first
	sqlPaths := []string{
		"seed.sql",
		"backend/seed.sql",
		"../seed.sql",
		"init.sql",
		"backend/init.sql",
	}

	var sqlBytes []byte
	var chosenPath string
	for _, p := range sqlPaths {
		b, err := os.ReadFile(p)
		if err == nil && len(b) > 0 {
			sqlBytes = b
			chosenPath = p
			break
		}
	}

	if len(sqlBytes) > 0 {
		fmt.Printf("🚀 Executing normalized SQL seed script from %s (%d bytes)...\n", chosenPath, len(sqlBytes))
		if err := db.Exec(string(sqlBytes)).Error; err != nil {
			log.Fatalf("❌ SQL script execution failed: %v", err)
		}
		fmt.Println("✅ SQL seed script executed successfully!")
	} else {
		fmt.Println("⚙️  Running database auto-migrations...")
		if err := db.AutoMigrate(
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
		); err != nil {
			log.Fatalf("❌ Migration failed: %v", err)
		}
	}

	// Verification
	fmt.Println("\n🔍 Database Master Statistics:")
	var masterCount, storeInvCount, custCount, txCount int64
	db.Table("master_products").Count(&masterCount)
	db.Table("store_inventory").Count(&storeInvCount)
	db.Table("customers").Count(&custCount)
	db.Table("transactions").Count(&txCount)

	fmt.Printf("   • Canonical Master Products: %d / 623 verified items\n", masterCount)
	fmt.Printf("   • Store Shelf Inventory:     %d products in stock\n", storeInvCount)
	fmt.Printf("   • Customer Profiles:         %d accounts with Khata ledger\n", custCount)
	fmt.Printf("   • Recorded Transactions:     %d orders\n", txCount)

	fmt.Println("\n==================================================")
	fmt.Println("✨ FMCG+ Database Ready for POS & Mobile Operations!")
	fmt.Println("==================================================")
}
