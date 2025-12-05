# Performance Options

Control threading, determinism, and cross-architecture scanning.

---

## `-t, --threads N`

Number of worker threads for parallel scanner execution.

**Default**: CPU count (auto-detected) - Parallel execution is enabled by default

**Range**: 1 to 32 threads

**Default Behavior** (when flag not specified):

- Automatically detects CPU count using `sysconf(_SC_NPROCESSORS_ONLN)`
- Creates thread pool with detected CPU count
- Fallback: 4 threads if detection fails

**How it works**:

- Creates thread pool with N worker threads
- Runs all 5 scanners in parallel (certificate, key, package, service, filesystem)
- Utilizes available CPU cores efficiently
- Thread-safe operations on shared asset store (mutex-protected)

```bash
# Use 8 threads (parallel)
./build/cbom-generator --threads 8 --output cbom.json

# Single-threaded (sequential fallback)
./build/cbom-generator --threads 1 --output cbom.json

# Maximum parallelism (default: CPU count)
./build/cbom-generator --output cbom.json
```

**Performance** (measured on /etc/ssl with 294 certificates):

| Mode | Time | Speedup |
|------|------|---------|
| Sequential (--threads 1) | 0.36s | baseline |
| Parallel (--threads 4) | 0.22s | **1.64x faster** |

**Note**: Speedup varies by workload. Best results on systems with 4+ cores scanning large directories.

---

## `-d, --deterministic` (Default: ON)

Enable deterministic output (same input produces identical hash).

```bash
# Deterministic mode (default)
./build/cbom-generator --deterministic --output cbom.json

# Disable determinism (includes timestamps)
./build/cbom-generator --no-deterministic --output cbom.json
```

**Use deterministic mode when**:

- Comparing CBOMs across time
- CI/CD pipelines
- Change detection
- Reproducible builds

---

## `--cross-arch` (v1.7+)

Enable cross-architecture scanning mode for embedded/Yocto systems.

This is the **canonical way** to scan cross-compiled rootfs images (e.g., ARM64 Yocto builds from an x86_64 development host).

**What it does**:

1. **Disables Host Package Manager**: Skips dpkg/rpm queries that would return incorrect host packages
2. **Uses VERNEED/SONAME Version Detection**: Extracts versions directly from ELF binaries
3. **Enables Embedded Service Detection**: Works with `--plugin-dir plugins/embedded`

**Version Resolution (without manifest)**:

| Tier | Source | Confidence | Example |
|------|--------|------------|---------|
| Tier 3 | ELF VERNEED | 0.80 | `OPENSSL_3.0.0` → `3.0.0` |
| Tier 4 | SONAME parsing | 0.60 | `libssl.so.3` → `3` |

**Canonical Usage (Yocto Development System)**:

```bash
# Define the rootfs path in your Yocto build directory
ROOTFS=/mnt/yocto-builds/yocto-cbom/poky/build-qemu/tmp/work/qemuarm64-poky-linux/core-image-minimal/1.0/rootfs

# Scan cross-compiled ARM64 rootfs from x86_64 host
./build/cbom-generator \
    --cross-arch \
    --discover-services \
    --plugin-dir plugins/embedded \
    --crypto-registry crypto-registry-yocto.yaml \
    --format cyclonedx --cyclonedx-spec=1.7 \
    -o yocto-cbom.json \
    $ROOTFS/usr/bin $ROOTFS/usr/sbin $ROOTFS/usr/lib $ROOTFS/etc
```

**Why scan binaries directly (not manifests)?**

Scanning the actual ELF binaries provides ground truth about what cryptographic libraries are actually linked:

- Runtime library substitutions
- Statically linked crypto
- Embedded crypto implementations
- Actual SONAME versions deployed

**What gets detected**:

- Crypto libraries via SONAME (libssl.so.3, libgnutls.so.30, libcrypto.so.3)
- Embedded services (dropbear, wpa_supplicant, strongSwan, lighttpd)
- Application-to-library dependencies
- Certificates and keys in the rootfs

**Important Notes**:

1. **Never use `--cross-arch` with host paths** like `/usr/bin` - that's contradictory
2. **Use Yocto build directory paths** - development systems have rootfs under `tmp/work/.../rootfs/`
3. **Include multiple directories** for comprehensive coverage
4. **Use embedded plugins** (`plugins/embedded/`) for IoT/embedded services
5. **Use Yocto crypto registry** (`crypto-registry-yocto.yaml`) for embedded library patterns

**See Also**:

- [Cross-Architecture Scanning Guide](../../docs/CROSS_ARCH_SCANNING.md)
- [Yocto Testing Guide](../../docs/YOCTO_TESTING_GUIDE.md)
