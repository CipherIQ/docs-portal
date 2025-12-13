---
hide:
  - toc
---
# Output Options

Control where and how CBOM output is generated.


### `-o, --output FILE`

Specify output file path (default: stdout).

```bash
# Write to file
./build/cbom-generator --output /tmp/cbom.json

# Write to stdout (default)
./build/cbom-generator > cbom.json
```

---

### `-f, --format FORMAT`

Output format selection.

**Values**: `json`, `cyclonedx` (both produce identical CycloneDX output)

**Note**: This flag is accepted for backward compatibility but has no effect. The generator always outputs CycloneDX format regardless of this flag's value.

```bash
# All of these produce identical CycloneDX output:
./build/cbom-generator --output cbom.json
./build/cbom-generator --format json --output cbom.json
./build/cbom-generator --format cyclonedx --output cbom.json
```

---

### `--cyclonedx-spec VERSION`

CycloneDX specification version.

**Values**: `1.6` (default), `1.7`

```bash
# CycloneDX 1.6 (default, maximum compatibility)
./build/cbom-generator --output cbom.json

# CycloneDX 1.7 (latest spec with dependencies array)
./build/cbom-generator --cyclonedx-spec=1.7 --output cbom.json
```


**Note**: Both versions produce similar content. Key differences:

| Feature | 1.6 | 1.7 |
|---------|-----|-----|
| `specVersion` field | `"1.6"` | `"1.7"` |
| Dependencies array | Supported | Enhanced |
| Tools compatibility | Wider | Limited |

**Recommendation**: Use `1.7` for the full dependency graph. Use `1.6` only for maximum compatibility with existing tools. 
