# Advanced Usage

This section covers advanced techniques for scripting, automation, and sophisticated analysis with crypto-tracer.

## Scripting and Automation

### Monitor in Background

Run crypto-tracer in the background while performing other tasks.

```bash
# Start monitoring in background
sudo ./crypto-tracer monitor --duration 3600 --output events.json &
MONITOR_PID=$!

# Do your work
./run-tests.sh
./deploy-application.sh

# Wait for monitoring to complete
wait $MONITOR_PID

# Process the results
cat events.json | jq -r '.process' | sort | uniq
```

**With cleanup:**
```bash
#!/bin/bash
set -e

# Start monitoring
sudo ./crypto-tracer monitor --duration 600 --output events.json &
MONITOR_PID=$!

# Ensure cleanup on exit
trap "kill $MONITOR_PID 2>/dev/null; wait $MONITOR_PID 2>/dev/null" EXIT

# Do your work
echo "Running tests while monitoring..."
./run-tests.sh

# Wait for monitoring
wait $MONITOR_PID
echo "Monitoring complete"
```

### Periodic Snapshots

Take regular snapshots for trend analysis.

```bash
#!/bin/bash
# take-periodic-snapshots.sh
# Take snapshot every hour

while true; do
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OUTPUT="snapshot-${TIMESTAMP}.json"
    
    echo "Taking snapshot: $OUTPUT"
    ./crypto-tracer snapshot --output "$OUTPUT"
    
    # Optional: Upload to storage
    # aws s3 cp "$OUTPUT" s3://my-bucket/snapshots/
    
    sleep 3600  # 1 hour
done
```

**With rotation (keep last 24 hours):**
```bash
#!/bin/bash
# take-snapshots-with-rotation.sh

SNAPSHOT_DIR="./snapshots"
mkdir -p "$SNAPSHOT_DIR"

while true; do
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OUTPUT="$SNAPSHOT_DIR/snapshot-${TIMESTAMP}.json"
    
    # Take snapshot
    ./crypto-tracer snapshot --output "$OUTPUT"
    
    # Delete snapshots older than 24 hours
    find "$SNAPSHOT_DIR" -name "snapshot-*.json" -mtime +1 -delete
    
    sleep 3600
done
```

### CI/CD Integration

Validate crypto configuration in your deployment pipeline.

```bash
#!/bin/bash
# validate-crypto-config.sh
# Use in CI/CD to verify crypto configuration

set -e

echo "=== Crypto Configuration Validation ==="

# Take snapshot before deployment
echo "Taking pre-deployment snapshot..."
./crypto-tracer snapshot --output before.json

# Deploy application
echo "Deploying application..."
./deploy.sh

# Wait for application to start
sleep 10

# Take snapshot after deployment
echo "Taking post-deployment snapshot..."
./crypto-tracer snapshot --output after.json

# Verify expected libraries are loaded
echo "Verifying libssl is loaded by myapp..."
if ! jq -e '.processes[] | select(.name == "myapp") | .libraries[] | select(contains("libssl"))' after.json > /dev/null; then
    echo "❌ ERROR: myapp not using libssl"
    exit 1
fi

echo "Verifying certificate files are accessible..."
if ! jq -e '.processes[] | select(.name == "myapp") | .open_crypto_files[] | select(contains(".crt"))' after.json > /dev/null; then
    echo "⚠️  WARNING: No certificate files open"
fi

# Compare before and after
echo "Comparing snapshots..."
BEFORE_COUNT=$(jq '.summary.total_processes' before.json)
AFTER_COUNT=$(jq '.summary.total_processes' after.json)

echo "Processes using crypto: $BEFORE_COUNT → $AFTER_COUNT"

echo "✅ Crypto validation passed"
exit 0
```

**GitLab CI example:**
```yaml
# .gitlab-ci.yml
validate-crypto:
  stage: test
  script:
    - ./crypto-tracer snapshot --output snapshot.json
    - |
      if ! jq -e '.processes[] | select(.name == "myapp")' snapshot.json; then
        echo "ERROR: myapp not found in crypto snapshot"
        exit 1
      fi
  artifacts:
    paths:
      - snapshot.json
    expire_in: 1 week
```

**GitHub Actions example:**
```yaml
# .github/workflows/crypto-check.yml
name: Crypto Configuration Check
on: [push, pull_request]

jobs:
  check-crypto:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install crypto-tracer
        run: |
          wget https://github.com/cipherio/crypto-tracer/releases/download/v1.0.0/crypto-tracer
          chmod +x crypto-tracer
      
      - name: Take snapshot
        run: ./crypto-tracer snapshot --output snapshot.json
      
      - name: Validate configuration
        run: |
          jq -e '.processes[] | select(.name == "myapp")' snapshot.json
      
      - name: Upload snapshot
        uses: actions/upload-artifact@v2
        with:
          name: crypto-snapshot
          path: snapshot.json
```

## Processing Output with jq

jq is essential for analyzing crypto-tracer JSON output.

### Extract Specific Fields

```bash
# Get all file paths
cat events.json | jq -r '.file' | sort | uniq

# Get all processes
cat events.json | jq -r '.process' | sort | uniq

# Get all library names
cat events.json | jq -r '.library_name' | sort | uniq

# Count events by type
cat events.json | jq -r '.event_type' | sort | uniq -c
```

### Filter Events

```bash
# Only certificate files
cat events.json | jq 'select(.file_type == "certificate")'

# Only specific process
cat events.json | jq 'select(.process == "nginx")'

# Only file_open events
cat events.json | jq 'select(.event_type == "file_open")'

# Multiple conditions (AND)
cat events.json | jq 'select(.process == "nginx" and .file_type == "certificate")'

# Multiple conditions (OR)
cat events.json | jq 'select(.process == "nginx" or .process == "apache2")'

# Files in specific directory
cat events.json | jq 'select(.file | startswith("/etc/ssl/"))'
```

### Aggregate Data

```bash
# Group by process
cat events.json | jq -s 'group_by(.process) | map({process: .[0].process, count: length})'

# Count files per process
cat events.json | jq -s 'group_by(.process) | map({
    process: .[0].process, 
    files: [.[].file] | unique | length
})'

# Count events by type
cat events.json | jq -s 'group_by(.event_type) | map({
    type: .[0].event_type,
    count: length
})'

# Timeline of events (TSV format)
cat events.json | jq -r '[.timestamp, .event_type, .process, .file] | @tsv' | column -t
```

### Generate Reports

```bash
# Summary report
cat events.json | jq -s '{
  total_events: length,
  unique_processes: [.[].process] | unique | length,
  unique_files: [.[].file] | unique | length,
  event_types: group_by(.event_type) | map({
    type: .[0].event_type, 
    count: length
  })
}'

# Top 10 most active processes
cat events.json | jq -s '
  group_by(.process) | 
  map({process: .[0].process, count: length}) | 
  sort_by(.count) | 
  reverse | 
  .[0:10]
'

# Files accessed by each process
cat events.json | jq -s '
  group_by(.process) | 
  map({
    process: .[0].process,
    files: [.[].file] | unique
  })
'
```

### Advanced jq Patterns

```bash
# Create CSV output
cat events.json | jq -r '[.timestamp, .process, .file] | @csv' > events.csv

# Filter by time range
cat events.json | jq 'select(
  .timestamp >= "2024-12-08T10:00:00Z" and 
  .timestamp <= "2024-12-08T11:00:00Z"
)'

# Extract nested fields from profile
cat profile.json | jq -r '.files_accessed[] | [.path, .access_count] | @tsv'

# Combine multiple files
jq -s 'add' file1.json file2.json file3.json > combined.json
```

## Monitoring Multiple Processes

### Monitor Process Group

**Approach 1: Multiple instances (not recommended)**
```bash
# Get all PIDs for a process group
PIDS=$(pgrep nginx | tr '\n' ',' | sed 's/,$//')

# Monitor each (requires multiple instances)
for pid in $(pgrep nginx); do
    sudo ./crypto-tracer profile --pid $pid --output "profile-$pid.json" &
done
wait

# Combine results
jq -s '.' profile-*.json > combined-profile.json
```

**Approach 2: Use name filter (recommended)**
```bash
# Monitors all nginx processes automatically
sudo ./crypto-tracer monitor --name nginx --duration 60

# This catches:
# - nginx master process
# - nginx worker processes
# - Any process with "nginx" in the name
```

### Monitor Multiple Applications

```bash
#!/bin/bash
# monitor-multiple-apps.sh

# Start monitoring for each application
sudo ./crypto-tracer monitor --name nginx --output nginx-events.json &
PID1=$!

sudo ./crypto-tracer monitor --name apache2 --output apache-events.json &
PID2=$!

sudo ./crypto-tracer monitor --name postgresql --output postgres-events.json &
PID3=$!

# Wait for all to complete
wait $PID1 $PID2 $PID3

echo "Monitoring complete"
```

## Long-Running Monitoring

### Rotate Output Files

Prevent output files from growing too large.

```bash
#!/bin/bash
# monitor-with-rotation.sh

HOUR=0
MAX_HOURS=24

while [ $HOUR -lt $MAX_HOURS ]; do
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OUTPUT="events-${TIMESTAMP}.json"
    
    echo "Starting monitoring hour $HOUR: $OUTPUT"
    
    sudo ./crypto-tracer monitor --duration 3600 \
        --output "$OUTPUT" \
        --format json-stream &
    MONITOR_PID=$!
    
    # Wait for this hour to complete
    sleep 3600
    
    # Gracefully stop if still running
    kill -TERM $MONITOR_PID 2>/dev/null
    wait $MONITOR_PID 2>/dev/null
    
    # Compress old file
    gzip "$OUTPUT"
    
    HOUR=$((HOUR + 1))
done

echo "24-hour monitoring complete"
```

### Monitor with Automatic Restart

Ensure monitoring continues even if crypto-tracer exits.

```bash
#!/bin/bash
# monitor-with-restart.sh

LOG_FILE="monitor.log"
OUTPUT_FILE="events.json"

while true; do
    echo "[$(date)] Starting crypto-tracer..." | tee -a "$LOG_FILE"
    
    sudo ./crypto-tracer monitor \
        --output "$OUTPUT_FILE" \
        --format json-stream \
        2>&1 | tee -a "$LOG_FILE"
    
    EXIT_CODE=$?
    echo "[$(date)] crypto-tracer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
    
    # If clean exit (Ctrl+C), stop
    if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 130 ]; then
        echo "Clean exit, stopping" | tee -a "$LOG_FILE"
        break
    fi
    
    # Otherwise restart after delay
    echo "Restarting in 5 seconds..." | tee -a "$LOG_FILE"
    sleep 5
done
```

### Systemd Service for Continuous Monitoring

Create a systemd service for production monitoring.

```ini
# /etc/systemd/system/crypto-tracer.service
[Unit]
Description=Crypto Tracer Monitoring Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/crypto-tracer monitor --output /var/log/crypto-tracer/events.json
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Enable and start:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable crypto-tracer
sudo systemctl start crypto-tracer

# Check status
sudo systemctl status crypto-tracer

# View logs
sudo journalctl -u crypto-tracer -f
```

## Alerting on Events

### Alert on Specific File Access

Send alerts when sensitive files are accessed.

```bash
#!/bin/bash
# alert-on-key-access.sh

ALERT_EMAIL="security@example.com"

sudo ./crypto-tracer files --file "*.key" --format json-stream | \
while read event; do
    file=$(echo "$event" | jq -r '.file')
    process=$(echo "$event" | jq -r '.process')
    pid=$(echo "$event" | jq -r '.pid')
    timestamp=$(echo "$event" | jq -r '.timestamp')
    
    # Send email alert
    echo "ALERT: Private key accessed
    
Time: $timestamp
Process: $process (PID: $pid)
File: $file

This is an automated alert from crypto-tracer." | \
    mail -s "CRYPTO ALERT: Private Key Access" "$ALERT_EMAIL"
    
    # Also log locally
    logger -t crypto-tracer "ALERT: $process accessed $file"
done
```

### Alert on Unexpected Library Loading

Detect when unexpected processes load crypto libraries.

```bash
#!/bin/bash
# alert-on-unexpected-library.sh

# Whitelist of expected processes
EXPECTED_PROCESSES="nginx|apache2|sshd|postgresql"

sudo ./crypto-tracer libs --format json-stream | \
while read event; do
    process=$(echo "$event" | jq -r '.process')
    library=$(echo "$event" | jq -r '.library')
    
    # Check if process is in whitelist
    if ! echo "$process" | grep -qE "$EXPECTED_PROCESSES"; then
        echo "⚠️  ALERT: Unexpected process $process loaded $library"
        
        # Send to syslog
        logger -p security.warning -t crypto-tracer \
            "Unexpected crypto library load: $process -> $library"
        
        # Could also send to SIEM, Slack, etc.
    fi
done
```

### Integration with Monitoring Systems

**Send to Prometheus Alertmanager:**
```bash
#!/bin/bash
# Send alert to Alertmanager

send_alert() {
    local summary="$1"
    local description="$2"
    
    curl -X POST http://alertmanager:9093/api/v1/alerts \
        -H 'Content-Type: application/json' \
        -d "[{
            \"labels\": {
                \"alertname\": \"CryptoAlert\",
                \"severity\": \"warning\",
                \"service\": \"crypto-tracer\"
            },
            \"annotations\": {
                \"summary\": \"$summary\",
                \"description\": \"$description\"
            }
        }]"
}

sudo ./crypto-tracer files --file "*.key" --format json-stream | \
while read event; do
    process=$(echo "$event" | jq -r '.process')
    file=$(echo "$event" | jq -r '.file')
    
    send_alert \
        "Private key accessed by $process" \
        "Process $process accessed private key: $file"
done
```

**Send to Slack:**
```bash
#!/bin/bash
# Send alert to Slack

SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

send_slack() {
    local message="$1"
    
    curl -X POST "$SLACK_WEBHOOK" \
        -H 'Content-Type: application/json' \
        -d "{\"text\": \"$message\"}"
}

sudo ./crypto-tracer monitor --format json-stream | \
while read event; do
    event_type=$(echo "$event" | jq -r '.event_type')
    
    if [ "$event_type" = "file_open" ]; then
        file=$(echo "$event" | jq -r '.file')
        if echo "$file" | grep -q "private"; then
            process=$(echo "$event" | jq -r '.process')
            send_slack "🔐 Private key accessed: $process → $file"
        fi
    fi
done
```

---

**Previous:** [Troubleshooting](10-troubleshooting.md) | **Next:** [Performance](12-performance.md)
