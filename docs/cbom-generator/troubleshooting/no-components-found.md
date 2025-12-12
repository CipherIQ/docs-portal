---
hide:
  - toc
---
# No Components Found

Troubleshooting when CBOM Generator returns empty or minimal results.


## Symptoms

- Output contains 0 or very few components
- Expected certificates/keys not detected
- Services not discovered

---

## Common Causes

### 1. Scanning Wrong Directory

**Problem**: Scanning a directory without cryptographic assets.

**Solution**: Scan system directories containing crypto:

```bash
# Recommended paths
./build/cbom-generator --output cbom.json /etc/ssl /etc/pki /usr/share/ca-certificates /etc/ssh

# Or scan broader system paths
./build/cbom-generator --output cbom.json /etc /usr/lib
```

### 2. Permission Issues

**Problem**: Scanner cannot read files.

**Solution**: Run with appropriate permissions:

```bash
# Check access
ls -la /etc/ssl/private/

# Run as root for full access
sudo ./build/cbom-generator --output cbom.json
```

See [Permission Errors](permission-errors.md) for details.

### 3. Service Discovery Not Enabled

**Problem**: Services not detected because `--discover-services` not used.

**Solution**: Enable service discovery:

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --output cbom.json
```

### 4. Cross-Architecture Mode Misconfigured

**Problem**: Scanning embedded rootfs without `--cross-arch`.

**Solution**: Enable cross-arch mode for Yocto/Buildroot:

```bash
./build/cbom-generator \
    --cross-arch \
    --output cbom.json \
    /path/to/rootfs/usr/bin /path/to/rootfs/etc
```

---

## Diagnostic Steps

### Step 1: Check Error Log

```bash
./build/cbom-generator --error-log /tmp/errors.log --output cbom.json /etc/ssl
cat /tmp/errors.log
```

### Step 2: Check Scan Statistics

```bash
cat cbom.json | jq '{
    total_components: (.components | length),
    certificates: [.components[] | select(.cryptoProperties?.assetType == "certificate")] | length,
    keys: [.components[] | select(.cryptoProperties?.assetType == "related-crypto-material")] | length,
    algorithms: [.components[] | select(.cryptoProperties?.assetType == "algorithm")] | length
}'
```

### Step 3: Check Diagnostics Metadata

```bash
cat cbom.json | jq '.metadata.properties[] | select(.name | contains("diagnostics"))'
```

### Step 4: Test Individual Directories

```bash
# Test certificates directory
./build/cbom-generator --output /tmp/test-certs.json /etc/ssl/certs
cat /tmp/test-certs.json | jq '.components | length'

# Test keys directory
sudo ./build/cbom-generator --output /tmp/test-keys.json /etc/ssl/private
cat /tmp/test-keys.json | jq '.components | length'
```

---

## Expected Results

For typical Linux systems:

| Directory | Expected Components |
|-----------|---------------------|
| /etc/ssl/certs | 100-200+ certificates |
| /etc/ssl/private | Varies (may need sudo) |
| /etc/ssh | SSH config, host keys |
| /usr/share/ca-certificates | System CA certificates |

---

## Deduplication Behavior

Note: Certificate bundles (like `ca-certificates.crt`) contain many certificates. With deduplication:

- Same certificate in multiple files → 1 component with multiple evidence entries
- ~95% of individual .pem files may be "duplicates" of bundle contents

This is **expected** and correct. Check `evidence.occurrences` array for all locations.
