#!/bin/bash

# Release packaging script for nano-recamera
# This script creates a release package with the compiled binary

set -e

VERSION=$(grep "PACKAGE_VERSION" config.h 2>/dev/null | cut -d'"' -f2 || echo "6.4")
RELEASE_NAME="nano-recamera-v${VERSION}"
RELEASE_DIR="release"

log() {
    echo "[INFO] $1"
}

success() {
    echo "[SUCCESS] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

# Create release package
create_release() {
    log "Creating release package for nano v${VERSION}..."
    
    # Check if binary exists
    if [ ! -f "src/nano" ]; then
        error "Binary not found. Run './build-recamera.sh' first."
    fi
    
    # Verify it's the right architecture
    if ! file src/nano | grep -q "UCB RISC-V"; then
        error "Binary is not RISC-V architecture!"
    fi
    
    # Create release directory
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR/$RELEASE_NAME"
    
    # Copy binary
    cp src/nano "$RELEASE_DIR/$RELEASE_NAME/nano-recamera"
    
    # Copy documentation
    cp README-RECAMERA.md "$RELEASE_DIR/$RELEASE_NAME/"
    cp QUICKSTART.md "$RELEASE_DIR/$RELEASE_NAME/"
    cp COPYING "$RELEASE_DIR/$RELEASE_NAME/LICENSE"
    
    # Create installation script
    cat > "$RELEASE_DIR/$RELEASE_NAME/install.sh" << 'EOF'
#!/bin/bash

# Installation script for nano-recamera
TARGET_HOST="${1:-192.168.42.1}"
TARGET_USER="${2:-recamera}"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [HOST] [USER]"
    echo "  HOST: reCamera IP address (default: 192.168.42.1)"
    echo "  USER: reCamera username (default: recamera)"
    exit 0
fi

echo "Installing nano to $TARGET_USER@$TARGET_HOST..."

# Copy binary
scp nano-recamera "$TARGET_USER@$TARGET_HOST:~/bin/nano"

# Make executable and test
ssh "$TARGET_USER@$TARGET_HOST" 'chmod +x ~/bin/nano && ~/bin/nano --version'

echo
echo "Installation complete! Choose an option:"
echo "1. Use with full path: ~/bin/nano filename.txt"
echo "2. Add to PATH: echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc"
echo "3. Install system-wide: sudo mv ~/bin/nano /usr/bin/nano"
echo

read -p "Install nano system-wide? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing system-wide..."
    ssh "$TARGET_USER@$TARGET_HOST" 'sudo mv ~/bin/nano /usr/bin/nano && nano --version'
    echo "Nano installed system-wide!"
else
    echo "Nano available at ~/bin/nano"
fi
EOF
    
    chmod +x "$RELEASE_DIR/$RELEASE_NAME/install.sh"
    
    # Create README for the release
    cat > "$RELEASE_DIR/$RELEASE_NAME/README.txt" << EOF
Nano Text Editor for reCamera - Release v${VERSION}
================================================

This package contains a pre-compiled nano text editor for reCamera devices.

Files included:
- nano-recamera     : The compiled binary (RISC-V 64-bit)
- install.sh        : Automated installation script
- README-RECAMERA.md: Complete documentation
- QUICKSTART.md     : Quick start guide
- LICENSE           : Software license

Quick Installation:
1. ./install.sh [your-recamera-ip] [username]
   Example: ./install.sh 192.168.42.1 recamera

Manual Installation:
1. scp nano-recamera recamera@192.168.42.1:~/bin/nano
2. ssh recamera@192.168.42.1
3. chmod +x ~/bin/nano
4. ~/bin/nano --version

Binary Information:
- Architecture: $(file nano-recamera | cut -d: -f2)
- Size: $(ls -lh nano-recamera | awk '{print $5}')
- Build date: $(date)

For issues and documentation:
https://github.com/Toastee0/nano
EOF
    
    # Create tarball
    cd "$RELEASE_DIR"
    tar -czf "${RELEASE_NAME}.tar.gz" "$RELEASE_NAME"
    zip -r "${RELEASE_NAME}.zip" "$RELEASE_NAME"
    cd ..
    
    # Show package info
    log "Release package created:"
    echo "  Directory: $RELEASE_DIR/$RELEASE_NAME/"
    echo "  Tarball:   $RELEASE_DIR/${RELEASE_NAME}.tar.gz"
    echo "  Zip file:  $RELEASE_DIR/${RELEASE_NAME}.zip"
    echo
    echo "Package contents:"
    ls -la "$RELEASE_DIR/$RELEASE_NAME/"
    echo
    echo "Package sizes:"
    ls -lh "$RELEASE_DIR/"*.{tar.gz,zip} 2>/dev/null || true
    
    success "Release package ready for distribution!"
}

# Create checksums
create_checksums() {
    log "Creating checksums..."
    cd "$RELEASE_DIR"
    
    # Create checksums file
    sha256sum *.tar.gz *.zip > checksums.sha256
    md5sum *.tar.gz *.zip > checksums.md5
    
    log "Checksums created:"
    cat checksums.sha256
    cd ..
}

# Show GitHub release instructions
show_github_instructions() {
    echo
    echo "GitHub Release Instructions:"
    echo "1. Go to: https://github.com/Toastee0/nano/releases/new"
    echo "2. Tag version: v${VERSION}"
    echo "3. Release title: 'Nano v${VERSION} for reCamera'"
    echo "4. Upload files:"
    echo "   - ${RELEASE_NAME}.tar.gz"
    echo "   - ${RELEASE_NAME}.zip"
    echo "   - checksums.sha256"
    echo "   - checksums.md5"
    echo
    echo "5. Description template:"
    echo "---"
    echo "# Nano Text Editor v${VERSION} for reCamera"
    echo ""
    echo "Pre-compiled nano text editor for reCamera devices (RISC-V architecture)."
    echo ""
    echo "## Download"
    echo "- \`${RELEASE_NAME}.tar.gz\` - Linux/Unix package"
    echo "- \`${RELEASE_NAME}.zip\` - Windows-friendly package"
    echo ""
    echo "## Installation"
    echo "1. Download and extract the package"
    echo "2. Run \`./install.sh\` for automatic installation"
    echo "3. Or follow manual installation in README-RECAMERA.md"
    echo ""
    echo "## Features"
    echo "- RISC-V 64-bit static binary"
    echo "- No runtime dependencies"
    echo "- UTF-8 support"
    echo "- Syntax highlighting"
    echo "- Only 571KB compressed"
    echo ""
    echo "## Verification"
    echo "Check file integrity with provided checksums."
    echo "---"
}

# Main execution
main() {
    create_release
    create_checksums
    show_github_instructions
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Release Packaging Script for nano-recamera"
    echo
    echo "Usage: $0"
    echo
    echo "This script creates a distribution package with:"
    echo "- Compiled nano binary"
    echo "- Installation script"
    echo "- Documentation"
    echo "- Checksums"
    echo
    echo "Prerequisites:"
    echo "- nano must be built (src/nano exists)"
    echo "- Binary must be RISC-V architecture"
    echo
    exit 0
fi

# Run main function
main "$@"
