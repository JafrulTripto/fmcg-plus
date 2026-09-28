package handlers

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"fmcg-pos-backend/internal/models"
	"fmcg-pos-backend/internal/repository"
	"fmcg-pos-backend/internal/services"
)

type AuthHandler struct {
	repo        repository.Repository
	jwtService  *services.JWTService
	otpProvider services.OTPProvider
}

func NewAuthHandler(repo repository.Repository, jwtService *services.JWTService, otpProvider services.OTPProvider) *AuthHandler {
	return &AuthHandler{
		repo:        repo,
		jwtService:  jwtService,
		otpProvider: otpProvider,
	}
}

// SendOTP handles dispatching an OTP code to a phone number
// POST /api/v1/auth/check-phone
// GET /api/v1/auth/check-phone
func (h *AuthHandler) CheckPhone(c *gin.Context) {
	phone := strings.TrimSpace(c.Query("phone"))
	if phone == "" {
		var req models.CheckPhoneRequest
		if err := c.ShouldBindJSON(&req); err == nil {
			phone = strings.TrimSpace(req.Phone)
		}
	}

	if phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Phone number is required"})
		return
	}

	user, err := h.repo.GetUserByPhone(phone)
	if err != nil || user == nil {
		c.JSON(http.StatusOK, models.CheckPhoneResponse{
			Registered: false,
			Phone:      phone,
			Message:    "Phone number is not registered",
		})
		return
	}

	storeName := ""
	stores, _ := h.repo.GetStoresByUserID(user.ID)
	if len(stores) > 0 {
		storeName = stores[0].Name
	}

	c.JSON(http.StatusOK, models.CheckPhoneResponse{
		Registered: true,
		Phone:      phone,
		Role:       user.Role,
		Name:       user.Name,
		StoreName:  storeName,
		Message:    "This phone number is already registered",
	})
}

// POST /api/v1/auth/send-otp
func (h *AuthHandler) SendOTP(c *gin.Context) {
	var req models.SendOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	phone := strings.TrimSpace(req.Phone)
	if phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Phone number is required"})
		return
	}

	// If sending OTP for registration, enforce that the user is not already registered
	purpose := strings.TrimSpace(req.Purpose)
	if purpose == "" {
		purpose = strings.TrimSpace(c.Query("purpose"))
	}
	if strings.EqualFold(purpose, "register") {
		existingUser, _ := h.repo.GetUserByPhone(phone)
		if existingUser != nil {
			storeName := ""
			stores, _ := h.repo.GetStoresByUserID(existingUser.ID)
			if len(stores) > 0 {
				storeName = stores[0].Name
			}
			c.JSON(http.StatusConflict, gin.H{
				"error":      "এই নম্বরটি ইতিমধ্যে নিবন্ধিত রয়েছে। দয়া করে লগইন করুন।",
				"registered": true,
				"phone":      phone,
				"store_name": storeName,
				"role":       existingUser.Role,
				"code":       "ALREADY_REGISTERED",
			})
			return
		}
	}

	sessionID, err := h.otpProvider.SendOTP(c.Request.Context(), phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send OTP", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.SendOTPResponse{
		SessionID: sessionID,
		Provider:  h.otpProvider.Name(),
		Message:   fmt.Sprintf("OTP sent successfully via %s provider", h.otpProvider.Name()),
	})
}

// VerifyOTP validates the code or Firebase token and issues a temporary verification token
// POST /api/v1/auth/verify-otp
func (h *AuthHandler) VerifyOTP(c *gin.Context) {
	var req models.VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	tokenOrCode := strings.TrimSpace(req.Code)
	if tokenOrCode == "" {
		tokenOrCode = strings.TrimSpace(req.FirebaseToken)
	}

	if tokenOrCode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Either code or firebase_token must be provided"})
		return
	}

	verified, verifiedPhone, err := h.otpProvider.VerifyOTP(c.Request.Context(), req.Phone, tokenOrCode)
	if err != nil || !verified {
		errMsg := "Verification failed"
		if err != nil {
			errMsg = err.Error()
		}
		c.JSON(http.StatusUnauthorized, gin.H{"error": errMsg, "verified": false})
		return
	}

	// Generate a 15-minute proof-of-verification token for registration or secure actions
	vToken, err := h.jwtService.GenerateVerificationToken(verifiedPhone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate verification proof", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.VerifyOTPResponse{
		Verified:          true,
		Phone:             verifiedPhone,
		VerificationToken: vToken,
		Message:           "Phone successfully verified",
	})
}

// RegisterMerchant handles merchant onboarding: creates User, Store, and StoreMember
// POST /api/v1/auth/register-merchant
func (h *AuthHandler) RegisterMerchant(c *gin.Context) {
	var req models.RegisterMerchantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	phone := strings.TrimSpace(req.Phone)

	// If verification token is provided, enforce that it matches the phone
	if req.VerificationToken != "" {
		vPhone, err := h.jwtService.ValidateVerificationToken(req.VerificationToken)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired verification token", "details": err.Error()})
			return
		}
		// Match the suffix/number
		if !strings.HasSuffix(phone, strings.TrimPrefix(vPhone, "+88")) && phone != vPhone {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Phone number does not match verification token"})
			return
		}
	}

	// Check if user already exists
	existingUser, _ := h.repo.GetUserByPhone(phone)
	if existingUser != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "User with this phone number already exists"})
		return
	}

	// Hash PIN
	pinHash, err := h.jwtService.HashCredential(req.PIN)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to securely hash PIN"})
		return
	}

	// 1. Create User
	user, err := h.repo.CreateUser(&models.User{
		Phone:         phone,
		Name:          strings.TrimSpace(req.Name),
		PasswordHash:  pinHash,
		Role:          "merchant",
		IsActive:      true,
		PhoneVerified: true,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user account", "details": err.Error()})
		return
	}

	// 2. Create Store Tenant
	store, err := h.repo.CreateStore(&models.Store{
		Name:       strings.TrimSpace(req.StoreName),
		OwnerName:  user.Name,
		OwnerPhone: user.Phone,
		Address:    strings.TrimSpace(req.StoreAddress),
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create store tenant", "details": err.Error()})
		return
	}

	// 3. Create StoreMember (Owner)
	member, err := h.repo.CreateStoreMember(&models.StoreMember{
		StoreID:    store.ID,
		UserID:     user.ID,
		MemberRole: "owner",
		IsActive:   true,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to assign store ownership", "details": err.Error()})
		return
	}

	// 4. Generate Auth Token Pair
	accessToken, refreshToken, expiresIn, err := h.jwtService.GenerateTokenPair(user, store.ID, member.MemberRole)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate session tokens", "details": err.Error()})
		return
	}

	// 5. Store Refresh Token
	_ = h.repo.StoreRefreshToken(&models.RefreshToken{
		UserID:    user.ID,
		TokenHash: h.jwtService.HashRefreshToken(refreshToken),
		ExpiresAt: time.Now().Add(h.jwtService.RefreshExpiryDuration()),
		IsRevoked: false,
	})

	c.JSON(http.StatusCreated, models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
		TokenType:    "Bearer",
		User:         user.ToProfile(),
		Store:        store,
		MemberRole:   member.MemberRole,
	})
}

// RegisterCustomer handles consumer registration for the Khata Portal
// POST /api/v1/auth/register-customer
func (h *AuthHandler) RegisterCustomer(c *gin.Context) {
	var req models.RegisterCustomerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	phone := strings.TrimSpace(req.Phone)

	if req.VerificationToken != "" {
		vPhone, err := h.jwtService.ValidateVerificationToken(req.VerificationToken)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired verification token", "details": err.Error()})
			return
		}
		if !strings.HasSuffix(phone, strings.TrimPrefix(vPhone, "+88")) && phone != vPhone {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Phone number does not match verification token"})
			return
		}
	}

	existingUser, _ := h.repo.GetUserByPhone(phone)
	if existingUser != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "User with this phone number already exists"})
		return
	}

	pinHash, err := h.jwtService.HashCredential(req.PIN)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to securely hash PIN"})
		return
	}

	user, err := h.repo.CreateUser(&models.User{
		Phone:         phone,
		Name:          strings.TrimSpace(req.Name),
		PasswordHash:  pinHash,
		Role:          "customer",
		IsActive:      true,
		PhoneVerified: true,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user account", "details": err.Error()})
		return
	}

	accessToken, refreshToken, expiresIn, err := h.jwtService.GenerateTokenPair(user, "", "")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate tokens", "details": err.Error()})
		return
	}

	_ = h.repo.StoreRefreshToken(&models.RefreshToken{
		UserID:    user.ID,
		TokenHash: h.jwtService.HashRefreshToken(refreshToken),
		ExpiresAt: time.Now().Add(h.jwtService.RefreshExpiryDuration()),
		IsRevoked: false,
	})

	c.JSON(http.StatusCreated, models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
		TokenType:    "Bearer",
		User:         user.ToProfile(),
	})
}

// Login authenticates a user via PIN, Password, or direct OTP/Firebase verification
// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	phone := strings.TrimSpace(req.Phone)
	user, err := h.repo.GetUserByPhone(phone)
	if err != nil || user == nil {
		log.Printf("[LOGIN FAILED] User not found for phone '%s' (variants: %v), err: %v", req.Phone, repository.PhoneVariants(req.Phone), err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid phone number or credentials"})
		return
	}

	if !user.IsActive {
		log.Printf("[LOGIN FAILED] Account deactivated for user: %s (Phone: %s)", user.ID, user.Phone)
		c.JSON(http.StatusForbidden, gin.H{"error": "Account has been deactivated. Please contact support."})
		return
	}

	// 1. PIN or Password authentication
	credential := strings.TrimSpace(req.PIN)
	if credential == "" {
		credential = strings.TrimSpace(req.Password)
	}

	authenticated := false

	if credential != "" {
		authenticated = h.jwtService.CheckCredential(credential, user.PasswordHash)
		if !authenticated {
			log.Printf("[LOGIN FAILED] Incorrect PIN/Password for user '%s' (Phone: '%s', DB Phone: '%s')", user.Name, req.Phone, user.Phone)
		}
	} else if req.OTPCode != "" || req.FirebaseToken != "" {
		// 2. Direct OTP / Firebase login
		tokenOrCode := req.OTPCode
		if tokenOrCode == "" {
			tokenOrCode = req.FirebaseToken
		}
		var otpErr error
		authenticated, _, otpErr = h.otpProvider.VerifyOTP(c.Request.Context(), phone, tokenOrCode)
		if otpErr != nil {
			log.Printf("[LOGIN FAILED] OTP verification failed: %v", otpErr)
			authenticated = false
		}
	}

	if !authenticated {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials or verification code"})
		return
	}

	log.Printf("[LOGIN SUCCESS] User authenticated successfully: '%s' (Phone: '%s')", user.Name, user.Phone)

	// Resolve active store and role
	var store *models.Store
	var memberRole string

	stores, _ := h.repo.GetStoresByUserID(user.ID)
	if len(stores) > 0 {
		store = stores[0]
		if member, err := h.repo.GetStoreMember(store.ID, user.ID); err == nil {
			memberRole = member.MemberRole
		}
	}

	storeID := ""
	if store != nil {
		storeID = store.ID
	}

	accessToken, refreshToken, expiresIn, err := h.jwtService.GenerateTokenPair(user, storeID, memberRole)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate tokens", "details": err.Error()})
		return
	}

	_ = h.repo.StoreRefreshToken(&models.RefreshToken{
		UserID:    user.ID,
		TokenHash: h.jwtService.HashRefreshToken(refreshToken),
		ExpiresAt: time.Now().Add(h.jwtService.RefreshExpiryDuration()),
		IsRevoked: false,
	})

	c.JSON(http.StatusOK, models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
		TokenType:    "Bearer",
		User:         user.ToProfile(),
		Store:        store,
		MemberRole:   memberRole,
	})
}

// RefreshToken rotates tokens and issues a new access token
// POST /api/v1/auth/refresh-token
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req models.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	tokenHash := h.jwtService.HashRefreshToken(req.RefreshToken)
	storedToken, err := h.repo.GetRefreshToken(tokenHash)
	if err != nil || storedToken == nil || storedToken.IsRevoked {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or revoked refresh token"})
		return
	}

	if time.Now().After(storedToken.ExpiresAt) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Refresh token has expired"})
		return
	}

	// Revoke the old refresh token (rotation)
	_ = h.repo.RevokeRefreshToken(tokenHash)

	user, err := h.repo.GetUserByID(storedToken.UserID)
	if err != nil || user == nil || !user.IsActive {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User account no longer active"})
		return
	}

	// Resolve store
	var store *models.Store
	var memberRole string
	stores, _ := h.repo.GetStoresByUserID(user.ID)
	if len(stores) > 0 {
		store = stores[0]
		if member, err := h.repo.GetStoreMember(store.ID, user.ID); err == nil {
			memberRole = member.MemberRole
		}
	}

	storeID := ""
	if store != nil {
		storeID = store.ID
	}

	accessToken, newRefreshToken, expiresIn, err := h.jwtService.GenerateTokenPair(user, storeID, memberRole)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token pair"})
		return
	}

	_ = h.repo.StoreRefreshToken(&models.RefreshToken{
		UserID:    user.ID,
		TokenHash: h.jwtService.HashRefreshToken(newRefreshToken),
		ExpiresAt: time.Now().Add(h.jwtService.RefreshExpiryDuration()),
		IsRevoked: false,
	})

	c.JSON(http.StatusOK, models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		ExpiresIn:    expiresIn,
		TokenType:    "Bearer",
		User:         user.ToProfile(),
		Store:        store,
		MemberRole:   memberRole,
	})
}

// Logout revokes the submitted refresh token
// POST /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	var req models.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err == nil && req.RefreshToken != "" {
		tokenHash := h.jwtService.HashRefreshToken(req.RefreshToken)
		_ = h.repo.RevokeRefreshToken(tokenHash)
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Successfully logged out",
	})
}

// GetMe returns the authenticated profile and associated stores
// GET /api/v1/auth/me
func (h *AuthHandler) GetMe(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDVal.(string)

	user, err := h.repo.GetUserByID(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	stores, _ := h.repo.GetStoresByUserID(user.ID)
	var activeStore *models.Store
	var memberRole string
	if len(stores) > 0 {
		activeStore = stores[0]
		if member, err := h.repo.GetStoreMember(activeStore.ID, user.ID); err == nil {
			memberRole = member.MemberRole
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"user":        user.ToProfile(),
		"store":       activeStore,
		"member_role": memberRole,
		"all_stores":  stores,
	})
}
