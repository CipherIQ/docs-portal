---
hide:
  - toc
---
# CLI Syntax Reference

Complete command-line syntax for CBOM Generator.


## Usage

```
cbom-generator [OPTIONS] [PATHS...]
```

If no paths specified, scans default system locations.

---

## Options

### Output Options

| Option | Description | Default |
|--------|-------------|---------|
| `-o, --output FILE` | Output file path | stdout |
| `-f, --format FORMAT` | Output format (json/cyclonedx) | cyclonedx |
| `--cyclonedx-spec VERSION` | Spec version (1.6/1.7) | 1.6 |

### Privacy Options

| Option | Description | Default |
|--------|-------------|---------|
| `--no-personal-data` | Redact personal data | ON |
| `--include-personal-data` | Include full paths/hostnames | OFF |
| `--no-network` | Disable network operations | OFF |

### Display Options

| Option | Description | Default |
|--------|-------------|---------|
| `--tui` | Enable Terminal UI | OFF |
| `--pqc-report FILE` | Generate PQC report | - |
| `--error-log FILE` | Write errors to file | - |

### Performance Options

| Option | Description | Default |
|--------|-------------|---------|
| `-t, --threads N` | Worker threads (1-32) | CPU count |
| `-d, --deterministic` | Deterministic output | ON |
| `--no-deterministic` | Include timestamps | OFF |
| `--cross-arch` | Cross-architecture mode | OFF |

### Deduplication Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dedup-mode MODE` | off/safe/strict | safe |
| `--emit-bundles` | Create bundle components | OFF |

### Service Discovery Options

| Option | Description | Default |
|--------|-------------|---------|
| `--discover-services` | Enable service discovery | OFF |
| `--plugin-dir DIR` | YAML plugin directory | plugins/ |
| `--list-plugins` | List plugins and exit | - |

### Crypto Registry Options

| Option | Description | Default |
|--------|-------------|---------|
| `--crypto-registry FILE` | External registry YAML | - |

### Attestation Options

| Option | Description | Default |
|--------|-------------|---------|
| `--enable-attestation` | Enable attestation | OFF |
| `--signature-method METHOD` | dsse/pgp | dsse |
| `--signing-key PATH` | Signing key file | - |

### Information Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Display help |
| `-v, --version` | Display version |

---

## Examples

### Basic Scan

```bash
./build/cbom-generator --output cbom.json
```

### Privacy-Compliant Scan

```bash
./build/cbom-generator --no-personal-data --output cbom.json
```

### Full Service Discovery

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output cbom.json
```

### Cross-Architecture (Yocto)

```bash
./build/cbom-generator \
    --cross-arch \
    --discover-services \
    --plugin-dir plugins/embedded \
    --crypto-registry crypto-registry-yocto.yaml \
    --output yocto-cbom.json \
    /path/to/rootfs/usr /path/to/rootfs/etc
```

### TUI with Logging

```bash
./build/cbom-generator \
    --tui \
    --error-log /tmp/errors.log \
    --output cbom.json
```

### Minimal Output

```bash
./build/cbom-generator \
    --dedup-mode strict \
    --emit-bundles \
    --output cbom.json
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (see stderr/error log) |

---