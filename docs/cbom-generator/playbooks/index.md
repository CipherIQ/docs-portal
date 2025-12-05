# Playbooks

Step-by-step migration guides for common cryptographic transitions.

---

## Available Playbooks

| Playbook | Description |
|----------|-------------|
| [OpenSSH PQC Migration](migrating-openssh.md) | Enable Post-Quantum key exchange in SSH |
| [TLS Upgrade Guide](tls-upgrade.md) | Migrate from TLS 1.0/1.1 to TLS 1.3 |
| [Certificate Rotation](certificate-rotation.md) | Plan and execute certificate lifecycle |
| [FIPS Compliance](fips-compliance.md) | Validate FIPS 140-2/3 compliance |

---

## Using CBOM Generator with Playbooks

Each playbook follows this pattern:

1. **Assess**: Run CBOM scan to establish baseline
2. **Plan**: Identify components needing migration
3. **Execute**: Make configuration changes
4. **Verify**: Re-scan to confirm improvements

---

## Common Commands

### Baseline Scan

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --pqc-report baseline-report.txt \
    --output baseline-cbom.json
```

### Verification Scan

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --pqc-report after-migration-report.txt \
    --output after-migration-cbom.json
```

### Compare Before/After

```bash
# Compare PQC readiness scores
cat baseline-cbom.json | jq '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score")'
cat after-migration-cbom.json | jq '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score")'
```

---

## Migration Priority Framework

| Priority | Break Year | Action Timeline |
|----------|------------|-----------------|
| CRITICAL | 2030 | Immediate (within 6 months) |
| HIGH | 2035 | Plan now (within 12 months) |
| MEDIUM | 2040 | Schedule (within 24 months) |
| LOW | 2045+ | Monitor (plan for future) |
