# Command-Line Reference

## Synopsis

```
pqc-flow [OPTIONS] [PCAP_FILE]
```

## Modes

**pqc-flow** operates in one of three modes:

| Mode | Usage | Description |
|------|-------|-------------|
| **Mock** | `--mock` | Generate synthetic PQC flow for testing |
| **Offline** | `<file.pcap>` | Analyze PCAP file |
| **Live** | `--live <iface>` | Monitor live network interface |

## Options

| Option | Argument | Description |
|--------|----------|-------------|
| `--mock` | - | Output synthetic test flow |
| `--live` | `<interface>` | Network interface for live capture |
| `--snaplen` | `<bytes>` | Packet capture length (default: 2048) |
| `--fanout` | `<group_id>` | Multi-core load distribution group |
| `--json` | - | Force JSON output (auto-detected) |

## Mode Details

### Mock Mode

Generate a synthetic PQC flow for testing output format and pipeline integration:

```bash
./pqc-flow --mock
```

Output includes all fields with sample PQC data. Useful for:

- Verifying installation
- Testing downstream JSON parsing
- Development and debugging

### Offline Mode

Analyze a PCAP file:

```bash
./pqc-flow capture.pcap
```

Flows are exported when:

- Handshake completes (negotiated algorithm detected)
- End of file reached (remaining flows flushed)

Supported formats:

- PCAP (`.pcap`)
- PCAP-NG (`.pcapng`)

### Live Mode

Monitor a network interface in real-time:

```bash
sudo ./pqc-flow --live eth0
```

Features:

- AF_PACKET TPACKET_V3 for zero-copy capture
- Immediate export on handshake completion
- Sub-100ms latency

Requirements:

- Root privileges or CAP_NET_RAW capability
- Valid network interface name

## Option Details

### `--snaplen`

Set packet capture length in bytes:

```bash
sudo ./pqc-flow --live eth0 --snaplen 4096
```

| Value | Use Case |
|-------|----------|
| 2048 (default) | Most handshakes |
| 4096 | Large TLS ClientHello with many extensions |

Increase if you see incomplete handshake detection.

### `--fanout`

Enable multi-core packet distribution:

```bash
sudo ./pqc-flow --live eth0 --fanout 100
```

The `group_id` is an arbitrary number. Multiple instances with the same group ID share packets via PACKET_FANOUT.

Use for high-throughput networks (>100K packets/second).

### `--json`

Force JSON output format:

```bash
./pqc-flow capture.pcap --json
```

Normally auto-detected based on terminal/pipe. Use `--json` to ensure JSON output when needed.

## Examples

### Basic Offline Analysis

```bash
./pqc-flow traffic.pcap
```

### Filter SSH Flows

```bash
./pqc-flow traffic.pcap | jq 'select(.ssh_kex_negotiated != "")'
```

### Filter PQC-Enabled Flows

```bash
./pqc-flow traffic.pcap | jq 'select(.pqc_flags > 0)'
```

### Live Capture on eth0

```bash
sudo ./pqc-flow --live eth0
```

### Live Capture with Larger Snaplen

```bash
sudo ./pqc-flow --live eth0 --snaplen 4096
```

### Live Capture with Real-Time Filtering

```bash
sudo ./pqc-flow --live eth0 | jq 'select(.pqc_flags > 0)'
```

### Multi-Core Live Capture

Run multiple instances for load distribution:

```bash
# Terminal 1
sudo ./pqc-flow --live eth0 --fanout 100

# Terminal 2
sudo ./pqc-flow --live eth0 --fanout 100
```

### Save Live Output to File

```bash
sudo ./pqc-flow --live eth0 --json >> flows.jsonl
```

### Pretty-Print Output

```bash
./pqc-flow capture.pcap | jq .
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (invalid arguments, file not found, etc.) |

## Environment Variables

No environment variables are currently used. All configuration is via command-line options.

## See Also

- [Understanding Output](output-format.md) - JSON field reference
- [Production Deployment](../operations/deployment.md) - Running as a service
