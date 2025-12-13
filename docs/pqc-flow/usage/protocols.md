# Protocol Coverage

**pqc-flow** detects PQC algorithms across multiple encrypted protocols.

## SSH

### Detection Method

Custom parser extracts KEXINIT messages from plaintext SSH version exchange.

The parser:

1. Identifies SSH version exchange (`SSH-2.0-...`)
2. Parses binary `SSH_MSG_KEXINIT` (type 20)
3. Extracts `kex_algorithms` name-list
4. Matches against PQC patterns

### Detected Algorithms

| Algorithm | Type | Status |
|-----------|------|--------|
| `sntrup761x25519-sha512@openssh.com` | Hybrid | Production (OpenSSH 9.0+) |
| `mlkem768x25519-sha256` | Hybrid | Emerging |
| `kyber512`, `kyber768`, `kyber1024` | Pure PQC | Research |

### Requirements

- Capture must include SSH handshake (first ~10 packets)
- Server must support PQC KEX algorithms
- Client OpenSSH 9.0+ for sntrup support

### Testing SSH PQC

```bash
# Check if your SSH client supports sntrup
ssh -Q kex | grep sntrup

# Connect with PQC KEX
ssh -oKexAlgorithms=sntrup761x25519-sha512@openssh.com user@server

# Verbose output to see negotiated KEX
ssh -v -oKexAlgorithms=sntrup761x25519-sha512@openssh.com user@server 2>&1 | grep 'kex:'
```

### Example Output

```json
{
  "dp": 22,
  "pqc_flags": 5,
  "pqc_reason": "ssh:sntrup|ssh:ntru|",
  "ssh_kex_negotiated": "sntrup761x25519-sha512@openssh.com"
}
```

---

## TLS 1.3 / DTLS 1.3

### Detection Method

Custom parser extracts `supported_groups` and `key_share` extensions from ClientHello/ServerHello.

The parser:

1. Identifies TLS records (type 0x16 = Handshake)
2. Parses ClientHello (type 0x01) and ServerHello (type 0x02)
3. Extracts extension 0x000a (`supported_groups`)
4. Extracts extension 0x0033 (`key_share`)
5. Maps group IDs to human-readable names

### Detected Groups

| Group Name | Hex Code | Vendor |
|------------|----------|--------|
| `X25519Kyber768` | 0x11ec | Chrome |
| `X25519Kyber768Draft00` | 0x6399 | Cloudflare/Google |
| `X25519+ML-KEM-768` | 0x2001 | NIST standard |
| `X25519+ML-KEM-1024` | 0x2002 | NIST standard |
| `P-256+ML-KEM-768` | 0x2005 | NIST standard |
| `P-384+ML-KEM-1024` | 0x2006 | NIST standard |

### Requirements

- TLS 1.3 connection (not TLS 1.2)
- PQC-enabled client
- PQC-enabled server

### PQC-Enabled Clients

| Client | Configuration |
|--------|---------------|
| Chrome | `--enable-features=PostQuantumKyber` |
| Edge | Same as Chrome |
| Firefox | `security.tls.enable_kyber` in about:config |

### PQC-Enabled Servers

- Cloudflare (most sites)
- AWS CloudFront
- Google Cloud

### Testing TLS PQC

```bash
# Cloudflare test endpoint
google-chrome --enable-features=PostQuantumKyber https://pq.cloudflareresearch.com/
```

!!! note
    Standard `curl` and `wget` do not support TLS PQC. Use Chrome or another PQC-enabled browser.

### Example Output

```json
{
  "dp": 443,
  "pqc_flags": 5,
  "pqc_reason": "tls:kyber|",
  "tls_negotiated_group": "X25519Kyber768"
}
```

---

## QUIC / HTTP/3

### Detection Method

TLS-in-QUIC uses the same extension parsing as TLS.

### Status

Partial implementation. Works when QUIC handshake is captured.

### Limitations

- QUIC Initial packets are encrypted (but with known keys)
- Current implementation relies on nDPI for QUIC detection
- Custom QUIC parser planned for improved coverage

### Example Output

```json
{
  "proto": 17,
  "dp": 443,
  "pqc_flags": 5,
  "quic_tls_negotiated_group": "X25519Kyber768"
}
```

---

## IKEv2 / IPsec

### Detection Method

nDPI protocol classification with `ke_chosen`/`ke_offered` extraction.

### Status

Limited implementation. Basic detection available.

### Detected Algorithms

PQC transform IDs when present in IKE_SA_INIT.

### Example Output

```json
{
  "proto": 17,
  "dp": 500,
  "ike_ke_chosen": "ML-KEM-768"
}
```

---

## WireGuard

### Status

Detection only. WireGuard uses fixed classical cryptography:

- Key exchange: Curve25519
- Encryption: ChaCha20-Poly1305
- Hash: BLAKE2s

### PQC Status

PQC variants of WireGuard are under research but not yet standardized:

- [Rosenpass](https://rosenpass.eu/) - Post-quantum key exchange for WireGuard
- [PQ-WireGuard](https://eprint.iacr.org/2020/379) - Academic proposal

**pqc-flow** will detect WireGuard traffic but will report `pqc_flags: 0` until PQC variants are deployed.

---

## Protocol Detection Summary

| Protocol | PQC Detection | Status |
|----------|---------------|--------|
| SSH | Full | Production |
| TLS 1.3 | Full | Production |
| DTLS 1.3 | Full | Production |
| QUIC | Partial | Works with nDPI |
| IKEv2 | Basic | Limited |
| WireGuard | None | Classical only |

## Filtered Ports

**pqc-flow** only processes traffic on handshake-relevant ports:

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 443 | TCP | HTTPS/TLS |
| 443 | UDP | QUIC/HTTP3 |
| 500 | UDP | IKE |
| 4500 | UDP | IKE NAT-T |
| 51820 | UDP | WireGuard |

## See Also

- [Reference Tables](../reference/tables.md) - Algorithm and group ID tables
