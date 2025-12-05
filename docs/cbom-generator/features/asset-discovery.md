# Asset Discovery

The CBOM Generator includes 8 scanner types that discover cryptographic assets across your system.

---

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

## File Counts vs Component Counts

The TUI displays both **file counts** (files examined) and **component counts** (assets discovered). These differ significantly:

**Example** (scanning /home with 4.23M files):
```
Certificate Scanner: 4,122,000 files examined (97.4%)
Key Scanner:         4,126,000 files examined (97.5%)
Filesystem Scanner:  1,525,000 files examined (36% - crypto files only)
```

**Why counts differ**:

- Certificate/Key scanners examine EVERY file (comprehensive search)
- Filesystem scanner pre-filters by extension (efficient search)
- Both strategies are correct for their use cases

---

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
