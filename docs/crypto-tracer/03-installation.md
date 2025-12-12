# Installation Guide

This guide covers installing crypto-tracer on your system, including setting up the necessary privileges.

## Installation Options

You can install crypto-tracer in two ways:

1. **Using a pre-built binary** (recommended for most users)
2. **Building from source** (for developers or custom builds)

## Option 1: Using Pre-built Binary (Recommended)

The easiest way to get started is with a pre-built static binary that works across different Linux distributions.

### Download and Install

```bash
# Download the package
wget https://github.com/cipheriq/crypto-tracer/releases/download/v1.0.0/crypto-tracer-1.0.0.tar.gz

# Extract
tar -xzf crypto-tracer-1.0.0.tar.gz
cd crypto-tracer-1.0.0

# Test it
./crypto-tracer --version

# Optional: Install system-wide
sudo cp crypto-tracer /usr/local/bin/
sudo cp crypto-tracer.1 /usr/local/share/man/man1/
sudo mandb  # Update man page database
```

The static binary has no external dependencies and works on any Linux distribution with kernel 4.15+.

### Verify Installation

```bash
# Check version
crypto-tracer --version

# Test with snapshot (no sudo needed)
crypto-tracer snapshot

# Test monitoring (requires sudo)
sudo crypto-tracer monitor --duration 5
```

## Option 2: Building from Source

Building from source gives you the latest features and allows customization.

### Install Build Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install gcc clang libbpf-dev libelf-dev zlib1g-dev
sudo apt install linux-tools-common linux-tools-generic  # for bpftool
```

**RHEL/Fedora:**
```bash
sudo dnf install gcc clang libbpf-devel elfutils-libelf-devel zlib-devel
sudo dnf install bpftool
```

**Alpine Linux:**
```bash
apk add gcc clang libbpf-dev elfutils-dev zlib-dev linux-headers bpftool
```

### Build crypto-tracer

```bash
# Clone the repository
git clone https://github.com/cipheriq/crypto-tracer.git
cd crypto-tracer

# Check dependencies
make check-deps

# Build
make

# Test
./build/crypto-tracer --version

# Optional: Install system-wide
sudo make install
```

### Build Options

```bash
# Build with debug symbols (for development)
make debug

# Build static binary (portable, no dependencies)
make static

# Create distribution package
make package-static

# Clean build artifacts
make clean
```

The static build is recommended for distribution as it works across different Linux versions without requiring specific library versions.

## Setting Up Privileges

crypto-tracer needs special privileges to load eBPF programs. You have three options:

### Option 1: Run with sudo (Simplest)

The simplest approach is to run crypto-tracer with sudo:

```bash
sudo crypto-tracer monitor
```

**Pros:**
- Works on all systems
- No setup required
- Always available

**Cons:**
- Need to enter password each time
- Runs with full root privileges
- Less convenient for frequent use

### Option 2: Grant CAP_BPF Capability (Recommended for Kernel 5.8+)

For modern kernels (5.8+), you can grant specific capabilities to the binary:

```bash
# One-time setup - grant capabilities to the binary
sudo setcap cap_bpf,cap_perfmon+ep /usr/local/bin/crypto-tracer

# Now you can run without sudo
crypto-tracer monitor
```

**Pros:**
- Most secure option (minimal privileges)
- No password needed after setup
- Works for all users
- Recommended approach

**Cons:**
- Only works on kernel 5.8+
- Must re-grant after rebuilding binary
- Requires initial sudo access

**Capabilities explained:**
- `cap_bpf` - Allows loading eBPF programs
- `cap_perfmon` - Allows reading performance events

### Option 3: Grant CAP_SYS_ADMIN Capability (For Older Kernels)

For kernels older than 5.8 that don't support CAP_BPF:

```bash
# For kernels < 5.8 that don't support CAP_BPF
sudo setcap cap_sys_admin+ep /usr/local/bin/crypto-tracer

# Now you can run without sudo
crypto-tracer monitor
```

**Pros:**
- Works on older kernels (4.15+)
- No password needed after setup

**Cons:**
- Grants more privileges than necessary
- Less secure than CAP_BPF
- Must re-grant after rebuilding

### Managing Capabilities

**Check current capabilities:**
```bash
getcap /usr/local/bin/crypto-tracer
```

Expected output for kernel 5.8+:
```
/usr/local/bin/crypto-tracer = cap_bpf,cap_perfmon+ep
```

Expected output for older kernels:
```
/usr/local/bin/crypto-tracer = cap_sys_admin+ep
```

**Remove capabilities:**
```bash
sudo setcap -r /usr/local/bin/crypto-tracer
```

**Check your kernel version:**
```bash
uname -r
```

### Important Notes About Capabilities

1. **Capabilities are tied to the binary file** - If you rebuild or update crypto-tracer, you must re-grant capabilities

2. **Automate capability granting** - Create a script for convenience:
   ```bash
   #!/bin/bash
   # build-and-cap.sh
   make && sudo setcap cap_bpf,cap_perfmon+ep ./build/crypto-tracer
   ```

3. **The snapshot command doesn't need privileges** - It only reads /proc and works without any special capabilities

4. **Check which capabilities you need:**
   ```bash
   # For kernel 5.8+
   if [ $(uname -r | cut -d. -f1) -ge 5 ] && [ $(uname -r | cut -d. -f2) -ge 8 ]; then
       echo "Use: cap_bpf,cap_perfmon"
   else
       echo "Use: cap_sys_admin"
   fi
   ```

## Verifying Installation

After installation, verify everything works:

### 1. Check Version
```bash
crypto-tracer --version
```

### 2. Test Snapshot (No Privileges Needed)
```bash
crypto-tracer snapshot
```

This should work without sudo and show processes using crypto.

### 3. Test Monitoring (Requires Privileges)
```bash
# With sudo
sudo crypto-tracer monitor --duration 5

# Or with capabilities granted
crypto-tracer monitor --duration 5
```

### 4. Generate Test Activity
```bash
# In one terminal
sudo crypto-tracer monitor --duration 30

# In another terminal
cat /etc/ssl/certs/ca-certificates.crt > /dev/null
openssl version
```

You should see events in the monitoring terminal.

## Uninstallation

### Remove System-Wide Installation

```bash
# Remove binary
sudo rm /usr/local/bin/crypto-tracer

# Remove man page
sudo rm /usr/local/share/man/man1/crypto-tracer.1
sudo mandb

# Remove documentation (if installed)
sudo rm -rf /usr/local/share/doc/crypto-tracer
```

### Remove Build Directory

```bash
cd crypto-tracer
make clean
cd ..
rm -rf crypto-tracer
```

## Troubleshooting Installation

### "bpftool not found"

**Problem:** Build fails with "bpftool: command not found"

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install linux-tools-common linux-tools-generic

# RHEL/Fedora
sudo dnf install bpftool

# Or install for your specific kernel
sudo apt install linux-tools-$(uname -r)
```

### "libbpf not found"

**Problem:** Build fails with libbpf errors

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install libbpf-dev

# RHEL/Fedora
sudo dnf install libbpf-devel
```

### "vmlinux.h generation failed"

**Problem:** Warning about BTF not available

**Impact:** This is usually not a problem. The build system automatically uses fallback headers.

**To enable BTF (optional):**
- Ensure kernel is compiled with `CONFIG_DEBUG_INFO_BTF=y`
- Check: `ls -la /sys/kernel/btf/vmlinux`
- Most modern distributions (Ubuntu 20.04+, RHEL 8+) have BTF enabled

### Static Linking Fails

**Problem:** Static build fails with linking errors

**Solution:**
```bash
# Ensure static libraries are installed
sudo apt install libbpf-dev:amd64 libelf-dev:amd64 zlib1g-dev:amd64

# Or use dynamic linking
make clean
make
```

## Post-Installation

### Set Up Shell Completion (Optional)

For bash completion:
```bash
# Generate completion script (future feature)
crypto-tracer completion bash > /tmp/crypto-tracer-completion.bash
sudo cp /tmp/crypto-tracer-completion.bash /etc/bash_completion.d/
```

### Create Aliases (Optional)

Add to your `~/.bashrc` or `~/.zshrc`:
```bash
alias ct='crypto-tracer'
alias ctm='sudo crypto-tracer monitor'
alias ctp='sudo crypto-tracer profile'
alias cts='crypto-tracer snapshot'
```

### Verify Kernel Compatibility

```bash
# Check kernel version
uname -r

# Check eBPF support
grep CONFIG_BPF /boot/config-$(uname -r)

# Check BTF support
ls -la /sys/kernel/btf/vmlinux
```

## Next Steps

Now that crypto-tracer is installed:

1. **Learn basic concepts** - Read [Basic Concepts](04-basic-concepts.md)
2. **Explore commands** - See [Commands Reference](05-commands-reference.md)
3. **Try examples** - Check [Common Use Cases](06-common-use-cases.md)

---

**Previous:** [Getting Started](02-getting-started.md) | **Next:** [Basic Concepts](04-basic-concepts.md)
