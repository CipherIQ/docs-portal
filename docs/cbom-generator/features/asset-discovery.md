---
hide:
  - toc
---
# Asset Discovery

The CBOM Generator includes 8 scanner types that discover cryptographic assets across your system. Each scanner uses a different strategy to find specific types of assets.

Understanding these strategies helps you target your scans effectively and interpret results correctly.


## Scanner Overview

| Scanner | Strategy | What It Finds |
|---------|----------|---------------|
| Certificate | Every file | X.509, OpenPGP certificates |
| Key | Every file | RSA, ECDSA, Ed25519, DSA, DH keys |
| Package | System-wide | Crypto libraries via package managers |
| Service | System-wide | Network services using crypto |
| Filesystem | Filtered | Crypto-related files by extension |
| Application | Binary analysis | Applications with crypto dependencies |
| Library | Integrated | Crypto libraries linked to apps |
| Algorithm | Derived | Algorithms from all sources |

---

## How Directories Affect Discovery

When you run the CBOM Generator, you specify one or more directories to scan:

```bash
./cbom-generator /usr/sbin /etc/ssl
```

However, not all scanners use these directories in the same way.

### Scanners That Use Your Directories

These scanners search only the directories you specify:

| Scanner | What Happens |
|---------|-------------|
| **Certificate** | Searches your directories for certificate files |
| **Key** | Searches your directories for key files |
| **Filesystem** | Catalogs crypto-related files in your directories |
| **Application** | Analyzes executables in your directories |

If you scan `/opt/myapp`, these scanners will only look inside `/opt/myapp`.

### Scanners That Ignore Your Directories

These scanners query system-wide resources regardless of what directories you specify:

| Scanner | What Happens |
|---------|-------------|
| **Package** | Queries your package manager (apt, rpm, pacman) for installed crypto packages |
| **Service** | Detects running services and their crypto configurations |

Even if you only scan `/home/user/myapp`, these scanners will still report all crypto packages installed on your system and all running crypto services.

### Scanners That Derive Information

These scanners don't search directories directly. They analyze assets found by other scanners:

| Scanner | What Happens |
|---------|-------------|
| **Library** | Identifies crypto libraries used by applications and services |
| **Algorithm** | Extracts algorithms from certificates, keys, and configurations |

---

## Controlling Scanner Behavior

### Enable Service Discovery Plugins

The `--discover-services` flag activates plugin-based service detection, which provides deeper analysis of service configurations:

```bash
./cbom-generator --discover-services /usr/sbin /etc
```

This enables detection of 69+ services with detailed protocol and cipher suite extraction.

### Specify Plugin Directory

Use `--plugin-dir` to load service plugins from a custom location:

```bash
./cbom-generator --discover-services --plugin-dir plugins/embedded /usr/sbin
```

The `plugins/embedded/` directory contains plugins for IoT and embedded systems.

### Use a Custom Crypto Registry

The `--crypto-registry` flag loads custom library definitions:

```bash
./cbom-generator --crypto-registry registry/crypto-registry-alpine.yaml /usr/bin
```

This helps identify crypto libraries in non-standard environments like Alpine Linux containers.

### Skip Package Manager Queries

Use `--cross-arch` when scanning foreign filesystems (containers, mounted images):

```bash
./cbom-generator --cross-arch /mnt/container-rootfs
```

Or use `--no-package-resolution` for faster scans:

```bash
./cbom-generator --no-package-resolution /etc/ssl
```

---

## Practical Examples

### Scan a Specific Application

```bash
./cbom-generator /opt/myapp
```

Finds certificates, keys, and crypto dependencies within `/opt/myapp`. System packages and services are also reported.

### Full System Inventory

```bash
./cbom-generator --discover-services /usr /etc /home
```

Comprehensive scan combining file discovery with detailed service analysis.

### Container Image

```bash
docker export mycontainer | tar -xf - -C /tmp/container-fs

./cbom-generator \
    --cross-arch \
    --crypto-registry registry/crypto-registry-alpine.yaml \
    /tmp/container-fs

rm -rf /tmp/container-fs
```

### Embedded System (Yocto/OpenWrt)

```bash
./cbom-generator \
    --cross-arch \
    --discover-services \
    --plugin-dir plugins/embedded \
    /mnt/rootfs/usr /mnt/rootfs/etc
```

---

## What Each Scanner Contributes

| Scanner | Primary Output | Additional Output |
|---------|---------------|-------------------|
| Certificate | Certificates | Signature algorithms |
| Key | Keys | Key algorithms |
| Filesystem | File inventory | File classifications |
| Application | Applications | Library relationships |
| Package | Installed packages | Version information |
| Service | Services | Protocols |
| Library | Libraries | Algorithm capabilities |
| Algorithm | — | Collected from all sources |




## Certificate Scanner

**Discovers**: X.509 and OpenPGP certificates

**Formats**: PEM, DER, PKCS#12

**Information Extracted**:

- Subject and issuer DNs (RFC2253 normalized)
- Validity periods (notValidBefore, notValidAfter)
- Signature algorithms with OIDs
- Public key algorithms and sizes
- Trust validation status (15 failure reasons tracked)
- Certificate state (active, expired, revoked)
- Extensions (KeyUsage, ExtendedKeyUsage, SubjectAltName)

**Deduplication Behavior**:

Certificate bundles (e.g., `ca-certificates.crt`) are processed first. Individual .pem files are often symlinks to certificates already in bundles, so they're skipped as duplicates. This is expected behavior.

---

## Key Scanner

**Discovers**: Private and public keys

**Formats**: PEM, DER, OpenSSH, PKCS#8, PKCS#1, SEC1

**Key Types**: RSA, ECDSA, Ed25519, Ed448, DSA, DH

**Security Features**:

- **CRITICAL**: Only stores SHA-256 hashes, NEVER raw key material
- Detects storage security (plaintext, encrypted, HSM, TPM)
- Tracks key lifecycle states (NIST SP 800-57)
- Identifies weak keys (RSA <2048, ECDSA <256)

---

## Package Scanner

**Discovers**: Cryptographic libraries via package managers

**Package Managers**: APT, RPM, Pacman, pip, npm, RubyGems

**How it works**:

- Queries package manager databases (no file scanning)
- System-wide scope
- Detects OpenSSL, GnuTLS, libgcrypt, nettle, and 20+ more

---

## Service Scanner

**Discovers**: Network services using cryptography

**Services**: Apache, Nginx, OpenSSH, Postfix (built-in) + 65+ via YAML plugins

**Analysis**:

- Config file parsing (httpd.conf, nginx.conf, sshd_config)
- TLS/SSH protocol detection
- Cipher suite extraction
- Security profile classification (MODERN, INTERMEDIATE, OLD)
- Network endpoint mapping

---

## Application Scanner

**Discovers**: Applications with cryptographic dependencies

**Directories Scanned**: `/usr/bin`, `/usr/sbin`, custom paths

**Discovery Process**:

1. **ELF Validation**: Checks executable permission and ELF magic bytes
2. **Library Extraction**: Uses `readelf -d` (cross-arch compatible)
3. **Crypto Detection**: Matches libraries against crypto registry
4. **Alternate Detection**: Kernel crypto API, static linking, symbol analysis

**Role Classification**:

| Role | Criteria | Examples |
|------|----------|----------|
| Service | Located in `/sbin/`, ends with 'd', contains "server" | sshd, nginx, dockerd |
| Client | Contains "client" | ssh, curl, wget |
| Utility | Default | openssl, gpg |

---

## Library Scanner

**Discovers**: Crypto libraries linked to applications

**Built-in Registry**:

| Library | SONAME Patterns | Algorithms |
|---------|-----------------|------------|
| OpenSSL | libssl.so, libcrypto.so | RSA, ECDSA, AES, ChaCha20 |
| libgcrypt | libgcrypt.so | RSA, DSA, AES, Twofish |
| libsodium | libsodium.so | X25519, Ed25519, ChaCha20 |
| nettle | libnettle.so, libhogweed.so | RSA, ECDSA, AES |
| Kerberos | libkrb5.so, libgssapi_krb5.so | AES, 3DES, RC4 |
| liboqs | liboqs.so | ML-KEM, ML-DSA, Falcon, SPHINCS+ |

---

## Algorithm Detection

Algorithms are **derived components** extracted from other assets:

**From Certificates**:
- Public Key Algorithm: RSA, ECDSA, Ed25519
- Signature Algorithm: sha256WithRSAEncryption, ecdsa-with-SHA256

**From Keys**:
- Key type and size: RSA-2048, ECDSA-P256

**From Cipher Suites**:
- Key Exchange: ECDHE, DHE
- Authentication: RSA, ECDSA
- Encryption: AES-256-GCM
- MAC: SHA384

**From Libraries**:
- Algorithm capabilities from crypto registry

## Common Questions

**Why do I see system packages when I only scanned a specific directory?**

The Package Scanner always queries your system's package manager. It reports all installed crypto packages regardless of which directories you specify.

**How do I scan only files without system-wide information?**

Use `--no-package-resolution` to skip package manager queries. Note that service detection still runs.

**What's the difference between basic and plugin-based service detection?**

Without `--discover-services`, only common services (Apache, nginx, OpenSSH) are detected with basic information. With the flag enabled, 69+ services can be detected with detailed cipher suite extraction.

**Why does the same library appear multiple times?**

Libraries may be found both through package manager queries and through binary analysis. The system merges duplicates when possible.

---

## See Also

- [Container Scanning](../advanced/container-scanning.md) - Scanning Docker and Podman containers
- [Cross-Architecture Scanning](../advanced/cross-architecture.md) - Scanning Yocto and embedded systems



---
