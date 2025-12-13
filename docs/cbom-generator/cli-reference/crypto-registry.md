---
hide:
  - toc
---
# Crypto Registry Extension 

Extensible crypto library registry via YAML configuration for detecting cryptographic libraries across different Linux distributions.

## Overview

The **Crypto Registry** is a declarative catalog of cryptographic libraries, providers, and embedded crypto engines. By externalizing this knowledge into YAML, the CBOM Generator can correctly classify crypto libraries (OpenSSL, GnuTLS, wolfSSL, mbedTLS, etc.) and create accurate **DEPENDS_ON** relationships in CycloneDX output.

**Benefits**:

- Support new distributions without code changes
- Detect custom/vendor-specific crypto libraries
- Platform-aware crypto visibility
- Instant adaptation via YAML updates

### `--crypto-registry FILE`

Load external crypto library registry from YAML file to extend built-in registry.

**How it works**:

1. **Built-in Registry** (Always Available): 5 crypto libraries
2. **YAML Extension** (Optional): Additional libraries from external file
3. **Lookup Order**: Built-in searched first, then YAML extensions
4. **Graceful Degradation**: YAML failures are warnings, not errors

```bash
# Standard scan (built-in registry only)
./build/cbom-generator --output cbom.json

# With Ubuntu/Debian registry extension
./build/cbom-generator --crypto-registry crypto-registry-ubuntu.yaml --output cbom.json

# With Yocto/embedded registry extension
./build/cbom-generator --crypto-registry crypto-registry-yocto.yaml --output cbom.json

# Invalid file (graceful degradation)
./build/cbom-generator --crypto-registry /nonexistent.yaml --output cbom.json
# Output: WARNING: Continuing with built-in crypto registry only.
```

## How Registry Works in Scan Flow

When scanning binaries, the CBOM Generator uses the registry to identify cryptographic dependencies:

```
1. Scanner finds ELF binary (e.g., /usr/sbin/nginx)
2. Reads ELF dependencies via readelf -d → [libssl.so.3, libcrypto.so.3]
3. Queries registry: find_crypto_lib_by_soname("libssl.so.3")
4. Registry returns: {id: "openssl", algorithms: [AES, RSA, ECDSA, ...]}
5. Creates DEPENDS_ON relationship: nginx → openssl
```

**Example: nginx with OpenSSL**:
```
Binary: /usr/sbin/nginx
    │
    ├── readelf -d → NEEDED: libssl.so.3
    │                        libcrypto.so.3
    │
    └── Registry Lookup:
        ├── libssl.so.3    → openssl (match!)
        ├── libcrypto.so.3 → openssl (match!)

Result: nginx DEPENDS_ON openssl
```


## Built-in Crypto Libraries

The generator includes 5 built-in crypto libraries:

| Library ID | Description | SONAME Patterns |
|------------|-------------|-----------------|
| **openssl** | OpenSSL TLS library | libssl.so, libcrypto.so |
| **libgcrypt** | GnuPG crypto library | libgcrypt.so |
| **libsodium** | NaCl crypto library | libsodium.so |
| **nettle** | Low-level crypto library | libnettle.so, libhogweed.so |
| **krb5** | Kerberos crypto | libgssapi_krb5.so, libkrb5.so |

**Built-in Embedded Apps **:

- `openssh_internal` - OpenSSH built-in crypto
- `wireguard_internal` - WireGuard VPN crypto
- `age_internal` - age encryption tool


## Available Registry Files

| Registry | Libraries | Apps | Target |
|----------|-----------|------|--------|
| `crypto-registry-ubuntu.yaml` | 16 | 7 | Ubuntu, Debian, Raspberry Pi OS |
| `registry/crypto-registry-yocto.yaml` | 26 | 4 | Yocto, Buildroot, embedded |
| `registry/crypto-registry-openwrt.yaml` | 6 | 7 | OpenWrt, LEDE, routers |
| `registry/crypto-registry-alpine.yaml` | 8 | 7 | Alpine, Docker containers |


## YAML Registry Format

```yaml
version: 1  # Schema version (required)

crypto_libraries:
  - id: boringssl                    # Unique identifier
    pkg_patterns:                     # Package name patterns
      - libboringssl
      - boringssl
    soname_patterns:                  # Shared library patterns
      - libboringssl.so
    algorithms:                       # Supported algorithms
      - RSA
      - ECDSA
      - AES-GCM

embedded_crypto_apps:
  - provider_id: dropbear            # Unique provider ID
    binary_names:                     # Binary name patterns
      - dropbear
      - dbclient
    package_names:                    # Package name patterns
      - dropbear
    algorithms:                       # Supported algorithms
      - aes128-ctr
      - curve25519-sha256
```

**Pattern Matching**: All patterns use substring matching:

- Pattern `libssl.so` matches `libssl.so.3`, `libssl.so.1.1`
- Pattern `openssl` matches `openssl-dev`, `libopenssl3`


## Creating Custom Registries

**Step 1: Copy example file**:
```bash
cp crypto-registry-ubuntu.yaml my-registry.yaml
```

**Step 2: Add your custom libraries**:
```yaml
version: 1

crypto_libraries:
  - id: my_custom_tls
    pkg_patterns:
      - my-tls-package
    soname_patterns:
      - libmytls.so
    algorithms:
      - RSA
      - AES-GCM
```

**Step 3: Validate**:
```bash
./build/cbom-generator --crypto-registry my-registry.yaml --help 2>&1 | grep -i "loaded"
```

**Step 4: Verify detection**:
```bash
./build/cbom-generator --crypto-registry my-registry.yaml --output cbom.json
cat cbom.json | jq '.components[] | select(.name | contains("my_custom_tls"))'
```


## Security Considerations

**Soft Limits** (prevent YAML bombs):

- Maximum 100 crypto libraries per YAML file
- Maximum 50 embedded apps per YAML file
- File size limited to 1MB
- Nesting depth limited to 32 levels

**Graceful Degradation**:

- YAML parsing errors → warning + continue with built-in
- File not found → warning + continue with built-in
- Scanner never fails due to registry issues

**Thread Safety**:

- Registry loaded once at startup
- Read-only after initialization
- No runtime reload (restart required for changes)

---

