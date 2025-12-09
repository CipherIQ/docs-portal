---
hide:
  - toc
---
# CLI Reference

Complete command-line interface documentation for CBOM Generator.

## Usage

```bash
./build/cbom-generator [OPTIONS] [PATHS...]
```

If no paths are specified, scans default system locations.

## Option Categories

| Category | Description |
|----------|-------------|
| [Output Options](output-options.md) | File output, format selection |
| [Privacy Options](privacy-options.md) | GDPR/CCPA compliance controls |
| [Display Options](display-options.md) | TUI, reports, error logging |
| [Performance Options](performance-options.md) | Threading, determinism, cross-arch |
| [Deduplication](deduplication-options.md) | Duplicate handling modes |
| [Service Discovery](service-discovery.md) | Plugin-based service detection |
| [Crypto Registry](crypto-registry.md) | Library detection configuration |
| [Attestation](attestation-options.md) | SLSA provenance and signing |

## Quick Reference

```bash
# Basic scan
./build/cbom-generator --output cbom.json /etc

# Privacy-compliant scan
./build/cbom-generator --no-personal-data --output cbom.json /etc

# Service discovery with plugins
./build/cbom-generator --discover-services --plugin-dir plugins/ubuntu --output cbom.json /etc

# CycloneDX 1.7 with dependencies
./build/cbom-generator --cyclonedx-spec 1.7 --output cbom.json /etc

# TUI mode with error logging
./build/cbom-generator --tui --error-log errors.log --output cbom.json /etc

# Cross-architecture (Yocto/embedded)
./build/cbom-generator --cross-arch --crypto-registry crypto-registry-yocto.yaml \
    --output rootfs-cbom.json /path/to/rootfs
```

## Common Combinations

### Production Scan
```bash
./build/cbom-generator \
    --no-personal-data \
    --discover-services \
    --plugin-dir plugins/ubuntu \
    --crypto-registry registry/crypto-registry-ubuntu.yaml \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output production-cbom.json
        /etc /usr/bin /usr/sbin
```

### Compliance Audit
```bash
./build/cbom-generator \
    --no-personal-data \
    --no-network \
    --deterministic \
    --discover-services \
    --plugin-dir plugins/ubuntu \
    --crypto-registry registry/crypto-registry-ubuntu.yaml \
    --pqc-report pqc-migration.txt \
    --output audit-cbom.json
        /etc /usr/bin /usr/sbin
```

### Embedded/Yocto Scan
```bash
ROOTFS=/path/to/yocto/rootfs
./build/cbom-generator \
    --cross-arch \
    --discover-services \
    --plugin-dir plugins/embedded \
    --crypto-registry registry/crypto-registry-yocto.yaml \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output yocto-cbom.json \
        $ROOTFS/usr/bin $ROOTFS/usr/sbin $ROOTFS/usr/lib $ROOTFS/etc
```
