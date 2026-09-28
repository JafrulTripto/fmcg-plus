package router

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"fmcg-pos-backend/internal/config"
	"fmcg-pos-backend/internal/handlers"
	"fmcg-pos-backend/internal/middleware"
)

func SetupRouter(cfg *config.Config, h *handlers.Handlers) *gin.Engine {
	r := gin.Default()

	// CORS Middleware for Mobile and Web
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	})

	// Static file serving for local image uploads
	r.Static("/uploads", cfg.UploadsDir)

	// API v1 Group
	v1 := r.Group("/api/v1")
	{
		// Health
		v1.GET("/health", h.HealthCheck)

		// Authentication, Pluggable OTP & Merchant/Customer Onboarding
		auth := v1.Group("/auth")
		{
			auth.POST("/check-phone", h.Auth.CheckPhone)
			auth.GET("/check-phone", h.Auth.CheckPhone)
			auth.POST("/send-otp", h.Auth.SendOTP)
			auth.POST("/verify-otp", h.Auth.VerifyOTP)
			auth.POST("/register-merchant", h.Auth.RegisterMerchant)
			auth.POST("/register-customer", h.Auth.RegisterCustomer)
			auth.POST("/login", h.Auth.Login)
			auth.POST("/refresh-token", h.Auth.RefreshToken)
			auth.POST("/logout", h.Auth.Logout)
			auth.GET("/me", middleware.AuthMiddleware(h.JWTService), h.Auth.GetMe)
		}

		// Dashboard
		v1.GET("/dashboard", h.GetDashboard)

		// Products & Store Inventory POS Scanning
		products := v1.Group("/products")
		{
			products.GET("", h.GetProducts)
			products.GET("/:id", h.GetProductByID)
			products.GET("/scan/:barcode", h.ScanBarcode)
			products.POST("/onboard", h.OnboardMasterProduct)
			products.POST("", h.CreateProduct)
			products.PUT("/:id", h.UpdateProduct)
			products.DELETE("/:id", h.DeleteProduct)
			products.POST("/:id/adjust-stock", h.AdjustStock)
		}

		// Canonical FMCG Master Catalog (623 Bangladesh Products)
		master := v1.Group("/master-catalog")
		{
			master.GET("", h.GetMasterProducts)
			master.GET("/:barcode", h.GetMasterProductByBarcode)
		}

		// Customers & Khata Ledger
		customers := v1.Group("/customers")
		{
			customers.GET("", h.GetCustomers)
			customers.GET("/:id", h.GetCustomerByID)
			customers.POST("", h.CreateCustomer)
			customers.POST("/:id/payments", h.RecordCustomerPayment)
			customers.POST("/:id/send-reminder-sms", h.SendKhataReminderSMS)
		}

		// Nishchit SMS Dispatch
		sms := v1.Group("/sms")
		{
			sms.POST("/send", h.SendSMS)
		}

		// Transactions & Checkout
		transactions := v1.Group("/transactions")
		{
			transactions.GET("", h.GetRecentTransactions)
			transactions.POST("/checkout", h.Checkout)
			transactions.GET("/:id/receipt", h.GetReceipt)
		}

		// Storage & S3
		storage := v1.Group("/storage")
		{
			storage.POST("/upload", h.UploadImage)
			storage.GET("/presigned-url", h.GetPresignedUploadURL)
		}
	}

	return r
}
