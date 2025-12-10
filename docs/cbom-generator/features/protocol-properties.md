---
hide:
  - toc
---
# Protocol Properties

The Protocol Analysis module extracts detailed cryptographic protocol configurations from services.


## Supported Protocol Types

| Protocol | Description | Detection Source |
|----------|-------------|------------------|
| **TLS** | Transport Layer Security | Apache, Nginx, Postfix configs |
| **SSH** | Secure Shell | sshd_config, ssh_config |
| **IPsec** | IP Security | strongSwan, OpenConnect configs |
| **DTLS** | Datagram TLS | VPN configurations |
| **QUIC** | Quick UDP Internet Connections | Modern web servers |
| **WireGuard** | WireGuard VPN | WireGuard configs |
| **OpenVPN** | OpenVPN protocol | OpenVPN configs |


---

## TLS Version Detection

Protocols track which TLS versions are enabled:

```json
{
  "type": "cryptographic-asset",
  "name": "TLS",
  "bom-ref": "protocol:tls",
  "properties": [
    { "name": "cbom:proto:type", "value": "TLS" },
    { "name": "cbom:proto:version_min", "value": "1.2" },
    { "name": "cbom:proto:version_max", "value": "1.3" },
    { "name": "cbom:proto:security_profile", "value": "MODERN" }
  ]
}
```

---

## Protocol Classification

TLS and SSH protocols receive special handling because their security depends on the key exchange algorithm, not just the protocol version or cipher suite.

### TLS Protocol Classification

The classifier evaluates TLS protocols based on version and key exchange configuration:

| Protocol | Status |  Rationale |
|----------|--------|----------------|
| TLS with PQC-hybrid KEX (Kyber, ML-KEM, X25519Kyber) | **SAFE** | PQC-hybrid key exchange |
| TLS 1.3 (without PQC hybrid) | **TRANSITIONAL** | TLS 1.2/1.3: quantum-safe symmetric (AES-GCM), vulnerable KEX (ECDHE) |
| TLS 1.2 (without PQC hybrid) | **TRANSITIONAL** | Same as TLS 1.3 - KEX is the vulnerability |
| TLS 1.1 | **DEPRECATED** | TLS 1.0/1.1 and SSLv3: deprecated protocols with known vulnerabilities |
| TLS 1.0 | **DEPRECATED** | Same - classical attacks (BEAST, etc.) + quantum-vulnerable |
| SSLv3 | **DEPRECATED** | Completely broken classically (POODLE) |


### TLS Cipher Suite Classification

Individual cipher suites are classified based on their components:

| Cipher Suite Pattern | Status |  Rationale |
|---------------------|--------|----------------|
| TLS 1.3 suites (`TLS_AES_*`, `TLS_CHACHA20_*`) | **TRANSITIONAL** | TLS 1.3 with classical KEX (X25519/ECDHE) - TRANSITIONAL for service |
| Contains `ECDHE` or `DHE` | **TRANSITIONAL** | Good forward secrecy but classical KEX |
| RSA key transport (no ECDHE/DHE) | **TRANSITIONAL** | RSA key transport (no forward secrecy) - still TRANSITIONAL for now |
| Contains `RC4`, `DES`, `NULL`, `EXPORT`, `MD5`, `3DES` | **DEPRECATED** | Classically broken ciphers |
| Default (other patterns) | **TRANSITIONAL** | Default assumption |


### SSH Protocol Classification

SSH protocols are classified based on their key exchange algorithms:

| Configuration | Status |  Rationale |
|---------------|--------|----------------|
| SSH with `sntrup761x25519` | **SAFE** | PQC-hybrid KEX (NTRU-Prime + X25519) |
| SSH with `ntruprime` or `Kyber` | **SAFE** | Uses quantum-resistant key exchange |
| SSH with curve25519/ECDH | **TRANSITIONAL** | quantum-safe symmetric, vulnerable KEX |


### Design Decision: Why RSA Key Transport is TRANSITIONAL

The code classifies RSA key transport cipher suites as **TRANSITIONAL** (not UNSAFE), even though they lack forward secrecy. 

This CBOM Generator treats RSA key transport equivalently to ECDHE for PQC classification because:

1. **Both are quantum-vulnerable**: Shor's algorithm can break both RSA and ECDHE
2. **Separate concerns**: Forward secrecy is a separate property from PQC readiness
3. **TRANSITIONAL = plan migration**: Both require migration to PQC, which is the primary concern

**Note:** Organizations with strict "harvest-now-decrypt-later" concerns may want to prioritize disabling RSA key transport before ECDHE suites.



---

## SSH Protocol Properties

SSH configurations are analyzed at three levels:

**Server Configuration** (`/etc/ssh/sshd_config`):
- KexAlgorithms (key exchange)
- Ciphers, MACs
- HostKeyAlgorithms
- Usage: `server` (inbound connections)

**System Client Configuration** (`/etc/ssh/ssh_config`):
- KexAlgorithms, Ciphers, MACs
- Usage: `client` (system-wide outbound)

**User Client Configuration** (`~/.ssh/config`):
- Requires `--include-personal-data` flag
- Per-user KEX preferences
- Usage: `client-user-<username>`

---

## PQC KEX Algorithm Detection

The scanner detects Post-Quantum safe KEX algorithms:

| Algorithm | Type | PQC Status |
|-----------|------|------------|
| `sntrup761x25519-sha512@openssh.com` | Hybrid (NTRU Prime + X25519) | **PQC SAFE** |
| `curve25519-sha256` | ECDH | Vulnerable |
| `ecdh-sha2-nistp256` | ECDH | Vulnerable |
| `diffie-hellman-group16-sha512` | DH | Vulnerable |

---

## Cipher Suite Decomposition

Cipher suites are broken down into component algorithms:

**TLS 1.3 Cipher Suites** (fixed format):

| Cipher Suite | Encryption | Hash |
|--------------|------------|------|
| TLS_AES_256_GCM_SHA384 | AES-256-GCM | SHA384 |
| TLS_AES_128_GCM_SHA256 | AES-128-GCM | SHA256 |
| TLS_CHACHA20_POLY1305_SHA256 | ChaCha20-Poly1305 | SHA256 |

**TLS 1.2 Cipher Suites** (decomposed):

Example: `ECDHE-RSA-AES256-GCM-SHA384`

| Component | Algorithm |
|-----------|-----------|
| Key Exchange | ECDHE |
| Authentication | RSA |
| Encryption | AES-256-GCM |
| MAC | SHA384 |

---

## Protocol CycloneDX Output

```json
{
  "type": "cryptographic-asset",
  "name": "TLS 1.3",
  "bom-ref": "protocol:tls-1.3",
  "cryptoProperties": {
    "assetType": "protocol",
    "protocolProperties": {
      "type": "tls",
      "version": "1.3"
    }
  },
  "properties": [
    { "name": "cbom:proto:type", "value": "TLS" },
    { "name": "cbom:proto:version", "value": "1.3" },
    { "name": "cbom:proto:security_profile", "value": "MODERN" },
    { "name": "cbom:pqc:status", "value": "UNSAFE" }
  ]
}
```

---

## Common Queries

### Finding Deprecated TLS Versions

```bash
cat cbom.json | jq -r '.components[] |
    select(.cryptoProperties?.protocolProperties?.type == "tls") |
    select(.cryptoProperties?.protocolProperties?.version | test("1.0|1.1")) |
    "\(.name) - DEPRECATED"'
```

### SSH KEX Algorithm Inventory

```bash
cat cbom.json | jq -r '.components[] |
    select(.bom-ref | startswith("algo:")) |
    select(.properties[]? | select(.name == "cbom:algo:context" and .value | test("kex"))) |
    .name'
```

### Services Using TLS 1.3

```bash
cat cbom.json | jq -r '.dependencies[] |
    select(.dependsOn[]? | contains("protocol:tls-1.3")) |
    .ref'
```
