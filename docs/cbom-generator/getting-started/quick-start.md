# Quick Start

Run your first CBOM scan in minutes.

---

## Basic System Scan

```bash
# Scan entire system, output to stdout
./build/cbom-generator

# Save to file
./build/cbom-generator --output my-cbom.json

# Generate CycloneDX format
./build/cbom-generator --format cyclonedx --output cbom.cdx.json
```

---

## Privacy-Compliant Scan

CBOM Generator is **privacy-by-default**. Personal data (hostnames, paths, usernames) is automatically redacted.

```bash
# Privacy mode (default: redacts hostnames, paths, usernames)
./build/cbom-generator --no-personal-data --output cbom.json

# Include full paths (disable redaction)
./build/cbom-generator --include-personal-data --output cbom-full.json
```

---

## PQC Readiness Check

Assess your system's Post-Quantum Cryptography readiness:

```bash
# Generate CBOM with PQC assessment
./build/cbom-generator --format cyclonedx --output pqc-assessment.json

# View PQC readiness score
cat pqc-assessment.json | jq '.metadata.properties[] | select(.name == "cbom:pqc_readiness_percent")'
```

**Understanding the Score**:

| Score | Status | Action |
|-------|--------|--------|
| 0-20% | Critical | Immediate migration needed |
| 20-50% | Poor | Plan migration timeline |
| 50-80% | Good | Continue improvements |
| 80-100% | Excellent | Quantum-safe infrastructure |

---

## Service Discovery

Discover running services and their cryptographic configurations:

```bash
# Enable service discovery with plugins
./build/cbom-generator --discover-services --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 --output services.json
```

This scans:
- Running processes (nginx, apache, sshd, etc.)
- Configuration files (TLS settings, cipher suites)
- Network endpoints (listening ports, protocols)

---

## Scan Specific Directories

Focus on particular areas of your system:

```bash
# Scan /etc for certificates and configs
./build/cbom-generator --output etc-cbom.json /etc

# Scan multiple directories
./build/cbom-generator --output app-cbom.json /usr/sbin /usr/lib /etc

# Scan embedded rootfs (Yocto/Buildroot)
./build/cbom-generator --cross-arch --output rootfs-cbom.json /path/to/rootfs
```

---

## Understanding the Output

CBOM Generator outputs JSON in CycloneDX format:

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "version": 1,
  "metadata": {
    "timestamp": "2025-12-04T12:00:00Z",
    "properties": [
      {"name": "cbom:total_components", "value": "150"},
      {"name": "cbom:pqc_readiness_percent", "value": "4.9"}
    ]
  },
  "components": [
    {
      "type": "cryptographic-asset",
      "name": "OpenSSL",
      "version": "3.0.2",
      "cryptoProperties": {
        "assetType": "library"
      }
    }
  ]
}
```

Key sections:
- **metadata**: Scan timestamp, totals, PQC readiness
- **components**: Discovered cryptographic assets
- **dependencies**: Relationships between components

---

## Next Steps

- [CLI Reference](../cli-reference/index.md) - Complete command-line options
- [Features](../features/index.md) - Deep-dive into capabilities
- [Playbooks](../playbooks/index.md) - Migration guides
