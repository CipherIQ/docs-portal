# Troubleshooting

This section covers common problems you may encounter when using crypto-tracer and their solutions.

## Common Issues

### Issue: Permission Denied

**Error:**
```
Error: Permission denied
Failed to load eBPF programs: Operation not permitted
```

**Cause:** crypto-tracer needs special privileges to load eBPF programs into the kernel.

**Solution:**

You have three options:

**Option 1: Run with sudo (Simplest)**
```bash
sudo ./crypto-tracer monitor
```

**Option 2: Grant capabilities (kernel 5.8+)**
```bash
# One-time setup
sudo setcap cap_bpf,cap_perfmon+ep ./crypto-tracer

# Now run without sudo
./crypto-tracer monitor
```

**Option 3: Grant capabilities (older kernels)**
```bash
# For kernels < 5.8
sudo setcap cap_sys_admin+ep ./crypto-tracer

# Now run without sudo
./crypto-tracer monitor
```

**Check current capabilities:**
```bash
getcap ./crypto-tracer

# Expected output (kernel 5.8+):
# ./crypto-tracer = cap_bpf,cap_perfmon+ep
```

**Remove capabilities if needed:**
```bash
sudo setcap -r ./crypto-tracer
```

### Issue: No Events Captured

**Symptoms:** Monitor runs but no events appear, even though you expect crypto activity.

**Diagnosis Steps:**

**1. Run with verbose mode to see what's happening:**
```bash
sudo ./crypto-tracer monitor --verbose
```

**2. Check if target process actually uses crypto:**
```bash
# Find the process
ps aux | grep myapp

# Check open files and libraries
sudo lsof -p <PID> | grep -E "libssl|libcrypto|\.pem|\.crt"

# Check loaded libraries
cat /proc/<PID>/maps | grep -E "libssl|libcrypto"
```

**3. Generate test activity:**
```bash
# Access a certificate file
cat /etc/ssl/certs/ca-certificates.crt > /dev/null

# Run openssl command
openssl version

# Load a library
python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"
```

**Common Causes:**

1. **Process not actually using crypto**
   - Verify the process loads crypto libraries
   - Check if it accesses crypto files

2. **Filters too restrictive**
   - Try without filters first
   - Gradually add filters to narrow down

3. **Libraries already loaded**
   - Library loading happens at process startup
   - Start monitoring before starting the process
   - Or use `snapshot` to see already-loaded libraries

4. **Child process issue**
   - See next section

### Issue: Missing Events from Child Processes

**Problem:** Profiling by PID but missing file access events.

**Cause:** Child processes have different PIDs!

When a process spawns a child (e.g., a bash script that runs `cat` to read a file), the file access happens in the child process with a different PID.

**Example:**
```bash
# Parent process (PID 1234): bash script
# Child process (PID 1235): cat command reading certificate
# If you filter by PID 1234, you'll miss the file access!
```

**Solution:**

**Use --name instead of --pid:**
```bash
# Instead of this (misses child processes)
sudo ./crypto-tracer profile --pid 1234

# Use this (catches processes with same name)
sudo ./crypto-tracer profile --name myapp

# Or use monitor to see all events
sudo ./crypto-tracer monitor --name myapp
```

**Why this works:**

- `--name` matches all processes with that name
- Child processes often have the same or similar name
- Catches the actual process doing the work

### Issue: Kernel Too Old

**Error:**
```
Error: Kernel version 3.10 is not supported (requires 4.15+)
```

**Cause:** crypto-tracer requires Linux kernel 4.15 or later for eBPF support.

**Check current kernel:**
```bash
uname -r
# Example output: 5.15.0-91-generic
```

**Solution: Upgrade kernel**

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt upgrade linux-generic
sudo reboot
```

**RHEL/Fedora:**
```bash
sudo yum update kernel
sudo reboot
```

**After reboot, verify:**
```bash
uname -r
```

**Supported Kernels:**

- **Minimum:** 4.15
- **Recommended:** 5.8+ (for CAP_BPF support)
- **Optimal:** 5.15+ (best eBPF features)

### Issue: Invalid JSON Output

**Problem:** JSON parsing fails when processing output.

**Symptoms:**
```
Error: Invalid JSON at line 1
```

**Common Causes:**

1. **Mixing verbose output with JSON**
2. **Incomplete output** (monitoring interrupted)
3. **Wrong format for your parser**

**Solutions:**

**Use json-stream format (each line is valid JSON):**
```bash
sudo ./crypto-tracer monitor --format json-stream > events.json

# Each line is a complete JSON object
cat events.json | while read line; do 
    echo "$line" | jq '.'
done
```

**Separate verbose output from JSON:**
```bash
# Redirect stderr to separate file
sudo ./crypto-tracer monitor > events.json 2> debug.log

# Now events.json contains only JSON
# debug.log contains verbose output
```

**Process line by line for json-stream:**
```bash
# Don't try to parse the whole file as one JSON object
# Process each line separately
cat events.json | while read line; do 
    echo "$line" | jq '.event_type'
done
```

**Convert json-stream to json-array if needed:**
```bash
# Use jq slurp mode
cat events.json | jq -s '.' > events-array.json
```

### Issue: High CPU Usage

**Symptoms:** crypto-tracer using >5% CPU, or system feels slow.

**Diagnosis:**

**Check event rate:**
```bash
# Run with verbose to see statistics
sudo ./crypto-tracer monitor --duration 10 --verbose
# Look for "events processed" and "events filtered" in output
```

**Monitor CPU usage:**
```bash
# Watch crypto-tracer CPU usage
top -p $(pgrep crypto-tracer)

# Or use htop
htop -p $(pgrep crypto-tracer)
```

**Common Causes:**

- Very high event rate (>10,000 events/second)
- System-wide monitoring without filters
- Inefficient output format

**Solutions:**

**1. Use filters to reduce event volume:**
```bash
# Instead of monitoring everything
sudo ./crypto-tracer monitor

# Monitor specific process
sudo ./crypto-tracer monitor --name nginx

# Monitor specific files
sudo ./crypto-tracer monitor --file "/etc/ssl/certs/*"

# Combine filters
sudo ./crypto-tracer monitor --name nginx --file "*.pem"
```

**2. Use efficient output format:**
```bash
# Most efficient (default)
sudo ./crypto-tracer monitor --format json-stream

# Less efficient (pretty printing overhead)
sudo ./crypto-tracer monitor --format json-pretty
```

**3. Write to fast storage:**
```bash
# Write to tmpfs for best performance
sudo ./crypto-tracer monitor --output /tmp/events.json

# Avoid network filesystems
```

**4. Limit monitoring duration:**
```bash
# Short monitoring periods
sudo ./crypto-tracer monitor --duration 60
```

### Issue: Capabilities Lost After Rebuild

**Problem:** After rebuilding crypto-tracer, capabilities are gone and you get permission denied again.

**Cause:** Capabilities are tied to the specific binary file. When you rebuild, a new binary is created without capabilities.

**Solution:**

**Re-grant capabilities after each build:**
```bash
make
sudo setcap cap_bpf,cap_perfmon+ep ./build/crypto-tracer
```

**Or create a build script:**
```bash
cat > build-and-cap.sh <<'EOF'
#!/bin/bash
set -e

echo "Building crypto-tracer..."
make

echo "Granting capabilities..."
sudo setcap cap_bpf,cap_perfmon+ep ./build/crypto-tracer

echo "Verifying capabilities..."
getcap ./build/crypto-tracer

echo "Done! You can now run: ./build/crypto-tracer monitor"
EOF

chmod +x build-and-cap.sh
```

**Use the script:**
```bash
./build-and-cap.sh
```

**Add to Makefile (optional):**
```makefile
# Add this target to your Makefile
.PHONY: install-caps
install-caps: all
	sudo setcap cap_bpf,cap_perfmon+ep $(BUILD_DIR)/crypto-tracer
	@echo "Capabilities granted"
```

Then use:
```bash
make install-caps
```

### Issue: eBPF Program Load Failure

**Error:**
```
Error: Failed to load eBPF program: Invalid argument
libbpf: prog 'trace_file_open': BPF program load failed
```

**Cause:** eBPF program rejected by kernel verifier, or kernel doesn't support required features.

**Diagnosis:**

**Enable verbose libbpf logging:**
```bash
export LIBBPF_LOG_LEVEL=4
sudo ./crypto-tracer monitor --verbose 2>&1 | tee bpf-debug.log
```

**Check kernel BPF support:**
```bash
# Check if BPF is enabled
cat /boot/config-$(uname -r) | grep CONFIG_BPF

# Should see:
# CONFIG_BPF=y
# CONFIG_BPF_SYSCALL=y
# CONFIG_BPF_JIT=y
```

**Solutions:**

1. **Update kernel** to 4.15 or later
2. **Enable BPF in kernel config** if building custom kernel
3. **Check for kernel security modules** (SELinux, AppArmor) blocking BPF
4. **Report bug** if on supported kernel

### Issue: Snapshot Command Shows No Processes

**Problem:** `snapshot` command returns empty or shows no crypto processes.

**Cause:** No processes currently have crypto libraries loaded or crypto files open.

**Diagnosis:**
```bash
# Check manually
ps aux | head -20

# Check for crypto libraries
sudo lsof | grep -E "libssl|libcrypto" | head -10

# Check for crypto files
sudo lsof | grep -E "\.pem|\.crt|\.key" | head -10
```

**Solutions:**

1. **Start some crypto-using processes:**
```bash
# Start a web server
sudo systemctl start nginx

# Or run openssl
openssl version &
```

2. **Check if libraries are statically linked:**
   - Some applications statically link crypto libraries
   - These won't show up in library scans
   - Use `monitor` or `profile` instead to see their file access

3. **Verify snapshot is working:**
```bash
# Run with verbose
./crypto-tracer snapshot --verbose
```

## Getting Help

### Check Version and Help

**Check version:**
```bash
./crypto-tracer --version
```

**View general help:**
```bash
./crypto-tracer --help
```

**View command-specific help:**
```bash
./crypto-tracer help monitor
./crypto-tracer monitor --help
```

### Enable Verbose Logging

**Run with verbose output:**
```bash
sudo ./crypto-tracer monitor --verbose 2>&1 | tee debug.log
```

This shows:

- eBPF program loading details
- Event processing statistics
- Filter application
- Error details

### Collect System Information

**Gather diagnostic information:**
```bash
# Kernel version
uname -r

# Distribution
cat /etc/os-release

# Current capabilities
getcap ./crypto-tracer

# BTF support
ls -la /sys/kernel/btf/vmlinux

# BPF support
cat /boot/config-$(uname -r) | grep CONFIG_BPF

# Available memory
free -h

# Disk space
df -h
```

**Save to file:**
```bash
cat > system-info.txt <<EOF
Kernel: $(uname -r)
Distribution: $(cat /etc/os-release | grep PRETTY_NAME)
Capabilities: $(getcap ./crypto-tracer)
BTF: $(ls -la /sys/kernel/btf/vmlinux 2>&1)
Memory: $(free -h | grep Mem)
EOF
```

### Additional Resources

**Online resources:**

- **GitHub Issues:** https://github.com/cipheriq/crypto-tracer/issues
- **Discussions:** https://github.com/cipheriq/crypto-tracer/discussions

**Reporting bugs:**

1. Search existing issues first
2. Include system information (see above)
3. Include debug output (`--verbose`)
4. Provide steps to reproduce
5. Include expected vs actual behavior

---

**Previous:** [Privacy and Security](09-privacy-security.md) | **Next:** [Advanced Usage](11-advanced-usage.md)
