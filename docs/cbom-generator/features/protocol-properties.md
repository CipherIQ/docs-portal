# Protocol Properties

The Protocol Analysis module extracts detailed cryptographic protocol configurations from services.

---

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

## TLS Version Analysis

| Version | Status | Risk Level |
|---------|--------|------------|
| TLS 1.3 | Current | Safe |
| TLS 1.2 | Supported | Safe (with modern ciphers) |
| TLS 1.1 | Deprecated | **HIGH RISK** |
| TLS 1.0 | Deprecated | **HIGH RISK** |
| SSLv3 | Obsolete | **CRITICAL** |

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
