# PQC Readiness Assessment

Post-Quantum Cryptography (PQC) assessment analyzes your cryptographic assets for quantum computer vulnerability.

---

## Safety Categories

| Category | Meaning | Examples | Risk Level |
|----------|---------|----------|------------|
| **SAFE** | Post-quantum secure | ML-KEM (Kyber), ML-DSA (Dilithium), SPHINCS+ | Low |
| **TRANSITIONAL** | Classically strong, quantum-vulnerable | RSA-2048+, ECDSA-P256+, AES-256, SHA-256 | Medium-High |
| **DEPRECATED** | Broken/weak algorithms | MD5, SHA-1, RC4, DES | Critical |
| **UNSAFE** | Quantum-vulnerable + weak | RSA-1024, DSA | Critical |

---

## Break Year Estimation

Each quantum-vulnerable algorithm includes an estimated break year based on NIST IR 8413 and NSA CNSA 2.0 guidance:

| Algorithm | Key Size | Break Year | Priority |
|-----------|----------|------------|----------|
| RSA-1024, MD5, SHA-1, RC4, DES | - | **2030** | CRITICAL |
| RSA-2048, ECDSA-P256, ECDH-P256 | 2048/256 bits | **2035** | HIGH |
| RSA-3072, ECDSA-P384 | 3072/384 bits | **2040** | MEDIUM |
| RSA-4096, ECDSA-P521 | 4096+/521 bits | **2045** | LOW |

---

## Readiness Score

The PQC readiness score (0-100%) is calculated as:

```
score = (SAFE×100 + TRANSITIONAL×50 + DEPRECATED×0 + UNSAFE×0) / total
```

**Migration Recommendations**:

| Score | Status | Action |
|-------|--------|--------|
| < 30% | CRITICAL | Immediate action required |
| 30-60% | Plan migration | Within 12-24 months |
| 60-90% | Good readiness | Complete remaining migrations |
| > 90% | PQC-ready | Maintain configuration |

---

## CBOM Output Properties

The CBOM includes aggregate PQC metrics:

```json
{
  "properties": [
    {"name": "cbom:pqc:total_assets", "value": "351"},
    {"name": "cbom:pqc:safe_count", "value": "1"},
    {"name": "cbom:pqc:transitional_count", "value": "20"},
    {"name": "cbom:pqc:deprecated_count", "value": "0"},
    {"name": "cbom:pqc:unsafe_count", "value": "330"},
    {"name": "cbom:pqc:readiness_score", "value": "3.1"},
    {"name": "cbom:pqc:break_2030_count", "value": "119"},
    {"name": "cbom:pqc:break_2035_count", "value": "64"},
    {"name": "cbom:pqc:break_2040_count", "value": "0"},
    {"name": "cbom:pqc:break_2045_count", "value": "0"}
  ]
}
```

---

## Per-Component PQC Status

Every algorithm, certificate, and key includes PQC assessment:

```json
{
  "name": "RSA-2048",
  "properties": [
    { "name": "cbom:pqc:status", "value": "TRANSITIONAL" },
    { "name": "cbom:pqc:confidence", "value": "HIGH" },
    { "name": "cbom:pqc:migration_urgency", "value": "HIGH" },
    { "name": "cbom:pqc:alternative", "value": "ML-DSA-65" },
    { "name": "cbom:pqc:break_estimate", "value": "2035" },
    { "name": "cbom:pqc:rationale", "value": "Quantum-vulnerable but meets current classical security standards" }
  ]
}
```

---

## Classification Philosophy

### Libraries: Worst-Case Classification

Libraries are classified based on the **weakest** algorithm they implement:

| Library Implements | Classification | Rationale |
|-------------------|----------------|-----------|
| AES-256 + RSA-2048 + MD5 | **DEPRECATED** | MD5 is deprecated |
| AES-256 + RSA-2048 | **TRANSITIONAL** | RSA-2048 is quantum-vulnerable |
| AES-256 + ML-KEM-768 | **SAFE** | Both are PQC-safe |

### Services/Applications: Best-Case Classification

Services are classified based on the **strongest** configured algorithm:

| Service Configured With | Classification |
|------------------------|----------------|
| TLS_AES_256_GCM_SHA384 + curve25519-sha256 | **TRANSITIONAL** |
| TLS_AES_256_GCM_SHA384 + sntrup761x25519 | **SAFE** |
| SSLv3 + RC4 only | **DEPRECATED** |

---

## PQC KEX Detection

The generator recognizes Post-Quantum key exchange algorithms:

| Pattern | Algorithm | Type |
|---------|-----------|------|
| `sntrup761*` | NTRU Prime hybrid | OpenSSH |
| `mlkem*` / `kyber*` | ML-KEM/Kyber | TLS 1.3 |
| `dilithium*` / `mldsa*` | ML-DSA/Dilithium | Signatures |

---

## Enabling PQC for Services

### OpenSSH (v9.0+)

```bash
# /etc/ssh/sshd_config
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256
```

### Nginx (OpenSSL 3.2+)

```nginx
ssl_ecdh_curve X25519MLKEM768:X25519:P-256;
```

### Apache (OpenSSL 3.2+)

```apache
SSLOpenSSLConfCmd Curves X25519MLKEM768:X25519:P-256
```

---

## Common Queries

### Finding Critical Assets (Break by 2030)

```bash
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:break_estimate" and .value == "2030")) |
    .name'
```

### Services Without PQC

```bash
cat cbom.json | jq -r '.components[] |
    select(.type == "operating-system") |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "TRANSITIONAL")) |
    "\(.name): \(.properties[] | select(.name == "cbom:pqc:rationale").value)"'
```

### PQC-Ready Components

```bash
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "SAFE")) |
    .name'
```
