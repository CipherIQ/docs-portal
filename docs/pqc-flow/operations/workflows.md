# Use Cases & Workflows

Common usage patterns for **pqc-flow**.

## SSH PQC Audit

Audit SSH connections across your infrastructure to identify quantum-vulnerable servers.

### Capture SSH Traffic

```bash
# Start capture in background
sudo tcpdump -i eth0 -w ssh-audit.pcap 'port 22' &

# Run your SSH automation/connections
# ... connect to servers ...

# Stop capture
sudo pkill tcpdump
```

### Analyze Results

```bash
# Show all SSH flows with KEX info
./pqc-flow ssh-audit.pcap | jq '{
  server: .dip,
  kex: .ssh_kex_negotiated,
  pqc: (.pqc_flags > 0)
}'
```

### Find Quantum-Vulnerable Servers

```bash
./pqc-flow ssh-audit.pcap | jq 'select(.pqc_flags == 0 and .dp == 22) | .dip' | sort -u
```

### Generate SSH Audit Report

```bash
./pqc-flow ssh-audit.pcap | jq -s '
  group_by(.dip) | map({
    server: .[0].dip,
    connections: length,
    pqc_enabled: ([.[] | select(.pqc_flags > 0)] | length > 0),
    kex: .[0].ssh_kex_negotiated
  })
'
```

---

## TLS Inventory Assessment

Identify which HTTPS connections use PQC.

### Capture HTTPS Traffic

```bash
# Start capture
sudo tcpdump -i eth0 -w https.pcap 'port 443' &

# Browse or run automated tests
# ... visit websites ...

# Stop capture
sudo pkill tcpdump
```

### Show TLS PQC Status

```bash
./pqc-flow https.pcap | jq 'select(.tls_negotiated_group != "") | {
  server: .dip,
  group: .tls_negotiated_group,
  pqc: (.pqc_flags > 0)
}'
```

### Find Classical-Only TLS Servers

```bash
./pqc-flow https.pcap | jq 'select(.pqc_flags == 0 and .tls_negotiated_group != "") | {
  server: .dip,
  group: .tls_negotiated_group
}'
```

---

## Live PQC Monitoring

Monitor real-time PQC adoption.

### Show Only PQC-Enabled Flows

```bash
sudo ./pqc-flow --live eth0 | jq 'select(.pqc_flags > 0)'
```

### Real-Time Summary

```bash
sudo ./pqc-flow --live eth0 | jq -c '{
  ts: (.ts_us/1000000 | strftime("%H:%M:%S")),
  dst: .dip,
  port: .dp,
  pqc: .pqc_flags
}'
```

### Log to File with Filtering

```bash
sudo ./pqc-flow --live eth0 | tee flows.jsonl | jq 'select(.pqc_flags > 0)'
```

---

## PQC Adoption Statistics

Calculate PQC adoption rate from a capture.

### Basic Statistics

```bash
./pqc-flow traffic.pcap | jq -s '
  {
    total: length,
    pqc_enabled: [.[] | select(.pqc_flags > 0)] | length,
    classical_only: [.[] | select(.pqc_flags == 0)] | length
  } | . + {adoption_rate: ((.pqc_enabled / .total * 100) | floor | tostring + "%")}
'
```

### Statistics by Protocol

```bash
./pqc-flow traffic.pcap | jq -s '
  {
    ssh: {
      total: [.[] | select(.dp == 22)] | length,
      pqc: [.[] | select(.dp == 22 and .pqc_flags > 0)] | length
    },
    tls: {
      total: [.[] | select(.dp == 443 and .proto == 6)] | length,
      pqc: [.[] | select(.dp == 443 and .proto == 6 and .pqc_flags > 0)] | length
    }
  }
'
```

### Algorithm Distribution

```bash
./pqc-flow traffic.pcap | jq -s '
  [.[] | select(.pqc_flags > 0)] |
  group_by(.tls_negotiated_group // .ssh_kex_negotiated) |
  map({algorithm: .[0].tls_negotiated_group // .[0].ssh_kex_negotiated, count: length})
'
```

---

## Alert on Classical-Only Connections

Detect and alert on connections without PQC protection.

### Basic Alert Script

```bash
sudo ./pqc-flow --live eth0 | jq -c 'select(.pqc_flags == 0 and .dp == 443)' | \
while read flow; do
  server=$(echo $flow | jq -r '.dip')
  echo "WARNING: Classical TLS connection to $server"
done
```

### Alert with Logging

```bash
#!/bin/bash
LOG_FILE="/var/log/pqc-alerts.log"

sudo ./pqc-flow --live eth0 | jq -c 'select(.pqc_flags == 0)' | \
while read flow; do
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  server=$(echo $flow | jq -r '.dip')
  port=$(echo $flow | jq -r '.dp')
  echo "$timestamp ALERT: Classical crypto to $server:$port" | tee -a $LOG_FILE
done
```

### Alert on High-Priority Servers

```bash
# List of critical servers that MUST use PQC
CRITICAL_SERVERS="10.0.0.1 10.0.0.2 192.168.1.100"

sudo ./pqc-flow --live eth0 | jq -c 'select(.pqc_flags == 0)' | \
while read flow; do
  server=$(echo $flow | jq -r '.dip')
  if echo "$CRITICAL_SERVERS" | grep -q "$server"; then
    echo "CRITICAL: Quantum-vulnerable connection to critical server $server"
  fi
done
```

---

## Integration Examples

### Export to CSV

```bash
./pqc-flow traffic.pcap | jq -r '[.sip, .dip, .dp, .pqc_flags, .pqc_reason] | @csv' > flows.csv
```

### Send to Syslog

```bash
sudo ./pqc-flow --live eth0 | \
while read flow; do
  logger -t pqc-flow "$flow"
done
```

### Webhook Notification

```bash
sudo ./pqc-flow --live eth0 | jq -c 'select(.pqc_flags == 0 and .dp == 443)' | \
while read flow; do
  curl -X POST -H "Content-Type: application/json" \
    -d "{\"text\": \"Classical TLS: $(echo $flow | jq -r '.dip')\"}" \
    https://hooks.example.com/webhook
done
```

---

## Periodic Reporting

### Daily PQC Report

Create `/etc/cron.daily/pqc-report`:

```bash
#!/bin/bash
PCAP_DIR="/var/log/pcap"
REPORT_DIR="/var/log/pqc-reports"
DATE=$(date +%Y-%m-%d)

# Analyze yesterday's captures
for pcap in $PCAP_DIR/*.pcap; do
  pqc-flow "$pcap"
done | jq -s '
  {
    date: "'$DATE'",
    total_flows: length,
    pqc_enabled: [.[] | select(.pqc_flags > 0)] | length,
    classical_only: [.[] | select(.pqc_flags == 0)] | length,
    vulnerable_servers: [.[] | select(.pqc_flags == 0) | .dip] | unique
  }
' > "$REPORT_DIR/pqc-report-$DATE.json"
```

## See Also

- [Production Deployment](deployment.md) - Running as a service
- [Command-Line Reference](../usage/cli-reference.md) - All options
