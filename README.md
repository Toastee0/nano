# Nano Text Editor for reCamera Devices

A cross-compiled version of GNU nano 6.4 text editor specifically built for [reCamera](https://wiki.seeedstudio.com/recamera_intro/) devices running RISC-V architecture.

## 📋 About reCamera

**reCamera** is an AI-powered camera device developed by Seeed Studio. For comprehensive information, documentation, and setup guides, visit the **[Seeed Studio reCamera Getting Started Guide](https://wiki.seeedstudio.com/recamera_getting_started/)**.

## 🚀 Quick Install

### Option 1: Download Pre-built Binary
```bash
# Download from releases
wget https://github.com/Toastee0/nano/releases/download/v6.4/nano-recamera-v6.4.tar.gz
tar -xzf nano-recamera-v6.4.tar.gz

# Copy to your reCamera device (user installation)
scp nano-recamera-v6.4 recamera@192.168.42.1:~/bin/nano

# OR for system-wide installation (accessible to all users)
scp nano-recamera-v6.4 recamera@192.168.42.1:~/nano
ssh recamera@192.168.42.1 "sudo mv ~/nano /usr/bin/nano"
```

### Option 2: Build from Source
```bash
git clone https://github.com/Toastee0/nano.git
cd nano
./build-recamera.sh
```

## ✨ Features

- ✅ **RISC-V Architecture**: Native support for reCamera's processor
- ✅ **Statically Linked**: No dependencies required on target device  
- ✅ **Compact Size**: Only 571KB stripped binary
- ✅ **Full Features**: UTF-8, syntax highlighting, undo/redo
- ✅ **Ready to Use**: Pre-compiled binaries available

## 📖 Documentation

- **Build Instructions**: See [README-RECAMERA.md](README-RECAMERA.md)
- **Quick Start**: See [QUICKSTART.md](QUICKSTART.md)
- **reCamera Getting Started**: https://wiki.seeedstudio.com/recamera_getting_started/

## 📜 License

GNU nano is licensed under the GNU General Public License v3.0. This cross-compiled version maintains the same license and includes full source code for GPL compliance.

## 🤝 Contributing

Contributions welcome! This project helps the reCamera community by providing essential development tools.

---

**Original GNU nano project**: https://www.nano-editor.org/
