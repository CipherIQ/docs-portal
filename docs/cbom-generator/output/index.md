---
hide:
  - toc
---
# CycloneDX CBOM Output

Understanding the CBOM Generator output format.


## Top-Level Structure

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:...",
  "version": 1,
  "metadata": { /* Tool, host, provenance */ },
  "components": [ /* Array of cryptographic assets */ ],
  "dependencies": [ /* Provider/consumer graph */ ],
  "relationships": [ /* Typed edges with confidence */ ],
  "pqc_assessment": { /* PQC readiness analysis */ },
  "scan_completion_pct": 92,
  "completion": { /* Scanner completeness */ },
  "errors": [ /* Non-fatal issues */ ]
}
```

---

## Key Sections

| Section | Description |
|---------|-------------|
| [Components](components.md) | Cryptographic assets discovered |
| [Crypto Properties](crypto-properties.md) | CycloneDX CBOM-specific fields |
| [Namespaced Properties](namespaced-properties.md) | cbom:* extended properties |
| [Dependencies](dependencies.md) | Provider/consumer relationships |
| [Relationships](relationships.md) | Typed edges with confidence |

---

## Output Formats

| Format | Version | Description |
|--------|---------|-------------|
| CycloneDX 1.6 | Default | Maximum compatibility |
| CycloneDX 1.7 | `--cyclonedx-spec 1.7` | Latest spec, enhanced dependencies |

Both formats produce similar content. Key differences:

- `specVersion` field: `"1.6"` vs `"1.7"`
- Schema validation: against respective CycloneDX schemas

---

## Metadata Section

```json
{
  "metadata": {
    "timestamp": "2025-12-04T12:00:00Z",
    "tools": [{
      "vendor": "Graziano Labs Corp.",
      "name": "cbom-generator",
      "version": "1.9.0"
    }],
    "properties": [
      {"name": "cbom:total_components", "value": "150"},
      {"name": "cbom:pqc_readiness_percent", "value": "4.9"},
      {"name": "cbom:scan_paths", "value": "/usr/sbin,/etc"}
    ],
    "privacy": {
      "no_personal_data": true,
      "redaction_applied": true,
      "compliance": ["GDPR", "CCPA"]
    },
    "provenance": {
      "git_commit": "abc123...",
      "compiler": "GCC 11.4.0",
      "openssl_version": "3.0.2",
      "build_timestamp": "2025-11-09T15:00:00Z"
    }
  }
}
```

---

## Quick Reference

### Finding All Certificates

```bash
cat cbom.json | jq '.components[] |
    select(.cryptoProperties?.assetType == "certificate") |
    .name'
```

### Counting Components by Type

```bash
cat cbom.json | jq '[.components[] | .cryptoProperties?.assetType] |
    group_by(.) |
    map({type: .[0], count: length})'
```

### Viewing Dependencies

```bash
cat cbom.json | jq '.dependencies[] | select(.ref | startswith("service:"))'
```
