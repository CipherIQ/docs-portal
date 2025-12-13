# Reference Tables

Quick lookup tables for **pqc-flow**.

## PQC Flags

### Flag Values

| Flag | Value | Meaning |
|------|-------|---------|
| `PQC_KEM_PRESENT` | 1 | PQC/hybrid key exchange offered or negotiated |
| `PQC_SIG_PRESENT` | 2 | PQC/hybrid signature present |
| `HYBRID_NEGOTIATED` | 4 | Chosen algorithm is hybrid (classical + PQC) |
| `PQC_OFFERED_ONLY` | 8 | PQC offered by client but server chose classical |
| `PQC_CERT_OR_HOSTKEY` | 16 | Server certificate uses PQC signature |
| `RESUMPTION_NO_HANDSHAKE` | 32 | Session resumed (no full handshake) |

### Common Combinations

| Value | Flags | Interpretation |
|-------|-------|----------------|
| 0 | (none) | Classical cryptography only |
| 1 | KEM | PQC KEM present (non-hybrid) |
| 2 | SIG | PQC signature only |
| 3 | KEM + SIG | PQC KEM and signature |
| 4 | HYBRID | Hybrid negotiated (unusual alone) |
| **5** | **KEM + HYBRID** | **Hybrid PQC (most common)** |
| 7 | KEM + SIG + HYBRID | Full PQC with hybrid |
| 9 | KEM + OFFERED_ONLY | PQC offered but server chose classical |
| 32 | RESUMPTION | Session resumed, no handshake |

---

## Detected Algorithms

### KEM Algorithms (Key Encapsulation)

| Token | Algorithm Family | Example | Status |
|-------|------------------|---------|--------|
| `ml-kem` | NIST ML-KEM | X25519+ML-KEM-768 | Standard |
| `kyber` | Kyber (pre-NIST) | X25519Kyber768 | Deployed |
| `sntrup` | NTRU Prime | sntrup761x25519 | Production |
| `ntru` | NTRU | ntruhrss701 | Legacy |
| `bike` | BIKE | bike-l1 | Research |
| `hqc` | HQC | hqc-128 | Research |
| `frodo` | FrodoKEM | frodokem640 | Research |

### Signature Algorithms

| Token | Algorithm Family | Status |
|-------|------------------|--------|
| `ml-dsa` | NIST ML-DSA (Dilithium) | Standard |
| `dilithium` | Dilithium (pre-NIST) | Deployed |
| `slh-dsa` | NIST SLH-DSA (SPHINCS+) | Standard |
| `sphincs` | SPHINCS+ (pre-NIST) | Deployed |
| `falcon` | Falcon | Standard |

---

## TLS Group IDs

### Classical Groups

| Group Name | Hex Code | Standard |
|------------|----------|----------|
| `x25519` | 0x001d | RFC 7748 |
| `secp256r1` (P-256) | 0x0017 | NIST |
| `secp384r1` (P-384) | 0x0018 | NIST |
| `secp521r1` (P-521) | 0x0019 | NIST |

### Hybrid PQC Groups (Production)

| Group Name | Hex Code | Vendor |
|------------|----------|--------|
| `X25519Kyber768` | 0x11ec | Chrome |
| `X25519Kyber1024` | 0x11ed | Chrome |
| `X25519Kyber768Draft00` | 0x6399 | Cloudflare/Google |
| `X25519Kyber768Draft00` | 0xfe31 | Alternate code |

### Hybrid PQC Groups (NIST Standard)

| Group Name | Hex Code | Standard |
|------------|----------|----------|
| `X25519+ML-KEM-768` | 0x2001 | NIST draft |
| `X25519+ML-KEM-1024` | 0x2002 | NIST draft |
| `P-256+ML-KEM-768` | 0x2005 | NIST draft |
| `P-384+ML-KEM-1024` | 0x2006 | NIST draft |
| `SecP256r1+ML-KEM-768` | 0x2003 | NIST draft |
| `SecP384r1+ML-KEM-1024` | 0x2004 | NIST draft |

---

## SSH KEX Algorithms

### PQC/Hybrid KEX

| Algorithm | Type | Availability |
|-----------|------|--------------|
| `sntrup761x25519-sha512@openssh.com` | Hybrid | OpenSSH 9.0+ |
| `mlkem768x25519-sha256` | Hybrid | Emerging |
| `kyber512` | Pure PQC | Research |
| `kyber768` | Pure PQC | Research |
| `kyber1024` | Pure PQC | Research |

### Classical KEX (Reference)

| Algorithm | Security |
|-----------|----------|
| `curve25519-sha256` | Classical |
| `ecdh-sha2-nistp256` | Classical |
| `diffie-hellman-group16-sha512` | Classical |

---

## Filtered Ports

**pqc-flow** only processes traffic on these ports:

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 443 | TCP | HTTPS/TLS |
| 443 | UDP | QUIC/HTTP3 |
| 500 | UDP | IKE |
| 4500 | UDP | IKE NAT-T |
| 51820 | UDP | WireGuard |

---

## JSON Output Fields

### Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `ts_us` | int | Timestamp (microseconds since epoch) |
| `proto` | int | IP protocol (6=TCP, 17=UDP) |
| `sip` | string | Source IP |
| `dip` | string | Destination IP |
| `sp` | int | Source port |
| `dp` | int | Destination port |
| `smac` | string | Source MAC |
| `dmac` | string | Destination MAC |

### PQC Fields

| Field | Type | Description |
|-------|------|-------------|
| `pqc_flags` | int | PQC feature bitmask |
| `pqc_reason` | string | Detected tokens (pipe-delimited) |

### Protocol Fields

| Field | Protocol | Description |
|-------|----------|-------------|
| `ssh_kex_negotiated` | SSH | Negotiated KEX algorithm |
| `ssh_kex_offered` | SSH | Offered KEX algorithms |
| `ssh_sig_alg` | SSH | Signature algorithm |
| `tls_negotiated_group` | TLS | Server-selected group |
| `tls_supported_groups` | TLS | Client-offered groups |
| `tls_server_sigalg` | TLS | Server signature algorithm |
| `quic_tls_negotiated_group` | QUIC | TLS group in QUIC |
| `ike_ke_chosen` | IKEv2 | Selected key exchange |
| `live` | - | 1 if live capture mode |

---

## Memory Usage

| Scenario | Memory |
|----------|--------|
| Base (ring buffer + hash table) | ~130 MB |
| Per concurrent flow | ~24 KB |
| 1,000 concurrent flows | ~154 MB |
| 10,000 concurrent flows | ~370 MB |

---

## Performance

| Metric | Value |
|--------|-------|
| SSH handshake detection | ~25-50 ms |
| TLS handshake detection | ~40-100 ms |
| Throughput (4-core laptop) | 50K pps |
| Throughput (8-core server) | 150K pps |
