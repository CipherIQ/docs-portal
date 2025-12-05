# What's New

Release highlights for CBOM Generator.

---

## v1.9.0 (December 2025)

### Crypto Registry Extension

- **External YAML registries** for custom crypto library detection
- **Distribution-specific registries**: Ubuntu, Yocto, Alpine, OpenWrt
- **No recompilation needed** for new library support

### Cross-Architecture Scanning

- **`--cross-arch` flag** for Yocto/Buildroot rootfs scanning
- **ELF VERNEED version detection** without package managers
- **Embedded service plugins** for IoT devices

### Alternate Detection PQC

- **Kernel crypto API detection** (AF_ALG)
- **Static linking detection** (Go, Rust)
- **Symbol analysis** for embedded crypto
- **Improved PQC classification** for alternate-detected apps

---

## v1.6.0 (November 2025)

### Extensible Crypto Registry

- **YAML configuration** for crypto library definitions
- **Built-in registry**: OpenSSL, libgcrypt, libsodium, nettle, Kerberos
- **Graceful fallback** on YAML errors

---

## v1.3.0 (November 2025)

### YAML Plugin Architecture

- **Declarative service plugins** in YAML
- **50+ enterprise plugins** included
- **19 embedded Linux plugins** for IoT
- **Phase pipeline**: Detection → Extraction → Generation

### Service Discovery Enhancements

- **5 detection methods**: process, port, config, systemd, package
- **6 config parsers**: INI, Apache, Nginx, YAML, JSON, OpenSSL cipher
- **Full dependency graph**: SERVICE→PROTOCOL→SUITE→ALGORITHM

---

## v1.2.0 (November 2025)

### PQC Assessment Enhancements

- **Break year estimation**: 2030/2035/2040/2045 timeline
- **Migration report**: `--pqc-report` flag
- **Per-component rationale**: Explains classification
- **Hybrid detection**: X25519-ML-KEM-768

---

## v1.1.0 (November 2025)

### Schema Compliance

- **100% CycloneDX validation** pass rate
- **Human-readable bom-refs**: `cert:digicert-root-ca`
- **Zero hash collisions**

### Deprecated

- Epoch timestamps (use ISO-8601)

---

## v1.0.0 (November 2025)

### Initial Release

- **5 built-in scanners**: Certificate, Key, Package, Service, Filesystem
- **CycloneDX 1.6/1.7 output**
- **PQC readiness assessment**
- **Privacy-by-default** (GDPR/CCPA)
- **Multi-threaded scanning**
- **Persistent caching**
- **SLSA provenance**
