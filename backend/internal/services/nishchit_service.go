package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Bangladesh mobile number regex: must match +8801[3-9]XXXXXXXX (14 characters total)
var bdPhoneRegex = regexp.MustCompile(`^\+8801[3-9]\d{8}$`)

// NishchitMessage represents a message record returned by Nishchit API
type NishchitMessage struct {
	ID             string `json:"id"`
	Object         string `json:"object"`
	Status         string `json:"status"`          // "accepted", "sending", "sent", "failed"
	DeliveryStatus string `json:"delivery_status"` // "unknown", "delivered", "undelivered", "rejected"
	To             string `json:"to"`
	From           string `json:"from"`
	Body           string `json:"body"`
	Segments       int    `json:"segments"`
	Encoding       string `json:"encoding"` // "gsm7" or "ucs2"
	Credits        int    `json:"credits"`
	Classification string `json:"classification,omitempty"` // "otp", "transactional", "promotional", "unknown"
	Reference      string `json:"reference,omitempty"`
	CreatedAt      string `json:"created_at"`
	SentAt         string `json:"sent_at,omitempty"`
	DeliveredAt    string `json:"delivered_at,omitempty"`
	FailedAt       string `json:"failed_at,omitempty"`
}

// NishchitErrorDetail represents the structured error response from Nishchit
type NishchitErrorDetail struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	Detail    string `json:"detail,omitempty"`
	DocURL    string `json:"doc_url"`
	RequestID string `json:"request_id"`
}

// NishchitError implements error and formats the exact doc_url and error code
type NishchitError struct {
	StatusCode int
	Detail     NishchitErrorDetail
}

func (e *NishchitError) Error() string {
	docInfo := ""
	if e.Detail.DocURL != "" {
		docInfo = fmt.Sprintf(" (see %s)", e.Detail.DocURL)
	}
	reqInfo := ""
	if e.Detail.RequestID != "" {
		reqInfo = fmt.Sprintf(" [request_id: %s]", e.Detail.RequestID)
	}
	return fmt.Sprintf("Nishchit error HTTP %d [%s]: %s%s%s", e.StatusCode, e.Detail.Code, e.Detail.Message, docInfo, reqInfo)
}

// SendSMSRequest represents the payload to send an SMS
type SendSMSRequest struct {
	To             string `json:"to"`
	Body           string `json:"body"`
	From           string `json:"from,omitempty"`
	Reference      string `json:"reference,omitempty"`
	CallbackURL    string `json:"callback_url,omitempty"`
	IdempotencyKey string `json:"-"`
}

// NishchitClient handles HTTP communication with the Nishchit SMS API
type NishchitClient struct {
	BaseURL     string
	APIKey      string
	DefaultFrom string
	HTTPClient  *http.Client
}

// NewNishchitClient creates a new Nishchit SMS client.
// Base URL defaults to https://api.nishchit.tech if empty.
// Recommended client timeout is 15 seconds.
func NewNishchitClient(apiKey, baseURL, defaultFrom string) *NishchitClient {
	cleanBase := strings.TrimRight(baseURL, "/")
	if cleanBase == "" {
		cleanBase = "https://api.nishchit.tech"
	}

	return &NishchitClient{
		BaseURL:     cleanBase,
		APIKey:      apiKey,
		DefaultFrom: defaultFrom,
		HTTPClient: &http.Client{
			Timeout: 15 * time.Second,
		},
	}
}

// IsTestKey checks if the client is operating in test mode (never charges credits, never reaches carriers)
func (c *NishchitClient) IsTestKey() bool {
	return strings.HasPrefix(c.APIKey, "nk_test_")
}

// NormalizeBangladeshPhone normalizes and validates a recipient phone number into E.164 +8801[3-9]XXXXXXXX.
func NormalizeBangladeshPhone(phone string) (string, error) {
	clean := strings.TrimSpace(phone)
	clean = strings.ReplaceAll(clean, " ", "")
	clean = strings.ReplaceAll(clean, "-", "")
	clean = strings.ReplaceAll(clean, "(", "")
	clean = strings.ReplaceAll(clean, ")", "")

	if strings.HasPrefix(clean, "01") && len(clean) == 11 {
		clean = "+88" + clean
	} else if strings.HasPrefix(clean, "8801") && len(clean) == 13 {
		clean = "+" + clean
	} else if strings.HasPrefix(clean, "1") && len(clean) == 10 {
		clean = "+880" + clean
	}

	if !bdPhoneRegex.MatchString(clean) {
		return "", fmt.Errorf("invalid recipient '%s': must be a valid Bangladesh mobile number matching +8801[3-9]XXXXXXXX (E.164)", phone)
	}

	return clean, nil
}

// SendMessage dispatches an SMS message through Nishchit POST /v1/messages.
// Always attaches an Idempotency-Key header to prevent duplicate sending on retries.
func (c *NishchitClient) SendMessage(ctx context.Context, req SendSMSRequest) (*NishchitMessage, error) {
	if c.APIKey == "" {
		return nil, fmt.Errorf("Nishchit API key is not configured. Set NISHCHIT_API_KEY in environment or .env")
	}

	normTo, err := NormalizeBangladeshPhone(req.To)
	if err != nil {
		return nil, err
	}
	req.To = normTo

	if strings.TrimSpace(req.Body) == "" {
		return nil, fmt.Errorf("message body cannot be empty")
	}

	if req.From == "" && c.DefaultFrom != "" {
		req.From = c.DefaultFrom
	}

	// Idempotency key must be provided or generated to ensure safe retries
	idempotencyKey := req.IdempotencyKey
	if idempotencyKey == "" {
		idempotencyKey = fmt.Sprintf("fmcg-%s", uuid.New().String())
	}

	reqPayload := map[string]interface{}{
		"to":   req.To,
		"body": req.Body,
	}
	if req.From != "" {
		reqPayload["from"] = req.From
	}
	if req.Reference != "" {
		reqPayload["reference"] = req.Reference
	}
	if req.CallbackURL != "" {
		reqPayload["callback_url"] = req.CallbackURL
	}

	jsonBytes, err := json.Marshal(reqPayload)
	if err != nil {
		return nil, fmt.Errorf("failed to encode request payload: %w", err)
	}

	url := fmt.Sprintf("%s/v1/messages", c.BaseURL)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewBuffer(jsonBytes))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+c.APIKey)
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Idempotency-Key", idempotencyKey)
	httpReq.Header.Set("User-Agent", "FMCGPlus-POS/1.0 (Bangladesh Retail POS)")

	resp, err := c.HTTPClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to dispatch request to Nishchit API: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read Nishchit response body: %w", err)
	}

	// 201 Created: message accepted
	if resp.StatusCode == http.StatusCreated {
		var msg NishchitMessage
		if err := json.Unmarshal(respBody, &msg); err != nil {
			return nil, fmt.Errorf("failed to decode Nishchit message response: %w (body: %s)", err, string(respBody))
		}
		log.Printf("[Nishchit] Message accepted! ID: %s | To: %s | Segments: %d | Encoding: %s | Credits: %d | Status: %s",
			msg.ID, msg.To, msg.Segments, msg.Encoding, msg.Credits, msg.Status)
		return &msg, nil
	}

	// Parse structured error
	var errResp struct {
		Error     NishchitErrorDetail `json:"error"`
		RequestID string              `json:"request_id"`
	}
	if err := json.Unmarshal(respBody, &errResp); err == nil && errResp.Error.Code != "" {
		if errResp.Error.RequestID == "" {
			errResp.Error.RequestID = errResp.RequestID
		}
		return nil, &NishchitError{
			StatusCode: resp.StatusCode,
			Detail:     errResp.Error,
		}
	}

	// Fallback error format
	return nil, &NishchitError{
		StatusCode: resp.StatusCode,
		Detail: NishchitErrorDetail{
			Code:    fmt.Sprintf("http_%d", resp.StatusCode),
			Message: string(respBody),
		},
	}
}

// SendOTP formats the body strictly as 'Your {Brand} OTP is {code}' to match Nishchit Content Guard guidelines.
// This guarantees a single-segment GSM-7 message with zero warnings.
func (c *NishchitClient) SendOTP(ctx context.Context, phone, code, brandName string) (*NishchitMessage, error) {
	if brandName == "" {
		brandName = "FMCG+"
	}
	body := fmt.Sprintf("Your %s OTP is %s", brandName, code)
	ref := fmt.Sprintf("otp-%d", time.Now().UnixNano())

	return c.SendMessage(ctx, SendSMSRequest{
		To:        phone,
		Body:      body,
		Reference: ref,
	})
}

// SendTransactionalSMS sends an order confirmation or Khata due reminder.
// Note: To stay in GSM-7 (160 chars/segment instead of 70 in UCS-2), write currency as 'BDT' instead of '৳'.
func (c *NishchitClient) SendTransactionalSMS(ctx context.Context, phone, message, reference string) (*NishchitMessage, error) {
	return c.SendMessage(ctx, SendSMSRequest{
		To:        phone,
		Body:      message,
		Reference: reference,
	})
}

// GetBalance returns the available credit balance in the Nishchit project.
func (c *NishchitClient) GetBalance(ctx context.Context) (int, error) {
	if c.APIKey == "" {
		return 0, fmt.Errorf("Nishchit API key is not configured")
	}

	url := fmt.Sprintf("%s/v1/balance", c.BaseURL)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0, err
	}
	req.Header.Set("Authorization", "Bearer "+c.APIKey)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("failed to fetch balance: HTTP %d (%s)", resp.StatusCode, string(body))
	}

	var data struct {
		Balance int `json:"balance"`
	}
	if err := json.Unmarshal(body, &data); err != nil {
		return 0, err
	}

	return data.Balance, nil
}
