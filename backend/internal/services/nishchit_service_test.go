package services

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
)

type roundTripperFunc func(*http.Request) (*http.Response, error)

func (f roundTripperFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func TestNormalizeBangladeshPhone(t *testing.T) {
	tests := []struct {
		input       string
		expected    string
		expectError bool
	}{
		// Valid inputs in various formats
		{"+8801712345678", "+8801712345678", false},
		{"01712345678", "+8801712345678", false},
		{"8801712345678", "+8801712345678", false},
		{"01811223344", "+8801811223344", false},
		{"01911223344", "+8801911223344", false},
		{"01311223344", "+8801311223344", false},
		{"01411223344", "+8801411223344", false},
		{"01511223344", "+8801511223344", false},
		{"01611223344", "+8801611223344", false},
		{"  01712-345678 ", "+8801712345678", false},
		{"+8801700000000", "+8801700000000", false}, // Nishchit magic number

		// Invalid inputs
		{"01211223344", "", true},   // 012 is invalid operator prefix
		{"01011223344", "", true},   // 010 is invalid
		{"01111223344", "", true},   // 011 is invalid
		{"+14155550100", "", true},  // Non-Bangladesh (US number)
		{"01712345", "", true},      // Too short
		{"0171234567890", "", true}, // Too long
		{"", "", true},              // Empty
	}

	for _, tc := range tests {
		got, err := NormalizeBangladeshPhone(tc.input)
		if tc.expectError {
			if err == nil {
				t.Errorf("NormalizeBangladeshPhone(%q) expected error, got %q", tc.input, got)
			}
		} else {
			if err != nil {
				t.Errorf("NormalizeBangladeshPhone(%q) unexpected error: %v", tc.input, err)
			}
			if got != tc.expected {
				t.Errorf("NormalizeBangladeshPhone(%q) = %q, expected %q", tc.input, got, tc.expected)
			}
		}
	}
}

func TestNishchitClient_SendMessage_Success(t *testing.T) {
	var capturedAuth string
	var capturedIdempotency string
	var capturedContentType string
	var capturedBody map[string]interface{}

	client := NewNishchitClient("nk_test_dummykey123", "https://api.nishchit.tech", "FMCG+")
	client.HTTPClient.Transport = roundTripperFunc(func(r *http.Request) (*http.Response, error) {
		capturedAuth = r.Header.Get("Authorization")
		capturedIdempotency = r.Header.Get("Idempotency-Key")
		capturedContentType = r.Header.Get("Content-Type")

		json.NewDecoder(r.Body).Decode(&capturedBody)

		resJSON := `{
			"id": "msg_01JBX7QW9K2M5T8N4V6C3Z1H0A",
			"object": "message",
			"status": "accepted",
			"delivery_status": "unknown",
			"to": "+8801712345678",
			"from": "NISHCHIT",
			"body": "Your FMCG+ OTP is 482913",
			"segments": 1,
			"encoding": "gsm7",
			"credits": 1,
			"reference": "user_9281",
			"created_at": "2026-09-29T10:00:00Z"
		}`

		return &http.Response{
			StatusCode: http.StatusCreated,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewBufferString(resJSON)),
		}, nil
	})

	ctx := context.Background()

	msg, err := client.SendMessage(ctx, SendSMSRequest{
		To:        "01712345678",
		Body:      "Your FMCG+ OTP is 482913",
		Reference: "user_9281",
	})
	if err != nil {
		t.Fatalf("SendMessage unexpected error: %v", err)
	}

	if msg.ID != "msg_01JBX7QW9K2M5T8N4V6C3Z1H0A" {
		t.Errorf("expected msg id msg_01JBX7QW9K2M5T8N4V6C3Z1H0A, got %s", msg.ID)
	}
	if msg.Status != "accepted" {
		t.Errorf("expected status accepted, got %s", msg.Status)
	}
	if msg.DeliveryStatus != "unknown" {
		t.Errorf("expected delivery_status unknown, got %s", msg.DeliveryStatus)
	}
	if msg.Segments != 1 {
		t.Errorf("expected 1 segment, got %d", msg.Segments)
	}
	if msg.Encoding != "gsm7" {
		t.Errorf("expected gsm7, got %s", msg.Encoding)
	}

	// Verify headers
	if capturedAuth != "Bearer nk_test_dummykey123" {
		t.Errorf("expected Authorization header Bearer nk_test_dummykey123, got %s", capturedAuth)
	}
	if capturedIdempotency == "" {
		t.Errorf("expected non-empty Idempotency-Key header")
	}
	if capturedContentType != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", capturedContentType)
	}

	// Verify payload
	if capturedBody["to"] != "+8801712345678" {
		t.Errorf("expected normalized to +8801712345678, got %v", capturedBody["to"])
	}
	if capturedBody["body"] != "Your FMCG+ OTP is 482913" {
		t.Errorf("expected body 'Your FMCG+ OTP is 482913', got %v", capturedBody["body"])
	}
}

func TestNishchitClient_ErrorHandling(t *testing.T) {
	client := NewNishchitClient("nk_test_dummykey123", "https://api.nishchit.tech", "")
	client.HTTPClient.Transport = roundTripperFunc(func(r *http.Request) (*http.Response, error) {
		errJSON := `{
			"error": {
				"code": "invalid_recipient",
				"message": "The recipient number is not a valid Bangladeshi mobile number.",
				"doc_url": "https://nishchit.tech/docs/errors#invalid_recipient",
				"request_id": "req_01JBX7QW"
			}
		}`

		return &http.Response{
			StatusCode: http.StatusBadRequest,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewBufferString(errJSON)),
		}, nil
	})

	ctx := context.Background()

	_, err := client.SendMessage(ctx, SendSMSRequest{
		To:   "01712345678",
		Body: "Hello",
	})
	if err == nil {
		t.Fatal("expected error, got nil")
	}

	nishErr, ok := err.(*NishchitError)
	if !ok {
		t.Fatalf("expected *NishchitError, got %T: %v", err, err)
	}

	if nishErr.StatusCode != 400 {
		t.Errorf("expected status code 400, got %d", nishErr.StatusCode)
	}
	if nishErr.Detail.Code != "invalid_recipient" {
		t.Errorf("expected code invalid_recipient, got %s", nishErr.Detail.Code)
	}
	if !strings.Contains(nishErr.Detail.DocURL, "https://nishchit.tech/docs/errors#invalid_recipient") {
		t.Errorf("expected doc_url link, got %s", nishErr.Detail.DocURL)
	}
}

func TestNishchitOTPProvider_Flow(t *testing.T) {
	provider := NewNishchitOTPProvider("nk_test_key123", "https://api.nishchit.tech", "FMCG+")
	provider.client.HTTPClient.Transport = roundTripperFunc(func(r *http.Request) (*http.Response, error) {
		resJSON := `{
			"id": "msg_otp_test_123",
			"object": "message",
			"status": "accepted",
			"delivery_status": "unknown",
			"to": "+8801700000000",
			"from": "FMCG+",
			"body": "Your FMCG+ OTP is 654321",
			"segments": 1,
			"encoding": "gsm7",
			"credits": 1,
			"created_at": "2026-09-29T10:00:00Z"
		}`
		return &http.Response{
			StatusCode: http.StatusCreated,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewBufferString(resJSON)),
		}, nil
	})

	if provider.Name() != "nishchit" {
		t.Errorf("expected provider name nishchit, got %s", provider.Name())
	}

	ctx := context.Background()
	phone := "01700000000" // magic success number

	sessID, err := provider.SendOTP(ctx, phone)
	if err != nil {
		t.Fatalf("SendOTP failed: %v", err)
	}
	if sessID != "msg_otp_test_123" {
		t.Errorf("expected sessID msg_otp_test_123, got %s", sessID)
	}

	// Verify with magic test code (in test mode nk_test_..., 123456 is allowed for tests)
	ok, verifiedPhone, err := provider.VerifyOTP(ctx, phone, "123456")
	if err != nil || !ok {
		t.Fatalf("VerifyOTP with test code failed: ok=%v, err=%v", ok, err)
	}
	if verifiedPhone != "+8801700000000" {
		t.Errorf("expected verified phone +8801700000000, got %s", verifiedPhone)
	}
}
