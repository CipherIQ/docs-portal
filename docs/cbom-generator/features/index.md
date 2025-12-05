# Features

CBOM Generator provides comprehensive cryptographic asset discovery and analysis capabilities.

## Core Features

| Feature | Description |
|---------|-------------|
| [Asset Discovery](asset-discovery.md) | 8 built-in scanners for comprehensive crypto detection |
| [Key Material Detection](key-material-detection.md) | Multi-format key discovery with security analysis |
| [Service Dependencies](service-dependencies.md) | 4-level dependency graph (SERVICE→PROTOCOL→SUITE→ALGO) |
| [Protocol Properties](protocol-properties.md) | TLS/SSH/IPsec protocol analysis |
| [PQC Assessment](pqc-assessment.md) | Post-Quantum Cryptography readiness scoring |
| [Relationship Graph](relationship-graph.md) | Complete dependency tracking |
| [Privacy Controls](privacy-controls.md) | GDPR/CCPA-compliant redaction |
| [Deduplication](deduplication.md) | Intelligent duplicate handling |

## Scanner Overview

CBOM Generator includes 8 scanner types:

```
┌─────────────────────────────────────────────────────────────┐
│                    CBOM Generator                            │
├─────────────────────────────────────────────────────────────┤
│  Scanners                                                    │
│  ├── Certificate Scanner (X.509, OpenPGP)                   │
│  ├── Key Scanner (RSA, ECDSA, Ed25519, DSA, DH)            │
│  ├── Package Scanner (APT, RPM, pip, npm)                   │
│  ├── Service Scanner (Apache, Nginx, OpenSSH)               │
│  ├── Filesystem Scanner (crypto-related files)              │
│  ├── Application Scanner (binary dependency analysis)       │
│  ├── Library Scanner (crypto library detection)             │
│  └── Algorithm Detection (derived from all sources)         │
└─────────────────────────────────────────────────────────────┘
```

## Component Types

| Type | Description | Example |
|------|-------------|---------|
| Certificate | X.509 and OpenPGP certificates | CA root certs, server certs |
| Key | Private/public key material | RSA-2048, Ed25519 keys |
| Algorithm | Cryptographic primitives | AES-256-GCM, SHA-384 |
| Library | Crypto libraries | OpenSSL, libgcrypt |
| Protocol | Communication protocols | TLS 1.3, SSH 2.0 |
| Service | Network services | nginx, sshd, postgres |
| Cipher Suite | Protocol cipher suites | TLS_AES_256_GCM_SHA384 |
| Application | Crypto-using applications | curl, git, openssl |

## Relationship Types

The scanner builds a complete dependency graph:

```
APPLICATION
    └── DEPENDS_ON → LIBRARY
                         └── PROVIDES → ALGORITHM

SERVICE
    └── USES → PROTOCOL
                   └── PROVIDES → CIPHER_SUITE
                                      └── USES → ALGORITHM

CERTIFICATE
    └── USES → ALGORITHM (signature)
    └── USES → ALGORITHM (public key)
```

## Supported Formats

**Input**: PEM, DER, PKCS#12, PKCS#8, OpenSSH, ELF binaries

**Output**: CycloneDX 1.6/1.7 JSON
