package config

import (
	"fmt"
	"os"
	"strings"
)

type Config struct {
	Port         string
	DatabaseURL  string
	DBHost       string
	DBPort       string
	DBUser       string
	DBPassword   string
	DBName       string
	DBSSLMode    string
	S3Bucket     string
	S3Region     string
	S3Endpoint   string
	S3AccessKey  string
	S3SecretKey  string
	UploadsDir   string
	DataFilePath string

	// Auth & Security
	JWTSecret            string
	JWTAccessExpiryHours int
	JWTRefreshExpiryDays int
	OTPProvider          string // "nishchit", "firebase", "local", "mock"
	FirebaseProjectID    string

	// Nishchit SMS Gateway (Bangladesh A2P Infrastructure)
	NishchitAPIKey  string
	NishchitBaseURL string
	NishchitFrom    string
}

// loadDotEnv parses key=value pairs from .env files and sets them if not already defined in the environment.
func loadDotEnv(paths ...string) {
	for _, path := range paths {
		content, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		lines := strings.Split(string(content), "\n")
		for _, line := range lines {
			trimmed := strings.TrimSpace(line)
			if trimmed == "" || strings.HasPrefix(trimmed, "#") {
				continue
			}
			parts := strings.SplitN(trimmed, "=", 2)
			if len(parts) == 2 {
				k := strings.TrimSpace(parts[0])
				v := strings.TrimSpace(parts[1])
				v = strings.Trim(v, `"'`)
				if os.Getenv(k) == "" {
					_ = os.Setenv(k, v)
				}
			}
		}
	}
}

func LoadConfig() *Config {
	loadDotEnv(".env", "../.env")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// PostgreSQL database configuration
	databaseURL := os.Getenv("DATABASE_URL")
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "postgres"
	}
	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		dbPassword = "postgres"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "fmcg_pos"
	}
	dbSSLMode := os.Getenv("DB_SSLMODE")
	if dbSSLMode == "" {
		dbSSLMode = "disable"
	}

	// S3 Storage
	bucket := os.Getenv("AWS_S3_BUCKET")
	if bucket == "" {
		bucket = "fmcg-plus-retail-assets"
	}
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "ap-southeast-1"
	}
	endpoint := os.Getenv("AWS_S3_ENDPOINT")
	accessKey := os.Getenv("AWS_ACCESS_KEY_ID")
	secretKey := os.Getenv("AWS_SECRET_ACCESS_KEY")

	uploadsDir := os.Getenv("UPLOADS_DIR")
	if uploadsDir == "" {
		uploadsDir = "uploads"
	}

	dataPath := os.Getenv("DATA_FILE_PATH")
	if dataPath == "" {
		dataPath = "../bangladesh_fmcg_products.json"
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "fmcg-plus-super-secret-jwt-key-for-local-development-2026"
	}

	otpProvider := os.Getenv("OTP_PROVIDER")
	nishchitAPIKey := os.Getenv("NISHCHIT_API_KEY")
	nishchitBaseURL := os.Getenv("NISHCHIT_BASE_URL")
	if nishchitBaseURL == "" {
		nishchitBaseURL = "https://api.nishchit.tech"
	}
	nishchitFrom := os.Getenv("NISHCHIT_FROM")

	if otpProvider == "" {
		if nishchitAPIKey != "" {
			otpProvider = "nishchit"
		} else {
			otpProvider = "mock"
		}
	}

	firebaseProjectID := os.Getenv("FIREBASE_PROJECT_ID")

	return &Config{
		Port:                 port,
		DatabaseURL:          databaseURL,
		DBHost:               dbHost,
		DBPort:               dbPort,
		DBUser:               dbUser,
		DBPassword:           dbPassword,
		DBName:               dbName,
		DBSSLMode:            dbSSLMode,
		S3Bucket:             bucket,
		S3Region:             region,
		S3Endpoint:           endpoint,
		S3AccessKey:          accessKey,
		S3SecretKey:          secretKey,
		UploadsDir:           uploadsDir,
		DataFilePath:         dataPath,
		JWTSecret:            jwtSecret,
		JWTAccessExpiryHours: 1,
		JWTRefreshExpiryDays: 30,
		OTPProvider:          otpProvider,
		FirebaseProjectID:    firebaseProjectID,
		NishchitAPIKey:       nishchitAPIKey,
		NishchitBaseURL:      nishchitBaseURL,
		NishchitFrom:         nishchitFrom,
	}
}

// GetPostgresDSN returns the connection string for PostgreSQL
func (c *Config) GetPostgresDSN() string {
	if c.DatabaseURL != "" {
		return c.DatabaseURL
	}
	return fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=Asia/Dhaka",
		c.DBHost, c.DBUser, c.DBPassword, c.DBName, c.DBPort, c.DBSSLMode,
	)
}
