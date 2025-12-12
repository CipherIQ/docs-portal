---
hide:
  - toc
---
# Non-Deterministic Output

Troubleshooting when identical scans produce different output.


## Symptoms

- SHA-256 hash of output differs between runs
- File order changes between scans
- CI/CD change detection triggers falsely

---

## Expected Determinism

By default, CBOM Generator produces **deterministic output**:

- Same input → identical JSON (byte-for-byte)
- Component order sorted alphabetically
- Timestamps excluded in deterministic mode
- Thread count doesn't affect output content

---

## Common Causes of Non-Determinism

### 1. Deterministic Mode Disabled

**Problem**: Running with `--no-deterministic`.

**Solution**: Use deterministic mode (default):

```bash
# Deterministic (default)
./build/cbom-generator --deterministic --output cbom.json

# Or simply omit the flag
./build/cbom-generator --output cbom.json
```

### 2. Different Input Files

**Problem**: Files changed between scans.

**Solution**: Ensure identical input:

```bash
# Compare file listings
find /etc/ssl -type f | sort > files-before.txt
# ... run scan ...
find /etc/ssl -type f | sort > files-after.txt
diff files-before.txt files-after.txt
```

### 3. Different CBOM_SALT

**Problem**: Privacy redaction salt differs between runs.

**Solution**: Set consistent salt:

```bash
export CBOM_SALT="consistent-salt-value"
./build/cbom-generator --no-personal-data --output cbom.json
```

### 4. Service State Changes

**Problem**: Running services changed between scans.

**Solution**: For reproducible results, don't use `--discover-services` or ensure services are in consistent state.

---

## Verifying Determinism

### Test 1: Identical Runs

```bash
./build/cbom-generator --output run1.json /etc/ssl/certs
./build/cbom-generator --output run2.json /etc/ssl/certs

# Compare
diff run1.json run2.json
# Should show no differences

# Or compare hashes
sha256sum run1.json run2.json
# Should be identical
```

### Test 2: Thread Invariance

```bash
./build/cbom-generator --threads 1 --output single.json /etc/ssl/certs
./build/cbom-generator --threads 4 --output multi.json /etc/ssl/certs

diff single.json multi.json
# Should show no differences
```

---

## CI/CD Integration

### Comparing CBOMs

```bash
# Generate current CBOM
./build/cbom-generator --deterministic --output current.json

# Compare with baseline (ignore timestamps if needed)
cat baseline.json | jq 'del(.metadata.timestamp)' > baseline-no-ts.json
cat current.json | jq 'del(.metadata.timestamp)' > current-no-ts.json
diff baseline-no-ts.json current-no-ts.json
```

### Change Detection

```bash
# Calculate hash for comparison
sha256sum cbom.json | cut -d' ' -f1 > cbom.hash

# In CI, compare with previous hash
if ! diff cbom.hash previous-cbom.hash; then
    echo "CBOM changed - review required"
    exit 1
fi
```

---

## Timestamps in Output

Deterministic mode excludes variable timestamps:

| Field | Deterministic | Non-Deterministic |
|-------|---------------|-------------------|
| `metadata.timestamp` | Excluded | Included |
| Epoch timestamps | Excluded | Included |
| Serial number | Deterministic UUID | Random UUID |

---

## Debugging Non-Determinism

### Identify Differences

```bash
# JSON diff showing specific changes
diff <(cat run1.json | jq -S .) <(cat run2.json | jq -S .)
```

### Check Sorting

```bash
# Verify components are sorted
cat cbom.json | jq '[.components[].name]' | head -20
```

### Verify Serial Number

```bash
# Deterministic serial numbers based on content hash
cat run1.json | jq '.serialNumber'
cat run2.json | jq '.serialNumber'
# Should be identical for identical content
```
