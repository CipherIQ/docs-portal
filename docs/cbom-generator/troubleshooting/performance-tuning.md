# Performance Tuning

Optimize CBOM Generator scan performance.

---

## Symptoms

- Scans take too long
- High memory usage
- System becomes unresponsive during scan

---

## Performance Factors

| Factor | Impact | Mitigation |
|--------|--------|------------|
| File count | Linear | Target specific directories |
| Thread count | Parallelism | Adjust `--threads` |
| Output size | Memory | Use deduplication |
| Service discovery | Adds overhead | Disable if not needed |

---

## Thread Optimization

### Default Behavior

By default, CBOM Generator uses CPU count threads:

```bash
# 4-core system → 4 threads
# 8-core system → 8 threads
```

### Adjusting Threads

```bash
# Reduce for low-memory systems
./build/cbom-generator --threads 2 --output cbom.json

# Increase for high-core systems (up to 32)
./build/cbom-generator --threads 16 --output cbom.json

# Single-threaded (sequential)
./build/cbom-generator --threads 1 --output cbom.json
```

### Performance Impact

| Threads | Time (294 certs) | Speedup |
|---------|------------------|---------|
| 1 | 0.36s | baseline |
| 4 | 0.22s | 1.64x |

---

## Scan Scope Optimization

### Target Specific Directories

```bash
# Instead of entire filesystem
./build/cbom-generator --output cbom.json /

# Target specific directories
./build/cbom-generator --output cbom.json \
    /etc/ssl /etc/pki /etc/ssh /usr/share/ca-certificates
```

### Exclude Non-Crypto Directories

The scanner automatically skips hidden directories (`.cache`, `.config`, etc.), but you can further optimize by specifying only relevant paths.

---

## Deduplication for Output Size

Large scans can produce huge output files:

```bash
# Strict deduplication for minimal output
./build/cbom-generator --dedup-mode=strict --emit-bundles --output cbom.json
```

| Mode | Output Size | Use Case |
|------|-------------|----------|
| off | Largest | Forensic analysis |
| safe | Medium (default) | General use |
| strict | Smallest | Large enterprise scans |

---

## Memory Optimization

### For Large Scans

```bash
# Reduce thread count to lower memory usage
./build/cbom-generator --threads 2 --output cbom.json

# Scan in batches
./build/cbom-generator --output cbom-etc.json /etc
./build/cbom-generator --output cbom-usr.json /usr
```

### Monitor Memory Usage

```bash
# Watch memory during scan
watch -n 1 'ps -o rss,vsz,comm -p $(pgrep cbom-generator)'
```

---

## Service Discovery Performance

Service discovery adds overhead. Disable if not needed:

```bash
# Without service discovery (faster)
./build/cbom-generator --output cbom.json /etc/ssl

# With service discovery (slower, more complete)
./build/cbom-generator --discover-services --plugin-dir plugins --output cbom.json
```

---

## Caching

CBOM Generator includes SQLite-based persistent caching:

- 10x+ improvement on repeated scans
- Cache stored automatically
- No configuration needed

### Clear Cache (if needed)

```bash
rm -rf ~/.cache/cbom-generator/
```

---

## Benchmarking

### Time a Scan

```bash
time ./build/cbom-generator --output cbom.json /etc/ssl
```

### TUI Progress Monitoring

```bash
# Visual progress indication
./build/cbom-generator --tui --output cbom.json
```

---

## Recommended Settings

### Desktop/Development

```bash
./build/cbom-generator \
    --dedup-mode=safe \
    --output cbom.json
```

### Server/Production

```bash
./build/cbom-generator \
    --threads 4 \
    --dedup-mode=safe \
    --no-personal-data \
    --output cbom.json
```

### Large Enterprise

```bash
./build/cbom-generator \
    --threads 8 \
    --dedup-mode=strict \
    --emit-bundles \
    --no-personal-data \
    --output cbom.json
```
