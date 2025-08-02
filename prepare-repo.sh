#!/bin/bash

# Repository preparation script for nano-recamera
# This script prepares the repository for GitHub upload

set -e

log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

success() {
    echo "[SUCCESS] $1"
}

# Clean build artifacts
clean_build_artifacts() {
    log "Cleaning build artifacts..."
    
    if [ -f "Makefile" ]; then
        make distclean 2>/dev/null || true
    fi
    
    # Remove build artifacts
    rm -f src/nano
    rm -f config.log config.status config.cache stamp-h1 config.h
    rm -rf autom4te.cache/
    
    # Remove personal build script
    if [ -f "build.sh" ]; then
        warn "Removing personal build.sh (contains credentials)"
        rm -f build.sh
    fi
    
    success "Build artifacts cleaned"
}

# Initialize git repository if not already done
init_git() {
    if [ ! -d ".git" ]; then
        log "Initializing git repository..."
        git init
        git add .
        git commit -m "Initial commit: Nano cross-compilation for reCamera

- Added comprehensive build system for RISC-V cross-compilation
- Includes automated deployment to reCamera devices
- Static linking with ncurses for no runtime dependencies
- Complete documentation and quick start guide"
        success "Git repository initialized"
    else
        log "Git repository already exists"
    fi
}

# Show repository status
show_status() {
    log "Repository status:"
    echo
    echo "Files ready for GitHub:"
    echo "- README-RECAMERA.md  (Main documentation)"
    echo "- QUICKSTART.md       (Quick start guide)"
    echo "- build-recamera.sh   (Build script)"
    echo "- .github/workflows/  (CI/CD configuration)"
    echo "- .gitignore          (Git ignore rules)"
    echo
    echo "Next steps:"
    echo "1. Create repository on GitHub: https://github.com/new"
    echo "2. Set repository name: nano"
    echo "3. Add remote: git remote add origin https://github.com/Toastee0/nano.git"
    echo "4. Push: git push -u origin main"
    echo
    echo "GitHub repository setup commands:"
    echo "git remote add origin https://github.com/Toastee0/nano.git"
    echo "git branch -M main"
    echo "git push -u origin main"
}

# Main execution
main() {
    log "Preparing nano repository for GitHub..."
    
    clean_build_artifacts
    init_git
    show_status
    
    success "Repository preparation complete!"
}

# Run main function
main "$@"
