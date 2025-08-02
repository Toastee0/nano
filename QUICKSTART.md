# Quick Start Guide - Nano for reCamera

This guide will get you up and running with nano on your reCamera device in just a few minutes.

## Option 1: Download Pre-built Binary (Easiest)

If available, download the pre-built binary from the [Releases](https://github.com/Toastee0/nano/releases) page.

```bash
# On your development machine
wget https://github.com/Toastee0/nano/releases/latest/download/nano-recamera-riscv64
chmod +x nano-recamera-riscv64

# Copy to your reCamera
scp nano-recamera-riscv64 recamera@192.168.42.1:~/bin/nano

# SSH to reCamera and test
ssh recamera@192.168.42.1
chmod +x ~/bin/nano
~/bin/nano --version
```

## Option 2: Build from Source

### 1. Setup Prerequisites

```bash
# Create directory structure
mkdir -p ~/recamera/host-tools/gcc
cd ~/recamera

# Download RISC-V toolchain
cd host-tools/gcc
wget https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-linux-musl/tarballs/riscv64-linux-musl--musl--stable-2023.05-1.tar.bz2
tar -xf riscv64-linux-musl--musl--stable-2023.05-1.tar.bz2
mv riscv64-linux-musl--musl--stable-2023.05-1 riscv64-linux-musl-x86_64
```

### 2. Build ncurses dependency

```bash
cd ~/recamera
git clone https://github.com/Toastee0/ncurses.git ncurses-src
cd ncurses-src
./build-for-recamera.sh  # Follow the ncurses build instructions
```

### 3. Build nano

```bash
cd ~/recamera
git clone https://github.com/Toastee0/nano.git nano-6.4
cd nano-6.4

# Build with deployment to device
TARGET_HOST=192.168.42.1 TARGET_PASSWORD=Watson64! ./build-recamera.sh

# Or build only (no deployment)
./build-recamera.sh
```

## Usage on reCamera

```bash
# SSH to your device
ssh recamera@192.168.42.1

# Option 1: Use with full path
~/bin/nano myfile.txt

# Option 2: Add ~/bin to PATH for easier access
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
nano myfile.txt

# Option 3: Install system-wide (requires sudo)
sudo mv ~/bin/nano /usr/bin/nano
nano myfile.txt
```

## Common Commands

- `Ctrl+X` - Exit (will prompt to save)
- `Ctrl+O` - Save file
- `Ctrl+K` - Cut line
- `Ctrl+U` - Paste line
- `Ctrl+W` - Search
- `Ctrl+\` - Replace
- `Ctrl+G` - Help

## Troubleshooting

### nano: command not found
```bash
# Option 1: Use full path
~/bin/nano myfile.txt

# Option 2: Add to PATH
export PATH="$HOME/bin:$PATH"

# Option 3: Install system-wide
sudo mv ~/bin/nano /usr/bin/nano
```

### Permission denied
```bash
chmod +x ~/bin/nano
```

### SSH connection issues
```bash
# Check reCamera is reachable
ping 192.168.42.1

# Try manual SSH
ssh recamera@192.168.42.1
```

## Need Help?

- Check the full [README-RECAMERA.md](README-RECAMERA.md) for detailed instructions
- Report issues on [GitHub Issues](https://github.com/Toastee0/nano/issues)
- For reCamera support, visit [SeeedStudio Forums](https://forum.seeedstudio.com/)

---
*This guide assumes default reCamera network settings (192.168.42.1). Adjust IP address as needed.*
