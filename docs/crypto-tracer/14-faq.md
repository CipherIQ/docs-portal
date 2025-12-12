# Frequently Asked Questions (FAQ)

This section answers common questions about **crypto-tracer**.

## General Questions

### Q: Do I need root access to use crypto-tracer?

**A:** Most commands require elevated privileges (CAP_BPF or root) to load eBPF programs. However, the `snapshot` command works without any special privileges. You can also grant capabilities to the binary to run without sudo.

```bash
# Option 1: Run with sudo
sudo ./crypto-tracer monitor

# Option 2: Grant capabilities (no sudo needed after)
sudo setcap cap_bpf,cap_perfmon+ep ./crypto-tracer
./crypto-tracer monitor

# Option 3: snapshot needs no privileges
./crypto-tracer snapshot
```

### Q: Does crypto-tracer work on my Linux distribution?

**A:** **crypto-tracer** works on any Linux distribution with kernel 4.15 or later and eBPF support. This includes:

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- RHEL 8, 9
- Fedora 36+
- Amazon Linux 2023
- Alpine Linux 3.17+
- Any distribution with kernel 4.15+

Check your kernel version:
```bash
uname -r
```

### Q: Will crypto-tracer slow down my applications?

**A:** No. **crypto-tracer** has minimal performance impact:

- **crypto-tracer CPU usage:** <0.5% per core
- **Application overhead:** <1% additional CPU
- **Memory usage:** <50 MB
- **Negligible impact** in production environments

It uses efficient eBPF technology that runs in the kernel with very low overhead.

### Q: Is crypto-tracer safe to use in production?

**A:** Yes. **crypto-tracer** is designed for production use:

- **Read-only operation** - Never modifies files or system state
- **No system changes** - No configuration modifications
- **No process interference** - Doesn't affect monitored applications
- **Kernel-verified** - All eBPF programs verified by kernel for safety
- **Automatic cleanup** - Resources cleaned up on exit

### Q: Does crypto-tracer send data anywhere?

**A:** No. **crypto-tracer** has:

- **No telemetry** - Doesn't send any data externally
- **Works offline** - No network connectivity required
- **Local data only** - All data stays on your system
- **You control output** - You decide where data goes

## Usage Questions

### Q: Why am I not seeing any events?

**A:** Common reasons and solutions:

1. **Process not actually using crypto**
   ```bash
   # Check if process has crypto libraries loaded
   sudo lsof -p <PID> | grep -E "libssl|libcrypto"
   ```

2. **Filters too restrictive**
   ```bash
   # Try without filters first
   sudo ./crypto-tracer monitor --duration 10
   ```

3. **Libraries already loaded before monitoring started**
   ```bash
   # Start monitoring before starting the application
   # Or use snapshot to see already-loaded libraries
   ./crypto-tracer snapshot
   ```

4. **Child process issue** - See next question

### Q: How do I monitor a process that spawns child processes?

**A:** Use `--name` instead of `--pid`. Child processes have different PIDs but often share the same name.

```bash
# ❌ This misses child processes
sudo ./crypto-tracer profile --pid 1234

# ✅ This catches all processes with the name
sudo ./crypto-tracer profile --name myapp

# ✅ Or use monitor to see everything
sudo ./crypto-tracer monitor --name myapp
```

**Why this matters:** If a bash script (PID 1234) spawns `cat` (PID 1235) to read a certificate, the file access happens in PID 1235, not 1234.

### Q: Can I monitor multiple processes at once?

**A:** Yes, several ways:

```bash
# Monitor all crypto activity system-wide
sudo ./crypto-tracer monitor

# Monitor all processes with specific name
sudo ./crypto-tracer monitor --name nginx

# Monitor specific file across all processes
sudo ./crypto-tracer monitor --file "*.pem"
```

The `monitor` command without filters shows all crypto activity from all processes.

### Q: How long should I run a profile?

**A:** It depends on your use case:

- **Default:** 30 seconds (usually sufficient)
- **Application startup:** Profile during startup (10-30 seconds)
- **Long-running apps:** 30-60 seconds to capture periodic activity
- **Troubleshooting:** As long as needed to reproduce the issue

```bash
# Default 30 seconds
sudo ./crypto-tracer profile --pid 1234

# Custom duration
sudo ./crypto-tracer profile --pid 1234 --duration 60
```

### Q: What's the difference between monitor and profile?

**A:** They serve different purposes:

| Feature | monitor | profile |
|---------|---------|---------|
| **Purpose** | Real-time event stream | Aggregated report |
| **Scope** | System-wide or filtered | Single process |
| **Output** | Stream of events | Summary document |
| **Duration** | Unlimited (default) | 30 seconds (default) |
| **Use case** | Observing activity | Analyzing specific process |

**Use monitor when:**

- You want to see what's happening in real-time
- You need to observe multiple processes
- You want to pipe events to other tools

**Use profile when:**

- You want detailed analysis of one process
- You need aggregated statistics
- You want a summary report

## Technical Questions

### Q: What is eBPF?

**A:** eBPF (Extended Berkeley Packet Filter) is a Linux kernel technology that allows safe, efficient programs to run in the kernel without modifying kernel code or loading kernel modules.

**Key features:**

- Runs in kernel space for efficiency
- Verified by kernel for safety
- Cannot crash the system
- Used for observability, networking, and security

**crypto-tracer** uses eBPF to observe system calls with minimal overhead.

### Q: What is CO-RE?

**A:** CO-RE (Compile Once - Run Everywhere) is a technology that makes eBPF programs portable across different kernel versions.

**Benefits:**

- Single binary works on multiple kernels
- No recompilation needed
- Automatic adaptation to kernel structures
- Handles kernel version differences

**crypto-tracer** uses CO-RE to work on various kernels (4.15+) without recompilation.

### Q: What is BTF?

**A:** BTF (BPF Type Format) provides kernel structure information that enables CO-RE.

**How it works:**

- Modern kernels (5.2+) include BTF data
- Provides type information for kernel structures
- Enables portable eBPF programs

**If your kernel doesn't have BTF:**

- **crypto-tracer** automatically uses fallback headers
- Functionality is the same
- No action needed from you

Check BTF support:
```bash
ls -la /sys/kernel/btf/vmlinux
```

### Q: Why do I need CAP_BPF or CAP_SYS_ADMIN?

**A:** Loading eBPF programs requires special privileges for security reasons:

- **CAP_BPF** (kernel 5.8+): Minimal privilege for eBPF operations
- **CAP_SYS_ADMIN** (older kernels): Broader privilege that includes eBPF

**Why it's needed:**

- eBPF programs run in kernel space
- Can observe system-wide activity
- Requires elevated privileges to prevent abuse

**Alternatives:**

- Run with sudo (simplest)
- Grant capabilities to binary (no sudo needed after)

### Q: Can I run crypto-tracer in a container?

**A:** Yes, but the container needs special configuration:

**Requirements:**

- Privileged mode OR CAP_BPF/CAP_SYS_ADMIN capability
- Access to host kernel (eBPF runs in kernel, not container)
- Kernel 4.15+ on the host

**Docker example:**
```bash
# With privileged mode
docker run --privileged \
  -v /sys/kernel/debug:/sys/kernel/debug:ro \
  crypto-tracer monitor

# With specific capabilities (preferred)
docker run --cap-add=CAP_BPF --cap-add=CAP_PERFMON \
  -v /sys/kernel/debug:/sys/kernel/debug:ro \
  crypto-tracer monitor
```

**Note:** The container monitors the host system, not just the container.

## Privacy and Security Questions

### Q: What data does crypto-tracer collect?

**A:** **crypto-tracer** collects metadata only:

**What IS collected:**

- File paths (redacted by default)
- Library paths
- Process names and PIDs
- User IDs (UIDs)
- Timestamps
- File types (certificate, key, keystore)
- Access modes (read, write)

**What is NEVER collected:**

- File content (certificates, keys, data)
- Passwords or passphrases
- Plaintext data
- Environment variables
- Private key material
- Certificate content

### Q: How does path redaction work?

**A:** By default, user home directories are redacted to protect privacy:

| Original Path | Redacted Path |
|--------------|---------------|
| `/home/alice/key.pem` | `/home/USER/key.pem` |
| `/home/bob/cert.pem` | `/home/USER/cert.pem` |
| `/root/secret.key` | `/home/ROOT/secret.key` |
| `/etc/ssl/certs/ca.crt` | `/etc/ssl/certs/ca.crt` (preserved) |

**System paths are preserved** because they don't contain user-specific information.

**Disable redaction:**
```bash
sudo ./crypto-tracer monitor --no-redact
```

### Q: Can crypto-tracer see my private keys?

**A:** No. **crypto-tracer** only sees that a file was opened, not its content.

**What crypto-tracer knows:**

- A file named `/etc/ssl/private/server.key` was opened
- Process `nginx` opened it
- It was opened for reading
- Timestamp of access

**What crypto-tracer does NOT know:**

- The content of the key
- The key material
- Any data read from the file

**crypto-tracer** observes file system operations, not file content.

### Q: Is the output safe to share?

**A:** With default path redaction enabled, yes. The output contains no sensitive data.

**Before sharing:**

1. Verify path redaction is enabled (default)
2. Review output for any sensitive information
3. Check that `--no-redact` was not used

**If you used `--no-redact`:**

- Review output carefully
- Redact any sensitive paths manually
- Consider regenerating with redaction enabled

## Troubleshooting Questions

### Q: Why do I get "Permission denied"?

**A:** You need elevated privileges to load eBPF programs.

**Solutions:**

```bash
# Option 1: Run with sudo
sudo ./crypto-tracer monitor

# Option 2: Grant capabilities (kernel 5.8+)
sudo setcap cap_bpf,cap_perfmon+ep ./crypto-tracer
./crypto-tracer monitor

# Option 3: Grant capabilities (older kernels)
sudo setcap cap_sys_admin+ep ./crypto-tracer
./crypto-tracer monitor
```

**Verify capabilities:**
```bash
getcap ./crypto-tracer
```

### Q: Why do I get "Kernel too old"?

**A:** **crypto-tracer** requires kernel 4.15 or later.

**Check your kernel:**
```bash
uname -r
```

**Upgrade kernel:**

Ubuntu/Debian:
```bash
sudo apt update
sudo apt upgrade linux-generic
sudo reboot
```

RHEL/Fedora:
```bash
sudo yum update kernel
sudo reboot
```

**Supported kernels:**

- Minimum: 4.15
- Recommended: 5.8+ (for CAP_BPF)

### Q: Why did my capabilities disappear after rebuilding?

**A:** Capabilities are tied to the specific binary file. Rebuilding creates a new binary without capabilities.

**Solution - Re-grant after each build:**
```bash
make
sudo setcap cap_bpf,cap_perfmon+ep ./build/crypto-tracer
```

**Or create a build script:**
```bash
cat > build-and-cap.sh <<'EOF'
#!/bin/bash
make && sudo setcap cap_bpf,cap_perfmon+ep ./build/crypto-tracer
EOF
chmod +x build-and-cap.sh
./build-and-cap.sh
```

### Q: Why is the JSON output invalid?

**A:** Common causes and solutions:

**Cause 1: Mixing verbose output with JSON**
```bash
# Wrong - verbose goes to stdout with JSON
sudo ./crypto-tracer monitor --verbose > events.json

# Right - separate verbose output
sudo ./crypto-tracer monitor > events.json 2> debug.log
```

**Cause 2: Incomplete output**

- Monitoring was interrupted
- Process crashed
- Disk full

**Cause 3: Wrong format for parser**
```bash
# json-stream: one JSON per line (not a valid JSON array)
# Process line by line:
cat events.json | while read line; do echo "$line" | jq '.'; done

# Or convert to array:
cat events.json | jq -s '.' > events-array.json
```

### Q: How do I report a bug?

**A:** Follow these steps:

1. **Enable verbose logging:**
   ```bash
   sudo ./crypto-tracer monitor --verbose 2>&1 | tee debug.log
   ```

2. **Collect system information:**
   ```bash
   ./crypto-tracer --version
   uname -r
   cat /etc/os-release
   getcap ./crypto-tracer
   ```

3. **Create minimal reproduction:**
   - Simplest command that shows the bug
   - Steps to reproduce
   - Expected vs actual behavior

4. **Report on GitHub Issues:**
   - Include all information above
   - Attach debug.log
   - Describe what you expected to happen
   - Describe what actually happened

## Output and Format Questions

### Q: How do I view json-stream output?

**A:** Each line is a separate JSON object:

```bash
# View raw
cat events.json | less

# Pretty-print each line
cat events.json | while read line; do 
    echo "$line" | jq '.'
    echo "---"
done | less

# Filter with jq
cat events.json | jq 'select(.event_type == "file_open")'

# Extract field
cat events.json | jq -r '.process'
```

### Q: Can I convert json-stream to json-array?

**A:** Yes, use jq:

```bash
# Convert json-stream to json-array
cat events.json | jq -s '.' > events-array.json

# Or use json-array format from the start
sudo ./crypto-tracer monitor --format json-array
```

**Reverse conversion:**
```bash
# Convert json-array to json-stream
cat events-array.json | jq -c '.[]' > events-stream.json
```

### Q: How do I parse the output in my script?

**A:** Depends on the format:

**For json-stream (recommended):**
```bash
cat events.json | while read line; do
    # Each $line is a complete JSON object
    process=$(echo "$line" | jq -r '.process')
    file=$(echo "$line" | jq -r '.file')
    echo "Process $process accessed $file"
done
```

**For json-array:**
```bash
# Extract all processes
cat events.json | jq -r '.[] | .process'

# Filter and process
cat events.json | jq -r '.[] | select(.event_type == "file_open") | .file'
```

**In Python:**
```python
import json

# json-stream
with open('events.json') as f:
    for line in f:
        event = json.loads(line)
        print(event['process'])

# json-array
with open('events.json') as f:
    events = json.load(f)
    for event in events:
        print(event['process'])
```

### Q: What timestamp format is used?

**A:** ISO 8601 with microsecond precision in UTC:

```
2024-12-08T10:30:45.123456Z
```

**Parse in bash:**
```bash
# Convert to local time
date -d "2024-12-08T10:30:45.123456Z" "+%Y-%m-%d %H:%M:%S %Z"
```

**Parse in Python:**
```python
from datetime import datetime

timestamp = "2024-12-08T10:30:45.123456Z"
dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
print(dt)
```

**Parse with jq:**
```bash
# Extract timestamp
cat events.json | jq -r '.timestamp'

# Convert to Unix epoch
cat events.json | jq -r '.timestamp | fromdateiso8601'
```

---

**Previous:** [Integration](13-integration.md) | **Next:** [Support and Resources](15-support.md)
