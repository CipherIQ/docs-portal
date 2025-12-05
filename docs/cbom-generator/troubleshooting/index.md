# Troubleshooting

Solutions for common issues with CBOM Generator.

---

## Common Issues

| Issue | Quick Link |
|-------|------------|
| Empty or minimal results | [No Components Found](no-components-found.md) |
| Access denied errors | [Permission Errors](permission-errors.md) |
| Slow scans or high memory | [Performance Tuning](performance-tuning.md) |
| Different output between runs | [Non-Deterministic Output](non-deterministic-output.md) |

---

## Quick Diagnostics

### Check Version

```bash
./build/cbom-generator --version
```

### Verify Installation

```bash
# Run help
./build/cbom-generator --help

# Quick test scan
./build/cbom-generator --output /tmp/test.json /etc/ssl/certs
cat /tmp/test.json | jq '.components | length'
```

### View Scan Errors

```bash
./build/cbom-generator --error-log /tmp/errors.log --output cbom.json
cat /tmp/errors.log
```

---

## Getting Help

### Error Log Analysis

Run with `--error-log` to capture detailed error information:

```bash
./build/cbom-generator --error-log /tmp/cbom-errors.log --output cbom.json 2>&1
```

### Verbose Output

Enable verbose mode for debugging:

```bash
./build/cbom-generator --output cbom.json /etc/ssl 2>&1 | tee scan.log
```

### Check Metadata Properties

The CBOM includes diagnostic metadata:

```bash
cat cbom.json | jq '.metadata.properties[] | select(.name | startswith("cbom:diagnostics"))'
```
