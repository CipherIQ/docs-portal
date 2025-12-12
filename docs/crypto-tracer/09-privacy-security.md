# Privacy and Security

crypto-tracer is designed with privacy and security as core principles. This section explains the privacy features and security considerations.

## Privacy Features

### Automatic Path Redaction

crypto-tracer protects sensitive information by default through automatic path redaction.

#### Default Behavior (Redaction Enabled)

User home directories are automatically redacted:

| Original Path | Redacted Path | Reason |
|--------------|---------------|---------|
| `/home/alice/private.key` | `/home/USER/private.key` | Protects username |
| `/home/bob/cert.pem` | `/home/USER/cert.pem` | Protects username |
| `/home/john/Documents/key.pem` | `/home/USER/Documents/key.pem` | Protects username |
| `/root/secret.key` | `/home/ROOT/secret.key` | Protects root paths |
| `/root/.ssh/id_rsa` | `/home/ROOT/.ssh/id_rsa` | Protects root paths |

System paths are preserved (not redacted):

| Path | Preserved | Reason |
|------|-----------|---------|
| `/etc/ssl/certs/ca.crt` | ✓ | System path |
| `/usr/lib/libssl.so` | ✓ | System library |
| `/var/lib/ssl/cert.pem` | ✓ | System path |
| `/opt/app/keystore.jks` | ✓ | Application path |

#### Redaction Algorithm

The redaction follows these rules:

1. **Home directories** (`/home/username/`) → `/home/USER/`
2. **Root directory** (`/root/`) → `/home/ROOT/`
3. **System paths** (starting with `/etc/`, `/usr/`, `/lib/`, `/var/lib/`, `/opt/`) → Preserved
4. **Everything else** → Preserved

#### Disabling Redaction

Use `--no-redact` flag to see actual paths:

```bash
sudo crypto-tracer monitor --no-redact
```

**When to disable:**

- Debugging specific path issues
- When privacy is not a concern
- For detailed troubleshooting
- Internal use only

**When to keep enabled (default):**

- Sharing output with others
- Compliance and audit reports
- Public demonstrations
- Documentation and screenshots

### What is Never Logged

crypto-tracer is designed to capture only metadata, never sensitive content:

**Never Logged:**

- ✗ Private key content
- ✗ Certificate content
- ✗ Passwords or passphrases
- ✗ Plaintext data
- ✗ Environment variables with secrets
- ✗ Command-line arguments with passwords
- ✗ File content of any kind

**What is Logged:**

- ✓ File paths (redacted by default)
- ✓ Library paths
- ✓ Process names and PIDs
- ✓ Timestamps
- ✓ File types (certificate, private_key, keystore)
- ✓ Access modes (read, write)
- ✓ User IDs (numeric)

### Data Minimization

crypto-tracer follows data minimization principles:

1. **Only crypto-related events** - Filters out non-crypto activity
2. **Metadata only** - Never reads file content
3. **Local processing** - All data stays on your system
4. **No telemetry** - No data sent anywhere
5. **User control** - You control all output

## Security Considerations

### Read-Only Operation

crypto-tracer operates in read-only mode:

**What it does:**

- ✓ Observes system calls
- ✓ Reads /proc filesystem
- ✓ Captures event metadata

**What it doesn't do:**

- ✗ Modify files
- ✗ Change system configuration
- ✗ Interfere with processes
- ✗ Create files (except specified output)
- ✗ Modify kernel state

### eBPF Safety

All eBPF programs are verified by the Linux kernel for safety:

**Kernel Verifier Ensures:**

- No infinite loops
- No out-of-bounds memory access
- No kernel crashes
- No undefined behavior
- Bounded execution time

**Safety Guarantees:**

- Cannot crash the system
- Cannot affect monitored applications
- Cannot cause data corruption
- Automatic cleanup on exit
- Isolated execution environment

### Privilege Requirements

crypto-tracer requires elevated privileges to load eBPF programs:

**Required Capabilities:**

- **CAP_BPF** (kernel 5.8+) - Minimal privilege for eBPF
- **CAP_PERFMON** (kernel 5.8+) - For performance events
- **CAP_SYS_ADMIN** (older kernels) - Alternative for older systems
- **Root** - Always works but not recommended

**Why Privileges are Needed:**

- Loading eBPF programs requires kernel access
- Ensures only authorized users can monitor system
- Protects against unauthorized surveillance
- Standard security model for system monitoring tools

**Privilege Minimization:**

- Use CAP_BPF instead of root when possible
- Grant capabilities to binary, not user
- Capabilities are file-based, not persistent
- Can be revoked at any time

### No System Modifications

crypto-tracer makes no persistent changes:

**Temporary (While Running):**

- eBPF programs loaded in kernel
- Ring buffer allocated
- File descriptors open

**Permanent (None):**

- No configuration files created
- No system settings changed
- No kernel modules installed
- No persistent state

**On Exit:**

- All eBPF programs unloaded
- All resources freed
- System returns to original state
- No traces left (except output files you created)

### Data Protection

**Local Processing:**

- All data processing happens locally
- No network communication
- No external dependencies
- Works completely offline

**Output Control:**

- You control where output goes
- Default: stdout (terminal)
- Optional: file you specify
- No automatic logging

**No Telemetry:**

- No usage statistics collected
- No crash reports sent
- No phone-home functionality
- No external connections

## Best Practices

### For Production Use

1. **Use path redaction (default)**
   ```bash
   sudo crypto-tracer monitor  # Redaction enabled
   ```

2. **Write output to files, not stdout**
   ```bash
   sudo crypto-tracer monitor --output /var/log/crypto-events.json
   ```

3. **Use specific filters to reduce data**
   ```bash
   sudo crypto-tracer monitor --name nginx --file "/etc/ssl/*"
   ```

4. **Monitor performance impact**
   ```bash
   top -p $(pgrep crypto-tracer)
   ```

5. **Rotate output files**
   ```bash
   # Use logrotate or similar
   sudo crypto-tracer monitor --output /var/log/crypto-$(date +%Y%m%d).json
   ```

### For Security Audits

1. **Take snapshots before and after changes**
   ```bash
   crypto-tracer snapshot --output before.json
   # Make changes
   crypto-tracer snapshot --output after.json
   ```

2. **Use profile command for detailed analysis**
   ```bash
   sudo crypto-tracer profile --name myapp --duration 60 --output profile.json
   ```

3. **Save all output for documentation**
   ```bash
   sudo crypto-tracer monitor --output audit-$(date +%Y%m%d).json
   ```

4. **Use `--no-redact` only when necessary**
   ```bash
   # Only for internal use
   sudo crypto-tracer monitor --no-redact --output internal-audit.json
   ```

5. **Review output before sharing**
   ```bash
   # Check for sensitive information
   cat audit.json | jq '.' | less
   ```

### For Compliance

1. **Generate regular snapshots for inventory**
   ```bash
   # Daily snapshot
   0 0 * * * /usr/local/bin/crypto-tracer snapshot --output /var/log/crypto-inventory-$(date +\%Y\%m\%d).json
   ```

2. **Archive output with timestamps**
   ```bash
   # Keep 90 days of history
   find /var/log/crypto-*.json -mtime +90 -delete
   ```

3. **Document monitoring procedures**
   - What is being monitored
   - Why it's being monitored
   - Who has access to output
   - How long data is retained

4. **Include crypto-tracer version in reports**
   ```bash
   crypto-tracer --version >> compliance-report.txt
   ```

5. **Maintain audit trail**
   - Log when monitoring starts/stops
   - Record who initiated monitoring
   - Document any configuration changes

## Security Checklist

Before deploying crypto-tracer:

- [ ] Understand what data is collected
- [ ] Review privacy implications
- [ ] Configure appropriate filters
- [ ] Set up output file permissions
- [ ] Plan data retention policy
- [ ] Document monitoring procedures
- [ ] Train users on privacy features
- [ ] Test in non-production first
- [ ] Monitor performance impact
- [ ] Establish incident response procedures

## Threat Model

### What crypto-tracer Protects Against

**Visibility into crypto operations:**

- Unauthorized certificate access
- Unexpected library loading
- Misconfigured applications
- Compliance violations

### What crypto-tracer Does Not Protect Against

**Not a security tool:**

- Does not prevent attacks
- Does not block malicious activity
- Does not encrypt data
- Does not provide access control

**Use crypto-tracer for:**

- Monitoring and observability
- Troubleshooting and debugging
- PQC readiness assessment
- Compliance and auditing
- Configuration verification

**Do not use crypto-tracer for:**

- Real-time threat prevention
- Intrusion detection (use IDS/IPS)
- Access control (use proper permissions)
- Data encryption (use encryption tools)

## Responsible Use

### Ethical Considerations

**Do:**

- Monitor systems you own or have permission to monitor
- Inform users when monitoring is active
- Protect collected data appropriately
- Follow organizational policies
- Respect privacy regulations (GDPR, etc.)

**Don't:**

- Monitor systems without authorization
- Collect more data than necessary
- Share output without reviewing for sensitive info
- Use for unauthorized surveillance
- Violate privacy laws or regulations

### Legal Compliance

**Consider:**

- Local privacy laws
- Organizational policies
- User consent requirements
- Data retention regulations
- Cross-border data transfer rules

**Consult:**

- Legal counsel for compliance questions
- Privacy officer for data handling
- Security team for deployment approval
- IT policy for monitoring guidelines

## Reporting Security Issues

If you discover a security issue in crypto-tracer:

**Do:**

- Report privately to: team@cipheriq.io
- Provide detailed description
- Include steps to reproduce
- Allow time for fix before disclosure

**Don't:**

- Publicly disclose before fix
- Exploit the vulnerability
- Share with unauthorized parties

**We will:**

- Acknowledge within 48 hours
- Provide timeline for fix
- Credit you in security advisory (if desired)
- Keep you informed of progress

---

**Previous:** [Filtering and Options](08-filtering-options.md) | **Next:** [Troubleshooting](10-troubleshooting.md)
