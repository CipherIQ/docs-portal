# Installation

## System Requirements

- Linux (kernel 3.0+ for AF_PACKET)
- CMake >= 3.16
- C11 compiler (GCC or Clang)
- pkg-config

## Dependencies

| Dependency | Purpose | Minimum Version |
|------------|---------|-----------------|
| libpcap    | Packet capture | Any recent |
| nDPI       | Deep packet inspection | 4.11+ |

### Ubuntu/Debian

```bash
sudo apt-get install cmake libpcap-dev build-essential pkg-config
```

### RHEL/CentOS/Fedora

```bash
sudo dnf install cmake libpcap-devel gcc make pkg-config
```

### nDPI from Source

If nDPI is not available in your distribution's repositories:

```bash
git clone https://github.com/ntop/nDPI.git
cd nDPI
./autogen.sh && ./configure && make && sudo make install
sudo ldconfig
```

Verify installation:

```bash
pkg-config --modversion libndpi
# Expected: 4.11.0 or higher
```

## Building from Source

### Clone and Build

```bash
git clone <repository-url>
cd pqc-flow
mkdir build && cd build
cmake .. -DENABLE_TESTS=ON
make -j$(nproc)
```

### Build Options

| Option | Default | Description |
|--------|---------|-------------|
| `-DENABLE_TESTS=ON` | OFF | Build unit tests |
| `-DCMAKE_BUILD_TYPE=Release` | - | Optimized build |
| `-DCMAKE_BUILD_TYPE=Debug` | - | Debug symbols |

## Verification

### Run Unit Tests

```bash
./pqc-tests
```

Expected output:

```
All PQC detection tests passed.
```

### Test Mock Output

```bash
./pqc-flow --mock
```

Should output JSON with PQC fields:

```json
{"proto":6,"sip":"192.0.2.1","dip":"192.0.2.2","sp":12345,"dp":443,"pqc_flags":5,...}
```

## System Installation (Optional)

Install to `/usr/local/bin`:

```bash
sudo make install
```

### Capability Setup

For non-root live capture, grant network capabilities:

```bash
sudo setcap cap_net_raw,cap_net_admin+ep /usr/local/bin/pqc-flow
```

Verify:

```bash
getcap /usr/local/bin/pqc-flow
# Expected: /usr/local/bin/pqc-flow cap_net_admin,cap_net_raw=ep
```

## Troubleshooting Installation

### nDPI Not Found

If CMake cannot find nDPI:

```bash
# Check if pkg-config can find it
pkg-config --libs libndpi

# If nDPI was installed from source, set PKG_CONFIG_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
```

### libpcap Not Found

```bash
# Verify libpcap installation
pkg-config --libs libpcap

# Install development package
sudo apt-get install libpcap-dev  # Debian/Ubuntu
sudo dnf install libpcap-devel    # RHEL/Fedora
```

## Next Steps

- [Quick Start](quick-start.md) - Run your first analysis
