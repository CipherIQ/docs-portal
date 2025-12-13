---
hide:
  - toc
---
# Privacy Options

Control personal data handling for GDPR/CCPA compliance.


### `--no-personal-data (Default: ON)`

Redact personal data for GDPR/CCPA compliance.

**What is redacted**:

| Data Type | Original | Redacted |
|-----------|----------|----------|
| Hostnames | `myserver.example.com` | `<host-hash-XXXXXXXX>` |
| Home directories | `/home/alice/.ssh` | `<path-hash-XXXXXXXX>` |
| Usernames | `alice` | salted hashes |

```bash
# Privacy mode (default)
./build/cbom-generator --no-personal-data --output cbom.json

# Explicitly enable (same as default)
./build/cbom-generator --no-personal-data --output cbom.json
```

---

### `--include-personal-data`

Include hostnames, usernames, full file paths, and scan user SSH configurations.

**What this enables**:

- Hostnames in metadata (instead of `<host-hash-XXXXXXXX>`)
- Usernames in file paths (instead of `<user-username>`)
- Full home directory paths (instead of `<path-hash-XXXXXXXX>`)
- **User SSH config scanning** (~/.ssh/config for all users in /home/*)

**Use when**: Internal scans, debugging, or when GDPR/CCPA doesn't apply.

```bash
# Include all personal data + user SSH configs
./build/cbom-generator --include-personal-data --output cbom-full.json
```

!!!warning
    Output may contain sensitive information. Use appropriate access controls.

**Note**: User SSH config scanning is privacy-sensitive because it:

- Accesses user home directories
- Reveals individual user cryptographic preferences
- May expose non-public KEX algorithm choices

---

### `--no-network`

Disable network operations.

**Status**: This flag is accepted and recorded in output metadata, but has no functional effect in v1.0 because network operations are not yet implemented.

**Planned for v2.0+**:

- OCSP (Online Certificate Status Protocol) validation
- CRL (Certificate Revocation List) checking
- Remote NIST CMVP certification database queries
- Network-based trust validation

**Current behavior**: Flag is stored in metadata and sets `revocation_policy` to "disabled" vs "cache-only" in output, but no actual network operations occur regardless of flag value.

```bash
# Flag accepted but has no effect in v1.0
./build/cbom-generator --no-network --output cbom.json

# Combine with privacy mode (both metadata-only in v1.0)
./build/cbom-generator --no-personal-data --no-network --output cbom.json
```
