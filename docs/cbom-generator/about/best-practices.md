# Best Practices

Recommended usage patterns for CBOM Generator.

---

## Privacy Mode

**Always use privacy mode for external sharing:**

```bash
./build/cbom-generator --no-personal-data --output audit-cbom.json
```

This ensures:
- Hostnames redacted
- Usernames redacted
- File paths anonymized
- GDPR/CCPA compliance

---

## Deduplication

**Use safe deduplication for production scans:**

```bash
./build/cbom-generator --dedup-mode=safe --output cbom.json
```

Benefits:
- Single component per unique certificate
- All locations preserved in evidence
- Balanced output size and detail

---

## CycloneDX Format

**Use CycloneDX for interoperability:**

```bash
./build/cbom-generator --format cyclonedx --cyclonedx-spec 1.7 --output cbom.json
```

- Industry standard format
- Tool ecosystem compatibility
- Full CBOM extension support

---

## CBOM_SALT

**Set consistent salt for reproducible pseudonyms:**

```bash
export CBOM_SALT="organization-specific-salt-value"
./build/cbom-generator --no-personal-data --output cbom.json
```

This allows:
- Consistent pseudonyms across scans
- Cross-organization correlation
- Reproducible results

---

## Schema Validation

**Validate output against CycloneDX schema:**

```bash
# Generate CBOM
./build/cbom-generator --output cbom.json

# Validate
cyclonedx validate --input cbom.json
```

---

## Service Discovery

**Enable service discovery for complete inventory:**

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output cbom.json
```

This captures:
- Running services
- TLS/SSH configurations
- Protocol and cipher suite details

---

## Error Logging

**Use error logging with TUI mode:**

```bash
./build/cbom-generator \
    --tui \
    --error-log /tmp/cbom-errors.log \
    --output cbom.json
```

TUI suppresses stderr, so error log is essential for debugging.

---

## Deterministic Output

**Keep deterministic mode enabled (default):**

```bash
./build/cbom-generator --deterministic --output cbom.json
```

Enables:
- CI/CD change detection
- CBOM comparison over time
- Reproducible results

---

## Cross-Architecture Scanning

**Use cross-arch mode for embedded systems:**

```bash
./build/cbom-generator \
    --cross-arch \
    --crypto-registry crypto-registry-yocto.yaml \
    --plugin-dir plugins/embedded \
    --output rootfs-cbom.json \
    /path/to/rootfs
```

---

## Regular Scanning

**Schedule regular scans for monitoring:**

```bash
# Weekly scan
0 0 * * 0 ./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --no-personal-data \
    --output /var/cbom/cbom-$(date +%Y%m%d).json
```

---

## PQC Migration

**Generate migration reports for planning:**

```bash
./build/cbom-generator \
    --pqc-report migration-plan.txt \
    --output cbom.json
```

Review break year distribution and prioritize migrations.
