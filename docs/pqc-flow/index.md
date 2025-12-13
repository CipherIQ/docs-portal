# Introduction

## What is pqc-flow?

**pqc-flow** is a passive network analyzer that identifies which network connections use post-quantum or hybrid cryptographic algorithms. It analyzes TLS, SSH, QUIC, and IKEv2 handshakes from either live network traffic or PCAP files.

## Why PQC Detection Matters

Quantum computers threaten current public-key cryptography. Organizations need to:

- **Inventory** existing cryptographic deployments
- **Identify** connections still using quantum-vulnerable algorithms
- **Track** PQC adoption progress across infrastructure
- **Validate** that PQC-capable clients/servers actually negotiate PQC

## Core Capabilities

| Capability | Description |
|------------|-------------|
| **Passive analysis** | No modification of traffic; read-only inspection |
| **Privacy-preserving** | Extracts only handshake metadata; no payload storage |
| **Protocol support** | SSH, TLS 1.3, DTLS, QUIC, IKEv2 |
| **Live & offline** | Analyze PCAP files or monitor live traffic |
| **JSON output** | Machine-readable JSONL format for integration |

## How It Works

pqc-flow inspects the initial handshake of encrypted protocols to extract cryptographic algorithm information:

```
Packet Capture → Protocol Detection → Handshake Parsing → PQC Detection → JSON Output
```

1. **Capture** - Reads packets from PCAP files or live network interfaces
2. **Detection** - Identifies SSH, TLS, QUIC, and IKE protocols
3. **Parsing** - Extracts key exchange algorithms and signature methods
4. **Analysis** - Matches algorithms against known PQC/hybrid patterns
5. **Output** - Emits JSON records with flow metadata and PQC status

## Key Features

### Hybrid Algorithm Detection

Detects both pure PQC and hybrid algorithms that combine classical and post-quantum cryptography:

- **SSH**: `sntrup761x25519-sha512@openssh.com`
- **TLS**: `X25519Kyber768`, `X25519+ML-KEM-768`

### Real-Time Monitoring

Live capture mode provides immediate visibility into PQC adoption as connections are established.

### Minimal Footprint

- No payload storage or reconstruction
- Bounded memory usage per flow
- Efficient AF_PACKET capture for high-throughput networks

## Use Cases

| Use Case | Description |
|----------|-------------|
| **Security Audit** | Inventory which servers support PQC |
| **Compliance** | Verify PQC deployment meets policy requirements |
| **Migration Tracking** | Monitor PQC adoption progress over time |
| **Incident Response** | Identify quantum-vulnerable connections |

## License

**pqc-flow** like all the tools in **CipherIQ** is dual-licensed:

- **GPL 3.0** - Free for open-source use (copyleft applies when distributing)
- **Commercial license** -  For proprietary integration without copyleft obligations


[See details](../index.md/#license)

## Next Steps

- [Installation](getting-started/installation.md) - Set up pqc-flow on your system
- [Quick Start](getting-started/quick-start.md) - Run your first analysis

---
Copyright (c) 2025 Graziano Labs Corp.
