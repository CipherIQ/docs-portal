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
./build/cbom-generator --output cbom.json

# Privacy-compliant scan
./build/cbom-generator --no-personal-data --output cbom.json

# Service discovery with plugins
./build/cbom-generator --discover-services --plugin-dir plugins --output cbom.json

# CycloneDX 1.7 with dependencies
./build/cbom-generator --cyclonedx-spec 1.7 --output cbom.json

# TUI mode with error logging
./build/cbom-generator --tui --error-log errors.log --output cbom.json

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
    --plugin-dir plugins \
    --dedup-mode safe \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output production-cbom.json
```

### Compliance Audit
```bash
./build/cbom-generator \
    --no-personal-data \
    --no-network \
    --deterministic \
    --pqc-report pqc-migration.txt \
    --output audit-cbom.json
```

### Embedded/Yocto Scan
```bash
ROOTFS=/path/to/yocto/rootfs
./build/cbom-generator \
    --cross-arch \
    --discover-services \
    --plugin-dir plugins/embedded \
    --crypto-registry crypto-registry-yocto.yaml \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output yocto-cbom.json \
    $ROOTFS/usr/bin $ROOTFS/usr/sbin $ROOTFS/usr/lib $ROOTFS/etc
```
