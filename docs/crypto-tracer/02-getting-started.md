# Quick Start

This guide will help you get crypto-tracer up and running in just a few minutes.

## Quick Start (5 Minutes)

### 1. Check if you have the binary

```bash
./build/crypto-tracer --version
```

You should see output like:
```
crypto-tracer version 1.0.0
Build date: Dec  8 2024 10:30:45
Kernel support: Linux 4.15+
License: GPL-3.0-or-later
Copyright (c) 2025 Graziano Labs Corp.
```

### 2. Take a system snapshot (no sudo needed!)

```bash
./build/crypto-tracer snapshot
```

This command scans your system for processes using cryptography and requires no special privileges.

### 3. Monitor crypto activity for 30 seconds

```bash
sudo ./build/crypto-tracer monitor --duration 30
```

This will show real-time cryptographic events as they occur on your system.

### 4. View output in a readable format

```bash
sudo ./build/crypto-tracer monitor --duration 10 --format json-pretty
```

The `json-pretty` format makes the output easier to read.

**That's it!** You're now monitoring cryptographic operations on your system.

## System Requirements

### Operating System

**Supported Linux Distributions:**

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- RHEL 8, 9
- Fedora 36+
- Amazon Linux 2023
- Alpine Linux 3.17+

**Kernel Requirements:**

- **Minimum:** Linux kernel 4.15 or later
- **Recommended:** Linux kernel 5.8+ (for CAP_BPF support)

Check your kernel version:
```bash
uname -r
```

### Kernel Features Required

Your kernel must have eBPF support enabled. Most modern distributions have this by default.

Required kernel configuration:

- `CONFIG_BPF=y` - BPF support
- `CONFIG_BPF_SYSCALL=y` - BPF system call
- `CONFIG_BPF_JIT=y` - BPF JIT compiler
- `CONFIG_TRACEPOINTS=y` - Tracepoint support

Optional but recommended:

- `CONFIG_DEBUG_INFO_BTF=y` - BTF support for CO-RE

Check if eBPF is available:
```bash
# Check for BTF support (recommended)
ls -la /sys/kernel/btf/vmlinux

# Check kernel config (if available)
grep CONFIG_BPF /boot/config-$(uname -r)
```

### Privileges

Most crypto-tracer commands require elevated privileges to load eBPF programs:

- **CAP_BPF** capability (kernel 5.8+) - Recommended
- **CAP_SYS_ADMIN** capability (older kernels) - Alternative
- **Root access** - Always works

**Exception:** The `snapshot` command works without any special privileges!

See the [Installation Guide](03-installation.md) for details on setting up privileges.

### Hardware Requirements

**Minimal:**

- 1 CPU core
- 512MB RAM
- 10MB disk space

**Recommended:**

- 2+ CPU cores
- 1GB+ RAM
- 50MB disk space

crypto-tracer is designed to be lightweight and runs efficiently even on modest hardware.

## First Steps

### Verify Installation

Check that crypto-tracer is working:

```bash
# Check version
./build/crypto-tracer --version

# View help
./build/crypto-tracer --help

# Test with snapshot (no sudo needed)
./build/crypto-tracer snapshot
```

### Test Monitoring (Requires Sudo)

Try monitoring for a few seconds:

```bash
sudo ./build/crypto-tracer monitor --duration 5
```

If you see events, crypto-tracer is working correctly!

### Generate Test Activity

If you don't see any events, generate some test activity:

```bash
# In one terminal, start monitoring
sudo ./build/crypto-tracer monitor --duration 30

# In another terminal, generate crypto activity
cat /etc/ssl/certs/ca-certificates.crt > /dev/null
openssl version
curl -I https://github.com 2>/dev/null | head -5
```

## Common First-Time Issues

### "Permission denied"

**Problem:** You see "Permission denied" or "Operation not permitted"

**Solution:** Run with sudo or grant capabilities (see [Installation](03-installation.md))

```bash
sudo ./build/crypto-tracer monitor
```

### "Kernel too old"

**Problem:** Error message about kernel version

**Solution:** Upgrade your kernel to 4.15 or later, or use a newer distribution

```bash
# Check current kernel
uname -r

# Upgrade kernel (Ubuntu/Debian)
sudo apt update && sudo apt upgrade linux-generic
```

### "No events captured"

**Problem:** Monitor runs but shows no events

**Solution:** Generate test activity (see above) or check if processes are actually using crypto

```bash
# Check if any processes have crypto libraries loaded
sudo lsof | grep -E "libssl|libcrypto" | head -5
```

## Next Steps

Now that you have crypto-tracer running:

1. **Learn the commands** - Read the [Commands Reference](05-commands-reference.md)
2. **Set up privileges** - See [Installation](03-installation.md) to run without sudo
3. **Try examples** - Check out [Common Use Cases](06-common-use-cases.md)
4. **Understand output** - Learn about [Output Formats](07-output-formats.md)

## Quick Reference

### Most Common Commands

```bash
# System snapshot (no sudo needed)
./crypto-tracer snapshot

# Monitor for 60 seconds
sudo ./crypto-tracer monitor --duration 60

# Profile a specific process
sudo ./crypto-tracer profile --pid 1234

# Monitor specific files
sudo ./crypto-tracer files --file "*.pem" --duration 30

# Track library loading
sudo ./crypto-tracer libs --duration 30
```

### Getting Help

```bash
# General help
./crypto-tracer --help

# Command-specific help
./crypto-tracer help monitor
./crypto-tracer monitor --help
```

---

**Previous:** [Introduction](index.md) | **Next:** [Installation](03-installation.md)
