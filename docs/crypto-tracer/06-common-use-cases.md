# Common Use Cases

This section provides practical examples of using crypto-tracer to solve real-world problems.

## Use Case 1: Debug SSL/TLS Certificate Issues

**Problem:** Your application fails to establish SSL/TLS connections, and you need to see which certificates it's trying to load.

**Solution:**

Terminal 1 - Start monitoring:
```bash
sudo crypto-tracer monitor --name myapp --format json-pretty
```

Terminal 2 - Run your application:
```bash
./myapp
```

**What to look for:**
- Check if certificates are being accessed
- Verify correct certificate paths
- Look for permission denied errors (check `flags` field)
- Confirm certificate file types

**Example output analysis:**
```json
{
  "event_type": "file_open",
  "file": "/etc/ssl/certs/ca-certificates.crt",
  "file_type": "certificate",
  "flags": "O_RDONLY"
}
```

If you see the file being accessed, the path is correct. If not, your application may be looking in the wrong location.

---

## Use Case 2: Verify Application Crypto Configuration

**Problem:** You need to verify your application is using the correct crypto libraries and certificates after deployment.

**Solution:**

```bash
# Profile the application for 30 seconds
sudo crypto-tracer profile --name myapp --duration 30 --output profile.json

# View the profile
cat profile.json | python3 -m json.tool | less
```

**What to check:**

1. **Libraries loaded:**
   ```bash
   cat profile.json | jq '.libraries[].name'
   ```
   Should see: `libssl`, `libcrypto`, etc.

2. **Certificate files accessed:**
   ```bash
   cat profile.json | jq '.files_accessed[] | select(.type == "certificate") | .path'
   ```

3. **Key files accessed:**
   ```bash
   cat profile.json | jq '.files_accessed[] | select(.type == "private_key") | .path'
   ```

4. **Access counts:**
   ```bash
   cat profile.json | jq '.files_accessed[] | {path: .path, count: .access_count}'
   ```

---

## Use Case 3: Generate Compliance Report

**Problem:** You need to document all cryptographic usage for a compliance audit.

**Solution:**

```bash
# Take a system snapshot
crypto-tracer snapshot --output crypto-inventory-$(date +%Y%m%d).json --format json-pretty

# Generate summary
crypto-tracer snapshot --format summary > crypto-summary.txt
```

**Report includes:**

- All processes using crypto
- Loaded crypto libraries
- Open crypto files
- System summary statistics

**Create a compliance report:**
```bash
#!/bin/bash
# compliance-report.sh

DATE=$(date +%Y%m%d)
REPORT_DIR="compliance-reports"
mkdir -p "$REPORT_DIR"

# Take snapshot
crypto-tracer snapshot --output "$REPORT_DIR/snapshot-$DATE.json"

# Generate summary
crypto-tracer snapshot --format summary > "$REPORT_DIR/summary-$DATE.txt"

# Extract key information
echo "Compliance Report - $DATE" > "$REPORT_DIR/report-$DATE.txt"
echo "================================" >> "$REPORT_DIR/report-$DATE.txt"
echo "" >> "$REPORT_DIR/report-$DATE.txt"

# List all processes using crypto
echo "Processes Using Cryptography:" >> "$REPORT_DIR/report-$DATE.txt"
jq -r '.processes[] | "\(.pid): \(.name) - \(.libraries | length) libraries"' \
    "$REPORT_DIR/snapshot-$DATE.json" >> "$REPORT_DIR/report-$DATE.txt"

echo "Report generated in $REPORT_DIR/"
```

---

## Use Case 4: Monitor Web Server Crypto Activity

**Problem:** You want to monitor your web server's certificate usage during operation.

**Solution:**

```bash
# Monitor nginx for 5 minutes
sudo crypto-tracer monitor --name nginx --duration 300 --output nginx-crypto.json

# Analyze the results
cat nginx-crypto.json | jq -r 'select(.event_type == "file_open") | .file' | sort | uniq -c
```

**What you'll see:**

- Certificate reloads (if configuration changes)
- Key file access
- Library loading at startup
- Access patterns over time

**Analyze certificate access frequency:**
```bash
# Count accesses per file
cat nginx-crypto.json | jq -r 'select(.event_type == "file_open") | .file' | \
    sort | uniq -c | sort -rn

# Timeline of certificate access
cat nginx-crypto.json | jq -r 'select(.event_type == "file_open") | 
    [.timestamp, .file] | @tsv' | column -t
```

---

## Use Case 5: Track Certificate Access Across System

**Problem:** You need to know which processes are accessing a specific certificate.

**Solution:**

```bash
# Monitor access to specific certificate
sudo crypto-tracer files --file "/etc/ssl/certs/my-cert.crt" --duration 60

# Or monitor all certificates in a directory
sudo crypto-tracer files --file "/etc/ssl/certs/*" --duration 60
```

**What you'll learn:**

- Which processes access the certificate
- How often it's accessed
- Access patterns and timing
- Unexpected access (security concern)

**Create an alert for specific certificate:**
```bash
#!/bin/bash
# alert-on-cert-access.sh

CERT="/etc/ssl/private/production.key"

sudo crypto-tracer files --file "$CERT" --format json-stream | \
while read event; do
    process=$(echo "$event" | jq -r '.process')
    timestamp=$(echo "$event" | jq -r '.timestamp')
    
    echo "ALERT: $process accessed $CERT at $timestamp"
    # Send email, log to SIEM, etc.
done
```

---

## Use Case 6: Validate Deployment

**Problem:** After deploying a new application, verify it's using the correct crypto configuration.

**Solution:**

```bash
# Take snapshot before deployment
crypto-tracer snapshot --output before.json

# Deploy application
./deploy.sh

# Take snapshot after deployment
crypto-tracer snapshot --output after.json

# Compare
diff <(jq -S . before.json) <(jq -S . after.json)
```

**Automated validation script:**
```bash
#!/bin/bash
# validate-crypto-deployment.sh

APP_NAME="myapp"
EXPECTED_LIBS=("libssl" "libcrypto")
EXPECTED_CERT="/etc/ssl/certs/app-cert.crt"

# Take snapshot
crypto-tracer snapshot --output /tmp/snapshot.json

# Check if app is running
if ! jq -e ".processes[] | select(.name == \"$APP_NAME\")" /tmp/snapshot.json > /dev/null; then
    echo "ERROR: $APP_NAME not found in snapshot"
    exit 1
fi

# Check libraries
for lib in "${EXPECTED_LIBS[@]}"; do
    if ! jq -e ".processes[] | select(.name == \"$APP_NAME\") | .libraries[] | select(contains(\"$lib\"))" \
        /tmp/snapshot.json > /dev/null; then
        echo "ERROR: $lib not loaded by $APP_NAME"
        exit 1
    fi
done

# Check certificate
if ! jq -e ".processes[] | select(.name == \"$APP_NAME\") | .open_crypto_files[] | select(. == \"$EXPECTED_CERT\")" \
    /tmp/snapshot.json > /dev/null; then
    echo "WARNING: Expected certificate $EXPECTED_CERT not open"
fi

echo "Crypto validation passed"
exit 0
```

---

## Use Case 7: Troubleshoot Library Loading Issues

**Problem:** Your application fails to start, possibly due to missing crypto libraries.

**Solution:**

```bash
# Monitor library loading during application startup
sudo crypto-tracer libs --duration 10 &
MONITOR_PID=$!

# Start your application
./myapp

# Wait for monitoring to complete
wait $MONITOR_PID
```

**Check for expected libraries:**
```bash
# Did the app load libssl?
cat libs.json | jq 'select(.library_name == "libssl")'

# What libraries did it load?
cat libs.json | jq -r '.library_name' | sort | uniq
```

**Common issues:**
- Library not found (check LD_LIBRARY_PATH)
- Wrong library version loaded
- Library loaded from unexpected location

---

## Use Case 8: Monitor Certificate Rotation

**Problem:** You're rotating certificates and want to verify the new certificates are being used.

**Solution:**

```bash
# Start monitoring before rotation
sudo crypto-tracer monitor --name nginx --output pre-rotation.json &
MONITOR_PID=$!

# Perform certificate rotation
sudo cp new-cert.crt /etc/ssl/certs/server.crt
sudo systemctl reload nginx

# Continue monitoring for a bit
sleep 30
sudo kill -TERM $MONITOR_PID

# Check if new certificate was accessed
cat pre-rotation.json | jq 'select(.file == "/etc/ssl/certs/server.crt")'
```

**Verify certificate reload:**
```bash
# Count accesses before and after reload
cat pre-rotation.json | jq -r 'select(.file == "/etc/ssl/certs/server.crt") | .timestamp' | \
    awk '{print $1}' | sort | uniq -c
```

---

## Use Case 9: Security Audit - Detect Unexpected Crypto Access

**Problem:** You want to detect if any unexpected processes are accessing crypto files.

**Solution:**

```bash
# Monitor all crypto file access
sudo crypto-tracer files --duration 3600 --output crypto-access.json

# Analyze for unexpected processes
EXPECTED_PROCESSES=("nginx" "apache2" "sshd")

cat crypto-access.json | jq -r '.process' | sort | uniq | \
while read process; do
    if [[ ! " ${EXPECTED_PROCESSES[@]} " =~ " ${process} " ]]; then
        echo "ALERT: Unexpected process accessing crypto: $process"
        # Show what it accessed
        cat crypto-access.json | jq "select(.process == \"$process\")"
    fi
done
```

---

## Use Case 10: Performance Testing - Verify Crypto Overhead

**Problem:** You want to measure the crypto overhead of your application.

**Solution:**

```bash
# Profile application during load test
sudo crypto-tracer profile --name myapp --duration 60 --output profile.json &
PROFILE_PID=$!

# Run load test
./run-load-test.sh

# Wait for profile to complete
wait $PROFILE_PID

# Analyze crypto activity
cat profile.json | jq '.statistics'
```

**Check crypto activity rate:**
```bash
# Calculate events per second
DURATION=$(cat profile.json | jq '.duration_seconds')
TOTAL_EVENTS=$(cat profile.json | jq '.statistics.total_events')
echo "scale=2; $TOTAL_EVENTS / $DURATION" | bc
```

---

## Quick Reference: Common Command Patterns

### Monitor specific application
```bash
sudo crypto-tracer monitor --name <app> --duration 60
```

### Profile application startup
```bash
sudo crypto-tracer profile --name <app> --duration 30
```

### Check system crypto inventory
```bash
crypto-tracer snapshot
```

### Track certificate access
```bash
sudo crypto-tracer files --file "*.crt" --duration 60
```

### Monitor library loading
```bash
sudo crypto-tracer libs --library libssl --duration 60
```

### Save output for analysis
```bash
sudo crypto-tracer monitor --output events.json --format json-stream
```

### Pretty output for viewing
```bash
sudo crypto-tracer monitor --format json-pretty | less
```

---

**Previous:** [Commands Reference](05-commands-reference.md) | **Next:** [Output Formats](07-output-formats.md)
