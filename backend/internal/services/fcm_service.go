package services

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

// FCMService handles push notification delivery via Firebase Cloud Messaging.
type FCMService struct {
	client *messaging.Client
}

// NewFCMService initializes the Firebase Admin SDK and returns an FCM client.
// credentialsPath is the path to the Firebase service account JSON key file.
func NewFCMService(credentialsPath string) (*FCMService, error) {
	if credentialsPath == "" {
		return nil, fmt.Errorf("FCM credentials path is empty")
	}

	ctx := context.Background()
	opt := option.WithCredentialsFile(credentialsPath)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize firebase app: %w", err)
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize FCM messaging client: %w", err)
	}

	log.Println("[FCM] Firebase Cloud Messaging service initialized successfully")
	return &FCMService{client: client}, nil
}

// SendToDevice sends a push notification to a single FCM registration token.
func (s *FCMService) SendToDevice(ctx context.Context, token, title, body string, data map[string]string) error {
	msg := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Sound:        "default",
				ChannelID:    "grocery_requests",
				DefaultSound: true,
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound:            "default",
					ContentAvailable: true,
				},
			},
		},
	}

	_, err := s.client.Send(ctx, msg)
	if err != nil {
		log.Printf("[FCM] Failed to send notification to token %s...: %v", token[:min(len(token), 20)], err)
		return err
	}

	log.Printf("[FCM] Notification sent successfully to token %s...", token[:min(len(token), 20)])
	return nil
}

// SendToMultiple sends a push notification to multiple FCM tokens.
// Returns a slice of errors for any failed sends (nil entries for successful ones).
func (s *FCMService) SendToMultiple(ctx context.Context, tokens []string, title, body string, data map[string]string) []error {
	var errs []error
	for _, token := range tokens {
		if err := s.SendToDevice(ctx, token, title, body, data); err != nil {
			errs = append(errs, err)
		}
	}
	return errs
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
