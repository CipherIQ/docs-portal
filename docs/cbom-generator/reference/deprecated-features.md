# Deprecated Features

Migration guidance for deprecated functionality.

---

## Deprecated in v1.1

### Epoch Timestamps

**Deprecated**: `cbom:cert:not_before_epoch`, `cbom:cert:not_after_epoch`

**Replacement**: Use ISO-8601 timestamps in `cryptoProperties.certificateProperties`:

```json
// Deprecated
{
  "name": "cbom:cert:not_before_epoch",
  "value": "1577836800"
}

// Use instead
{
  "cryptoProperties": {
    "certificateProperties": {
      "notValidBefore": "2020-01-01T00:00:00Z",
      "notValidAfter": "2030-01-01T00:00:00Z"
    }
  }
}
```

**Reason**: ISO-8601 is human-readable and CycloneDX standard.

---

## Deprecated in v1.7

### `--no-package-resolution`

**Deprecated**: `--no-package-resolution` flag

**Replacement**: Use `--cross-arch`:

```bash
# Deprecated
./build/cbom-generator --no-package-resolution --output cbom.json

# Use instead
./build/cbom-generator --cross-arch --output cbom.json
```

**Reason**: `--cross-arch` provides clearer semantics and enables VERNEED version detection.

---

## Vestigial Flags

These flags are accepted for backward compatibility but have no effect:

### `--format json`

**Status**: Accepted, no effect

**Behavior**: All output is CycloneDX format regardless of this flag.

```bash
# These produce identical output
./build/cbom-generator --format json --output cbom.json
./build/cbom-generator --format cyclonedx --output cbom.json
./build/cbom-generator --output cbom.json
```

### `--no-network`

**Status**: Accepted, recorded in metadata, no functional effect in v1.0

**Planned for v1.1+**: Will control OCSP, CRL, and NIST CMVP validation.

---

## Removed Features

None. All features from v1.0 remain available.

---

## Migration Path

### For v1.0 → v1.1+

1. Update any scripts parsing epoch timestamps to use ISO-8601
2. Replace `--no-package-resolution` with `--cross-arch`
3. No action needed for vestigial flags (still accepted)

### Compatibility Mode

Deprecated features remain functional for at least 2 minor versions after deprecation notice.
