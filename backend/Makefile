.PHONY: help db-up db-down db-logs migrate seed run test build clean

help:
	@echo "FMCG+ Backend Command Center"
	@echo "=================================================="
	@echo "  make db-up      - Start PostgreSQL in Docker container"
	@echo "  make db-down    - Stop PostgreSQL container"
	@echo "  make db-logs    - Follow PostgreSQL container logs"
	@echo "  make migrate    - Run schema migrations against PostgreSQL"
	@echo "  make seed       - Run migrations & seed 623 products into PostgreSQL"
	@echo "  make run        - Run backend API server"
	@echo "  make test       - Run all unit and integration tests"
	@echo "  make build      - Compile server, seeder, and migrate binaries"
	@echo "=================================================="

db-up:
	docker compose up -d

db-down:
	docker compose down

db-logs:
	docker compose logs -f postgres

migrate:
	go run cmd/migrate/main.go

seed:
	go run cmd/seed/main.go

run:
	go run cmd/server/main.go

test:
	go test -v ./...

build:
	go build -o server ./cmd/server
	go build -o seeder ./cmd/seed
	go build -o migrate ./cmd/migrate

clean:
	rm -f server seeder migrate
