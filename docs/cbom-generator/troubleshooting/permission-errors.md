---
hide:
  - toc
---
# Permission Errors

Troubleshooting access denied and permission issues.


## Symptoms

- "Permission denied" errors in log
- Private keys not detected
- Service configs not readable
- Incomplete results

---

## Common Scenarios

### 1. Private Key Directories

**Problem**: `/etc/ssl/private` requires root access.

```
[error] key_scanner: Permission denied: /etc/ssl/private/server.key
```

**Solution**: Run as root:

```bash
sudo ./build/cbom-generator --output cbom.json
```

### 2. Service Configuration Files

**Problem**: Some service configs are root-only.

**Solution**: Run with elevated privileges:

```bash
sudo ./build/cbom-generator --discover-services --plugin-dir plugins --output cbom.json
```

### 3. User Home Directories

**Problem**: Cannot scan other users' files.

**Solution**: Either:
- Run as root for full access
- Accept partial results for accessible files

```bash
# Full access (requires root)
sudo ./build/cbom-generator --include-personal-data --output cbom.json /home

# Current user only
./build/cbom-generator --include-personal-data --output cbom.json ~/
```

---

## Graceful Degradation

CBOM Generator handles permission errors gracefully:

- Logs the error
- Continues scanning accessible files
- Reports partial results

This is by design - you get the best possible results given current permissions.

---

## Checking Permission Errors

### In Error Log

```bash
./build/cbom-generator --error-log /tmp/errors.log --output cbom.json
grep "Permission denied" /tmp/errors.log
```

### In Output Metadata

```bash
cat cbom.json | jq '.errors[] | select(.message | contains("Permission"))'
```

---

## Best Practices

### Development/Testing

```bash
# Run as current user, accept limitations
./build/cbom-generator --output cbom.json /etc/ssl /etc/ssh
```

### Production/Audit

```bash
# Run as root for complete inventory
sudo ./build/cbom-generator --output cbom.json --no-personal-data
```

### Least Privilege

Create a dedicated user with read access:

```bash
# Create scanner group
sudo groupadd cbom-scanner

# Add read permissions where needed
sudo setfacl -R -m g:cbom-scanner:r /etc/ssl/private/

# Run as member of that group
sudo -u cbom-user ./build/cbom-generator --output cbom.json
```

---

## Security Considerations

When running as root:

- Output may contain sensitive file paths
- Use `--no-personal-data` for external sharing
- Secure the output file appropriately

```bash
sudo ./build/cbom-generator --no-personal-data --output /secure/cbom.json
sudo chmod 600 /secure/cbom.json
```
