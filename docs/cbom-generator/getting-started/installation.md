---
hide:
  - toc
---
# Installation

## Prerequisites

### Ubuntu/Debian

```bash
sudo apt-get install build-essential cmake libssl-dev libjson-c-dev \
    libcurl4-openssl-dev libncurses-dev libyaml-dev libjansson-dev
```

### RHEL/CentOS

```bash
sudo yum install gcc cmake openssl-devel json-c-devel libcurl-devel \
    ncurses-devel libyaml-devel jansson-devel
```

### Required Dependencies

| Dependency | Minimum Version | Notes |
|------------|-----------------|-------|
| OpenSSL | 3.0+ | 3.5+ recommended for PQC support |
| json-c | 0.15+ | JSON output generation |
| libcurl | latest | Network operations |
| ncurses | 6.0+ | TUI display |
| libyaml | 0.2.2+ | YAML plugin support |
| jansson | 2.13+ | JSON parsing |
| CMake | 3.16+ | Build system |
| GCC | C11 support | Compiler |

---

## Build from Source

```bash
# Clone repository
git clone https://github.com/CipherIQ/cbom-generator.git
cd cbom-generator

# Configure for release build
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Install (optional)
sudo cmake --install build
```

### Build Options

| Option | Default | Description |
|--------|---------|-------------|
| `CMAKE_BUILD_TYPE` | Release | Release or Debug |
| `ENABLE_TESTS` | ON | Build test suite |
| `ENABLE_STATIC_ANALYSIS` | OFF | Enable Clang analyzer |

### Debug Build

For development or troubleshooting:

```bash
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug
```

---

## Verify Installation

```bash
# Check version
./build/cbom-generator --version
# Output: CBOM Generator 1.9.0

# Run help
./build/cbom-generator --help

# Run test suite (optional)
cd build && ctest
```

---

## Troubleshooting Installation

### Missing OpenSSL Headers

```
fatal error: openssl/ssl.h: No such file or directory
```

**Solution**: Install OpenSSL development package:
```bash
sudo apt-get install libssl-dev  # Debian/Ubuntu
sudo yum install openssl-devel   # RHEL/CentOS
```

### CMake Version Too Old

```
CMake 3.16 or higher is required
```

**Solution**: Install newer CMake:
```bash
pip install cmake --upgrade
# Or download from https://cmake.org/download/
```

### Missing libyaml

```
Could not find libyaml
```

**Solution**: Install libyaml development package:
```bash
sudo apt-get install libyaml-dev  # Debian/Ubuntu
sudo yum install libyaml-devel    # RHEL/CentOS
```

---

## Next Steps

- [Quick Start](quick-start.md) - Run your first scan
