# Production Deployment

Deploy **pqc-flow** as a production service.

## Systemd Service

### Service File

Create `/etc/systemd/system/pqc-flow.service`:

```ini
[Unit]
Description=PQC Flow Analyzer
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pqc-flow --live eth0 --json
StandardOutput=append:/var/log/pqc-flow/flows.jsonl
StandardError=append:/var/log/pqc-flow/error.log
Restart=always
RestartSec=5
RuntimeMaxSec=21600

# Security hardening
User=nobody
Group=nogroup
CapabilityBoundingSet=CAP_NET_RAW CAP_NET_ADMIN
AmbientCapabilities=CAP_NET_RAW CAP_NET_ADMIN
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/pqc-flow

[Install]
WantedBy=multi-user.target
```

### Deployment Steps

```bash
# Create log directory
sudo mkdir -p /var/log/pqc-flow
sudo chown nobody:nogroup /var/log/pqc-flow

# Install the binary
sudo cp build/pqc-flow /usr/local/bin/
sudo chmod 755 /usr/local/bin/pqc-flow

# Install and start service
sudo systemctl daemon-reload
sudo systemctl enable pqc-flow
sudo systemctl start pqc-flow
```

### Verify Service

```bash
# Check status
sudo systemctl status pqc-flow

# View logs
sudo journalctl -u pqc-flow -f

# View flow output
tail -f /var/log/pqc-flow/flows.jsonl | jq 'select(.pqc_flags > 0)'
```

---

## Capability Setup

Grant network capture capabilities without running as root.

### Grant Capabilities

```bash
sudo setcap cap_net_raw,cap_net_admin+ep /usr/local/bin/pqc-flow
```

### Verify Capabilities

```bash
getcap /usr/local/bin/pqc-flow
# Expected: /usr/local/bin/pqc-flow cap_net_admin,cap_net_raw=ep
```

### Why Capabilities?

| Approach | Security | Convenience |
|----------|----------|-------------|
| Running as root | Low | High |
| sudo | Medium | Medium |
| Capabilities | High | High |

Capabilities provide fine-grained permissions without full root access.

---

## Log Rotation

### Logrotate Configuration

Create `/etc/logrotate.d/pqc-flow`:

```
/var/log/pqc-flow/*.jsonl {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 nobody nogroup
    postrotate
        systemctl reload pqc-flow 2>/dev/null || true
    endscript
}

/var/log/pqc-flow/error.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0640 nobody nogroup
}
```

### Test Rotation

```bash
sudo logrotate -d /etc/logrotate.d/pqc-flow
```

---

## Performance Tuning

### Snaplen Configuration

Increase packet capture length for large TLS ClientHello:

```ini
ExecStart=/usr/local/bin/pqc-flow --live eth0 --snaplen 4096
```

| Snaplen | Use Case | Memory Impact |
|---------|----------|---------------|
| 2048 (default) | Most handshakes | Lower |
| 4096 | Large ClientHello | Moderate |

### Multi-Core Distribution

For high-traffic networks (>100K packets/second):

```ini
ExecStart=/usr/local/bin/pqc-flow --live eth0 --fanout 100
```

Run multiple instances with the same fanout group:

```bash
# Multiple service instances
sudo systemctl enable pqc-flow@1
sudo systemctl enable pqc-flow@2
sudo systemctl start pqc-flow@1
sudo systemctl start pqc-flow@2
```

### Memory Considerations

| Scenario | Memory Usage |
|----------|--------------|
| Base (ring buffer + hash table) | ~130 MB |
| Per concurrent flow | ~24 KB |
| 1,000 concurrent flows | ~154 MB |
| 10,000 concurrent flows | ~370 MB |

### Memory Management

Current limitation: Flow table grows without cleanup in live mode.

Workaround using `RuntimeMaxSec`:

```ini
RuntimeMaxSec=21600  # Restart every 6 hours
```

---

## High Availability

### Multiple Interfaces

Monitor multiple interfaces with separate service instances:

```ini
# /etc/systemd/system/pqc-flow@.service
[Unit]
Description=PQC Flow Analyzer on %i
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pqc-flow --live %i --json
StandardOutput=append:/var/log/pqc-flow/%i.jsonl
# ... rest of configuration
```

Deploy:

```bash
sudo systemctl enable pqc-flow@eth0
sudo systemctl enable pqc-flow@eth1
sudo systemctl start pqc-flow@eth0
sudo systemctl start pqc-flow@eth1
```

### Load Balancing with PACKET_FANOUT

```bash
# Instance 1
./pqc-flow --live eth0 --fanout 100 >> /var/log/pqc-flow/flows-1.jsonl &

# Instance 2
./pqc-flow --live eth0 --fanout 100 >> /var/log/pqc-flow/flows-2.jsonl &
```

Packets are distributed across instances sharing the same fanout group.

---

## Security Hardening

### Systemd Security Options

The example service file includes these security features:

| Option | Purpose |
|--------|---------|
| `User=nobody` | Run as unprivileged user |
| `CapabilityBoundingSet` | Limit available capabilities |
| `NoNewPrivileges=true` | Prevent privilege escalation |
| `ProtectSystem=strict` | Read-only filesystem |
| `ProtectHome=true` | Hide /home directories |
| `ReadWritePaths` | Explicit write access |

### Network Isolation

If **pqc-flow** only needs to capture, not transmit:

```ini
RestrictAddressFamilies=AF_PACKET AF_UNIX
```

---

## Monitoring the Service

### Health Check Script

```bash
#!/bin/bash
# /usr/local/bin/pqc-flow-healthcheck

# Check if service is running
if ! systemctl is-active --quiet pqc-flow; then
  echo "CRITICAL: pqc-flow service not running"
  exit 2
fi

# Check if output is being generated
LAST_LINE=$(tail -1 /var/log/pqc-flow/flows.jsonl 2>/dev/null)
if [ -z "$LAST_LINE" ]; then
  echo "WARNING: No recent flow output"
  exit 1
fi

echo "OK: pqc-flow is running"
exit 0
```

### Prometheus Metrics (Example)

Create a wrapper to expose metrics:

```bash
#!/bin/bash
# Count flows by PQC status
TOTAL=$(wc -l < /var/log/pqc-flow/flows.jsonl)
PQC=$(jq 'select(.pqc_flags > 0)' /var/log/pqc-flow/flows.jsonl | wc -l)

cat << EOF
# HELP pqc_flows_total Total flows analyzed
# TYPE pqc_flows_total counter
pqc_flows_total $TOTAL

# HELP pqc_flows_pqc_enabled Flows with PQC enabled
# TYPE pqc_flows_pqc_enabled counter
pqc_flows_pqc_enabled $PQC
EOF
```

## See Also

- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Command-Line Reference](../usage/cli-reference.md) - All options
