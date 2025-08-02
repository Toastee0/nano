#!/bin/bash

# Nano Cross-Compilation Build Script for reCamera (RISC-V)
# 
# This script cross-compiles GNU nano 6.4 for reCamera devices
# Requirements:
# - RISC-V cross-compilation toolchain
# - Cross-compiled ncurses library
# - Proper directory structure (see README-RECAMERA.md)

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - adjust these paths as needed
TOOLCHAIN_PATH="$HOME/recamera/host-tools/gcc/riscv64-linux-musl-x86_64/bin"
NCURSES_PATH="$HOME/recamera/ncurses-6.4"
TARGET_HOST="${TARGET_HOST:-192.168.42.1}"
TARGET_USER="${TARGET_USER:-recamera}"
TARGET_PASSWORD="${TARGET_PASSWORD:-}"

# Function for colored output
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Verify prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check toolchain
    if [ ! -d "$TOOLCHAIN_PATH" ]; then
        error "RISC-V toolchain not found at $TOOLCHAIN_PATH"
    fi
    
    # Check ncurses
    if [ ! -f "$NCURSES_PATH/lib/libncursesw.a" ]; then
        error "ncurses library not found at $NCURSES_PATH/lib/libncursesw.a"
    fi
    
    # Check compiler
    export PATH="$TOOLCHAIN_PATH:$PATH"
    if ! command -v riscv64-unknown-linux-musl-gcc >/dev/null 2>&1; then
        error "RISC-V compiler not found in PATH"
    fi
    
    success "Prerequisites check passed"
}

# SSH helper functions (optional deployment)
setup_ssh_key() {
    if [ -z "$TARGET_PASSWORD" ]; then
        warn "No target password set, skipping SSH key setup"
        return 1
    fi
    
    log "Setting up SSH key authentication..."
    
    # Generate SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        log "Generating SSH key..."
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
    fi
    
    # Copy SSH key to target device using sshpass
    if command -v sshpass >/dev/null 2>&1; then
        log "Copying SSH key to target device..."
        sshpass -p "$TARGET_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST"
    else
        warn "sshpass not found. Install with: sudo apt-get install sshpass"
        return 1
    fi
}

# Execute SSH commands with fallback
ssh_exec() {
    local cmd="$1"
    # Try with SSH key first
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "$cmd" 2>/dev/null; then
        return 0
    else
        # Fallback to password if key auth fails
        if command -v sshpass >/dev/null 2>&1 && [ -n "$TARGET_PASSWORD" ]; then
            sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST" "$cmd"
        else
            warn "SSH key auth failed and no password available"
            return 1
        fi
    fi
}

# Execute SCP with fallback
scp_exec() {
    local src="$1"
    local dst="$2"
    # Try with SSH key first
    if scp -o BatchMode=yes -o ConnectTimeout=5 "$src" "$TARGET_USER@$TARGET_HOST:$dst" 2>/dev/null; then
        return 0
    else
        # Fallback to password if key auth fails
        if command -v sshpass >/dev/null 2>&1 && [ -n "$TARGET_PASSWORD" ]; then
            sshpass -p "$TARGET_PASSWORD" scp -o StrictHostKeyChecking=no "$src" "$TARGET_USER@$TARGET_HOST:$dst"
        else
            warn "SSH key auth failed and no password available"
            return 1
        fi
    fi
}

# Build nano
build_nano() {
    log "Building nano for RISC-V..."
    
    # Export cross-compilation environment
    export PATH="$TOOLCHAIN_PATH:$PATH"
    export PKG_CONFIG_PATH="$NCURSES_PATH/lib/pkgconfig"
    export CPPFLAGS="-I$NCURSES_PATH/include -I$NCURSES_PATH/include/ncursesw"
    export LDFLAGS="-L$NCURSES_PATH/lib -static"
    
    log "Using compiler: $(which riscv64-unknown-linux-musl-gcc)"
    
    # Clean any previous builds
    if [ -f "Makefile" ]; then
        log "Cleaning previous build..."
        make distclean || true
    fi
    
    # Configure with RISC-V cross-compilation
    log "Configuring build..."
    ./configure \
        --host=riscv64-unknown-linux-musl \
        --prefix=/opt/nano-rv \
        --enable-utf8 \
        --disable-libmagic \
        --disable-nls \
        NCURSESW_CFLAGS="-I$NCURSES_PATH/include/ncursesw" \
        NCURSESW_LIBS="-L$NCURSES_PATH/lib -lncursesw" \
        || error "Configure failed"
    
    # Build
    log "Compiling nano..."
    make -j$(nproc) || error "Build failed"
    
    # Show binary info
    log "Build successful! Binary info:"
    ls -lh src/nano
    file src/nano
    
    # Strip binary for smaller size
    log "Stripping binary..."
    riscv64-unknown-linux-musl-strip src/nano
    
    success "Stripped binary size: $(ls -lh src/nano | awk '{print $5}')"
}

# Deploy to device (optional)
deploy_nano() {
    if [ -z "$TARGET_HOST" ] || [ -z "$TARGET_USER" ]; then
        warn "No target device configured, skipping deployment"
        log "To deploy manually: scp src/nano user@device:~/bin/"
        return 0
    fi
    
    log "Deploying to reCamera device..."
    
    # Test SSH connection
    log "Testing SSH connection to $TARGET_USER@$TARGET_HOST..."
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "echo 'SSH test'" 2>/dev/null; then
        log "SSH key authentication not working. Setting up..."
        if ! setup_ssh_key; then
            error "Failed to setup SSH authentication"
        fi
    fi
    
    # Create bin directory on target
    log "Creating ~/bin directory on target..."
    ssh_exec "mkdir -p ~/bin" || error "Failed to create bin directory"
    
    # Copy binary
    log "Copying nano binary to target device..."
    scp_exec "src/nano" "~/bin/nano" || error "Failed to copy binary"
    
    # Make executable
    log "Making nano executable..."
    ssh_exec "chmod +x ~/bin/nano" || error "Failed to make executable"
    
    # Test installation
    log "Testing nano installation..."
    if ssh_exec "~/bin/nano --version" >/dev/null 2>&1; then
        success "Nano deployed successfully!"
        ssh_exec "~/bin/nano --version"
        echo
        log "Installation options:"
        log "1. Use with full path: ~/bin/nano filename.txt"
        log "2. Add to PATH: echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc"
        log "3. Install system-wide: sudo mv ~/bin/nano /usr/bin/nano"
        echo
        read -p "Install nano system-wide? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Installing nano system-wide..."
            if ssh_exec "sudo mv ~/bin/nano /usr/bin/nano"; then
                success "Nano installed system-wide at /usr/bin/nano"
                ssh_exec "nano --version"
            else
                warn "System-wide installation failed. Nano remains at ~/bin/nano"
            fi
        else
            log "Nano remains at ~/bin/nano"
        fi
    else
        error "Nano deployment verification failed"
    fi
}

# Main execution
main() {
    log "Starting nano cross-compilation for reCamera..."
    
    check_prerequisites
    build_nano
    
    # Ask about deployment
    if [ -n "$TARGET_HOST" ] && [ -n "$TARGET_USER" ]; then
        echo
        read -p "Deploy to reCamera device $TARGET_USER@$TARGET_HOST? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            deploy_nano
        else
            log "Skipping deployment. Binary available at: src/nano"
        fi
    else
        log "No deployment target configured. Binary available at: src/nano"
    fi
    
    success "Build complete!"
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Nano Cross-Compilation Build Script for reCamera"
    echo
    echo "Usage: $0"
    echo
    echo "Environment variables:"
    echo "  TARGET_HOST     - reCamera device IP (default: 192.168.42.1)"
    echo "  TARGET_USER     - reCamera username (default: recamera)"
    echo "  TARGET_PASSWORD - reCamera password (for automatic deployment)"
    echo
    echo "Prerequisites:"
    echo "  - RISC-V toolchain at ~/recamera/host-tools/gcc/riscv64-linux-musl-x86_64/"
    echo "  - Cross-compiled ncurses at ~/recamera/ncurses-6.4/"
    echo
    echo "Example with custom settings:"
    echo "  TARGET_HOST=192.168.1.100 TARGET_PASSWORD=mypass $0"
    echo
    exit 0
fi

# Run main function
main "$@"
