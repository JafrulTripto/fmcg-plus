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

func setupTestApp() (*handlers.Handlers, http.Handler) {
	cfg := &config.Config{
		JWTSecret:            "test-jwt-secret-key-32-bytes-long!",
		JWTAccessExpiryHours: 1,
		JWTRefreshExpiryDays: 30,
		OTPProvider:          "mock",
	}

	repo, _ := repository.NewMemoryRepository("")
	storage := services.NewStorageService(cfg)
	jwtService := services.NewJWTService(cfg)
	otpProvider := services.NewOTPProvider(cfg)

	h := handlers.NewHandlers(repo, storage, jwtService, otpProvider, nil)
	r := router.SetupRouter(cfg, h)

	return h, r
}

func TestAuthFlow_OTP_RegisterMerchant_Login_Me(t *testing.T) {
	_, r := setupTestApp()

	// 1. Send OTP
	sendReq := models.SendOTPRequest{Phone: "01711223344"}
	body, _ := json.Marshal(sendReq)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/send-otp", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", w.Code, w.Body.String())
	}

	var sendResp models.SendOTPResponse
	_ = json.Unmarshal(w.Body.Bytes(), &sendResp)
	if sendResp.Provider != "mock" {
		t.Errorf("expected mock provider, got %s", sendResp.Provider)
	}

	// 2. Verify OTP (using mock bypass code 123456)
	verifyReq := models.VerifyOTPRequest{
		Phone: "01711223344",
		Code:  "123456",
	}
	body, _ = json.Marshal(verifyReq)
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("verify OTP failed: %d %s", w.Code, w.Body.String())
	}

	var verifyResp models.VerifyOTPResponse
	_ = json.Unmarshal(w.Body.Bytes(), &verifyResp)
	if !verifyResp.Verified || verifyResp.VerificationToken == "" {
		t.Fatalf("expected verified token, got %+v", verifyResp)
	}

	// 3. Register Merchant
	regReq := models.RegisterMerchantRequest{
		Phone:             "01711223344",
		Name:              "Babul Hossain",
		StoreName:         "Babul General Store",
		StoreAddress:      "Mirpur-10, Dhaka",
		PIN:               "1234",
		VerificationToken: verifyResp.VerificationToken,
	}
	body, _ = json.Marshal(regReq)
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/register-merchant", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("register merchant failed: %d %s", w.Code, w.Body.String())
	}

	var authResp models.AuthResponse
	_ = json.Unmarshal(w.Body.Bytes(), &authResp)
	if authResp.AccessToken == "" || authResp.RefreshToken == "" {
		t.Fatalf("expected tokens in auth response, got %+v", authResp)
	}
	if authResp.Store == nil || authResp.Store.Name != "Babul General Store" {
		t.Fatalf("expected store details in auth response, got %+v", authResp.Store)
	}
	if authResp.MemberRole != "owner" {
		t.Errorf("expected member role 'owner', got %s", authResp.MemberRole)
	}

	accessToken := authResp.AccessToken
	refreshToken := authResp.RefreshToken

	// 4. Duplicate Registration Should Fail
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/register-merchant", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusConflict {
		t.Errorf("expected 409 Conflict on duplicate registration, got %d", w.Code)
	}

	// 5. Test Access Protected /me Endpoint
	req, _ = http.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+accessToken)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("get /me failed: %d %s", w.Code, w.Body.String())
	}

	var meResp map[string]interface{}
	_ = json.Unmarshal(w.Body.Bytes(), &meResp)
	userMap, ok := meResp["user"].(map[string]interface{})
	if !ok || userMap["phone"] != "01711223344" {
		t.Errorf("unexpected user in /me response: %+v", meResp)
	}

	// 6. Test Login with PIN
	loginReq := models.LoginRequest{
		Phone: "01711223344",
		PIN:   "1234",
	}
	body, _ = json.Marshal(loginReq)
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("login failed: %d %s", w.Code, w.Body.String())
	}

	// 7. Test Login with Wrong PIN
	badLoginReq := models.LoginRequest{
		Phone: "01711223344",
		PIN:   "9999",
	}
	body, _ = json.Marshal(badLoginReq)
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 Unauthorized for bad PIN, got %d", w.Code)
	}

	// 8. Refresh Token Rotation
	refReq := models.RefreshTokenRequest{RefreshToken: refreshToken}
	body, _ = json.Marshal(refReq)
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/refresh-token", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("refresh token failed: %d %s", w.Code, w.Body.String())
	}

	var refResp models.AuthResponse
	_ = json.Unmarshal(w.Body.Bytes(), &refResp)
	if refResp.AccessToken == "" || refResp.RefreshToken == refreshToken {
		t.Errorf("expected rotated new refresh token, got %+v", refResp)
	}

	// 9. Old Refresh Token must now be rejected
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/refresh-token", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 for reused old refresh token, got %d", w.Code)
	}

	// 10. CheckPhone Endpoint
	// Registered number check:
	req, _ = http.NewRequest(http.MethodGet, "/api/v1/auth/check-phone?phone=01711223344", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("expected 200 for CheckPhone, got %d", w.Code)
	}
	var checkResp models.CheckPhoneResponse
	_ = json.Unmarshal(w.Body.Bytes(), &checkResp)
	if !checkResp.Registered {
		t.Errorf("expected registered=true for 01711223344, got false")
	}

	// Unregistered number check:
	req, _ = http.NewRequest(http.MethodGet, "/api/v1/auth/check-phone?phone=01999999999", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("expected 200 for CheckPhone, got %d", w.Code)
	}
	var checkRespUnreg models.CheckPhoneResponse
	_ = json.Unmarshal(w.Body.Bytes(), &checkRespUnreg)
	if checkRespUnreg.Registered {
		t.Errorf("expected registered=false for 01999999999, got true")
	}

	// 11. SendOTP with purpose="register" on already registered number must return 409 Conflict
	dupSendOtp := models.SendOTPRequest{
		Phone:   "01711223344",
		Purpose: "register",
	}
	body, _ = json.Marshal(dupSendOtp)
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/auth/send-otp", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusConflict {
		t.Errorf("expected 409 Conflict for SendOTP on registered number with purpose=register, got %d: %s", w.Code, w.Body.String())
	}
}

func TestPluggableOTPProvider_LocalSMSAndFirebase(t *testing.T) {
	// Test Local SMS Provider
	smsProvider := services.NewLocalSMSOTPProvider()
	ctx := t.Context()
	sessID, err := smsProvider.SendOTP(ctx, "01811223344")
	if err != nil || sessID == "" {
		t.Fatalf("local sms SendOTP failed: %v", err)
	}

	// Wrong code fails
	ok, _, err := smsProvider.VerifyOTP(ctx, "01811223344", "000000")
	if ok || err == nil {
		t.Errorf("expected wrong code to fail")
	}

	// Test Firebase Mock Token
	fbProvider := services.NewFirebaseOTPProvider("fmcg-plus-test-project")
	verified, phone, err := fbProvider.VerifyOTP(ctx, "01911223344", "mock-firebase-token:01911223344")
	if err != nil || !verified || phone != "+8801911223344" {
		t.Errorf("firebase mock verify failed: verified=%v, phone=%s, err=%v", verified, phone, err)
	}
}
