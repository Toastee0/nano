# Nano Text Editor for reCamera (RISC-V Cross-Compiled)

A cross-compiled version of the GNU nano text editor specifically built for reCamera devices running on RISC-V architecture with musl libc.

## Overview

This repository contains a pre-configured build system for cross-compiling GNU nano 6.4 for reCamera devices. The build creates a statically-linked binary that requires no additional dependencies on the target device.

## reCamera Information

For detailed information about reCamera devices, setup guides, and documentation, visit the **[Seeed Studio reCamera Getting Started Guide](https://wiki.seeedstudio.com/recamera_getting_started/)**.

## Features

- **Architecture**: RISC-V 64-bit (riscv64-unknown-linux-musl)
- **Library**: Statically linked with ncurses for terminal UI
- **Size**: Compact 571KB stripped binary
- **Features**: UTF-8 support, syntax highlighting, comprehensive editing capabilities
- **Dependencies**: None (statically linked)

## Prerequisites

### Host System Requirements
- Linux development environment (tested on Ubuntu/Debian)
- Git
- Build tools (`build-essential`, `cmake`, `make`)
- SSH tools (`ssh`, `scp`, optionally `sshpass`)

### Required Components
1. **RISC-V Cross-Compilation Toolchain**
   ```bash
   # Download and extract to ~/recamera/host-tools/gcc/riscv64-linux-musl-x86_64/
   wget https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-linux-musl/tarballs/riscv64-linux-musl--musl--stable-2023.05-1.tar.bz2
   ```

2. **ncurses Library (Cross-compiled)**
   - Clone and build from: https://github.com/Toastee0/ncurses
   - Must be built for RISC-V and installed to `../ncurses-6.4/`

### Directory Structure
```
~/recamera/
├── host-tools/
│   └── gcc/
│       └── riscv64-linux-musl-x86_64/
├── ncurses-6.4/          # Cross-compiled ncurses
└── nano-6.4/             # This repository
```

## Quick Start

### 1. Setup Environment
```bash
# Clone this repository
git clone https://github.com/Toastee0/nano.git ~/recamera/nano-6.4
cd ~/recamera/nano-6.4

# Ensure ncurses is built and available
ls ../ncurses-6.4/lib/libncursesw.a  # Should exist
```

### 2. Configure Target Device
Edit the SSH configuration in `build.sh`:
```bash
TARGET_HOST="192.168.42.1"    # Your reCamera IP
TARGET_USER="recamera"        # Username
TARGET_PASSWORD="Watson64!"   # Password
```

### 3. Build and Deploy
```bash
./build.sh
```

The script will:
- Configure nano with RISC-V cross-compilation
- Build the static binary
- Deploy to your reCamera device
- Install to `~/bin/nano` on the device

## Manual Build Process

If you prefer to build manually:

```bash
# Set up cross-compilation environment
export PATH=$HOME/recamera/host-tools/gcc/riscv64-linux-musl-x86_64/bin:$PATH

# Clean any previous builds
make distclean

# Configure with absolute paths to ncurses
./configure \
    --host=riscv64-unknown-linux-musl \
    --prefix=/opt/nano-rv \
    --enable-utf8 \
    --disable-libmagic \
    --disable-nls \
    PKG_CONFIG_PATH="/home/$USER/recamera/ncurses-6.4/lib/pkgconfig" \
    CPPFLAGS="-I/home/$USER/recamera/ncurses-6.4/include -I/home/$USER/recamera/ncurses-6.4/include/ncursesw" \
    LDFLAGS="-L/home/$USER/recamera/ncurses-6.4/lib -static" \
    NCURSESW_CFLAGS="-I/home/$USER/recamera/ncurses-6.4/include/ncursesw" \
    NCURSESW_LIBS="-L/home/$USER/recamera/ncurses-6.4/lib -lncursesw"

# Build
make -j$(nproc)

# Strip binary for smaller size
strip src/nano
```

## Installation on reCamera

### Automatic (via build.sh)
The build script automatically deploys and installs nano to `~/bin/nano`.

### Manual Installation
```bash
# Copy binary to device (user installation)
scp src/nano recamera@192.168.42.1:~/bin/

# OR for system-wide installation (accessible to all users)
scp src/nano recamera@192.168.42.1:~/nano
ssh recamera@192.168.42.1 "sudo mv ~/nano /usr/bin/nano"
```

## Usage

On your reCamera device:
```bash
# Option 1: If installed in ~/bin and added to PATH
nano filename.txt

# Option 2: If installed system-wide
nano filename.txt

# Option 3: Use full path if not in PATH
~/bin/nano filename.txt
```
```

## Usage

On your reCamera device:
```bash
# Use with full path
~/bin/nano filename.txt

# Or if added to PATH
nano filename.txt
```

## Verification

To verify the build:
```bash
# Check architecture
file src/nano
# Output: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), statically linked, stripped

# Check on device
ssh recamera@192.168.42.1 '~/bin/nano --version'
# Output: GNU nano, version 6.4
```

## Troubleshooting

### Build Issues
- **curses.h not found**: Ensure ncurses is properly cross-compiled and paths are correct
- **Wrong architecture**: Verify RISC-V toolchain is in PATH and configure uses correct host triplet
- **Link errors**: Check that ncurses libraries are statically built

### Deployment Issues
- **SSH connection fails**: Verify reCamera IP address and credentials
- **Permission denied**: Check that target user has write access to destination directory

### Runtime Issues
- **nano not found**: Add `~/bin` to PATH, use full path, or install system-wide with `sudo mv ~/bin/nano /usr/bin/nano`
- **Segmentation fault**: Verify binary was built for correct architecture

## Dependencies

### Build Dependencies
- GNU nano 6.4 source code
- RISC-V cross-compilation toolchain (musl)
- Cross-compiled ncurses library
- Standard build tools (gcc, make, autotools)

### Runtime Dependencies
None - the binary is statically linked.

## Technical Details

### Cross-Compilation Settings
- **Target**: riscv64-unknown-linux-musl
- **C Library**: musl libc
- **Linking**: Static (no runtime dependencies)
- **ncurses**: Wide character support (ncursesw)

### Build Configuration
- UTF-8 support enabled
- libmagic disabled (reduces dependencies)
- NLS (internationalization) disabled (reduces size)
- Static linking for portability

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes on reCamera hardware
4. Submit a pull request

## License

This project maintains the original GNU nano license (GPL v3). See `COPYING` for details.

## Acknowledgments

- GNU nano development team
- ncurses library developers
- RISC-V toolchain maintainers
- reCamera community

## Related Projects

- [ncurses for reCamera](https://github.com/Toastee0/ncurses) - Cross-compiled ncurses dependency
- [reCamera SDK](https://github.com/SeeedStudio/sscma-example-sg200x) - Official reCamera development tools

---

**Build tested on**: Ubuntu 22.04 LTS  
**Target tested on**: reCamera with RISC-V SG2002 SoC  
**Last updated**: August 2025
