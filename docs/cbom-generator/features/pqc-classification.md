---
hide:
  - toc
---
# How PQC Classification Works

## Overview

The CBOM Generator uses a multi-stage classification process to assess each cryptographic asset for Post-Quantum Cryptography (PQC) readiness. This document explains the methodology, decision logic, and standards that inform the classification.

---

## Classification Pipeline

Each cryptographic asset goes through this assessment pipeline:

```
Asset Discovered
      |
      v
+---------------------+
|  1. Algorithm       |
|     Identification  |
+---------------------+
      |
      v
+---------------------+
|  2. Normalization   |
|     & Parsing       |
+---------------------+
      |
      v
+---------------------+
|  3. Category        |
|     Classification  |
+---------------------+
      |
      v
+---------------------+
|  4. Break Year      |
|     Estimation      |
+---------------------+
      |
      v
+---------------------+
|  5. Urgency         |
|     Assignment      |
+---------------------+
      |
      v
+---------------------+
|  6. Alternative     |
|     Suggestion      |
+---------------------+
      |
      v
Final PQC Assessment
```

---

## Stage 1: Algorithm Identification

The scanner identifies algorithms from multiple sources:

| Source | Examples | Detection Method |
|--------|----------|------------------|
| X.509 Certificates | RSA-2048, ECDSA-P256 | Parse certificate signature and public key algorithms |
| Private Keys | RSA-4096, Ed25519 | Analyze key file format and parameters |
| Service Configs | TLS cipher suites | Parse Apache, nginx, sshd configurations |
| Binary Analysis | OpenSSL symbols | Detect crypto library imports in ELF binaries |
| Kernel Crypto API | gcm(aes), sha256 | Parse /proc/crypto and kernel module usage |

### Detection Methods for Applications

For compiled binaries, the classifier uses multiple detection methods:

| Method | What It Detects | Example |
|--------|-----------------|---------|
| ELF Library Imports | Linked crypto libraries | libssl.so.3, libcrypto.so.3 |
| Symbol Analysis | Function imports | `AES_encrypt`, `SHA256_Init` |
| Go Package Detection | Go crypto imports | `crypto/tls`, `crypto/aes` |
| Rust Crate Detection | Rust crypto crates | `rustls::`, `ring::` |
| Kernel Crypto API | Kernel cipher names | `gcm(aes)`, `sha256` |


## Stage 2: Algorithm Normalization

Raw algorithm names are normalized to canonical forms for consistent classification:

### Kernel Crypto API Patterns

| Raw Name | Normalized | Key Size Assumed |
|----------|------------|------------------|
| `gcm(aes)` | AES-256-GCM | 256 bits |
| `xts(aes)` | AES-256-XTS | 256 bits |
| `cbc(aes)` | AES-128-CBC | 128 bits |
| `sha256` | SHA-256 | 256 bits |
| `hmac(sha256)` | HMAC-SHA256 | 256 bits |

### Go Crypto Package Patterns

| Import Path | Normalized |
|-------------|------------|
| `crypto/aes` | AES |
| `crypto/rsa` | RSA |
| `crypto/ecdsa` | ECDSA |
| `crypto/sha256` | SHA-256 |
| `crypto/tls` | TLS-1.2 |

### Rust Crate Patterns

| Crate Name | Normalized |
|------------|------------|
| `ring::` | AES-256-GCM |
| `rustls::` | TLS-1.3 |
| `aes_gcm::` | AES-256-GCM |
| `x25519_dalek::` | X25519 |
| `ed25519_dalek::` | ED25519 |

### Symbol Patterns

| Function Symbol | Normalized |
|-----------------|------------|
| `AES_encrypt` | AES |
| `SHA256_Init` | SHA-256 |
| `EVP_EncryptInit` | AES |
| `gcry_cipher_open` | AES |
| `nettle_sha256_digest` | SHA-256 |


## Stage 3: Category Classification

The classification function evaluates algorithms in a specific order, using the first matching rule:

### Decision Tree

```
Is algorithm NIST-finalized PQC?
  |-- YES --> PQC_SAFE
  |-- NO  --> Continue
          |
Is it symmetric cipher >= 256 bits?
  |-- YES --> PQC_SAFE
  |-- NO  --> Continue
          |
Is it hash function >= 256 bits?
  |-- YES --> PQC_SAFE
  |-- NO  --> Continue
          |
Is it MD5, SHA-1, RC4, or DES?
  |-- YES --> PQC_DEPRECATED
  |-- NO  --> Continue
          |
Is it RSA?
  |-- YES --> Key size >= 2048?
  |           |-- YES --> PQC_TRANSITIONAL
  |           |-- NO  --> PQC_UNSAFE
  |-- NO  --> Continue
          |
Is it ECDSA/ECDH/EC/P-256/P-384/P-521?
  |-- YES --> Key size >= 256 or named curve?
  |           |-- YES --> PQC_TRANSITIONAL
  |           |-- NO  --> PQC_UNSAFE
  |-- NO  --> Continue
          |
Is it DSA (not ECDSA)?
  |-- YES --> PQC_UNSAFE
  |-- NO  --> Continue
          |
Is it Ed25519/Ed448?
  |-- YES --> PQC_TRANSITIONAL
  |-- NO  --> Continue
          |
Is it sntrup/NTRU/ntruprime?
  |-- YES --> PQC_SAFE (lattice-based)
  |-- NO  --> Continue
          |
Is it X25519/curve25519?
  |-- YES --> PQC_TRANSITIONAL
  |-- NO  --> Continue
          |
Is it AES?
  |-- YES --> 256-bit key?
  |           |-- YES --> PQC_SAFE
  |           |-- NO  --> PQC_TRANSITIONAL
  |-- NO  --> Continue
          |
Is it ChaCha20/Salsa20/Camellia?
  |-- YES --> PQC_TRANSITIONAL
  |-- NO  --> Continue
          |
Is it SHA-256/384/512/SHA3/BLAKE?
  |-- YES --> PQC_TRANSITIONAL
  |-- NO  --> Continue
          |
Is it DH/DHE?
  |-- YES --> Key size >= 2048?
  |           |-- YES --> PQC_TRANSITIONAL
  |           |-- NO  --> PQC_UNSAFE
  |-- NO  --> PQC_UNKNOWN
```

### NIST-Finalized PQC Algorithms

These algorithms are automatically classified as **PQC_SAFE**:

| Algorithm Family | FIPS Standard | Variants |
|------------------|---------------|----------|
| ML-KEM (Kyber) | FIPS 203 | ML-KEM-512, ML-KEM-768, ML-KEM-1024 |
| ML-DSA (Dilithium) | FIPS 204 | ML-DSA-44, ML-DSA-65, ML-DSA-87 |
| SLH-DSA (SPHINCS+) | FIPS 205 | SLH-DSA-SHA2-* variants |
| Falcon | FIPS 206 (pending) | Falcon-512, Falcon-1024 |
| BIKE | Round 4 | BIKE-L1, BIKE-L3, BIKE-L5 |
| HQC | Round 4 | HQC-128, HQC-192, HQC-256 |
| Classic McEliece | Round 4 | McEliece variants |
| NTRU/sntrup | Legacy PQC | sntrup761, NTRU-Prime |

### Hybrid Algorithm Detection

Hybrid algorithms combine classical and PQC components:

| Pattern | Classical | PQC | Classification |
|---------|-----------|-----|----------------|
| X25519Kyber768 | X25519 | Kyber-768 | PQC_SAFE (hybrid) |
| X25519-ML-KEM-768 | X25519 | ML-KEM-768 | PQC_SAFE (hybrid) |
| SecP256r1Kyber768 | P-256 ECDH | Kyber-768 | PQC_SAFE (hybrid) |
| sntrup761x25519 | X25519 | sntrup761 | PQC_SAFE (hybrid) |

Hybrid algorithms are marked with `cbom:pqc:is_hybrid = true`.

---

## Protocol Classification

TLS and SSH protocols receive special handling because their security depends on the key exchange algorithm, not just the protocol version or cipher suite.

### TLS Protocol Classification

The classifier evaluates TLS protocols based on version and key exchange configuration:

| Protocol | Status |  Rationale |
|----------|--------|----------------|
| TLS with PQC-hybrid KEX (Kyber, ML-KEM, X25519Kyber) | **SAFE** | PQC-hybrid key exchange |
| TLS 1.3 (without PQC hybrid) | **TRANSITIONAL** | TLS 1.2/1.3: quantum-safe symmetric (AES-GCM), vulnerable KEX (ECDHE) |
| TLS 1.2 (without PQC hybrid) | **TRANSITIONAL** | Same as TLS 1.3 - KEX is the vulnerability |
| TLS 1.1 | **DEPRECATED** | TLS 1.0/1.1 and SSLv3: deprecated protocols with known vulnerabilities |
| TLS 1.0 | **DEPRECATED** | Same - classical attacks (BEAST, etc.) + quantum-vulnerable |
| SSLv3 | **DEPRECATED** | Completely broken classically (POODLE) |


### TLS Cipher Suite Classification

Individual cipher suites are classified based on their components:

| Cipher Suite Pattern | Status |  Rationale |
|---------------------|--------|----------------|
| TLS 1.3 suites (`TLS_AES_*`, `TLS_CHACHA20_*`) | **TRANSITIONAL** | TLS 1.3 with classical KEX (X25519/ECDHE) - TRANSITIONAL for service |
| Contains `ECDHE` or `DHE` | **TRANSITIONAL** | Good forward secrecy but classical KEX |
| RSA key transport (no ECDHE/DHE) | **TRANSITIONAL** | RSA key transport (no forward secrecy) - still TRANSITIONAL for now |
| Contains `RC4`, `DES`, `NULL`, `EXPORT`, `MD5`, `3DES` | **DEPRECATED** | Classically broken ciphers |
| Default (other patterns) | **TRANSITIONAL** | Default assumption |


### SSH Protocol Classification

SSH protocols are classified based on their key exchange algorithms:

| Configuration | Status |  Rationale |
|---------------|--------|----------------|
| SSH with `sntrup761x25519` | **SAFE** | PQC-hybrid KEX (NTRU-Prime + X25519) |
| SSH with `ntruprime` or `Kyber` | **SAFE** | Uses quantum-resistant key exchange |
| SSH with curve25519/ECDH | **TRANSITIONAL** | quantum-safe symmetric, vulnerable KEX |


### Design Decision: Why RSA Key Transport is TRANSITIONAL

The CBOM Generator classifies RSA key transport cipher suites as **TRANSITIONAL** (not UNSAFE), even though they lack forward secrecy.

This design choice treats RSA key transport equivalently to ECDHE for PQC classification because:

1. **Both are quantum-vulnerable**: Shor's algorithm can break both RSA and ECDHE
2. **Separate concerns**: Forward secrecy is a separate property from PQC readiness
3. **TRANSITIONAL = plan migration**: Both require migration to PQC, which is the primary concern

**Note:** Organizations with strict "harvest-now-decrypt-later" concerns may want to prioritize disabling RSA key transport before ECDHE suites.


## Stage 4: Break Year Estimation

Break year indicates when quantum computers are expected to break the algorithm. Based on **NIST IR 8413** and **NSA CNSA 2.0** guidance:

### RSA Algorithms

| Key Size | Break Year | Priority | Rationale |
|----------|------------|----------|-----------|
| RSA-1024 | 2030 | CRITICAL | Already classically weakened |
| RSA-2048 | 2035 | HIGH | NIST baseline, NSA CNSA 2.0 deadline |
| RSA-3072 | 2040 | MEDIUM | Conservative quantum resistance |
| RSA-4096 | 2045 | LOW | Optimistic, slower quantum progress |

### ECDSA/ECDH Algorithms

| Curve Size | Break Year | Priority | Rationale |
|------------|------------|----------|-----------|
| P-256 (256 bits) | 2035 | HIGH | NSA CNSA 2.0 deadline |
| P-384 (384 bits) | 2040 | MEDIUM | Medium-term vulnerable |
| P-521 (521 bits) | 2045 | LOW | Conservative estimate |

### Diffie-Hellman

| Key Size | Break Year | Priority |
|----------|------------|----------|
| DH-1024 | 2030 | CRITICAL |
| DH-2048 | 2035 | HIGH |
| DH-3072+ | 2040 | MEDIUM |

### DSA

| Key Size | Break Year | Priority |
|----------|------------|----------|
| DSA < 3072 | 2030 | CRITICAL |
| DSA >= 3072 | 2035 | HIGH |

### Deprecated Algorithms

| Algorithm | Break Year | Rationale |
|-----------|------------|-----------|
| MD5 | 2030 | Already broken (collision attacks) |
| SHA-1 | 2030 | Already broken (collision attacks) |
| RC4 | 2030 | Multiple breaks known |
| DES | 2030 | 56-bit key, trivially broken |
| 3DES | 2030 | Meet-in-the-middle attacks |

### Quantum-Safe Algorithms

| Algorithm | Break Year | Rationale |
|-----------|------------|-----------|
| AES-256 | N/A (0) | 128-bit post-quantum security |
| SHA-256/384/512 | N/A (0) | Collision-resistant |
| ML-KEM/ML-DSA | N/A (0) | NIST-finalized PQC |



## Stage 5: Urgency Assignment

Migration urgency is derived from category and deprecation status:

| Category | Deprecated? | Urgency | Action |
|----------|-------------|---------|--------|
| PQC_SAFE | No | LOW | No action needed |
| PQC_SAFE | Yes | LOW | No action needed |
| PQC_TRANSITIONAL | No | HIGH | Plan migration |
| PQC_TRANSITIONAL | Yes | CRITICAL | Immediate action |
| PQC_DEPRECATED | - | CRITICAL | Immediate action |
| PQC_UNSAFE | - | CRITICAL | Immediate action |
| PQC_UNKNOWN | - | UNKNOWN | Manual review |



## Stage 6: Alternative Suggestions

The classifier suggests PQC replacements based on algorithm type and key size:

### RSA Alternatives (Signatures)

| Original | Key Size | Suggested Alternative |
|----------|----------|----------------------|
| RSA | >= 4096 | Dilithium-5 (ML-DSA-87) |
| RSA | >= 3072 | Dilithium-3 (ML-DSA-65) |
| RSA | < 3072 | Dilithium-2 (ML-DSA-44) |

### ECDSA Alternatives (Signatures)

| Original | Curve | Suggested Alternative |
|----------|-------|----------------------|
| ECDSA | P-384+ | Dilithium-3 (ML-DSA-65) |
| ECDSA | P-256 | Dilithium-2 (ML-DSA-44) |
| Ed25519 | - | Dilithium-2 (ML-DSA-44) |
| Ed448 | - | Dilithium-3 (ML-DSA-65) |

### ECDH/DH Alternatives (Key Exchange)

| Original | Key Size | Suggested Alternative |
|----------|----------|----------------------|
| ECDH/DH | >= 4096 | Kyber-1024 (ML-KEM-1024) |
| ECDH/DH | >= 2048 | Kyber-768 (ML-KEM-768) |
| ECDH/DH | < 2048 | Kyber-512 (ML-KEM-512) |
| X25519 | - | Kyber-768 or X25519Kyber768 (hybrid) |
| X448 | - | Kyber-1024 (ML-KEM-1024) |

### DSA Alternatives

| Original | Suggested Alternative |
|----------|----------------------|
| DSA (any) | Dilithium-3 (ML-DSA-65) |

### Deprecated Algorithm Alternatives

| Original | Suggested Alternative |
|----------|----------------------|
| MD5, SHA-1 | SHA-256 or SHA-384 |
| RC4, DES | AES-256-GCM or ChaCha20-Poly1305 |

---

## Readiness Score Calculation

The overall PQC readiness score (0-100) is calculated using weighted scoring:

| Category | Points | Weight Rationale |
|----------|--------|------------------|
| PQC_SAFE | 100 | Fully quantum-resistant |
| PQC_TRANSITIONAL | 60 | Classically strong, quantum-vulnerable |
| PQC_DEPRECATED | 20 | Known vulnerabilities |
| PQC_UNSAFE | 0 | Weak on both fronts |

**Formula:**
```
readiness_score = (safe_count * 100 + transitional_count * 60 +
                   deprecated_count * 20 + unsafe_count * 0) / total_count
```

### Score Interpretation

| Score | Rating | Meaning |
|-------|--------|---------|
| 90-100 | Excellent | Minimal migration needed |
| 70-89 | Good | Some migration needed |
| 50-69 | Moderate | Significant migration needed |
| 30-49 | Poor | Extensive migration required |
| 0-29 | Critical | Urgent action required |

---

## Library Classification

When classifying cryptographic libraries (OpenSSL, GnuTLS, etc.), the **worst-case algorithm** determines the library's overall classification:

```
Library implements: [AES-256 (SAFE), RSA-2048 (TRANSITIONAL), SHA-256 (SAFE)]
                                        |
                                        v
                    Library classification: TRANSITIONAL
```

This follows the security principle that the weakest link determines overall security posture.

### Assumed Key Sizes for Libraries

When key sizes aren't available, conservative defaults are assumed:

| Algorithm Type | Assumed Key Size | Rationale |
|----------------|------------------|-----------|
| RSA | 2048 bits | Modern library minimum |
| ECDSA/ECDH | 256 bits | P-256 is the minimum modern curve |
| Symmetric | 128-256 bits | Context-dependent |
| Hash | 256 bits | SHA-256 default |

---

## Confidence Levels

Classification confidence is based on available information:

| Information Available | Confidence | Level |
|-----------------------|------------|-------|
| Algorithm name + key size | 0.95 | HIGH |
| Algorithm name only | 0.75 | MEDIUM |
| Partial information | 0.50 | LOW |

---

## Standards References

The classification methodology is based on:

### NIST IR 8413 (March 2022)
"Status Report on the Third Round of the NIST Post-Quantum Cryptography Standardization Process"
- Defines security levels (1, 2, 3, 4, 5)
- Identifies finalized algorithms
- Provides quantum security guidance

### NSA CNSA 2.0 (September 2022)
"Commercial National Security Algorithm Suite 2.0"
- Sets 2035 deadline for RSA-2048/ECDSA-P256 migration
- Recommends ML-KEM-768, ML-DSA-65/87
- Defines post-quantum algorithm suite

### NIST FIPS 203/204/205 (2024)
- FIPS 203: ML-KEM (Kyber) standard
- FIPS 204: ML-DSA (Dilithium) standard
- FIPS 205: SLH-DSA (SPHINCS+) standard

### NIST SP 800-57 Rev. 5
"Recommendation for Key Management"
- Classical security strength calculations
- Key length recommendations

---

## Limitations

### What the Classifier Cannot Determine

1. **Actual key sizes in binaries**: Without runtime analysis, exact key sizes may be unknown
2. **Algorithm usage context**: Same algorithm may be used differently in different contexts
3. **Custom implementations**: Non-standard crypto implementations may not be detected
4. **Hardware security modules**: HSM-based crypto may not be visible to file-based scanning

### Conservative Defaults

When information is incomplete, the classifier uses conservative assumptions:

- RSA without key size: assumed 2048 bits (TRANSITIONAL, not UNSAFE)
- ECDSA without curve: assumed P-256 (TRANSITIONAL)
- Unknown algorithms: PQC_UNKNOWN (not automatically marked unsafe)

