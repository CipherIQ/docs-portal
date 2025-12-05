# Output Format Reference

CycloneDX format specification details.

---

## Supported Formats

CBOM Generator outputs CycloneDX format only:

| Format | Specification | CLI Flag |
|--------|---------------|----------|
| CycloneDX 1.6 | Default | `--cyclonedx-spec 1.6` or omit |
| CycloneDX 1.7 | Latest | `--cyclonedx-spec 1.7` |

---

## CycloneDX 1.6 vs 1.7

Both versions produce similar content:

| Feature | 1.6 | 1.7 |
|---------|-----|-----|
| `specVersion` | `"1.6"` | `"1.7"` |
| Schema validation | CycloneDX 1.6 schema | CycloneDX 1.7 schema |
| Tool compatibility | Wider | Growing |
| Dependencies array | Supported | Enhanced |

**Recommendation**: Use 1.6 for maximum compatibility. Use 1.7 when you need full dependency graph features.

---

## JSON Structure

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:...",
  "version": 1,
  "metadata": {},
  "components": [],
  "dependencies": [],
  "relationships": []
}
```

---

## Schema Validation

Validate output against CycloneDX schema:

```bash
# Using cyclonedx-cli
cyclonedx validate --input cbom.json

# Using ajv
ajv validate -s bom-1.6.schema.json -d cbom.json
```

Schema files available at:
- https://cyclonedx.org/schema/bom-1.6.schema.json
- https://cyclonedx.org/schema/bom-1.7.schema.json

---

## CBOM Extensions

CBOM Generator uses standard CycloneDX fields plus namespaced properties:

### Standard CycloneDX Fields

- `type`: Component type
- `name`: Component name
- `bom-ref`: Unique identifier
- `version`: Version string
- `cryptoProperties`: CBOM crypto details

### CBOM Namespaced Properties

Properties prefixed with `cbom:` provide extended detail:

- `cbom:pqc:*` - PQC assessment
- `cbom:cert:*` - Certificate details
- `cbom:key:*` - Key details
- `cbom:proto:*` - Protocol details
- `cbom:ctx:*` - Detection context

---

## Output Determinism

With `--deterministic` (default):

- Component order: Sorted alphabetically
- Property order: Consistent
- Timestamps: Excluded
- Serial number: Content-based UUID

---

## File Size Estimates

| Scan Type | Components | File Size |
|-----------|------------|-----------|
| /etc/ssl/certs only | ~200 | ~500KB |
| System scan | ~500-1000 | ~1-2MB |
| With services | ~500-2000 | ~2-5MB |
| Enterprise | ~5000+ | ~10MB+ |

Use `--dedup-mode=strict` to reduce size.
