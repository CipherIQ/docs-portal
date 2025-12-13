# Quick Start

Get **pqc-flow** running in minutes with these examples.

## 1. Mock Mode (No Network Required)

Test that **pqc-flow** works without any network access:

```bash
./pqc-flow --mock
```

Output:

```json
{"proto":6,"sip":"192.0.2.1","dip":"192.0.2.2","sp":12345,"dp":443,"pqc_flags":5,"pqc_reason":"tls:ml-kem|ssh:sntrup|","tls_negotiated_group":"X25519+ML-KEM-768","ssh_kex_negotiated":"sntrup761x25519-sha512@openssh.com"}
```

This confirms the tool is working correctly.

## 2. Analyze a PCAP File

Basic analysis:

```bash
./pqc-flow capture.pcap
```

Filter for PQC-enabled flows only:

```bash
./pqc-flow capture.pcap | jq 'select(.pqc_flags > 0)'
```

Pretty-print output:

```bash
./pqc-flow capture.pcap | jq .
```

## 3. Live Network Capture

Live capture requires root privileges or CAP_NET_RAW capability.

### With sudo

```bash
sudo ./pqc-flow --live eth0
```

### With Capabilities (Recommended)

One-time setup:

```bash
sudo setcap cap_net_raw,cap_net_admin+ep ./pqc-flow
```

Then run without sudo:

```bash
./pqc-flow --live eth0
```

### Filter Live Output

Show only PQC-enabled connections:

```bash
sudo ./pqc-flow --live eth0 | jq 'select(.pqc_flags > 0)'
```

## 4. Capture and Analyze SSH

### Create a Test Capture

```bash
# Start capture in background
sudo tcpdump -i eth0 -w ssh-test.pcap 'port 22' &

# Connect with PQC-enabled SSH
ssh -oKexAlgorithms=sntrup761x25519-sha512@openssh.com user@server

# Stop capture
sudo pkill tcpdump
```

### Analyze

```bash
./pqc-flow ssh-test.pcap | jq .
```

Expected output for PQC connection:

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

## 5. Capture and Analyze TLS

### Test with Cloudflare's PQC Endpoint

```bash
# Start capture
sudo tcpdump -i eth0 -w tls-test.pcap 'host pq.cloudflareresearch.com and port 443' &

# Visit with PQC-enabled Chrome
google-chrome --enable-features=PostQuantumKyber https://pq.cloudflareresearch.com/

# Stop capture
sudo pkill tcpdump

# Analyze
./pqc-flow tls-test.pcap | jq .
```

Expected output:

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

## Understanding the Output

| Field | Meaning |
|-------|---------|
| `pqc_flags` | Bitmask of PQC features (5 = hybrid PQC) |
| `pqc_reason` | Detected PQC algorithm tokens |
| `ssh_kex_negotiated` | SSH key exchange algorithm |
| `tls_negotiated_group` | TLS key exchange group |

### Common `pqc_flags` Values

| Value | Meaning |
|-------|---------|
| 0 | Classical cryptography only |
| 5 | Hybrid PQC negotiated (most common) |
| 9 | PQC offered but not selected |

## Next Steps

- [Command-Line Reference](../usage/cli-reference.md) - All options and modes
- [Understanding Output](../usage/output-format.md) - Detailed field reference
- [Use Cases & Workflows](../operations/workflows.md) - Common usage patterns
