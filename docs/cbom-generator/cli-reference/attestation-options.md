---
hide:
  - toc
---
# Attestation Options

SLSA provenance and digital signature support for CBOM integrity.

---

## Current Status (v1.9)

| Feature | Status |
|---------|--------|
| SLSA v0.2 provenance metadata | Implemented |
| Cryptographic signing (DSSE/PGP) | Deferred to v2.0 |

**What v1.9 Provides**:

The `metadata.provenance` block includes build attestation:

```json
{
  "provenance": {
    "git_commit": "abc123...",
    "compiler": "GCC 11.4.0",
    "openssl_version": "3.0.2",
    "build_timestamp": "2025-11-09T15:00:00Z",
    "build_type": "Release"
  }
}
```

This allows build verification without cryptographic signatures.

---

## `--enable-attestation`

Enable CBOM attestation with digital signature.

**Status**: v1.9 accepts flag but skips signing; v2.0 will implement full DSSE/PGP signing.

```bash
# Enable attestation (v1.0: metadata only, v1.1: with signature)
./build/cbom-generator --enable-attestation --signing-key key.pem --output cbom.json
```

---

## `--signature-method METHOD`

Signature method selection.

**Values**: `dsse` (default), `pgp`

**Status**: Planned for v2.0

```bash
# DSSE envelope (v2.0)
./build/cbom-generator --enable-attestation --signature-method=dsse --signing-key key.pem

# PGP signature (v2.0)
./build/cbom-generator --enable-attestation --signature-method=pgp --signing-key key.asc
```

---

## `--signing-key PATH`

Path to signing key file.

**Status**: Planned for v1.1

```bash
./build/cbom-generator --enable-attestation --signing-key /path/to/key.pem --output cbom.json
```

---

## SLSA Provenance Fields

The provenance metadata includes:

| Field | Description |
|-------|-------------|
| `git_commit` | Git commit hash of the build |
| `compiler` | Compiler name and version |
| `openssl_version` | OpenSSL library version |
| `build_timestamp` | ISO-8601 build timestamp |
| `build_type` | Release or Debug |

---

## v2.0 Planned Features

- DSSE (Dead Simple Signing Envelope) support
- PGP signature support
- Key management integration
- Signature verification tooling

See GitHub issues for timeline.
