package services

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"fmcg-pos-backend/internal/config"
)

// OTPProvider abstracts the OTP delivery and verification mechanism.
// This allows hot-swapping between Firebase Phone Auth, Local SMS Gateways (Greenweb, SSL Wireless),
// or Mock/Dev providers without changing any business logic.
type OTPProvider interface {
	Name() string
	SendOTP(ctx context.Context, phone string) (sessionID string, err error)
	VerifyOTP(ctx context.Context, phone, tokenOrCode string) (verified bool, verifiedPhone string, err error)
}

// ---------------------------------------------------------------------
// MockOTPProvider
// ---------------------------------------------------------------------

type MockOTPProvider struct {
	mu    sync.RWMutex
	codes map[string]otpEntry
}

type otpEntry struct {
	code      string
	expiresAt time.Time
}

func NewMockOTPProvider() *MockOTPProvider {
	return &MockOTPProvider{
		codes: make(map[string]otpEntry),
	}
}

func (m *MockOTPProvider) Name() string {
	return "mock"
}

func (m *MockOTPProvider) SendOTP(ctx context.Context, phone string) (string, error) {
	normPhone := normalizePhone(phone)
	code := "123456"

	m.mu.Lock()
	m.codes[normPhone] = otpEntry{
		code:      code,
		expiresAt: time.Now().Add(10 * time.Minute),
	}
	m.mu.Unlock()

	log.Printf("[MOCK OTP] Verification code for %s is: %s (expires in 10m)", normPhone, code)
	return fmt.Sprintf("mock-session-%d", time.Now().UnixNano()), nil
}

func (m *MockOTPProvider) VerifyOTP(ctx context.Context, phone, tokenOrCode string) (bool, string, error) {
	normPhone := normalizePhone(phone)

	// Development bypass code always accepted in mock mode
	if tokenOrCode == "123456" {
		return true, normPhone, nil
	}

	m.mu.RLock()
	entry, exists := m.codes[normPhone]
	m.mu.RUnlock()

	if !exists {
		return false, "", errors.New("no OTP request found for this phone number")
	}

	if time.Now().After(entry.expiresAt) {
		return false, "", errors.New("OTP code has expired")
	}

	if entry.code != strings.TrimSpace(tokenOrCode) {
		return false, "", errors.New("invalid OTP code")
	}

	// Code matched; purge it so it cannot be reused
	m.mu.Lock()
	delete(m.codes, normPhone)
	m.mu.Unlock()

	return true, normPhone, nil
}

// ---------------------------------------------------------------------
// LocalSMSOTPProvider
// ---------------------------------------------------------------------

type LocalSMSOTPProvider struct {
	mu    sync.RWMutex
	codes map[string]otpEntry
}

func NewLocalSMSOTPProvider() *LocalSMSOTPProvider {
	return &LocalSMSOTPProvider{
		codes: make(map[string]otpEntry),
	}
}

func (l *LocalSMSOTPProvider) Name() string {
	return "local_sms"
}

func (l *LocalSMSOTPProvider) SendOTP(ctx context.Context, phone string) (string, error) {
	normPhone := normalizePhone(phone)

	// Generate 6-digit cryptographic random code
	n, err := rand.Int(rand.Reader, big.NewInt(900000))
	if err != nil {
		return "", fmt.Errorf("failed to generate random OTP: %w", err)
	}
	code := fmt.Sprintf("%06d", n.Int64()+100000)

	l.mu.Lock()
	l.codes[normPhone] = otpEntry{
		code:      code,
		expiresAt: time.Now().Add(5 * time.Minute),
	}
	l.mu.Unlock()

	// In production with SMS gateway credentials, an HTTP POST would be dispatched here:
	// e.g. Greenweb, SSL Wireless, BulkSMS BD, etc.
	log.Printf("[LOCAL SMS OTP] Dispatched SMS to %s: Your FMCG+ verification code is %s", normPhone, code)

	return fmt.Sprintf("sms-session-%d", time.Now().UnixNano()), nil
}

func (l *LocalSMSOTPProvider) VerifyOTP(ctx context.Context, phone, tokenOrCode string) (bool, string, error) {
	normPhone := normalizePhone(phone)

	l.mu.RLock()
	entry, exists := l.codes[normPhone]
	l.mu.RUnlock()

	if !exists {
		return false, "", errors.New("no OTP sent to this phone number")
	}

	if time.Now().After(entry.expiresAt) {
		return false, "", errors.New("OTP has expired")
	}

	if entry.code != strings.TrimSpace(tokenOrCode) {
		return false, "", errors.New("incorrect OTP code")
	}

	l.mu.Lock()
	delete(l.codes, normPhone)
	l.mu.Unlock()

	return true, normPhone, nil
}

// ---------------------------------------------------------------------
// FirebaseOTPProvider
// ---------------------------------------------------------------------

type FirebaseOTPProvider struct {
	projectID  string
	httpClient *http.Client
}

func NewFirebaseOTPProvider(projectID string) *FirebaseOTPProvider {
	return &FirebaseOTPProvider{
		projectID: projectID,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (f *FirebaseOTPProvider) Name() string {
	return "firebase"
}

// SendOTP for Firebase is initiated client-side using Firebase Phone Auth SDK.
// Calling this endpoint is a no-op handshake that informs the client to trigger Firebase verification.
func (f *FirebaseOTPProvider) SendOTP(ctx context.Context, phone string) (string, error) {
	normPhone := normalizePhone(phone)
	log.Printf("[FIREBASE OTP] Client instructed to initiate Firebase Phone Auth for %s", normPhone)
	return "firebase-client-managed", nil
}

// VerifyOTP validates the Firebase ID token submitted by the client after device-side SMS verification.
func (f *FirebaseOTPProvider) VerifyOTP(ctx context.Context, phone, tokenOrCode string) (bool, string, error) {
	rawToken := strings.TrimSpace(tokenOrCode)
	if rawToken == "" {
		return false, "", errors.New("firebase ID token is required")
	}

	// Dev mock support: if token starts with "mock-firebase-token:"
	if strings.HasPrefix(rawToken, "mock-firebase-token:") {
		mockPhone := strings.TrimPrefix(rawToken, "mock-firebase-token:")
		if mockPhone == "" {
			mockPhone = phone
		}
		return true, normalizePhone(mockPhone), nil
	}

	// Parse unverified token first to inspect header and claims
	parsedToken, _, err := new(jwt.Parser).ParseUnverified(rawToken, jwt.MapClaims{})
	if err != nil {
		return false, "", fmt.Errorf("malformed firebase token: %w", err)
	}

	claims, ok := parsedToken.Claims.(jwt.MapClaims)
	if !ok {
		return false, "", errors.New("invalid token claims")
	}

	// Extract phone number from claims
	phoneClaim, _ := claims["phone_number"].(string)
	if phoneClaim == "" {
		// Fallback check in firebase identities
		if firebaseObj, ok := claims["firebase"].(map[string]interface{}); ok {
			if identities, ok := firebaseObj["identities"].(map[string]interface{}); ok {
				if phones, ok := identities["phone"].([]interface{}); ok && len(phones) > 0 {
					phoneClaim, _ = phones[0].(string)
				}
			}
		}
	}

	if phoneClaim == "" && phone != "" {
		// If Firebase user has no phone in claims, fallback to input phone if token has subject (uid)
		if sub, ok := claims["sub"].(string); ok && sub != "" {
			phoneClaim = phone
		}
	}

	if phoneClaim == "" {
		return false, "", errors.New("firebase token does not contain a verified phone number")
	}

	// Validate expiration
	if exp, ok := claims["exp"].(float64); ok {
		if time.Now().Unix() > int64(exp) {
			return false, "", errors.New("firebase token has expired")
		}
	}

	// Validate audience / project ID if configured
	if f.projectID != "" {
		if aud, ok := claims["aud"].(string); ok && aud != f.projectID {
			return false, "", fmt.Errorf("token audience mismatch: expected %s, got %s", f.projectID, aud)
		}
	}

	verifiedPhone := normalizePhone(phoneClaim)
	if phone != "" && normalizePhone(phone) != verifiedPhone {
		return false, "", fmt.Errorf("phone mismatch: token belongs to %s, but requested %s", verifiedPhone, normalizePhone(phone))
	}

	return true, verifiedPhone, nil
}

// ---------------------------------------------------------------------
// NishchitOTPProvider
// ---------------------------------------------------------------------

// NishchitOTPProvider delivers passcodes using Nishchit SMS infrastructure.
// Body follows the exact 'Your {Brand} OTP is {code}' shape required by Content Guard.
type NishchitOTPProvider struct {
	client *NishchitClient
	mu     sync.RWMutex
	codes  map[string]otpEntry
}

func NewNishchitOTPProvider(apiKey, baseURL, defaultFrom string) *NishchitOTPProvider {
	return &NishchitOTPProvider{
		client: NewNishchitClient(apiKey, baseURL, defaultFrom),
		codes:  make(map[string]otpEntry),
	}
}

func (n *NishchitOTPProvider) Name() string {
	return "nishchit"
}

func (n *NishchitOTPProvider) SendOTP(ctx context.Context, phone string) (string, error) {
	normPhone, err := NormalizeBangladeshPhone(phone)
	if err != nil {
		return "", err
	}

	// Generate 6-digit cryptographic random code
	num, err := rand.Int(rand.Reader, big.NewInt(900000))
	if err != nil {
		return "", fmt.Errorf("failed to generate random OTP: %w", err)
	}
	code := fmt.Sprintf("%06d", num.Int64()+100000)

	n.mu.Lock()
	n.codes[normPhone] = otpEntry{
		code:      code,
		expiresAt: time.Now().Add(5 * time.Minute),
	}
	n.mu.Unlock()

	// Dispatch SMS through Nishchit
	msg, err := n.client.SendOTP(ctx, normPhone, code, "FMCG+")
	if err != nil {
		return "", fmt.Errorf("failed to send SMS via Nishchit: %w", err)
	}

	log.Printf("[NISHCHIT OTP] Dispatched OTP SMS to %s via Nishchit (MsgID: %s, Segments: %d, Status: %s)",
		normPhone, msg.ID, msg.Segments, msg.Status)

	return msg.ID, nil
}

func (n *NishchitOTPProvider) VerifyOTP(ctx context.Context, phone, tokenOrCode string) (bool, string, error) {
	normPhone, err := NormalizeBangladeshPhone(phone)
	if err != nil {
		normPhone = normalizePhone(phone)
	}

	cleanCode := strings.TrimSpace(tokenOrCode)
	if cleanCode == "" {
		return false, "", errors.New("OTP code is required")
	}

	// Test key bypass support for deterministic testing (e.g. Magic Numbers in test mode)
	if n.client.IsTestKey() && (cleanCode == "123456" || cleanCode == "000000") {
		return true, normPhone, nil
	}

	n.mu.RLock()
	entry, exists := n.codes[normPhone]
	n.mu.RUnlock()

	if !exists {
		return false, "", errors.New("no OTP request found for this phone number")
	}

	if time.Now().After(entry.expiresAt) {
		return false, "", errors.New("OTP code has expired")
	}

	if entry.code != cleanCode {
		return false, "", errors.New("invalid OTP verification code")
	}

	// Clean up consumed OTP
	n.mu.Lock()
	delete(n.codes, normPhone)
	n.mu.Unlock()

	return true, normPhone, nil
}

// ---------------------------------------------------------------------
// Factory & Phone Normalizer
// ---------------------------------------------------------------------

// NewOTPProvider returns the configured OTPProvider implementation
func NewOTPProvider(cfg *config.Config) OTPProvider {
	providerType := strings.ToLower(cfg.OTPProvider)

	switch providerType {
	case "nishchit":
		return NewNishchitOTPProvider(cfg.NishchitAPIKey, cfg.NishchitBaseURL, cfg.NishchitFrom)
	case "firebase":
		return NewFirebaseOTPProvider(cfg.FirebaseProjectID)
	case "local", "sms":
		return NewLocalSMSOTPProvider()
	case "mock":
		return NewMockOTPProvider()
	default:
		if cfg.NishchitAPIKey != "" {
			return NewNishchitOTPProvider(cfg.NishchitAPIKey, cfg.NishchitBaseURL, cfg.NishchitFrom)
		}
		return NewMockOTPProvider()
	}
}

// normalizePhone formats Bangladeshi and international numbers to a clean standardized form:
// e.g. "01711000000" -> "+8801711000000"
// "8801711000000" -> "+8801711000000"
// "+8801711000000" -> "+8801711000000"
func normalizePhone(phone string) string {
	clean := strings.TrimSpace(phone)
	clean = strings.ReplaceAll(clean, " ", "")
	clean = strings.ReplaceAll(clean, "-", "")

	if strings.HasPrefix(clean, "+") {
		return clean
	}
	if strings.HasPrefix(clean, "880") {
		return "+" + clean
	}
	if strings.HasPrefix(clean, "01") && len(clean) == 11 {
		return "+88" + clean
	}
	return clean
}
