package models

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// User represents a system identity (store owner, staff, customer, or admin)
type User struct {
	ID            string    `json:"id" gorm:"primaryKey"`
	Phone         string    `json:"phone" binding:"required" gorm:"uniqueIndex"`
	Name          string    `json:"name" binding:"required"`
	NameBn        string    `json:"name_bn,omitempty"`
	PasswordHash  string    `json:"-" gorm:"not null"` // Hidden from JSON serialization
	Role          string    `json:"role" gorm:"default:'customer'"`
	IsActive      bool      `json:"is_active" gorm:"default:true"`
	PhoneVerified bool      `json:"phone_verified" gorm:"default:false"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// UserProfile is a safe, public view of a user
type UserProfile struct {
	ID            string    `json:"id"`
	Phone         string    `json:"phone"`
	Name          string    `json:"name"`
	NameBn        string    `json:"name_bn,omitempty"`
	Role          string    `json:"role"`
	IsActive      bool      `json:"is_active"`
	PhoneVerified bool      `json:"phone_verified"`
	CreatedAt     time.Time `json:"created_at"`
}

func (u *User) ToProfile() UserProfile {
	return UserProfile{
		ID:            u.ID,
		Phone:         u.Phone,
		Name:          u.Name,
		NameBn:        u.NameBn,
		Role:          u.Role,
		IsActive:      u.IsActive,
		PhoneVerified: u.PhoneVerified,
		CreatedAt:     u.CreatedAt,
	}
}

// StoreMember associates a user with a specific retail store tenant
type StoreMember struct {
	ID         string    `json:"id" gorm:"primaryKey"`
	StoreID    string    `json:"store_id" binding:"required" gorm:"index"`
	UserID     string    `json:"user_id" binding:"required" gorm:"index"`
	MemberRole string    `json:"member_role" gorm:"default:'staff'"` // 'owner', 'manager', 'cashier'
	IsActive   bool      `json:"is_active" gorm:"default:true"`
	CreatedAt  time.Time `json:"created_at"`
}

// RefreshToken stores rotated long-lived refresh tokens
type RefreshToken struct {
	ID        string    `json:"id" gorm:"primaryKey"`
	UserID    string    `json:"user_id" gorm:"index"`
	TokenHash string    `json:"-" gorm:"not null"`
	ExpiresAt time.Time `json:"expires_at"`
	IsRevoked bool      `json:"is_revoked" gorm:"default:false"`
	CreatedAt time.Time `json:"created_at"`
}

// JWTClaims holds custom and standard claims for FMCG+ tokens
type JWTClaims struct {
	UserID     string `json:"user_id"`
	Phone      string `json:"phone"`
	Role       string `json:"role"`
	StoreID    string `json:"store_id,omitempty"`
	MemberRole string `json:"member_role,omitempty"`
	jwt.RegisteredClaims
}

// DTOs for Auth Requests & Responses

type SendOTPRequest struct {
	Phone   string `json:"phone" binding:"required"`
	Purpose string `json:"purpose,omitempty"`
}

type CheckPhoneRequest struct {
	Phone string `json:"phone" binding:"required"`
}

type CheckPhoneResponse struct {
	Registered bool   `json:"registered"`
	Phone      string `json:"phone"`
	Role       string `json:"role,omitempty"`
	Name       string `json:"name,omitempty"`
	StoreName  string `json:"store_name,omitempty"`
	Message    string `json:"message"`
}

type SendOTPResponse struct {
	SessionID string `json:"session_id,omitempty"`
	Provider  string `json:"provider"`
	Message   string `json:"message"`
}

type VerifyOTPRequest struct {
	Phone         string `json:"phone"`
	Code          string `json:"code,omitempty"`
	FirebaseToken string `json:"firebase_token,omitempty"`
}

type VerifyOTPResponse struct {
	Verified          bool   `json:"verified"`
	Phone             string `json:"phone"`
	VerificationToken string `json:"verification_token"`
	Message           string `json:"message"`
}

type RegisterMerchantRequest struct {
	Phone             string `json:"phone" binding:"required"`
	Name              string `json:"name" binding:"required"`
	StoreName         string `json:"store_name" binding:"required"`
	StoreAddress      string `json:"store_address"`
	PIN               string `json:"pin" binding:"required,min=4,max=8"`
	VerificationToken string `json:"verification_token,omitempty"`
}

type RegisterCustomerRequest struct {
	Phone             string `json:"phone" binding:"required"`
	Name              string `json:"name" binding:"required"`
	PIN               string `json:"pin" binding:"required,min=4,max=8"`
	VerificationToken string `json:"verification_token,omitempty"`
}

type LoginRequest struct {
	Phone         string `json:"phone" binding:"required"`
	PIN           string `json:"pin,omitempty"`
	Password      string `json:"password,omitempty"`
	OTPCode       string `json:"otp_code,omitempty"`
	FirebaseToken string `json:"firebase_token,omitempty"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type ChangePINRequest struct {
	OldPIN string `json:"old_pin" binding:"required"`
	NewPIN string `json:"new_pin" binding:"required,min=4,max=8"`
}

type AuthResponse struct {
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	ExpiresIn    int64        `json:"expires_in"` // Seconds
	TokenType    string       `json:"token_type"`
	User         UserProfile  `json:"user"`
	Store        *Store       `json:"store,omitempty"`
	MemberRole   string       `json:"member_role,omitempty"`
}
