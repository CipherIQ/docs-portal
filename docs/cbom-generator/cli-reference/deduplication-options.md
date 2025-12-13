---
hide:
  - toc
---
# Deduplication Options

Control how duplicate cryptographic assets are handled.

---

### `--dedup-mode MODE`

Control duplicate asset handling.

**Values**:

| Mode | Description |
|------|-------------|
| `off` | No deduplication (legacy behavior) |
| `safe` | Deduplicate certificates, keys, OpenPGP (default, recommended) |
| `strict` | Safe mode + bundle modeling + relationship pruning |

```bash
# Safe deduplication (default)
./build/cbom-generator --dedup-mode=safe --output cbom.json

# No deduplication (all files reported separately)
./build/cbom-generator --dedup-mode=off --output cbom.json

# Strict deduplication with bundle modeling
./build/cbom-generator --dedup-mode=strict --emit-bundles --output cbom.json
```

**Deduplication Behavior**:

### Safe Mode (Default)

Same certificate found in multiple locations becomes a single component with multiple evidence entries:

```json
{
  "name": "DigiCert Global Root CA",
  "evidence": {
    "occurrences": [
      {"location": "/etc/ssl/certs/DigiCert_Global_Root_CA.pem"},
      {"location": "/usr/share/ca-certificates/DigiCert_Global_Root_CA.crt"}
    ]
  }
}
```

### Strict Mode

Bundles similar components (e.g., all system CA certificates become a single bundle).

---

### `--emit-bundles`

Emit bundle components when using `--dedup-mode=strict`.

```bash
# Strict mode with bundles
./build/cbom-generator --dedup-mode=strict --emit-bundles --output cbom.json
```

**Bundle Example**:

```json
{
  "type": "cryptographic-asset",
  "name": "System CA Bundle",
  "description": "System root certificate authority bundle",
  "components": [
    {"ref": "cert-digicert-global-root-ca"},
    {"ref": "cert-isrg-root-x1"},
    {"ref": "cert-globalsign-root-ca"}
  ]
}
```

---

## Choosing a Mode

| Use Case | Recommended Mode |
|----------|------------------|
| General scanning | `safe` (default) |
| Compliance audits | `safe` |
| Debugging/investigation | `off` |
| Large enterprise scans | `strict --emit-bundles` |
| Minimal output size | `strict --emit-bundles` |

**Note**: Safe mode provides the best balance of accuracy and readability for most use cases.
