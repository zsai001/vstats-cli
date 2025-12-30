# vStats CLI Makefile

# Build variables
BINARY_NAME=vstats
VERSION?=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -s -w"

# Go commands
GO=go
GOBUILD=$(GO) build
GOTEST=$(GO) test
GOCLEAN=$(GO) clean
GOMOD=$(GO) mod

# Directories
BIN_DIR=bin
DIST_DIR=dist

# Platforms for cross-compilation
PLATFORMS=linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64 windows/arm64

.PHONY: all build build-all clean test deps lint install uninstall help

# Default target
all: build

# Build for current platform
build:
	@echo "Building $(BINARY_NAME) $(VERSION)..."
	@mkdir -p $(BIN_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME) .
	@echo "Build complete: $(BIN_DIR)/$(BINARY_NAME)"

# Build for all platforms
build-all: clean
	@echo "Building $(BINARY_NAME) $(VERSION) for all platforms..."
	@mkdir -p $(DIST_DIR)
	@for platform in $(PLATFORMS); do \
		os=$${platform%/*}; \
		arch=$${platform#*/}; \
		output=$(DIST_DIR)/$(BINARY_NAME)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then output=$$output.exe; fi; \
		echo "  Building $$os/$$arch..."; \
		GOOS=$$os GOARCH=$$arch $(GOBUILD) $(LDFLAGS) -o $$output . || exit 1; \
	done
	@echo "Build complete. Binaries in $(DIST_DIR)/"
	@ls -la $(DIST_DIR)/

# Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v ./...

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	$(GOTEST) -v -coverprofile=coverage.out ./...
	$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy

# Lint code
lint:
	@echo "Linting..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run ./...; \
	else \
		echo "golangci-lint not installed. Run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	fi

# Format code
fmt:
	@echo "Formatting code..."
	$(GO) fmt ./...

# Vet code
vet:
	@echo "Vetting code..."
	$(GO) vet ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -rf $(BIN_DIR) $(DIST_DIR)
	rm -f coverage.out coverage.html

# Install to /usr/local/bin
install: build
	@echo "Installing $(BINARY_NAME) to /usr/local/bin..."
	sudo cp $(BIN_DIR)/$(BINARY_NAME) /usr/local/bin/$(BINARY_NAME)
	@echo "Installed. Run '$(BINARY_NAME) --help' to get started."

# Uninstall from /usr/local/bin
uninstall:
	@echo "Uninstalling $(BINARY_NAME)..."
	sudo rm -f /usr/local/bin/$(BINARY_NAME)
	@echo "Uninstalled."

# Create release archives
release: build-all
	@echo "Creating release archives..."
	@mkdir -p $(DIST_DIR)/release
	@for platform in $(PLATFORMS); do \
		os=$${platform%/*}; \
		arch=$${platform#*/}; \
		binary=$(DIST_DIR)/$(BINARY_NAME)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then binary=$$binary.exe; fi; \
		archive=$(DIST_DIR)/release/$(BINARY_NAME)-$(VERSION)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then \
			zip -j $$archive.zip $$binary README.md; \
		else \
			tar -czvf $$archive.tar.gz -C $(DIST_DIR) $$(basename $$binary) -C .. README.md; \
		fi; \
	done
	@echo "Release archives in $(DIST_DIR)/release/"
	@ls -la $(DIST_DIR)/release/

# Generate checksums
checksums:
	@echo "Generating checksums..."
	@cd $(DIST_DIR) && sha256sum $(BINARY_NAME)-* > checksums.txt
	@echo "Checksums:"
	@cat $(DIST_DIR)/checksums.txt

# Run the CLI
run: build
	./$(BIN_DIR)/$(BINARY_NAME) $(ARGS)

# Development: build and run with arguments
dev:
	$(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME) . && ./$(BIN_DIR)/$(BINARY_NAME) $(ARGS)

# Show help
help:
	@echo "vStats CLI Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make              Build for current platform"
	@echo "  make build        Build for current platform"
	@echo "  make build-all    Build for all platforms"
	@echo "  make test         Run tests"
	@echo "  make test-coverage Run tests with coverage"
	@echo "  make deps         Download dependencies"
	@echo "  make lint         Lint code"
	@echo "  make fmt          Format code"
	@echo "  make vet          Vet code"
	@echo "  make clean        Clean build artifacts"
	@echo "  make install      Install to /usr/local/bin"
	@echo "  make uninstall    Uninstall from /usr/local/bin"
	@echo "  make release      Create release archives"
	@echo "  make checksums    Generate checksums for binaries"
	@echo "  make run ARGS='...' Build and run with arguments"
	@echo "  make dev ARGS='...' Quick dev build and run"
	@echo "  make help         Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  VERSION           Set build version (default: git tag or 'dev')"
	@echo ""
	@echo "Examples:"
	@echo "  make build VERSION=1.0.0"
	@echo "  make run ARGS='server list'"
	@echo "  make dev ARGS='login --help'"

