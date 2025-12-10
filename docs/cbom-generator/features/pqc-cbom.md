---
hide:
  - toc
---
# PQC in CBOM Output

## Overview

Post-Quantum Cryptography (PQC) assessment evaluates each cryptographic asset for vulnerability to quantum computing attacks. The CBOM Generator classifies every algorithm, certificate, and protocol to help you plan your migration to quantum-resistant cryptography.

---

## PQC Status Categories

Each cryptographic asset receives one of five status classifications:

| Status | Meaning | Action Required |
|--------|---------|-----------------|
| **SAFE** | Quantum-resistant algorithm | None - already protected |
| **TRANSITIONAL** | Vulnerable but acceptable for now | Plan migration before break year |
| **DEPRECATED** | Weak regardless of quantum threat | Migrate immediately |
| **UNSAFE** | Highly vulnerable, short break timeline | Prioritize migration |
| **UNKNOWN** | Cannot be classified | Manual review needed |

### SAFE

Assets classified as SAFE use quantum-resistant algorithms:

- **NIST-Finalized PQC**: ML-KEM (Kyber), ML-DSA (Dilithium), SLH-DSA (SPHINCS+)
- **Symmetric 256-bit**: AES-256, ChaCha20-256
- **Hash 256-bit+**: SHA-256, SHA-384, SHA-512, SHA3-256, BLAKE2b

Symmetric algorithms with 256-bit keys remain secure under Grover's algorithm, which only halves effective key strength.

### TRANSITIONAL

Assets that are secure today but will become vulnerable when large-scale quantum computers exist:

- **RSA >= 2048 bits**: RSA-2048, RSA-3072, RSA-4096
- **ECDSA >= 256 bits**: ECDSA-P256, ECDSA-P384, ECDSA-P521
- **Edwards curves**: Ed25519, Ed448
- **Key exchange**: X25519, X448, ECDH
- **Symmetric 128/192-bit**: AES-128, AES-192

These algorithms should be migrated before their estimated break year.

### DEPRECATED

Cryptographically weak regardless of quantum computing:

- **Broken hashes**: MD5, SHA-1
- **Weak ciphers**: RC4, DES, 3DES, Blowfish
- **Export-grade**: 40-bit and 56-bit ciphers
- **NULL ciphers**: No encryption

Migrate these immediately - they're already insecure.

### UNSAFE

High-priority migration targets with short break timelines:

- **Small RSA**: RSA-1024, RSA-512
- **Small ECDSA**: ECDSA-P192
- **DSA**: All key sizes
- **Weak DH**: DH parameters < 2048 bits

These are vulnerable to both classical and quantum attacks.

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

## Break Year Estimates

Break year indicates when an algorithm is expected to become vulnerable to quantum attack, based on NIST IR 8413 and NSA CNSA 2.0 guidance:

| Algorithm/Key Size | Break Year | Urgency |
|--------------------|------------|---------|
| RSA-1024, MD5, SHA-1, DES | 2030 | CRITICAL |
| RSA-2048, ECDSA-P256, Ed25519 | 2035 | HIGH |
| RSA-3072, ECDSA-P384 | 2040 | MEDIUM |
| RSA-4096, ECDSA-P521 | 2045 | LOW |
| ML-KEM, ML-DSA, AES-256 | Never | None |

**Data retention consideration**: If your encrypted data must remain confidential beyond the break year, migrate sooner. An attacker can capture encrypted traffic today and decrypt it once quantum computers are available ("harvest now, decrypt later").

---

## Migration Urgency Levels

| Urgency | Timeline | Recommended Action |
|---------|----------|-------------------|
| **CRITICAL** | Break by 2030 | Immediate migration required |
| **HIGH** | Break by 2035 | Begin migration planning now |
| **MEDIUM** | Break by 2040 | Include in 3-5 year roadmap |
| **LOW** | Break by 2045 | Monitor standards development |

---

## Readiness Score

The PQC readiness score (0-100%) is calculated as:

```
score = (SAFE×100 + TRANSITIONAL×50 + DEPRECATED×20 + UNSAFE×0) / total
```

---

## PQC KEX Detection

The generator recognizes Post-Quantum key exchange algorithms:

| Pattern | Algorithm | Type |
|---------|-----------|------|
| `sntrup761*` | NTRU Prime hybrid | OpenSSH |
| `mlkem*` / `kyber*` | ML-KEM/Kyber | TLS 1.3 |
| `dilithium*` / `mldsa*` | ML-DSA/Dilithium | Signatures |

---

## Enabling PQC in Selected Services

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
## CBOM Output Properties

PQC assessment adds properties to each cryptographic component in the CBOM:

### Component Properties

```json
{
  "type": "cryptographic-asset",
  "name": "RSA-2048",
  "cryptoProperties": {
    "assetType": "algorithm",
    "algorithmProperties": {
      "primitive": "pke",
      "parameterSetIdentifier": "2048"
    }
  },
  "properties": [
    { "name": "cbom:pqc:status", "value": "TRANSITIONAL" },
    { "name": "cbom:pqc:break_estimate", "value": "2035" },
    { "name": "cbom:pqc:migration_urgency", "value": "HIGH" },
    { "name": "cbom:pqc:rationale", "value": "RSA-2048 is quantum-vulnerable; plan PQC migration" }
  ]
}
```

| Property | Description |
|----------|-------------|
| `cbom:pqc:status` | Classification: SAFE, TRANSITIONAL, DEPRECATED, UNSAFE, UNKNOWN |
| `cbom:pqc:break_estimate` | Year when algorithm becomes vulnerable |
| `cbom:pqc:migration_urgency` | Priority level: CRITICAL, HIGH, MEDIUM, LOW |
| `cbom:pqc:rationale` | Explanation of the classification |
| `cbom:pqc:is_hybrid` | "true" if hybrid PQC+classical algorithm |
| `cbom:pqc:alternative` | Recommended PQC replacement algorithm |
| `cbom:pqc:confidence` | Classification confidence: HIGH, MEDIUM, LOW |
| `cbom:pqc:source` | Standards reference (e.g., "NIST IR 8413") |

### Metadata Properties


The CBOM metadata includes aggregate PQC statistics:

```json
{
  "metadata": {
    "properties": [
      { "name": "cbom:pqc:readiness_score", "value": "60" },
      { "name": "cbom:pqc:safe_count", "value": "45" },
      { "name": "cbom:pqc:transitional_count", "value": "120" },
      { "name": "cbom:pqc:unsafe_count", "value": "5" },
      { "name": "cbom:pqc:deprecated_count", "value": "3" },
      { "name": "cbom:pqc:break_2030_count", "value": "8" },
      { "name": "cbom:pqc:break_2035_count", "value": "95" },
      { "name": "cbom:pqc:assessment_date", "value": "2025-01-15T10:30:00Z" }
    ]
  }
}
```

---

## The PQC Migration Report

The `--pqc-report` flag generates a comprehensive, human-readable migration report that provides actionable guidance for transitioning to quantum-resistant cryptography.

### Generating the Report

```bash
./cbom-generator --pqc-report /path/to/report.txt [directories-to-scan]
```

The report is generated alongside the standard CBOM output, providing a text-based summary suitable for management review and compliance documentation.

### Report Sections

#### Executive Summary

```
EXECUTIVE SUMMARY
-----------------
Total Cryptographic Assets: 160
PQC-Safe Assets: 8 (5.0%)
Quantum-Vulnerable Assets: 48 (30.0%)
Hybrid Deployments: 2
```

Quick overview showing your total cryptographic inventory, how many assets are already quantum-safe, how many need migration, and whether you have any hybrid PQC deployments.

#### Vulnerability Breakdown by Break Year

```
VULNERABILITY BREAKDOWN BY BREAK YEAR
--------------------------------------
CRITICAL (Break by 2030):      7 assets  [IMMEDIATE ACTION]
   - MD5, SHA-1, RC4, DES, RSA-1024 (already weakened classically)

HIGH (Break by 2035):          4 assets  [PLAN MIGRATION NOW]
   - RSA-2048, ECDSA-P256, ECDH-P256 (NIST baseline, NSA CNSA 2.0 deadline)

MEDIUM (Break by 2040):        0 assets  [MONITOR CLOSELY]
   - RSA-3072, ECDSA-P384 (conservative estimate)

LOW (Break by 2045+):          0 assets  [LONG-TERM PLAN]
   - RSA-4096, ECDSA-P521 (optimistic, slower quantum progress)
```

Groups your vulnerable assets by their estimated break year, with clear urgency indicators:

- **CRITICAL**: Already classically weak or breaking by 2030
- **HIGH**: NSA CNSA 2.0 deadline of 2035
- **MEDIUM**: Conservative 2040 timeline
- **LOW**: Extended 2045+ timeline for strongest classical algorithms

#### Migration Priority Timeline

```
MIGRATION PRIORITY TIMELINE
----------------------------
2024-2027: Pilot PQC deployments, migrate CRITICAL assets (7 by 2030)
2027-2030: Phase 1 migration complete
2030-2035: Phase 2 migration (4 assets by 2035)
2035-2040: Phase 3 migration (0 assets by 2040)
2040-2045: Phase 4 migration (0 assets by 2045)
```

Provides a phased migration roadmap aligned with industry timelines and regulatory deadlines.

#### NIST PQC Standards Reference

```
NIST PQC STANDARDS
------------------
- FIPS 203: Module-Lattice-Based Key-Encapsulation (ML-KEM)
  ML-KEM-512 (Level 1), ML-KEM-768 (Level 3), ML-KEM-1024 (Level 5)

- FIPS 204: Module-Lattice-Based Digital Signatures (ML-DSA)
  ML-DSA-44 (Level 2), ML-DSA-65 (Level 3), ML-DSA-87 (Level 5)

- FIPS 205: Stateless Hash-Based Digital Signatures (SLH-DSA)
  SLH-DSA-SHA2 variants (Levels 1, 3, 5)
```

Quick reference to the NIST-standardized PQC algorithms you should migrate to.

#### Specific Recommendations

```
RECOMMENDATIONS
---------------
1. URGENT: Migrate critical assets before 2030
   - Replace MD5/SHA-1 with SHA-256 or SHA3-256
   - Retire RSA-1024 immediately (vulnerable to classical attacks)
   - Replace RC4, DES, 3DES with AES-256-GCM

2. HIGH PRIORITY: Plan migration for assets (2030-2035)
   - RSA-2048 -> ML-DSA-65 (Dilithium3)
   - ECDSA-P256 -> ML-DSA-65 (Dilithium3)
   - ECDH-P256 -> ML-KEM-768 (Kyber768)

3. TRANSITIONAL: Consider hybrid modes for gradual migration
   - X25519-ML-KEM-768 for key exchange
   - P256-ML-DSA-65 for signatures
```

Actionable recommendations with specific replacement algorithms for each vulnerability category.

#### Risk Assessment Matrix

```
RISK ASSESSMENT MATRIX
----------------------
| Break Year      | Assets   | Priority Level          |
|-----------------|----------|-------------------------|
| 2030 (CRITICAL) |        7 | IMMEDIATE ACTION        |
| 2035 (HIGH)     |        4 | PLAN NOW                |
| 2040 (MEDIUM)   |        0 | MONITOR CLOSELY         |
| 2045+ (LOW)     |        0 | LONG-TERM PLANNING      |
```

Visual summary of your risk exposure by timeline.

#### PQC Readiness Score

```
PQC READINESS SCORE
-------------------
Overall Score: 57.1 / 100
Rating: MODERATE - Significant migration needed
```

A single numeric score (0-100) representing your organization's quantum readiness:

| Score | Rating | Meaning |
|-------|--------|---------|
| 90-100 | Excellent | Minimal migration needed |
| 70-89 | Good | Some migration needed |
| 50-69 | Moderate | Significant migration needed |
| 30-49 | Poor | Extensive migration required |
| 0-29 | Critical | Urgent action required |

#### Phased Migration Action Plan

```
MIGRATION ACTION PLAN
---------------------
PHASE 0 (2024-2027): CRITICAL ASSETS
  Scope: 7 assets requiring immediate migration
  Timeline: Complete by 2027
  Actions:
    - Audit all MD5, SHA-1, RC4, DES usage
    - Replace with SHA-256, AES-256-GCM
    - Retire RSA-1024 certificates and keys
  Priority: CRITICAL

PHASE 1 (2027-2030): HIGH PRIORITY ASSETS
  Scope: 4 assets (RSA-2048, ECDSA-P256)
  Timeline: Complete by 2030
  Actions:
    - Deploy hybrid RSA-2048 + ML-DSA-65
    - Transition ECDH-P256 to X25519-ML-KEM-768
  Priority: HIGH
```

Detailed phase-by-phase migration plan with specific actions, timelines, and scope for each phase.

#### Compliance References

```
COMPLIANCE & GOVERNANCE
-----------------------
Regulatory Requirements:
  - NIST SP 800-131A: Transition away from deprecated algorithms
  - NSA CNSA 2.0: Quantum-resistant algorithms by 2035
  - FIPS 140-3: Approved PQC algorithms in cryptographic modules
```

References to relevant compliance frameworks and deadlines.

---

## Interpreting Results

### Readiness Score

The PQC readiness score (0-100%) is calculated as:

```
score = (SAFE×100 + TRANSITIONAL×50 + DEPRECATED×20 + UNSAFE×0) / total
```


### High Readiness Score (80-100%)

Most assets are SAFE or have long migration timelines. Continue monitoring PQC standards.

### Medium Readiness Score (50-79%)

Typical for current environments. Most assets are TRANSITIONAL with 2035+ break years. Begin planning migrations.

### Low Readiness Score (0-49%)

Significant exposure to deprecated or unsafe algorithms. Prioritize:
1. Replace all DEPRECATED assets immediately
2. Migrate UNSAFE assets within 12 months
3. Create roadmap for TRANSITIONAL assets

---

## Algorithm Classification Reference

### Quantum-Safe (SAFE)

| Algorithm | Type | Notes |
|-----------|------|-------|
| ML-KEM-512/768/1024 | Key encapsulation | NIST FIPS 203 |
| ML-DSA-44/65/87 | Digital signature | NIST FIPS 204 |
| SLH-DSA | Digital signature | NIST FIPS 205 |
| AES-256 | Symmetric cipher | 128-bit post-quantum security |
| SHA-256/384/512 | Hash | Collision-resistant |
| SHA3-256/384/512 | Hash | Keccak-based |
| ChaCha20-Poly1305 | AEAD | 256-bit key |

### Transitional

| Algorithm | Type | Break Year |
|-----------|------|------------|
| RSA-2048 | Signature/Encryption | 2035 |
| RSA-3072 | Signature/Encryption | 2040 |
| RSA-4096 | Signature/Encryption | 2045 |
| ECDSA-P256 | Signature | 2035 |
| ECDSA-P384 | Signature | 2040 |
| Ed25519 | Signature | 2035 |
| X25519 | Key exchange | 2035 |
| AES-128 | Symmetric cipher | Post-quantum secure* |

*AES-128 provides 64-bit post-quantum security under Grover's algorithm.

### Deprecated

| Algorithm | Type | Issue |
|-----------|------|-------|
| MD5 | Hash | Collision attacks |
| SHA-1 | Hash | Collision attacks |
| RC4 | Stream cipher | Multiple breaks |
| DES | Block cipher | 56-bit key |
| 3DES | Block cipher | Meet-in-middle attacks |

### Unsafe

| Algorithm | Type | Issue |
|-----------|------|-------|
| RSA-1024 | Signature/Encryption | Factorable today |
| DSA | Signature | Implementation vulnerabilities |
| ECDSA-P192 | Signature | Insufficient security margin |
| DH-1024 | Key exchange | Precomputation attacks |

---

## Example Workflow

### Generate CBOM with PQC Report

```bash
./cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx \
    --cyclonedx-spec 1.7 \
    --pqc-report /tmp/migration-report.txt \
    --output /tmp/system-cbom.json \
    /usr /etc
```

### Query PQC Statistics from CBOM

```bash
# View readiness score
cat /tmp/system-cbom.json | jq '.metadata.properties[] |
    select(.name | startswith("cbom:pqc"))'

# Count unsafe algorithms
cat /tmp/system-cbom.json | jq '[.components[] |
    select(.properties[]? |
        select(.name == "cbom:pqc:status" and .value == "UNSAFE"))] | length'

# List all critical migrations needed
cat /tmp/system-cbom.json | jq '.components[] |
    select(.properties[]? |
        select(.name == "cbom:pqc:migration_urgency" and .value == "CRITICAL")) |
    {name, status: .properties[] | select(.name == "cbom:pqc:status") | .value}'
```

### View Migration Report Summary

```bash
# View the readiness score
grep "Overall Score" /tmp/migration-report.txt

# Count critical assets
grep "CRITICAL" /tmp/migration-report.txt | head -5

# View recommendations
sed -n '/RECOMMENDATIONS/,/SUMMARY/p' /tmp/migration-report.txt
```

---

## Using the Report for Compliance

The PQC migration report can be used for:

1. **Executive Briefings**: The summary statistics and readiness score provide management-level visibility
2. **Compliance Audits**: Demonstrates awareness and planning for post-quantum requirements
3. **Budget Justification**: Quantifies the scope of migration work needed
4. **Project Planning**: The phased action plan provides a starting point for migration projects
5. **Risk Assessment**: The risk matrix supports enterprise risk management processes

---

## See Also

- [NSA CNSA 2.0 Suite](https://media.defense.gov/2025/May/30/2003728741/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS.PDF) - Official guidance
- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography) - Standards development
- [NIST IR 8413](https://csrc.nist.gov/publications/detail/nistir/8413/final) - PQC assessment methodology
- [CISA Post-Quantum Initiative](https://www.cisa.gov/quantum) - Federal guidance


---
<script>
document.addEventListener('DOMContentLoaded', function() {
  var links = document.querySelectorAll('a');
  for (var i = 0; i < links.length; i++) {
    if (links[i].hostname !== window.location.hostname) {
      links[i].target = '_blank';
      links[i].rel = 'noopener noreferrer';
    }
  }
});
</script>