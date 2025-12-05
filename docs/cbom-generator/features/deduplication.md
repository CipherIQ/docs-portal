# Deduplication

Control how duplicate cryptographic assets are handled in the CBOM output.

---

## Deduplication Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **OFF** | No deduplication | Forensic analysis, exact file tracking |
| **SAFE** | Smart deduplication (default) | Most production scans |
| **STRICT** | Aggressive with bundles | Enterprise scans, minimal output |

---

## OFF Mode

Legacy behavior with no deduplication:

- Same certificate found in 3 files → 3 separate components
- Every occurrence is a distinct component
- Largest output size

```bash
./build/cbom-generator --dedup-mode=off --output cbom.json
```

**Use when**:
- Forensic analysis requiring exact file locations
- Debugging duplicate detection
- Compliance requiring per-file tracking

---

## SAFE Mode (Default, Recommended)

Smart deduplication with evidence tracking:

- Same certificate in 3 files → 1 component with 3 evidence occurrences
- Applies to: Certificates, keys, OpenPGP keys
- Preserves all location information

```bash
./build/cbom-generator --dedup-mode=safe --output cbom.json
```

**Output example**:

```json
{
  "name": "DigiCert Global Root CA",
  "bom-ref": "cert:digicert-global-root-ca-sha256:abc123",
  "evidence": {
    "occurrences": [
      {"location": "/etc/ssl/certs/DigiCert_Global_Root_CA.pem"},
      {"location": "/usr/share/ca-certificates/DigiCert_Global_Root_CA.crt"},
      {"location": "/etc/pki/tls/certs/ca-bundle.crt"}
    ]
  }
}
```

**Benefits**:
- Single component per unique certificate
- All locations preserved in evidence
- Balanced output size and detail

---

## STRICT Mode

Aggressive deduplication with bundle modeling:

- Safe mode features plus bundle grouping
- Groups similar components (e.g., all CA certs → single bundle)
- Smallest output size

```bash
./build/cbom-generator --dedup-mode=strict --emit-bundles --output cbom.json
```

**Bundle example**:

```json
{
  "type": "cryptographic-asset",
  "name": "System CA Bundle",
  "description": "System root certificate authority bundle (147 certificates)",
  "components": [
    {"ref": "cert:digicert-global-root-ca"},
    {"ref": "cert:isrg-root-x1"},
    {"ref": "cert:globalsign-root-ca"}
  ]
}
```

---

## `--emit-bundles` Flag

Use with `--dedup-mode=strict` to create bundle components:

```bash
./build/cbom-generator --dedup-mode=strict --emit-bundles --output cbom.json
```

**Without `--emit-bundles`**: Strict mode applies aggressive deduplication but doesn't create explicit bundle components.

---

## Deduplication Statistics

The CBOM includes deduplication metrics:

```json
{
  "properties": [
    { "name": "cbom:dedup:mode", "value": "safe" },
    { "name": "cbom:dedup:total_candidates", "value": "1245" },
    { "name": "cbom:dedup:unique_components", "value": "328" },
    { "name": "cbom:dedup:duplicates_merged", "value": "917" }
  ]
}
```

---

## Choosing a Mode

| Scenario | Recommended Mode |
|----------|------------------|
| General production scanning | `safe` (default) |
| Compliance audit | `safe` |
| Security investigation | `off` |
| Large enterprise scan | `strict --emit-bundles` |
| Minimal output for CI/CD | `strict --emit-bundles` |
| Exact file tracking | `off` |

---

## How Deduplication Works

1. **Content Hashing**: SHA-256 hash of certificate/key content
2. **Identity Check**: Same hash = same cryptographic asset
3. **Evidence Merging**: All locations stored in evidence array
4. **First-Wins**: First occurrence's metadata is preserved

**Example flow**:
```
/etc/ssl/certs/ca-certificates.crt  (contains 147 certs)
    ↓ Parse and hash each certificate
/etc/ssl/certs/DigiCert.pem         (symlink to single cert)
    ↓ Hash matches cert #42 from bundle
    → Merge: Add location to cert #42's evidence
    → Skip: Don't create duplicate component
```
