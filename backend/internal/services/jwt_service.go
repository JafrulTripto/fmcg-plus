package services

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"fmcg-pos-backend/internal/config"
	"fmcg-pos-backend/internal/models"
)

// JWTService handles cryptographic token creation, validation, and credential hashing.
type JWTService struct {
	secret            []byte
	accessExpiryHours int
	refreshExpiryDays int
}

func NewJWTService(cfg *config.Config) *JWTService {
	accessExpiry := cfg.JWTAccessExpiryHours
	if accessExpiry <= 0 {
		accessExpiry = 1
	}
	refreshExpiry := cfg.JWTRefreshExpiryDays
	if refreshExpiry <= 0 {
		refreshExpiry = 30
	}

	return &JWTService{
		secret:            []byte(cfg.JWTSecret),
		accessExpiryHours: accessExpiry,
		refreshExpiryDays: refreshExpiry,
	}
}

// GenerateTokenPair generates an access token (HS256) and a cryptographically secure refresh token
func (s *JWTService) GenerateTokenPair(user *models.User, storeID, memberRole string) (string, string, int64, error) {
	now := time.Now()
	accessExpiryDuration := time.Duration(s.accessExpiryHours) * time.Hour
	accessExpiryTime := now.Add(accessExpiryDuration)

	claims := &models.JWTClaims{
		UserID:     user.ID,
		Phone:      user.Phone,
		Role:       user.Role,
		StoreID:    storeID,
		MemberRole: memberRole,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   user.ID,
			Issuer:    "fmcg-plus-api",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(accessExpiryTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	accessToken, err := token.SignedString(s.secret)
	if err != nil {
		return "", "", 0, fmt.Errorf("failed to sign access token: %w", err)
	}

	// Generate 32-byte cryptographically secure random refresh token string
	randomBytes := make([]byte, 32)
	if _, err := rand.Read(randomBytes); err != nil {
		return "", "", 0, fmt.Errorf("failed to generate refresh token entropy: %w", err)
	}
	refreshToken := hex.EncodeToString(randomBytes)

	return accessToken, refreshToken, int64(accessExpiryDuration.Seconds()), nil
}

// ValidateAccessToken parses and validates an HMAC-signed access token
func (s *JWTService) ValidateAccessToken(tokenStr string) (*models.JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &models.JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.secret, nil
	})

	if err != nil {
		return nil, fmt.Errorf("invalid access token: %w", err)
	}

	claims, ok := token.Claims.(*models.JWTClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	return claims, nil
}

// VerificationClaims represents the payload of a temporary registration proof token
type VerificationClaims struct {
	Phone   string `json:"phone"`
	Purpose string `json:"purpose"`
	jwt.RegisteredClaims
}

// GenerateVerificationToken creates a short-lived (15 min) token proving that a phone OTP was verified
func (s *JWTService) GenerateVerificationToken(phone string) (string, error) {
	now := time.Now()
	claims := &VerificationClaims{
		Phone:   phone,
		Purpose: "phone_verification",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   phone,
			Issuer:    "fmcg-plus-api",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secret)
}

// ValidateVerificationToken validates the phone verification token and returns verified phone number
func (s *JWTService) ValidateVerificationToken(tokenStr string) (string, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &VerificationClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.secret, nil
	})

	if err != nil {
		return "", fmt.Errorf("invalid verification token: %w", err)
	}

	claims, ok := token.Claims.(*VerificationClaims)
	if !ok || !token.Valid || claims.Purpose != "phone_verification" {
		return "", errors.New("invalid or expired verification token")
	}

	return claims.Phone, nil
}

// HashCredential hashes a PIN or password using bcrypt with standard cost
func (s *JWTService) HashCredential(pinOrPassword string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(pinOrPassword), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("failed to hash credential: %w", err)
	}
	return string(hash), nil
}

// CheckCredential compares a plain text PIN or password with a bcrypt hash
func (s *JWTService) CheckCredential(pinOrPassword, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(pinOrPassword))
	return err == nil
}

// HashRefreshToken generates a SHA-256 hex hash of the refresh token for secure database storage
func (s *JWTService) HashRefreshToken(token string) string {
	hasher := sha256.New()
	hasher.Write([]byte(token))
	return hex.EncodeToString(hasher.Sum(nil))
}

// RefreshExpiryDuration returns the duration configured for refresh token validity
func (s *JWTService) RefreshExpiryDuration() time.Duration {
	return time.Duration(s.refreshExpiryDays) * 24 * time.Hour
}
