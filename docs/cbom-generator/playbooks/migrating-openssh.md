# OpenSSH PQC Migration

Enable Post-Quantum key exchange in OpenSSH to protect against future quantum computer attacks.

---

## Prerequisites

- OpenSSH 9.0 or later (includes sntrup761 hybrid KEX)
- CBOM Generator installed
- Root access for SSH configuration

### Check OpenSSH Version

```bash
ssh -V
# OpenSSH_9.0p1, OpenSSL 3.0.2 15 Mar 2022
```

---

## Step 1: Assess Current SSH Crypto Posture

Run CBOM scan to identify current SSH configuration:

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --pqc-report ssh-baseline.txt \
    --output ssh-baseline.json /etc/ssh
```

### Check Current KEX Algorithms

```bash
cat ssh-baseline.json | jq '.components[] |
    select(.name | test("ssh|sshd"; "i")) |
    {name, pqc_status: [.properties[] | select(.name == "cbom:pqc:status")][0].value}'
```

### View Current SSH Config

```bash
grep -E "^(KexAlgorithms|Ciphers|MACs)" /etc/ssh/sshd_config
```

---

## Step 2: Enable Hybrid PQC Key Exchange

Edit the SSH server configuration:

```bash
sudo nano /etc/ssh/sshd_config
```

Add or modify the KexAlgorithms line:

```
# Enable hybrid PQC KEX (NTRU Prime + X25519) as first priority
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
```

### Understanding the Algorithm Order

| Position | Algorithm | Security |
|----------|-----------|----------|
| 1st | sntrup761x25519-sha512@openssh.com | **PQC SAFE** (hybrid) |
| 2nd | curve25519-sha256 | Classical (quantum-vulnerable) |
| 3rd+ | Fallbacks | For older client compatibility |

---

## Step 3: Update Client Configuration (Optional)

For system-wide client PQC:

```bash
sudo nano /etc/ssh/ssh_config
```

Add:

```
# System-wide SSH client PQC KEX
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
```

For user-specific configuration:

```bash
nano ~/.ssh/config
```

Add to host sections:

```
Host *
    KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256
```

---

## Step 4: Restart SSH Service

```bash
# Test configuration first
sudo sshd -t

# If test passes, restart
sudo systemctl restart sshd

# Verify service is running
sudo systemctl status sshd
```

---

## Step 5: Verify with CBOM Scan

Re-run the CBOM scan:

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --pqc-report ssh-after-migration.txt \
    --output ssh-after-migration.json /etc/ssh
```

### Verify PQC Status

```bash
cat ssh-after-migration.json | jq '.components[] |
    select(.name | test("sshd|openssh"; "i")) |
    {name, pqc_status: [.properties[] | select(.name == "cbom:pqc:status")][0].value,
     rationale: [.properties[] | select(.name == "cbom:pqc:rationale")][0].value}'
```

Expected output:

```json
{
  "name": "sshd",
  "pqc_status": "SAFE",
  "rationale": "PQC-ready via sntrup761x25519-sha512@openssh.com"
}
```

---

## Step 6: Test PQC Negotiation

Connect and verify the KEX algorithm:

```bash
ssh -vvv localhost 2>&1 | grep "kex:"
# Should show: kex: algorithm: sntrup761x25519-sha512@openssh.com
```

---

## Rollback Plan

If issues occur, revert to classical-only KEX:

```bash
# /etc/ssh/sshd_config
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512

# Restart
sudo systemctl restart sshd
```

---

## Compatibility Notes

| Client Version | PQC KEX Support |
|----------------|-----------------|
| OpenSSH 9.0+ | Full (sntrup761) |
| OpenSSH 8.5-8.9 | Experimental (may need compile flag) |
| OpenSSH < 8.5 | No (falls back to curve25519) |

When connecting to systems with older OpenSSH, the hybrid KEX will fall back gracefully to curve25519-sha256.

---

## Success Criteria

- [ ] sshd_config contains sntrup761 as first KEX algorithm
- [ ] SSH service restart successful
- [ ] CBOM shows sshd with `cbom:pqc:status = SAFE`
- [ ] Test connection shows sntrup761 KEX negotiation
- [ ] PQC readiness score improved
