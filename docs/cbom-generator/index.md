---
hide:
  - toc
---
# CBOM Generator

**Version**: 1.9.0 | **Platform**: Linux (Ubuntu, RHEL, Debian)

---

## What is CBOM Generator?

The **Cryptography Bill of Materials (CBOM) Generator** is a production-ready, high-performance C11 multithreaded application that inventories cryptographic assets on Linux systems to assess Post-Quantum Cryptography (PQC) readiness.

**Key Capabilities**:

- **Comprehensive Asset Discovery**: Certificates, keys, packages, services, protocols, cipher suites
- **Complete Dependency Graph**: Tracks relationships between services, protocols, and algorithms
- **PQC Readiness Assessment**: Analyzes quantum vulnerability across your entire cryptographic infrastructure
- **High Performance**: Scans 12,000+ files/minute with parallel processing
- **Privacy-by-Default**: GDPR/CCPA compliant with configurable redaction
- **Industry Standards**: Outputs CycloneDX 1.6/1.7 format with CBOM extensions

---

## Why Use CBOM Generator?

### For Security Teams

- Inventory all cryptographic assets before quantum computers break current encryption
- Identify weak or deprecated algorithms that need immediate replacement
- Track certificate expiration and trust issues
- Map service dependencies on cryptographic components

### For Compliance

- Generate machine-readable cryptographic inventories for audits (CyclneDX standard format)
- Track FIPS 140-2/3 certified implementations
- Document privacy controls and data redaction
- Provide SLSA provenance for build transparency

### For Operations

- Discover all TLS/SSH configurations across infrastructure
- Identify services using deprecated protocols or cipher suites
- Plan migrations with PQC readiness scoring and recommendations

---

## Quick Links

- [Installation](getting-started/installation.md) - Get started with building and installing
- [Quick Start](getting-started/quick-start.md) - Run your first scan
- [CLI Reference](cli-reference/index.md) - Complete command-line options
- [Features](features/index.md) - Deep-dive into capabilities
- [Playbooks](playbooks/index.md) - Step-by-step migration guides
