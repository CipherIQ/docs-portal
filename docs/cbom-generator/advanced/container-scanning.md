---
hide:
  - toc
---
# Container Scanning Workflow

## Overview

The CBOM Generator can scan container filesystems to inventory cryptographic assets. This is accomplished by exporting a container's filesystem and scanning it using cross-architecture mode.

**Key Concept:** Container scanning analyzes the *contents* of a container image or exported container. This is different from detecting services running inside containers on your host system.



## Prerequisites

- Docker or Podman installed
- CBOM Generator built (`./build/cbom-generator`)
- Sufficient disk space for extracted filesystem (typically 50MB - 2GB depending on image)

---

## Quick Start

### Scanning a Running Container

```bash
# 1. Export the container filesystem
docker export my-container | tar -xf - -C /tmp/container-fs

# 2. Scan with cross-arch mode
./build/cbom-generator \
    --cross-arch \
    --crypto-registry registry/crypto-registry-alpine.yaml \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output container-cbom.json \
    /tmp/container-fs

# 3. Clean up
rm -rf /tmp/container-fs
```

### Scanning a Container Image

For images (not running containers), create a temporary container first:

```bash
# 1. Create temporary container from image
docker create --name cbom-scan-temp nginx:alpine

# 2. Export the filesystem
mkdir -p /tmp/container-fs
docker export cbom-scan-temp | tar -xf - -C /tmp/container-fs

# 3. Remove temporary container
docker rm cbom-scan-temp

# 4. Scan
./build/cbom-generator \
    --cross-arch \
    --crypto-registry registry/crypto-registry-alpine.yaml \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output nginx-alpine-cbom.json \
    /tmp/container-fs

# 5. Clean up
rm -rf /tmp/container-fs
```

---

## Podman Support

The workflow is identical for Podman:

```bash
# Export running container
podman export my-container | tar -xf - -C /tmp/container-fs

# Or from image
podman create --name cbom-scan-temp docker.io/library/nginx:alpine
podman export cbom-scan-temp | tar -xf - -C /tmp/container-fs
podman rm cbom-scan-temp

# Scan
./build/cbom-generator \
    --cross-arch \
    --crypto-registry registry/crypto-registry-alpine.yaml \
    --output container-cbom.json \
    /tmp/container-fs
```

---

## Alpine Linux Containers

Most lightweight containers are based on Alpine Linux. The `crypto-registry-alpine.yaml` registry includes patterns for:

**Crypto Libraries:**
- OpenSSL (libcrypto.so.3, libssl.so.3)
- LibreSSL (libtls.so)
- libsodium
- GnuTLS
- mbedTLS
- NSS

**Common Services:**
- OpenSSH
- nginx
- haproxy
- stunnel
- WireGuard
- BusyBox (with SSL applets)

### Example: Scan an Alpine-based nginx Container

```bash
# Pull and create container
docker pull nginx:alpine
docker create --name nginx-scan nginx:alpine

# Export and scan
mkdir -p /tmp/nginx-fs
docker export nginx-scan | tar -xf - -C /tmp/nginx-fs
docker rm nginx-scan

./build/cbom-generator \
    --cross-arch \
    --crypto-registry registry/crypto-registry-alpine.yaml \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output nginx-cbom.json \
    /tmp/nginx-fs/usr/sbin \
    /tmp/nginx-fs/usr/lib \
    /tmp/nginx-fs/etc/nginx

rm -rf /tmp/nginx-fs
```

---

## Scanning Specific Directories

For faster scans, target specific directories within the container:

```bash
# Scan only binaries and libraries (skip docs, locales, etc.)
./build/cbom-generator \
    --cross-arch \
    --crypto-registry registry/crypto-registry-alpine.yaml \
    --output container-cbom.json \
    /tmp/container-fs/usr/bin \
    /tmp/container-fs/usr/sbin \
    /tmp/container-fs/usr/lib \
    /tmp/container-fs/etc
```

**Common paths to scan:**

| Path | Contents |
|------|----------|
| `/usr/bin`, `/usr/sbin` | Application binaries |
| `/usr/lib` | Shared libraries |
| `/etc` | Configuration files, certificates |
| `/usr/local/bin` | Custom binaries |
| `/app` or `/opt` | Application code (varies) |

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Container CBOM Scan

on:
  push:
    branches: [main]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build container
        run: docker build -t myapp:latest .

      - name: Export container filesystem
        run: |
          docker create --name scan-target myapp:latest
          mkdir -p /tmp/container-fs
          docker export scan-target | tar -xf - -C /tmp/container-fs
          docker rm scan-target

      - name: Run CBOM scan
        run: |
          ./build/cbom-generator \
            --cross-arch \
            --crypto-registry registry/crypto-registry-alpine.yaml \
            --format cyclonedx --cyclonedx-spec 1.7 \
            --output container-cbom.json \
            /tmp/container-fs

      - name: Upload CBOM
        uses: actions/upload-artifact@v4
        with:
          name: container-cbom
          path: container-cbom.json

      - name: Cleanup
        run: rm -rf /tmp/container-fs
```

### GitLab CI Example

```yaml
container-cbom:
  stage: security
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t myapp:scan .
    - docker create --name scan-target myapp:scan
    - mkdir -p /tmp/container-fs
    - docker export scan-target | tar -xf - -C /tmp/container-fs
    - docker rm scan-target
    - ./build/cbom-generator
        --cross-arch
        --crypto-registry registry/crypto-registry-alpine.yaml
        --format cyclonedx --cyclonedx-spec 1.7
        --output container-cbom.json
        /tmp/container-fs
    - rm -rf /tmp/container-fs
  artifacts:
    paths:
      - container-cbom.json
```

---

## One-Liner Script

For convenience, here's a reusable script:

```bash
#!/bin/bash
# scan-container.sh - Scan a container image for cryptographic assets

set -e

IMAGE="${1:?Usage: $0 <image:tag>}"
OUTPUT="${2:-cbom-$(echo $IMAGE | tr '/:' '-').json}"
WORKDIR=$(mktemp -d)

echo "Scanning image: $IMAGE"
echo "Output: $OUTPUT"

# Create and export
docker create --name cbom-scan-$$ "$IMAGE"
docker export cbom-scan-$$ | tar -xf - -C "$WORKDIR"
docker rm cbom-scan-$$

# Scan
./build/cbom-generator \
    --cross-arch \
    --crypto-registry registry/crypto-registry-alpine.yaml \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output "$OUTPUT" \
    "$WORKDIR"

# Cleanup
rm -rf "$WORKDIR"

echo "CBOM written to: $OUTPUT"
```

Usage:
```bash
chmod +x scan-container.sh
./scan-container.sh nginx:alpine
./scan-container.sh redis:7-alpine redis-cbom.json
```

---

## Security Considerations

1. **Temporary Files**: Always clean up extracted filesystems after scanning
2. **Permissions**: Use restrictive permissions on temp directories (`chmod 700`)
3. **Secrets**: Container exports may contain secrets - handle with care
4. **Disk Space**: Large images can consume significant space when extracted

### Secure Workflow

```bash
# Create secure temp directory
WORKDIR=$(mktemp -d)
chmod 700 "$WORKDIR"

# ... export and scan ...

# Secure cleanup
rm -rf "$WORKDIR"
```

---

## Troubleshooting

### No Components Found

**Problem**: Scan returns empty or minimal results.

**Solutions**:
1. Verify the container has cryptographic libraries installed
2. Check you're scanning the right paths (binaries in `/usr/bin`, libs in `/usr/lib`)
3. Ensure the crypto registry matches the container's base image

```bash
# Verify crypto libraries exist
ls -la /tmp/container-fs/usr/lib/libcrypto* /tmp/container-fs/usr/lib/libssl*
```

### Wrong Library Versions

**Problem**: Version detection shows incorrect versions.

**Solution**: In cross-arch mode, version detection uses ELF VERNEED symbols. This is expected behavior when the host package manager cannot be used.

### Large Output File

**Problem**: CBOM file is very large.

**Solution**: Scan only relevant directories instead of the entire filesystem:
```bash
./build/cbom-generator --cross-arch \
    /tmp/container-fs/usr/lib \
    /tmp/container-fs/usr/bin \
    /tmp/container-fs/etc/ssl
```

---

## Limitations

- **Running Container Introspection**: This workflow scans exported filesystems. It cannot introspect libraries of services running inside containers from the host. For running services, the container process is visible but its internal library dependencies are not accessible due to filesystem namespace isolation.

- **Multi-Stage Builds**: Only the final image layer is scanned. Intermediate build stages are not included in the exported filesystem.

- **Scratch Images**: Containers based on `scratch` or distroless images may have minimal or no standard library paths.
