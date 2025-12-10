---
hide:
  - toc
---
# Privacy Controls

The CBOM Generator implements privacy-by-default for GDPR/CCPA compliance.


## Privacy-by-Default

Personal data is automatically redacted unless `--include-personal-data` is specified.

### What is Redacted

| Data Type | Original | Redacted |
|-----------|----------|----------|
| Hostnames | `myserver.example.com` | `<host-hash-XXXXXXXX>` |
| Usernames | `alice` | `<user-alice>` |
| Home directories | `/home/alice/.ssh` | `<path-hash-XXXXXXXX>` |
| User paths | `/home/bob/certs` | `<path-hash-XXXXXXXX>` |

### What is NOT Redacted

- System paths (`/etc`, `/usr`, `/var`)
- Algorithm names and OIDs
- Certificate subjects/issuers (already pseudonymous)
- Cryptographic properties
- Package names and versions

---

## Redaction Method

CBOM Generator uses salted hashing for consistent pseudonymization:

1. **Salted Hashing**: Uses `CBOM_SALT` environment variable
2. **Consistency**: Same input produces same pseudonym across runs
3. **Entropy Validation**: Requires ≥128 bits entropy

```bash
# Set custom salt for reproducible pseudonyms
export CBOM_SALT="my-organization-specific-salt-value"
./build/cbom-generator --no-personal-data --output cbom.json
```
>NOTE: User defined salt will be implemented in v2.0

---

## Privacy Metadata

The output includes privacy documentation:

```json
{
  "metadata": {
    "privacy": {
      "no_personal_data": true,
      "redaction_applied": true,
      "methods": ["hostname_redaction", "path_redaction", "username_redaction"],
      "compliance": ["GDPR", "CCPA"],
      "mode": "privacy-by-default"
    }
  }
}
```

---

## CLI Options

### `--no-personal-data` (Default: ON)

Enables privacy redaction.

```bash
./build/cbom-generator --no-personal-data --output cbom.json
```

### `--include-personal-data`

Disables privacy redaction for internal scans.

```bash
./build/cbom-generator --include-personal-data --output cbom-full.json
```

**Warning**: Output may contain sensitive information. Use appropriate access controls.

---

## User SSH Configuration

User SSH configs (`~/.ssh/config`) are only scanned with `--include-personal-data`:

| Mode | User SSH Configs |
|------|------------------|
| `--no-personal-data` | Not scanned |
| `--include-personal-data` | Scanned for all users in /home/* |

**Rationale**: User SSH configs reveal:

- Individual cryptographic preferences
- Non-public KEX algorithm choices
- Personal security configurations

---

## Compliance

### GDPR Compliance

- **Article 25**: Privacy by design (default redaction)
- **Article 4(5)**: Pseudonymization (salted hashing)
- **Article 89**: Research safeguards (consistent pseudonyms)

### CCPA Compliance

- **1798.100(c)**: De-identified data requirements
- **1798.140(h)**: Pseudonymization standards

---

## Use Cases

### External Sharing

```bash
# Safe for sharing with third parties
./build/cbom-generator --no-personal-data --output audit-cbom.json
```

### Internal Investigation

```bash
# Full details for internal security team
./build/cbom-generator --include-personal-data --output internal-cbom.json
```

### Cross-Organization Analysis

```bash
# Same salt across organization for correlation
export CBOM_SALT="org-wide-consistent-salt"
./build/cbom-generator --no-personal-data --output team-a-cbom.json
```
