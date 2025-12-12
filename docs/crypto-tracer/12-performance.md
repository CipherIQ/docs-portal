# Performance Considerations

This section covers performance characteristics, optimization techniques, and monitoring for **crypto-tracer**.

## Expected Performance

**crypto-tracer** is designed to have minimal impact on system performance.

### CPU Usage

**crypto-tracer process:**

- **Average:** <0.5% per core
- **Peak:** <2% per core during event bursts
- **Typical:** 0.1-0.3% during normal monitoring

**Impact on monitored applications:**

- **Overhead:** <1% additional CPU usage
- **Negligible** for most applications
- **Unnoticeable** in production environments

**Example measurements:**
```bash
# Monitor CPU usage
top -p $(pgrep crypto-tracer)

# Typical output:
# PID    USER   %CPU  %MEM  COMMAND
# 12345  root   0.3   0.5   crypto-tracer monitor
```

### Memory Usage

**Resident Set Size (RSS):**

- **Typical:** 20-30 MB
- **Maximum:** <50 MB
- **Startup:** ~15 MB

**Memory breakdown:**

- **Event buffer:** 10 MB (pre-allocated ring buffer)
- **eBPF programs:** 2-5 MB (loaded in kernel)
- **User-space code:** 5-10 MB
- **Working memory:** 5-10 MB

**Example measurements:**
```bash
# Check memory usage
ps aux | grep crypto-tracer

# Or more detailed
cat /proc/$(pgrep crypto-tracer)/status | grep -E "VmRSS|VmSize"
```

### Event Processing

**Throughput:**

- **Capacity:** Up to 5,000 events/second
- **Typical load:** 100-500 events/second
- **Burst handling:** 10,000 events/second for short periods

**Latency:**

- **Per-event processing:** <5 ms (including enrichment)
- **Ring buffer latency:** <1 ms
- **Output formatting:** <2 ms per event

**Startup time:**

- **eBPF program loading:** <1 second
- **Initialization:** <1 second
- **Total startup:** <2 seconds

### Disk I/O

**Write performance:**

- **json-stream:** ~1 MB/s for 1,000 events/second
- **json-pretty:** ~2 MB/s for 1,000 events/second
- **Buffered writes:** Minimal impact

**Storage requirements:**

- **Per event:** ~500-1000 bytes (json-stream)
- **Per hour:** ~180 MB at 100 events/second
- **Per day:** ~4.3 GB at 100 events/second

## Optimizing Performance

### Use Specific Filters

Reduce event volume by filtering at the source.

**Filter by process:**
```bash
# Instead of monitoring everything
sudo ./crypto-tracer monitor

# Monitor specific process (much less overhead)
sudo ./crypto-tracer monitor --name nginx
```

**Filter by file pattern:**
```bash
# Monitor only certificate files
sudo ./crypto-tracer monitor --file "*.crt"

# Monitor specific directory
sudo ./crypto-tracer monitor --file "/etc/ssl/certs/*"
```

**Combine filters:**
```bash
# Most efficient - very specific
sudo ./crypto-tracer monitor --name nginx --file "*.pem"
```

**Performance impact:**
```
No filters:     10,000 events/sec → 0.5% CPU
Process filter:  1,000 events/sec → 0.1% CPU
File filter:       500 events/sec → 0.05% CPU
Both filters:      100 events/sec → 0.02% CPU
```

### Choose Efficient Output Format

Different formats have different performance characteristics.

**Format comparison:**

| Format | CPU Overhead | Disk I/O | Best For |
|--------|-------------|----------|----------|
| json-stream | Lowest | Lowest | Production, real-time |
| json-array | Low | Low | Batch processing |
| json-pretty | Medium | High | Human viewing, small datasets |
| summary | N/A | N/A | Snapshot only |

**Recommendations:**
```bash
# Production monitoring (most efficient)
sudo ./crypto-tracer monitor --format json-stream

# Development/debugging (readable)
sudo ./crypto-tracer monitor --format json-pretty --duration 30

# Batch analysis (standard JSON)
sudo ./crypto-tracer monitor --format json-array --duration 60
```

### Limit Monitoring Duration

Avoid indefinite monitoring in production.

```bash
# Short monitoring periods
sudo ./crypto-tracer monitor --duration 60

# For continuous monitoring, use rotation
# See Advanced Usage section
```

**Why this helps:**

- Prevents unbounded memory growth
- Limits output file size
- Allows for periodic cleanup
- Easier to manage and analyze

### Write to Fast Storage

Output location affects performance.

**Storage options (fastest to slowest):**

1. **tmpfs (RAM disk)** - Fastest
```bash
sudo ./crypto-tracer monitor --output /tmp/events.json
```

2. **Local SSD** - Very fast
```bash
sudo ./crypto-tracer monitor --output /var/log/crypto-tracer/events.json
```

3. **Local HDD** - Acceptable
```bash
sudo ./crypto-tracer monitor --output /data/events.json
```

4. **Network filesystem (NFS, CIFS)** - Avoid if possible
```bash
# Not recommended for high-volume monitoring
sudo ./crypto-tracer monitor --output /mnt/network/events.json
```

**Performance impact:**
```
tmpfs:     No noticeable impact
Local SSD: <0.1% additional CPU
Local HDD: <0.2% additional CPU
Network:   0.5-2% additional CPU (depends on network)
```

### Reduce Output Verbosity

Disable verbose mode in production.

```bash
# Development (verbose)
sudo ./crypto-tracer monitor --verbose

# Production (quiet)
sudo ./crypto-tracer monitor --quiet

# Or default (normal)
sudo ./crypto-tracer monitor
```

### Use Snapshot for Point-in-Time Data

For inventory purposes, use `snapshot` instead of continuous monitoring.

```bash
# Instead of monitoring for hours
sudo ./crypto-tracer monitor --duration 3600

# Take instant snapshot (completes in <5 seconds)
./crypto-tracer snapshot
```

**Benefits:**

- No eBPF overhead
- Completes instantly
- No special privileges needed
- Perfect for periodic checks

## Monitoring Performance

### Check Event Rate

Monitor how many events **crypto-tracer** is processing.

```bash
# Run with verbose to see statistics
sudo ./crypto-tracer monitor --duration 10 --verbose

# Look for output like:
# Events processed: 1,234
# Events filtered: 234
# Events output: 1,000
# Rate: 123 events/second
```

**Interpret the numbers:**

- **High event rate (>5,000/sec):** Consider adding filters
- **Many filtered events:** Filters are working well
- **Event drops:** System overloaded (see troubleshooting)

### Monitor Resource Usage

**Real-time monitoring:**
```bash
# Watch CPU and memory
top -p $(pgrep crypto-tracer)

# Or with htop (more detailed)
htop -p $(pgrep crypto-tracer)
```

**Detailed statistics:**
```bash
# CPU and memory
ps aux | grep crypto-tracer

# Memory details
cat /proc/$(pgrep crypto-tracer)/status | grep -E "Vm|Rss"

# I/O statistics
cat /proc/$(pgrep crypto-tracer)/io
```

**Continuous monitoring script:**
```bash
#!/bin/bash
# monitor-crypto-tracer-performance.sh

while true; do
    PID=$(pgrep crypto-tracer)
    if [ -n "$PID" ]; then
        CPU=$(ps -p $PID -o %cpu= | tr -d ' ')
        MEM=$(ps -p $PID -o %mem= | tr -d ' ')
        RSS=$(ps -p $PID -o rss= | tr -d ' ')
        
        echo "$(date) - CPU: ${CPU}% MEM: ${MEM}% RSS: ${RSS}KB"
    fi
    sleep 5
done
```

### Detect Event Drops

Event drops indicate the system can't keep up with event volume.

```bash
# Check for backpressure warnings
sudo ./crypto-tracer monitor --verbose 2>&1 | grep -i "drop\|backpressure"

# Example warning:
# WARNING: Ring buffer backpressure detected, 123 events dropped
```

**If you see drops:**

1. Add filters to reduce event volume
2. Increase system resources
3. Use faster storage
4. Check for system bottlenecks

### Benchmark Your System

Test **crypto-tracer** performance on your specific system.

```bash
#!/bin/bash
# benchmark-crypto-tracer.sh

echo "=== crypto-tracer Performance Benchmark ==="

# Test 1: Startup time
echo "Test 1: Startup time"
time sudo ./crypto-tracer monitor --duration 1 --quiet > /dev/null

# Test 2: Event processing rate
echo "Test 2: Event processing rate (10 seconds)"
sudo ./crypto-tracer monitor --duration 10 --verbose 2>&1 | grep "Events processed"

# Test 3: CPU usage
echo "Test 3: CPU usage (30 seconds)"
sudo ./crypto-tracer monitor --duration 30 --output /tmp/test.json &
PID=$!
sleep 5
ps -p $PID -o %cpu,%mem,rss
wait $PID

# Test 4: Output file size
echo "Test 4: Output file size"
ls -lh /tmp/test.json
EVENT_COUNT=$(wc -l < /tmp/test.json)
FILE_SIZE=$(stat -f%z /tmp/test.json 2>/dev/null || stat -c%s /tmp/test.json)
BYTES_PER_EVENT=$((FILE_SIZE / EVENT_COUNT))
echo "Events: $EVENT_COUNT, Size: $FILE_SIZE bytes, Per event: $BYTES_PER_EVENT bytes"

rm /tmp/test.json
echo "=== Benchmark Complete ==="
```

## Performance Troubleshooting

### High CPU Usage

**Symptoms:**

- **crypto-tracer** using >5% CPU
- System feels slow
- High load average

**Diagnosis:**
```bash
# Check event rate
sudo ./crypto-tracer monitor --duration 10 --verbose

# Check system load
uptime

# Check for other processes
top
```

**Solutions:**

1. **Add filters to reduce event volume:**
```bash
# Instead of system-wide
sudo ./crypto-tracer monitor

# Filter by process
sudo ./crypto-tracer monitor --name nginx

# Filter by file
sudo ./crypto-tracer monitor --file "/etc/ssl/*"
```

2. **Check for very high event rates:**
```bash
# If seeing >10,000 events/second, system may be overloaded
# Consider monitoring specific processes only
```

3. **Verify system has sufficient resources:**
```bash
# Check CPU availability
nproc

# Check system load
uptime

# Check for CPU-intensive processes
top
```

4. **Use more efficient output format:**
```bash
# Use json-stream (most efficient)
sudo ./crypto-tracer monitor --format json-stream
```

### High Memory Usage

**Symptoms:**

- **crypto-tracer** using >100 MB RAM
- System running out of memory
- OOM killer messages

**Diagnosis:**
```bash
# Check memory usage
ps aux | grep crypto-tracer

# Check for memory leaks
watch -n 1 'ps -p $(pgrep crypto-tracer) -o rss='
```

**Solutions:**

1. **Limit monitoring duration:**
```bash
# Instead of indefinite monitoring
sudo ./crypto-tracer monitor

# Use limited duration
sudo ./crypto-tracer monitor --duration 3600
```

2. **Use monitor instead of profile for long sessions:**
```bash
# Profile accumulates data in memory
# Monitor streams to output
sudo ./crypto-tracer monitor --duration 3600
```

3. **Check for memory leaks:**
```bash
# If memory grows continuously, report bug
# Include verbose output and system info
```

### Event Drops

**Symptoms:**

- Warning messages about dropped events
- Missing events in output
- Backpressure warnings

**Diagnosis:**
```bash
# Check for drop warnings
sudo ./crypto-tracer monitor --verbose 2>&1 | grep -i drop

# Check event rate
sudo ./crypto-tracer monitor --duration 10 --verbose
```

**Solutions:**

1. **Reduce event volume with filters:**
```bash
sudo ./crypto-tracer monitor --name nginx --file "*.pem"
```

2. **Increase system resources:**
- Add more CPU cores
- Add more RAM
- Use faster storage

3. **Use faster storage for output:**
```bash
# Write to tmpfs
sudo ./crypto-tracer monitor --output /tmp/events.json
```

4. **Check for system bottlenecks:**
```bash
# Check I/O wait
iostat -x 1

# Check disk usage
df -h

# Check for slow disk
hdparm -t /dev/sda
```

### Slow Output Processing

**Symptoms:**

- Output file grows slowly
- Delayed event appearance
- High I/O wait

**Diagnosis:**
```bash
# Check I/O statistics
iostat -x 1

# Check disk performance
hdparm -t /dev/sda

# Check filesystem
df -h
```

**Solutions:**

1. **Use faster storage:**
```bash
# tmpfs (fastest)
sudo ./crypto-tracer monitor --output /tmp/events.json

# Local SSD
sudo ./crypto-tracer monitor --output /var/log/events.json
```

2. **Use more efficient format:**
```bash
# json-stream is most efficient
sudo ./crypto-tracer monitor --format json-stream
```

3. **Avoid network filesystems:**
```bash
# Don't write to NFS/CIFS during high-volume monitoring
```

## Performance Best Practices

### For Production Monitoring

1. **Use specific filters** to reduce event volume
2. **Use json-stream format** for efficiency
3. **Write to local fast storage** (SSD or tmpfs)
4. **Limit monitoring duration** and rotate files
5. **Monitor crypto-tracer itself** for resource usage
6. **Test in non-production first** to establish baseline

### For Development and Testing

1. **Use verbose mode** to understand behavior
2. **Use json-pretty format** for readability
3. **Short monitoring durations** for quick feedback
4. **Profile specific processes** for detailed analysis

### For Compliance and Auditing

1. **Use snapshot command** for point-in-time inventory
2. **Schedule periodic snapshots** instead of continuous monitoring
3. **Archive snapshots** with timestamps
4. **Minimal performance impact** with snapshot approach

---

**Previous:** [Advanced Usage](11-advanced-usage.md) | **Next:** [Integration](13-integration.md)
