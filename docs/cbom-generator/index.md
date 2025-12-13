---
hide:
  - toc
---
# Introduction

## What is CBOM Generator?

The **Cryptography Bill of Materials (CBOM) Generator** is a production-ready, high-performance C11 multithreaded application that inventories cryptographic assets on Linux systems to assess Post-Quantum Cryptography (PQC) readiness.

## Key Capabilities

- **Comprehensive Asset Discovery**: Certificates, keys, packages, services, protocols, cipher suites
- **Complete Dependency Graph**: Tracks relationships between services, protocols, and algorithms
- **PQC Readiness Assessment**: Analyzes quantum vulnerability across your entire cryptographic infrastructure
- **High Performance**: Scans 12,000+ files/minute with parallel processing
- **Privacy-by-Default**: GDPR/CCPA compliant with configurable redaction
- **Industry Standards**: Outputs CycloneDX 1.6/1.7 format with CBOM extensions

**Version**: 1.9.0 | **Platform**: Linux (Ubuntu, RHEL, Debian)


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
## Yocto CBOM Sample

??? note "Click to expand: Full first 200 lines of yocto-cbom.json"

    ```json linenums="1"
    --8<-- "https://raw.githubusercontent.com/CipherIQ/cbom-explorer/main/samples/yocto-cbom.json:1:200"
    ```

[View the full Yocto CBOM on GitHub (pretty-printed, searchable)](https://github.com/CipherIQ/cbom-explorer/blob/main/samples/yocto-cbom.json)↗


## License

**crypto-tracer** like all the tools in **CipherIQ** is dual-licensed:

- **GPL 3.0** - Free for open-source use (copyleft applies when distributing)
- **Commercial license** -  For proprietary integration without copyleft obligations

  [See details](../index.md/#license)

---

## Quick Links

- [Installation](getting-started/installation.md) - Get started with building and installing
- [Quick Start](getting-started/quick-start.md) - Run your first scan
- [CLI Reference](cli-reference/index.md) - Complete command-line options
- [Features](features/index.md) - Deep-dive into capabilities
- [Playbooks](playbooks/index.md) - Step-by-step migration guides

---
Copyright (c) 2025 Graziano Labs Corp.

<script>
document.addEventListener('DOMContentLoaded', function() {
  var links = document.querySelectorAll('a');
  for (var i = 0; i < links.length; i++) {
    if (links[i].hostname !== window.location.hostname) {
      links[i].target = '_blank';
      links[i].rel = 'noopener noreferrer';
    }
  }
});
</script>