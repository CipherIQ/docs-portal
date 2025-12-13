# Understanding Output

**pqc-flow** outputs one JSON object per line (JSONL format). Each line represents a completed flow.

## Output Format

```json
{"proto":6,"sip":"192.168.1.100","dip":"203.0.113.50","sp":52341,"dp":22,"pqc_flags":5,"pqc_reason":"ssh:sntrup|","ssh_kex_negotiated":"sntrup761x25519-sha512@openssh.com"}
```

Pretty-printed:

```json
{
  "proto": 6,
  "sip": "192.168.1.100",
  "dip": "203.0.113.50",
  "sp": 52341,
  "dp": 22,
  "pqc_flags": 5,
  "pqc_reason": "ssh:sntrup|",
  "ssh_kex_negotiated": "sntrup761x25519-sha512@openssh.com"
}
```

## Field Reference

### Core Flow Fields

| Field | Type | Description |
|-------|------|-------------|
| `ts_us` | integer | First packet timestamp (microseconds since epoch) |
| `proto` | integer | IP protocol number (6=TCP, 17=UDP) |
| `sip` | string | Source IP address (canonical lower endpoint) |
| `dip` | string | Destination IP address (canonical higher endpoint) |
| `sp` | integer | Source port (canonical) |
| `dp` | integer | Destination port (canonical) |
| `smac` | string | Source MAC address |
| `dmac` | string | Destination MAC address |

### Canonical Ordering

Both directions of a bidirectional connection map to the same flow. The canonical ordering ensures consistent identification:

- **Source** = Lexicographically lower IP/port combination
- **Destination** = Lexicographically higher IP/port combination

### PQC Detection Fields

| Field | Type | Description |
|-------|------|-------------|
| `pqc_flags` | integer | Bitmask indicating PQC features detected |
| `pqc_reason` | string | Pipe-delimited list of detected PQC tokens |

### Protocol-Specific Fields

| Field | Protocol | Description |
|-------|----------|-------------|
| `ssh_kex_negotiated` | SSH | Negotiated key exchange algorithm |
| `ssh_kex_offered` | SSH | Offered KEX algorithms |
| `ssh_sig_alg` | SSH | Signature algorithm |
| `tls_negotiated_group` | TLS | Server-selected key exchange group |
| `tls_supported_groups` | TLS | Client-offered groups |
| `tls_server_sigalg` | TLS | Server signature algorithm |
| `quic_tls_negotiated_group` | QUIC | TLS group in QUIC |
| `ike_ke_chosen` | IKEv2 | Selected key exchange |
| `live` | - | Set to 1 in live capture mode |

## PQC Flags Bitmask

The `pqc_flags` field is a bitmask indicating detected PQC features:

| Value | Flag Name | Meaning |
|-------|-----------|---------|
| 1 | `PQC_KEM_PRESENT` | PQC/hybrid key exchange offered or negotiated |
| 2 | `PQC_SIG_PRESENT` | PQC/hybrid signature present |
| 4 | `HYBRID_NEGOTIATED` | Chosen algorithm is hybrid (classical + PQC) |
| 8 | `PQC_OFFERED_ONLY` | PQC offered by client but server chose classical |
| 16 | `PQC_CERT_OR_HOSTKEY` | Server certificate uses PQC signature |
| 32 | `RESUMPTION_NO_HANDSHAKE` | Session resumed (no full handshake) |

### Common Flag Combinations

| Value | Interpretation | Action |
|-------|----------------|--------|
| 0 | Classical cryptography only | Quantum-vulnerable |
| 1 | PQC KEM present (non-hybrid) | PQC in use |
| **5** | **Hybrid PQC negotiated** | **Best practice** |
| 9 | PQC offered but not selected | Server needs upgrade |
| 32 | Session resumed | No handshake to analyze |

## Example Interpretations

### SSH with Hybrid PQC

```json
{
  "proto": 6,
  "sip": "192.168.1.100",
  "dip": "203.0.113.50",
  "sp": 52341,
  "dp": 22,
  "pqc_flags": 5,
  "pqc_reason": "ssh:sntrup|ssh:ntru|",
  "ssh_kex_negotiated": "sntrup761x25519-sha512@openssh.com"
}
```

**Analysis:**

- `pqc_flags: 5` = PQC_KEM_PRESENT (1) + HYBRID_NEGOTIATED (4)
- `pqc_reason` shows detection of "sntrup" and "ntru" tokens
- Connection uses OpenSSH's hybrid PQC key exchange
- **Status: Quantum-resistant**

### TLS with Kyber

```json
{
  "proto": 6,
  "sip": "10.0.0.5",
  "dip": "104.16.132.229",
  "sp": 44892,
  "dp": 443,
  "pqc_flags": 5,
  "pqc_reason": "tls:kyber|",
  "tls_negotiated_group": "X25519Kyber768"
}
```

**Analysis:**

- Server (Cloudflare) negotiated hybrid Kyber key exchange
- Client (Chrome with PQC enabled) and server both support PQC
- **Status: Quantum-resistant**

### Classical Only (No PQC)

```json
{
  "proto": 6,
  "sip": "10.0.0.5",
  "dip": "93.184.216.34",
  "sp": 55123,
  "dp": 443,
  "pqc_flags": 0,
  "pqc_reason": "",
  "tls_negotiated_group": "x25519"
}
```

**Analysis:**

- `pqc_flags: 0` indicates classical-only cryptography
- Using X25519 (Curve25519) for key exchange
- **Status: Quantum-vulnerable**

### PQC Offered But Not Selected

```json
{
  "proto": 6,
  "sip": "10.0.0.5",
  "dip": "198.51.100.10",
  "sp": 51234,
  "dp": 443,
  "pqc_flags": 9,
  "pqc_reason": "tls:kyber|",
  "tls_supported_groups": "X25519Kyber768,x25519,secp256r1",
  "tls_negotiated_group": "x25519"
}
```

**Analysis:**

- `pqc_flags: 9` = PQC_KEM_PRESENT (1) + PQC_OFFERED_ONLY (8)
- Client offered Kyber but server selected classical X25519
- Server needs upgrade to support PQC
- **Status: Quantum-vulnerable (server limitation)**

## Filtering with jq

### Show Only PQC-Enabled Flows

```bash
./pqc-flow capture.pcap | jq 'select(.pqc_flags > 0)'
```

### Show Quantum-Vulnerable Flows

```bash
./pqc-flow capture.pcap | jq 'select(.pqc_flags == 0)'
```

### Show SSH Flows

```bash
./pqc-flow capture.pcap | jq 'select(.ssh_kex_negotiated != "")'
```

### Show TLS Flows

```bash
./pqc-flow capture.pcap | jq 'select(.tls_negotiated_group != "")'
```

### Extract Server IPs with PQC

```bash
./pqc-flow capture.pcap | jq 'select(.pqc_flags > 0) | .dip' | sort -u
```

### Summary Statistics

```bash
./pqc-flow capture.pcap | jq -s '{
  total: length,
  pqc: [.[] | select(.pqc_flags > 0)] | length,
  classical: [.[] | select(.pqc_flags == 0)] | length
}'
```

## See Also

- [Protocol Coverage](protocols.md) - Supported protocols and algorithms
- [Reference Tables](../reference/tables.md) - Quick lookup tables
