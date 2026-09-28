package services

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"

	"fmcg-pos-backend/internal/config"
)

type StorageService interface {
	UploadImage(ctx context.Context, fileHeader *multipart.FileHeader) (string, error)
	GeneratePresignedUploadURL(ctx context.Context, filename string) (string, string, error)
}

type s3Service struct {
	cfg        *config.Config
	s3Client   *s3.Client
	presignS3  *s3.PresignClient
	isRealS3   bool
	uploadsDir string
}

func NewStorageService(cfg *config.Config) StorageService {
	svc := &s3Service{
		cfg:        cfg,
		uploadsDir: cfg.UploadsDir,
		isRealS3:   false,
	}

	// Ensure local uploads fallback dir exists
	_ = os.MkdirAll(cfg.UploadsDir, 0755)

	// If AWS credentials provided, configure real AWS S3 client
	if cfg.S3AccessKey != "" && cfg.S3SecretKey != "" {
		customResolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
			if cfg.S3Endpoint != "" {
				return aws.Endpoint{
					URL:               cfg.S3Endpoint,
					SigningRegion:     cfg.S3Region,
					HostnameImmutable: true,
				}, nil
			}
			return aws.Endpoint{}, &aws.EndpointNotFoundError{}
		})

		awsCfg, err := awsconfig.LoadDefaultConfig(context.TODO(),
			awsconfig.WithRegion(cfg.S3Region),
			awsconfig.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(cfg.S3AccessKey, cfg.S3SecretKey, "")),
			awsconfig.WithEndpointResolverWithOptions(customResolver),
		)
		if err == nil {
			client := s3.NewFromConfig(awsCfg)
			svc.s3Client = client
			svc.presignS3 = s3.NewPresignClient(client)
			svc.isRealS3 = true
		}
	}

	return svc
}

func (s *s3Service) UploadImage(ctx context.Context, fileHeader *multipart.FileHeader) (string, error) {
	file, err := fileHeader.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer file.Close()

	ext := filepath.Ext(fileHeader.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	objectKey := fmt.Sprintf("products/%s%s", uuid.New().String(), ext)

	// If real S3 client is configured
	if s.isRealS3 && s.s3Client != nil {
		buf := bytes.NewBuffer(nil)
		if _, err := io.Copy(buf, file); err != nil {
			return "", err
		}

		_, err = s.s3Client.PutObject(ctx, &s3.PutObjectInput{
			Bucket:      aws.String(s.cfg.S3Bucket),
			Key:         aws.String(objectKey),
			Body:        bytes.NewReader(buf.Bytes()),
			ContentType: aws.String(fileHeader.Header.Get("Content-Type")),
		})
		if err != nil {
			return "", fmt.Errorf("failed to upload to S3: %w", err)
		}

		s3URL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.cfg.S3Bucket, s.cfg.S3Region, objectKey)
		return s3URL, nil
	}

	// Fallback to local storage with simulated S3 URL
	localPath := filepath.Join(s.uploadsDir, filepath.Base(objectKey))
	out, err := os.Create(localPath)
	if err != nil {
		return "", fmt.Errorf("failed to create local file: %w", err)
	}
	defer out.Close()

	if _, err := io.Copy(out, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("/uploads/%s", filepath.Base(objectKey)), nil
}

func (s *s3Service) GeneratePresignedUploadURL(ctx context.Context, filename string) (string, string, error) {
	ext := filepath.Ext(filename)
	if ext == "" {
		ext = ".jpg"
	}
	objectKey := fmt.Sprintf("products/%s%s", uuid.New().String(), ext)

	if s.isRealS3 && s.presignS3 != nil {
		req, err := s.presignS3.PresignPutObject(ctx, &s3.PutObjectInput{
			Bucket: aws.String(s.cfg.S3Bucket),
			Key:    aws.String(objectKey),
		}, s3.WithPresignExpires(15*time.Minute))
		if err != nil {
			return "", "", fmt.Errorf("failed to generate S3 presigned URL: %w", err)
		}
		publicURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.cfg.S3Bucket, s.cfg.S3Region, objectKey)
		return req.URL, publicURL, nil
	}

	// Simulated presigned URL endpoint for development
	mockUploadURL := fmt.Sprintf("/api/v1/storage/upload?key=%s", objectKey)
	publicURL := fmt.Sprintf("/uploads/%s", filepath.Base(objectKey))
	return mockUploadURL, publicURL, nil
}
