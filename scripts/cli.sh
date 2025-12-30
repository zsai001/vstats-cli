#!/bin/bash
# vStats CLI Installer
# Usage: curl -fsSL https://vstats.zsoft.cc/cli.sh | sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="zsai001/vstats-cli"
BINARY_NAME="vstats"
INSTALL_DIR="/usr/local/bin"

# Detect OS and Architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac

    case "$OS" in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        *)
            echo -e "${RED}Error: Unsupported operating system: $OS${NC}"
            exit 1
            ;;
    esac

    PLATFORM="${OS}-${ARCH}"
    echo -e "${BLUE}Detected platform: ${PLATFORM}${NC}"
}

# Get latest version from GitHub
get_latest_version() {
    LATEST_VERSION=$(curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${YELLOW}Warning: Could not fetch latest version, using 'latest'${NC}"
        LATEST_VERSION="latest"
    fi
    echo -e "${BLUE}Latest version: ${LATEST_VERSION}${NC}"
}

# Download and install
install() {
    DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_VERSION}/vstats-cli-${PLATFORM}"
    
    echo -e "${BLUE}Downloading ${BINARY_NAME} from ${DOWNLOAD_URL}...${NC}"
    
    TMP_DIR=$(mktemp -d)
    TMP_FILE="${TMP_DIR}/${BINARY_NAME}"
    
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"; then
        echo -e "${RED}Error: Failed to download ${BINARY_NAME}${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    chmod +x "$TMP_FILE"
    
    # Install to system directory
    if [ -w "$INSTALL_DIR" ]; then
        mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
    else
        echo -e "${YELLOW}Installing to ${INSTALL_DIR} requires sudo...${NC}"
        sudo mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
    fi
    
    rm -rf "$TMP_DIR"
    
    echo -e "${GREEN}✓ ${BINARY_NAME} installed successfully to ${INSTALL_DIR}/${BINARY_NAME}${NC}"
}

# Verify installation
verify() {
    if command -v "$BINARY_NAME" &> /dev/null; then
        VERSION=$("$BINARY_NAME" version 2>&1 || echo "unknown")
        echo -e "${GREEN}✓ Installation verified: ${VERSION}${NC}"
    else
        echo -e "${YELLOW}Warning: ${BINARY_NAME} not found in PATH${NC}"
        echo -e "${YELLOW}You may need to add ${INSTALL_DIR} to your PATH${NC}"
    fi
}

# Print usage
print_usage() {
    echo ""
    echo -e "${GREEN}vStats CLI has been installed!${NC}"
    echo ""
    echo "Quick Start:"
    echo "  ${BINARY_NAME} login              # Login to vStats Cloud"
    echo "  ${BINARY_NAME} server list        # List your servers"
    echo "  ${BINARY_NAME} server create web1 # Create a new server"
    echo "  ${BINARY_NAME} ssh agent root@srv # Deploy agent via SSH"
    echo ""
    echo "Documentation: https://vstats.zsoft.cc/docs/cli"
    echo ""
}

# Main
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       vStats CLI Installer                ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
    echo ""

    detect_platform
    get_latest_version
    install
    verify
    print_usage
}

main "$@"

