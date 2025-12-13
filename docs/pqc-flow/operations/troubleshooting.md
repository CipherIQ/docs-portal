# Troubleshooting

Common issues and solutions for **pqc-flow**.

## No Output from PCAP File

**Symptoms:** `./pqc-flow file.pcap` produces no output.

### Check for Handshakes

```bash
# Verify capture contains TCP SYN packets (connection starts)
tcpdump -r file.pcap 'tcp[tcpflags] & tcp-syn != 0' | head
```

### Check Capture Timing

Handshakes occur at connection start. If capture started after connections were established, no handshakes will be present.

**Solution:** Restart capture before establishing connections.

### Check Port Filter

**pqc-flow** only processes traffic on specific ports:

```bash
# Verify traffic on supported ports
tcpdump -r file.pcap 'port 22 or port 443' | head
```

Supported ports: TCP 22, 443; UDP 443, 500, 4500, 51820

---

## Live Capture Permission Denied

**Symptoms:** `Operation not permitted` when running `--live`.

### Solution 1: Use sudo

```bash
sudo ./pqc-flow --live eth0
```

### Solution 2: Grant Capabilities

```bash
sudo setcap cap_net_raw,cap_net_admin+ep ./pqc-flow
./pqc-flow --live eth0
```

### Solution 3: Verify Interface

```bash
# Check interface exists
ip link show eth0

# List all interfaces
ip link show
```

---

## PQC Flags Always Zero

**Symptoms:** All flows show `pqc_flags: 0` despite expecting PQC.

### Cause 1: Server Doesn't Support PQC

Not all servers support PQC yet. Test with a known PQC endpoint:

```bash
# Cloudflare PQC test
curl -I https://pq.cloudflareresearch.com/
```

### Cause 2: Client Doesn't Support PQC

Standard tools don't support TLS PQC:

| Tool | PQC Support |
|------|-------------|
| curl | No |
| wget | No |
| Chrome | Yes (with flag) |
| OpenSSH 9.0+ | Yes (sntrup) |

**TLS testing:**

```bash
google-chrome --enable-features=PostQuantumKyber https://pq.cloudflareresearch.com/
```

**SSH testing:**

```bash
ssh -oKexAlgorithms=sntrup761x25519-sha512@openssh.com user@host
```

### Cause 3: Session Resumption

Browser reused an existing TLS session (no handshake).

**Solution:** Clear browser cache and retry:

```bash
# Chrome: clear cache or use incognito
google-chrome --incognito --enable-features=PostQuantumKyber https://example.com/
```

### Cause 4: SSH Not Offering PQC KEX

Force PQC key exchange:

```bash
ssh -oKexAlgorithms=sntrup761x25519-sha512@openssh.com user@host
```

Check supported KEX algorithms:

```bash
ssh -Q kex | grep sntrup
```

---

## Missing Protocol Fields

**Symptoms:** `ssh_kex_negotiated` or `tls_negotiated_group` is empty.

### Cause 1: Incomplete Handshake Capture

Ensure capture includes the full handshake.

**Solution:** Increase snaplen:

```bash
./pqc-flow --live eth0 --snaplen 4096
```

### Cause 2: TLS 1.2 Encrypted Extensions

TLS 1.3 ClientHello/ServerHello are cleartext. TLS 1.2 may encrypt some extensions.

**Solution:** Ensure TLS 1.3 is used.

### Verification with ndpiReader

```bash
ndpiReader -i file.pcap -J | jq . | grep -i 'kex\|group'
```

---

## High Memory Usage

**Symptoms:** **pqc-flow** memory grows over time in live mode.

### Cause

Flow table accumulates (no cleanup in current version).

### Solution 1: RuntimeMaxSec

Use systemd to restart periodically:

```ini
[Service]
RuntimeMaxSec=21600  # Restart every 6 hours
```

### Solution 2: Manual Restart

```bash
sudo systemctl restart pqc-flow
```

### Solution 3: Monitor Memory

```bash
# Check memory usage
ps -o rss= -p $(pgrep pqc-flow) | awk '{print $1/1024 " MB"}'
```

---

## Interface Not Found

**Symptoms:** Error about interface not existing.

### Find Correct Interface Name

```bash
# List all interfaces
ip link show

# Common interface names:
# - eth0, eth1 (legacy naming)
# - enp0s31f6, ens192 (predictable naming)
# - wlan0, wlp2s0 (wireless)
```

### Verify Interface is Up

```bash
ip link show eth0
# Should show "state UP"
```

---

## No Traffic Captured

**Symptoms:** Live mode runs but no output.

### Check Traffic Exists

```bash
# Verify traffic on interface
sudo tcpdump -i eth0 -c 10
```

### Check Port Filter

**pqc-flow** only captures on specific ports. Verify traffic on those ports:

```bash
sudo tcpdump -i eth0 'port 22 or port 443' -c 10
```

### Check Promiscuous Mode

```bash
# Verify interface in promiscuous mode
ip link show eth0 | grep PROMISC
```

---

## Verifying PQC Support

### Test SSH PQC

```bash
# Check if client supports sntrup
ssh -Q kex | grep sntrup

# Expected output:
# sntrup761x25519-sha512@openssh.com

# Test connection with verbose output
ssh -v -oKexAlgorithms=sntrup761x25519-sha512@openssh.com user@host 2>&1 | grep 'kex:'
```

### Test TLS PQC

```bash
# Cloudflare test endpoint
curl -I https://pq.cloudflareresearch.com/

# View in Chrome DevTools > Security tab
google-chrome --enable-features=PostQuantumKyber https://pq.cloudflareresearch.com/
```

---

## Debug Checklist

When troubleshooting, verify each step:

| Step | Check | Command |
|------|-------|---------|
| 1 | Binary works | `./pqc-flow --mock` |
| 2 | Interface exists | `ip link show eth0` |
| 3 | Traffic present | `sudo tcpdump -i eth0 -c 10` |
| 4 | Permissions | `getcap ./pqc-flow` |
| 5 | Handshakes in PCAP | `tcpdump -r file.pcap 'tcp[tcpflags] & tcp-syn != 0'` |
| 6 | Correct ports | `tcpdump -r file.pcap 'port 22 or port 443'` |
| 7 | PQC-capable client | `ssh -Q kex \| grep sntrup` |
| 8 | PQC-capable server | Test against `pq.cloudflareresearch.com` |

---

## Getting Help

If these solutions don't resolve your issue:

1. Check the output of `./pqc-flow --mock` works correctly
2. Verify with `ndpiReader` that nDPI sees the expected metadata
3. Capture a small PCAP and test offline before live capture
4. Check system logs: `journalctl -u pqc-flow`

## See Also

- [Command-Line Reference](../usage/cli-reference.md) - All options
- [Protocol Coverage](../usage/protocols.md) - Supported protocols
