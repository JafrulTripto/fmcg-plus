package main

import (
	"fmt"
	"log"

	"fmcg-pos-backend/internal/config"
	"fmcg-pos-backend/internal/handlers"
	"fmcg-pos-backend/internal/repository"
	"fmcg-pos-backend/internal/router"
	"fmcg-pos-backend/internal/services"
)

func main() {
	cfg := config.LoadConfig()

	fmt.Println("==================================================")
	fmt.Println("🚀 Starting FMCG+ Retail POS Backend Server (Go/Gin)")
	fmt.Printf("📦 S3 Storage Bucket: %s (Region: %s)\n", cfg.S3Bucket, cfg.S3Region)
	fmt.Printf("🔌 Listening on Port: %s\n", cfg.Port)
	fmt.Println("==================================================")

	// Initialize Repository (PostgreSQL with smart dev fallback)
	var repo repository.Repository
	var err error

	repo, err = repository.NewPostgresRepository(cfg.GetPostgresDSN(), cfg.DataFilePath)
	if err == nil {
		fmt.Printf("🐘 Database: PostgreSQL Connected (Host: %s:%s, DB: %s)\n", cfg.DBHost, cfg.DBPort, cfg.DBName)
	} else {
		fmt.Printf("⚠️ PostgreSQL not connected (%v)\n", err)
		fmt.Println("💾 Using In-Memory Repository pre-seeded with authentic Bangladesh FMCG products.")
		repo, err = repository.NewMemoryRepository(cfg.DataFilePath)
		if err != nil {
			log.Fatalf("Failed to initialize repository: %v", err)
		}
	}

	// Initialize Storage Service (S3)
	storage := services.NewStorageService(cfg)

	// Initialize Auth & Pluggable OTP Services
	jwtService := services.NewJWTService(cfg)
	otpProvider := services.NewOTPProvider(cfg)
	fmt.Printf("🔑 Auth & Identity Service: Ready (Provider: %s)\n", otpProvider.Name())

	// Initialize Nishchit SMS Infrastructure Client
	var nishchitClient *services.NishchitClient
	if cfg.NishchitAPIKey != "" {
		nishchitClient = services.NewNishchitClient(cfg.NishchitAPIKey, cfg.NishchitBaseURL, cfg.NishchitFrom)
		mode := "Live Mode (Real Carrier Dispatch)"
		if nishchitClient.IsTestKey() {
			mode = "Test Mode (Deterministic Sandbox, Zero Credits Charged)"
		}
		fmt.Printf("📱 Nishchit SMS Infrastructure: Connected (%s | Base: %s)\n", mode, cfg.NishchitBaseURL)
	} else {
		fmt.Println("ℹ️  Nishchit SMS Gateway: Not configured (running with mock/local fallback). Set NISHCHIT_API_KEY in .env")
	}

	// Initialize FCM Service
	var fcmService *services.FCMService
	if cfg.FCMCredentialsPath != "" {
		svc, err := services.NewFCMService(cfg.FCMCredentialsPath)
		if err == nil {
			fcmService = svc
			fmt.Println("🔔 FCM Push Notification Service: Connected")
		} else {
			fmt.Printf("⚠️ FCM service init failed: %v\n", err)
		}
	} else {
		fmt.Println("ℹ️  FCM Push Notification Service: Not configured. Set FCM_CREDENTIALS_PATH in .env")
	}

	// Initialize Handlers
	h := handlers.NewHandlers(repo, storage, jwtService, otpProvider, nishchitClient, fcmService)

	// Setup Router
	r := router.SetupRouter(cfg, h)

	// Run Server
	addr := fmt.Sprintf(":%s", cfg.Port)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Server failed to run: %v", err)
	}
}
