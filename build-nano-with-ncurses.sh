#!/bin/bash

# RISC-V cross-compilation environment
export TOOLCHAIN_PATH="/home/toastee/recamera/host-tools/gcc/riscv64-linux-musl-x86_64"
export PREFIX="/opt/nano-rv"
export SYSROOT="$TOOLCHAIN_PATH/sysroot"
export NCURSES_PREFIX="/opt/ncurses-rv"

# Cross-compiler settings
export CC="$TOOLCHAIN_PATH/bin/riscv64-unknown-linux-musl-gcc"
export CXX="$TOOLCHAIN_PATH/bin/riscv64-unknown-linux-musl-g++"
export AR="$TOOLCHAIN_PATH/bin/riscv64-unknown-linux-musl-ar"
export RANLIB="$TOOLCHAIN_PATH/bin/riscv64-unknown-linux-musl-ranlib"
export STRIP="$TOOLCHAIN_PATH/bin/riscv64-unknown-linux-musl-strip"

# Additional flags with ncurses paths
export CFLAGS="-O2 -pipe -I$SYSROOT$NCURSES_PREFIX/include/ncursesw -I$SYSROOT$NCURSES_PREFIX/include"
export CXXFLAGS="-O2 -pipe -I$SYSROOT$NCURSES_PREFIX/include/ncursesw -I$SYSROOT$NCURSES_PREFIX/include"
export LDFLAGS="-L$SYSROOT$NCURSES_PREFIX/lib"
export LIBS="-lncursesw"
export NCURSES_LIBS="-lncursesw"

# SSH configuration
TARGET_HOST="192.168.42.1"
TARGET_USER="recamera"
TARGET_PASSWORD="Watson64!"

# Function to setup SSH key if it doesn't exist
setup_ssh_key() {
    echo "Setting up SSH key authentication..."
    
    # Generate SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Generating SSH key..."
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
    fi
    
    # Copy SSH key to target device using sshpass
    if command -v sshpass >/dev/null 2>&1; then
        echo "Copying SSH key to target device..."
        sshpass -p "$TARGET_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST"
    else
        echo "sshpass not found. Installing..."
        sudo apt-get update && sudo apt-get install -y sshpass
        echo "Copying SSH key to target device..."
        sshpass -p "$TARGET_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST"
    fi
}

# Function to execute SSH commands with key or password fallback
ssh_exec() {
    local cmd="$1"
    # Try with SSH key first
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "$cmd" 2>/dev/null; then
        return 0
    else
        # Fallback to password if key auth fails
        if command -v sshpass >/dev/null 2>&1; then
            sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST" "$cmd"
        else
            echo "SSH key auth failed and sshpass not available. Please enter password manually:"
            ssh "$TARGET_USER@$TARGET_HOST" "$cmd"
        fi
    fi
}

# Function to execute SCP with key or password fallback
scp_exec() {
    local src="$1"
    local dst="$2"
    # Try with SSH key first
    if scp -o BatchMode=yes -o ConnectTimeout=5 "$src" "$TARGET_USER@$TARGET_HOST:$dst" 2>/dev/null; then
        return 0
    else
        # Fallback to password if key auth fails
        if command -v sshpass >/dev/null 2>&1; then
            sshpass -p "$TARGET_PASSWORD" scp -o StrictHostKeyChecking=no "$src" "$TARGET_USER@$TARGET_HOST:$dst"
        else
            echo "SSH key auth failed and sshpass not available. Please enter password manually:"
            scp "$src" "$TARGET_USER@$TARGET_HOST:$dst"
        fi
    fi
}

echo "Building nano for RISC-V..."
echo "Using compiler: $CC"
echo "Using ncurses from: $SYSROOT$NCURSES_PREFIX"

# Clean previous build
make distclean 2>/dev/null || true

# Configure nano for cross-compilation
./configure \
    --host=riscv64-unknown-linux-musl \
    --target=riscv64-unknown-linux-musl \
    --build=x86_64-pc-linux-gnu \
    --prefix="$PREFIX" \
    --disable-shared \
    --with-ncursesw \
    NCURSES_LIBS="$NCURSES_LIBS" \
    CC="$CC" \
    CXX="$CXX" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    STRIP="$STRIP" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS"

if [ $? -eq 0 ]; then
    echo "Configuration successful, building..."
    make -j$(nproc)
    
    if [ $? -eq 0 ]; then
        echo "Build successful!"
        
        # Check if nano binary was created
        if [ ! -f "src/nano" ]; then
            echo "Error: nano binary not found in src/"
            exit 1
        fi

        echo "Build successful! Binary size:"
        ls -lh src/nano
        
        # Verify the binary is RISC-V
        echo "Verifying binary architecture:"
        file src/nano

        # Strip the binary to reduce size
        echo "Stripping binary..."
        $STRIP src/nano

        echo "Stripped binary size:"
        ls -lh src/nano
        
        # Check if SSH key authentication is working
        echo "Testing SSH connection..."
        if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" "echo 'SSH key auth working'" 2>/dev/null; then
            echo "SSH key authentication not working. Setting up..."
            setup_ssh_key
        fi

        # Copy the built binary to the target device
        echo "Copying nano binary to target device..."
        scp_exec "src/nano" "/tmp/nano"

        # Install nano on the target device
        echo "Installing nano on target device..."
        if ssh_exec "sudo cp /tmp/nano /usr/local/bin/nano && sudo chmod +x /usr/local/bin/nano"; then
            echo "Nano installed to /usr/local/bin/nano"
            NANO_PATH="/usr/local/bin/nano"
        else
            echo "sudo install failed, installing to ~/bin instead..."
            ssh_exec "mkdir -p ~/bin && cp /tmp/nano ~/bin/nano && chmod +x ~/bin/nano"
            echo "Nano installed to ~/bin/nano (add ~/bin to PATH if needed)"
            NANO_PATH="~/bin/nano"
        fi

        # Test nano on target
        echo "Testing nano installation..."
        ssh_exec "$NANO_PATH --version"

        echo "Nano build and deployment complete!"
        echo "You can now use 'nano' on the reCamera device."
        
    else
        echo "Build failed!"
        exit 1
    fi
else
    echo "Configuration failed!"
    exit 1
fi
