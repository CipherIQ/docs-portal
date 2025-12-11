---
hide:
  - toc
---
# FIPS Compliance Validation

Validate FIPS 140-2/3 compliance using CBOM Generator.



## Overview

FIPS 140-2/3 (Federal Information Processing Standards) are U.S. government security standards for cryptographic modules. Many organizations require FIPS compliance for:

- Government contracts
- Financial services
- Healthcare (HIPAA)
- Critical infrastructure

---

## Prerequisites

- CBOM Generator installed
- Root access for system scanning
- Understanding of your compliance requirements

---

## Step 1: Scan for FIPS-Certified Libraries

Run comprehensive CBOM scan:

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output fips-assessment.json
```

### Find Libraries with FIPS Status

```bash
cat fips-assessment.json | jq '.components[] |
    select(.type == "library") |
    {name, version,
     fips_status: [.properties[] | select(.name | contains("fips"))][0].value // "NOT_VALIDATED"}'
```

---

## Step 2: Identify Non-Compliant Algorithms

### Find Deprecated Algorithms

```bash
cat fips-assessment.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "DEPRECATED")) |
    {name, reason: [.properties[] | select(.name == "cbom:pqc:rationale")][0].value}'
```

### Check for Banned Algorithms

FIPS prohibits certain algorithms:

| Algorithm | Status | Replacement |
|-----------|--------|-------------|
| MD5 | Banned | SHA-256+ |
| SHA-1 | Deprecated | SHA-256+ |
| DES | Banned | AES |
| 3DES | Limited (2023 cutoff) | AES |
| RC4 | Banned | AES-GCM |
| RSA < 2048 | Banned | RSA-2048+ |

```bash
# Find banned algorithms
cat fips-assessment.json | jq '.components[] |
    select(.name | test("MD5|DES|RC4|SHA-1"; "i")) |
    {name, location: .evidence.occurrences[0].location}'
```

---

## Step 3: Verify Approved Algorithms

### FIPS 140-2/3 Approved Algorithms

| Category | Approved |
|----------|----------|
| Symmetric | AES (128, 192, 256) |
| Hash | SHA-256, SHA-384, SHA-512, SHA-3 |
| Signature | RSA (2048+), ECDSA (P-256+) |
| Key Agreement | ECDH, DH (2048+) |
| MAC | HMAC-SHA-256+ |
| KDF | PBKDF2, HKDF |

```bash
# Count approved vs non-approved
cat fips-assessment.json | jq '
    [.components[] |
     select(.cryptoProperties?.assetType == "algorithm") |
     if (.name | test("AES|SHA-256|SHA-384|SHA-512|ECDSA|RSA-[2-9][0-9]{3}"; "i"))
     then "APPROVED" else "REVIEW" end] |
    group_by(.) |
    map({status: .[0], count: length})'
```

---

## Step 4: Check Service Configurations

### Verify TLS Cipher Suites

FIPS-approved TLS cipher suites:

```bash
cat fips-assessment.json | jq '.components[] |
    select(.["bom-ref"] | startswith("cipher:")) |
    select(.name | test("AES.*GCM|AES.*CBC"; "i")) |
    .name' | sort | uniq
```

### Check SSH Algorithms

```bash
cat fips-assessment.json | jq '.components[] |
    select(.name | test("ssh|sshd"; "i")) |
    {name, ciphers: [.properties[] | select(.name | contains("cipher"))][0].value}'
```

---

## Step 5: Replace Non-Compliant Algorithms

### Update OpenSSL Configuration

For FIPS mode (OpenSSL 3.0+):

```bash
# Enable FIPS provider
sudo nano /etc/ssl/openssl.cnf
```

Add:

```
[provider_sect]
default = default_sect
fips = fips_sect
base = base_sect

[fips_sect]
activate = 1

[base_sect]
activate = 1

[default_sect]
activate = 1
```

### Update Application Configurations

Ensure services use FIPS-approved algorithms only:

**Apache**:
```apache
SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
```

**Nginx**:
```nginx
ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
```

---

## Step 6: Validate Compliance

Re-run CBOM scan:

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output fips-after-remediation.json
```

### Generate Compliance Report

```bash
# Summary statistics
echo "=== FIPS Compliance Summary ==="

echo "Deprecated algorithms:"
cat fips-after-remediation.json | jq '[.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "DEPRECATED"))] | length'

echo "Weak/Unsafe algorithms:"
cat fips-after-remediation.json | jq '[.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "UNSAFE"))] | length'

echo "Approved algorithms:"
cat fips-after-remediation.json | jq '[.components[] |
    select(.cryptoProperties?.assetType == "algorithm") |
    select(.name | test("AES|SHA-256|SHA-384|SHA-512|ECDSA|RSA-[2-9]"; "i"))] | length'
```

---

## Step 7: Generate Audit Report

Create documentation for auditors:

```bash
# Export compliance evidence
cat fips-after-remediation.json | jq '{
    scan_date: .metadata.timestamp,
    total_components: (.components | length),
    libraries: [.components[] | select(.type == "library") | {name, version}],
    algorithms: [.components[] | select(.cryptoProperties?.assetType == "algorithm") | .name] | unique,
    deprecated_count: [.components[] | select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "DEPRECATED"))] | length,
    unsafe_count: [.components[] | select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "UNSAFE"))] | length
}' > fips-audit-report.json
```

---

## NIST CMVP Certification

The NIST Cryptographic Module Validation Program (CMVP) validates cryptographic modules.

### Check for Validated Modules

Visit: [https://csrc.nist.gov/projects/cryptographic-module-validation-program/validated-modules](https://csrc.nist.gov/projects/cryptographic-module-validation-program/validated-modules)

Common validated modules:
- OpenSSL FIPS Provider
- libgcrypt FIPS mode
- AWS-LC FIPS
- NSS FIPS mode

---

## Important Note

The CBOM Generator provides **stub metadata** for FIPS certification status. Actual FIPS validation must be verified against the NIST CMVP database.
