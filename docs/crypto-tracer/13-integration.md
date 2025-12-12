# Integration with Other Tools

This section covers how to integrate crypto-tracer with popular monitoring, logging, and analysis tools.

## Integration with jq

jq is a powerful JSON processor that's essential for analyzing crypto-tracer output.

### Installation

```bash
# Ubuntu/Debian
sudo apt install jq

# RHEL/Fedora
sudo dnf install jq

# macOS
brew install jq

# Alpine Linux
apk add jq
```

### Common jq Patterns

**Pretty print:**
```bash
cat events.json | jq '.'
```

**Extract specific field:**
```bash
# Get all file paths
cat events.json | jq -r '.file'

# Get all processes
cat events.json | jq -r '.process'

# Get timestamps
cat events.json | jq -r '.timestamp'
```

**Filter events:**
```bash
# Filter by process
cat events.json | jq 'select(.process == "nginx")'

# Filter by event type
cat events.json | jq 'select(.event_type == "file_open")'

# Filter by file type
cat events.json | jq 'select(.file_type == "certificate")'
```

**Count and aggregate:**
```bash
# Count total events
cat events.json | jq -s 'length'

# Group by process and count
cat events.json | jq -s 'group_by(.process) | map({process: .[0].process, count: length})'

# Count unique files
cat events.json | jq -s '[.[].file] | unique | length'
```

**Advanced queries:**
```bash
# Top 10 most active processes
cat events.json | jq -s 'group_by(.process) | map({process: .[0].process, count: length}) | sort_by(.count) | reverse | .[0:10]'

# Files accessed by each process
cat events.json | jq -s 'group_by(.process) | map({process: .[0].process, files: [.[].file] | unique})'

# Timeline analysis
cat events.json | jq -r '[.timestamp, .event_type, .process, .file] | @tsv' | column -t
```

See the [Advanced Usage](11-advanced-usage.md) section for more jq examples.

## Integration with Elasticsearch

Index crypto-tracer events in Elasticsearch for powerful search and analysis.

### Stream Events to Elasticsearch

```bash
#!/bin/bash
# stream-to-elasticsearch.sh

ELASTICSEARCH_URL="http://localhost:9200"
INDEX_NAME="crypto-events"

sudo ./crypto-tracer monitor --format json-stream | \
while read event; do
    curl -X POST "${ELASTICSEARCH_URL}/${INDEX_NAME}/_doc" \
        -H 'Content-Type: application/json' \
        -d "$event"
done
```

### Bulk Index Events

More efficient for large volumes:

```bash
#!/bin/bash
# bulk-index-elasticsearch.sh

ELASTICSEARCH_URL="http://localhost:9200"
INDEX_NAME="crypto-events"

# Collect events
sudo ./crypto-tracer monitor --duration 60 --output events.json

# Convert to bulk format and index
cat events.json | jq -c '. | {"index": {"_index": "'$INDEX_NAME'"}}, .' | \
    curl -X POST "${ELASTICSEARCH_URL}/_bulk" \
        -H 'Content-Type: application/x-ndjson' \
        --data-binary @-
```

### Create Index Template

```bash
curl -X PUT "http://localhost:9200/_index_template/crypto-events" \
  -H 'Content-Type: application/json' \
  -d '{
    "index_patterns": ["crypto-events-*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1
      },
      "mappings": {
        "properties": {
          "timestamp": {"type": "date"},
          "event_type": {"type": "keyword"},
          "process": {"type": "keyword"},
          "pid": {"type": "integer"},
          "uid": {"type": "integer"},
          "file": {"type": "text", "fields": {"keyword": {"type": "keyword"}}},
          "file_type": {"type": "keyword"},
          "library": {"type": "text", "fields": {"keyword": {"type": "keyword"}}},
          "library_name": {"type": "keyword"}
        }
      }
    }
  }'
```

### Query Examples

```bash
# Search for certificate access
curl -X GET "http://localhost:9200/crypto-events/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "term": {"file_type": "certificate"}
    }
  }'

# Aggregate by process
curl -X GET "http://localhost:9200/crypto-events/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "by_process": {
        "terms": {"field": "process"}
      }
    }
  }'
```

## Integration with Splunk

Forward crypto-tracer events to Splunk for centralized logging and analysis.

### Configure Splunk HTTP Event Collector (HEC)

1. In Splunk Web, go to **Settings > Data Inputs > HTTP Event Collector**
2. Click **New Token**
3. Name it "crypto-tracer"
4. Note the token value

### Forward Events to Splunk

```bash
#!/bin/bash
# forward-to-splunk.sh

SPLUNK_URL="https://splunk.example.com:8088"
SPLUNK_TOKEN="YOUR-HEC-TOKEN-HERE"

sudo ./crypto-tracer monitor --format json-stream | \
while read event; do
    curl -k -X POST "${SPLUNK_URL}/services/collector/event" \
        -H "Authorization: Splunk ${SPLUNK_TOKEN}" \
        -H 'Content-Type: application/json' \
        -d "{\"event\": $event, \"sourcetype\": \"crypto-tracer\"}"
done
```

### Splunk Search Examples

```spl
# All crypto events
sourcetype="crypto-tracer"

# Certificate access events
sourcetype="crypto-tracer" file_type="certificate"

# Events by process
sourcetype="crypto-tracer" | stats count by process

# Timeline chart
sourcetype="crypto-tracer" | timechart count by event_type

# Top files accessed
sourcetype="crypto-tracer" event_type="file_open" | top file
```

## Integration with Prometheus

Export crypto-tracer metrics to Prometheus for monitoring and alerting.

### Generate Prometheus Metrics

```bash
#!/bin/bash
# export-prometheus-metrics.sh

METRICS_FILE="/var/lib/node_exporter/textfile_collector/crypto.prom"

# Take snapshot and generate metrics
./crypto-tracer snapshot --format json-pretty | \
jq -r '
    "# HELP crypto_processes Total processes using crypto",
    "# TYPE crypto_processes gauge",
    ("crypto_processes " + (.summary.total_processes | tostring)),
    "",
    "# HELP crypto_libraries Total crypto libraries loaded",
    "# TYPE crypto_libraries gauge",
    ("crypto_libraries " + (.summary.total_libraries | tostring)),
    "",
    "# HELP crypto_files Total crypto files open",
    "# TYPE crypto_files gauge",
    ("crypto_files " + (.summary.total_files | tostring))
' > "$METRICS_FILE"
```

### Periodic Metrics Export

```bash
#!/bin/bash
# prometheus-exporter.sh
# Run this with cron every minute

METRICS_FILE="/var/lib/node_exporter/textfile_collector/crypto.prom"

while true; do
    ./crypto-tracer snapshot --format json-pretty | \
    jq -r '
        "# HELP crypto_processes Total processes using crypto",
        "# TYPE crypto_processes gauge",
        ("crypto_processes " + (.summary.total_processes | tostring)),
        "",
        "# HELP crypto_libraries Total crypto libraries loaded",
        "# TYPE crypto_libraries gauge",
        ("crypto_libraries " + (.summary.total_libraries | tostring)),
        "",
        "# HELP crypto_files Total crypto files open",
        "# TYPE crypto_files gauge",
        ("crypto_files " + (.summary.total_files | tostring))
    ' > "$METRICS_FILE.tmp"
    
    mv "$METRICS_FILE.tmp" "$METRICS_FILE"
    sleep 60
done
```

### Prometheus Queries

```promql
# Current number of processes using crypto
crypto_processes

# Rate of change
rate(crypto_processes[5m])

# Alert if no processes using crypto (unexpected)
crypto_processes == 0
```

### Alerting Rules

```yaml
# prometheus-alerts.yml
groups:
  - name: crypto-tracer
    rules:
      - alert: NoCryptoProcesses
        expr: crypto_processes == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "No processes using crypto detected"
          description: "No crypto processes found for 5 minutes"
      
      - alert: HighCryptoActivity
        expr: crypto_processes > 50
        for: 5m
        labels:
          severity: info
        annotations:
          summary: "High crypto activity detected"
          description: "{{ $value }} processes using crypto"
```

## Integration with Grafana

Visualize crypto-tracer data in Grafana dashboards.

### Setup

1. **Configure data source** (Elasticsearch, Prometheus, or InfluxDB)
2. **Import events** using one of the methods above
3. **Create dashboard** with panels

### Example Dashboard Panels

**Panel 1: Events Over Time**
```
Data source: Elasticsearch
Query: Count of events grouped by time
Visualization: Time series graph
```

**Panel 2: Top Processes**
```
Data source: Elasticsearch
Query: Aggregation by process field
Visualization: Bar chart
```

**Panel 3: File Access Heatmap**
```
Data source: Elasticsearch
Query: File access events by time and file
Visualization: Heatmap
```

**Panel 4: Library Usage**
```
Data source: Elasticsearch
Query: Aggregation by library_name
Visualization: Pie chart
```

### Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "Crypto Tracer Monitoring",
    "panels": [
      {
        "title": "Events Over Time",
        "type": "graph",
        "targets": [
          {
            "query": "SELECT count(*) FROM crypto_events GROUP BY time(1m)"
          }
        ]
      },
      {
        "title": "Top Processes",
        "type": "bargauge",
        "targets": [
          {
            "query": "SELECT count(*) FROM crypto_events GROUP BY process"
          }
        ]
      }
    ]
  }
}
```

## Integration with SIEM Systems

Forward crypto-tracer events to Security Information and Event Management (SIEM) systems.

### Forward to Syslog

```bash
#!/bin/bash
# forward-to-syslog.sh

sudo ./crypto-tracer monitor --format json-stream | \
while read event; do
    # Send to local syslog
    logger -t crypto-tracer -p local0.info "$event"
done
```

### Forward to Remote SIEM via TCP

```bash
#!/bin/bash
# forward-to-siem.sh

SIEM_HOST="siem.example.com"
SIEM_PORT="514"

sudo ./crypto-tracer monitor --format json-stream | \
while read event; do
    echo "$event" | nc "$SIEM_HOST" "$SIEM_PORT"
done
```

### Forward to Remote SIEM via TLS

```bash
#!/bin/bash
# forward-to-siem-tls.sh

SIEM_HOST="siem.example.com"
SIEM_PORT="6514"

sudo ./crypto-tracer monitor --format json-stream | \
while read event; do
    echo "$event" | openssl s_client -connect "$SIEM_HOST:$SIEM_PORT" -quiet 2>/dev/null
done
```

### Rsyslog Configuration

```conf
# /etc/rsyslog.d/crypto-tracer.conf

# Forward crypto-tracer events to remote SIEM
if $programname == 'crypto-tracer' then @@siem.example.com:514
```

## Integration with Python

Process crypto-tracer events in Python for custom analysis.

### Real-time Event Processing

```python
#!/usr/bin/env python3
"""
process-crypto-events.py
Process crypto-tracer events in real-time
"""

import json
import subprocess
import sys

def process_event(event):
    """Process a single event"""
    event_type = event.get('event_type')
    
    if event_type == 'file_open':
        process = event.get('process')
        file_path = event.get('file')
        print(f"📄 {process} opened {file_path}")
        
        # Alert on private key access
        if 'private' in file_path.lower() or '.key' in file_path:
            print(f"⚠️  ALERT: Private key accessed by {process}")
    
    elif event_type == 'lib_load':
        process = event.get('process')
        library = event.get('library_name')
        print(f"📚 {process} loaded {library}")

def main():
    # Start crypto-tracer
    proc = subprocess.Popen(
        ['sudo', './crypto-tracer', 'monitor', '--format', 'json-stream'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    try:
        # Process events line by line
        for line in proc.stdout:
            try:
                event = json.loads(line.strip())
                process_event(event)
            except json.JSONDecodeError as e:
                print(f"Error parsing JSON: {e}", file=sys.stderr)
    
    except KeyboardInterrupt:
        print("\nStopping...")
        proc.terminate()
        proc.wait()

if __name__ == '__main__':
    main()
```

### Batch Analysis

```python
#!/usr/bin/env python3
"""
analyze-crypto-events.py
Analyze crypto-tracer event file
"""

import json
import sys
from collections import Counter, defaultdict

def analyze_events(filename):
    """Analyze events from file"""
    events = []
    
    # Read events
    with open(filename, 'r') as f:
        for line in f:
            try:
                events.append(json.loads(line.strip()))
            except json.JSONDecodeError:
                continue
    
    # Analysis
    print(f"Total events: {len(events)}")
    print()
    
    # Event types
    event_types = Counter(e['event_type'] for e in events)
    print("Event types:")
    for event_type, count in event_types.most_common():
        print(f"  {event_type}: {count}")
    print()
    
    # Top processes
    processes = Counter(e.get('process', 'unknown') for e in events)
    print("Top 10 processes:")
    for process, count in processes.most_common(10):
        print(f"  {process}: {count}")
    print()
    
    # Files by process
    files_by_process = defaultdict(set)
    for e in events:
        if e.get('event_type') == 'file_open':
            files_by_process[e.get('process')].add(e.get('file'))
    
    print("Files accessed by process:")
    for process, files in sorted(files_by_process.items()):
        print(f"  {process}: {len(files)} files")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <events.json>")
        sys.exit(1)
    
    analyze_events(sys.argv[1])
```

## Integration with Ansible

Automate crypto-tracer deployment and data collection with Ansible.

### Playbook: Deploy crypto-tracer

```yaml
---
# deploy-crypto-tracer.yml
- name: Deploy crypto-tracer
  hosts: all
  become: yes
  
  tasks:
    - name: Download crypto-tracer
      get_url:
        url: https://github.com/cipheriq/crypto-tracer/releases/download/v1.0.0/crypto-tracer
        dest: /usr/local/bin/crypto-tracer
        mode: '0755'
    
    - name: Grant capabilities
      capabilities:
        path: /usr/local/bin/crypto-tracer
        capability: cap_bpf,cap_perfmon+ep
        state: present
      when: ansible_kernel is version('5.8', '>=')
    
    - name: Grant capabilities (older kernels)
      capabilities:
        path: /usr/local/bin/crypto-tracer
        capability: cap_sys_admin+ep
        state: present
      when: ansible_kernel is version('5.8', '<')
    
    - name: Verify installation
      command: /usr/local/bin/crypto-tracer --version
      register: version_output
    
    - name: Display version
      debug:
        msg: "{{ version_output.stdout }}"
```

### Playbook: Collect Crypto Inventory

```yaml
---
# collect-crypto-inventory.yml
- name: Collect crypto inventory from all hosts
  hosts: all
  
  tasks:
    - name: Run crypto-tracer snapshot
      command: /usr/local/bin/crypto-tracer snapshot --output /tmp/crypto-snapshot.json
      register: snapshot_result
    
    - name: Fetch snapshot
      fetch:
        src: /tmp/crypto-snapshot.json
        dest: "inventory/{{ inventory_hostname }}-snapshot.json"
        flat: yes
    
    - name: Clean up remote snapshot
      file:
        path: /tmp/crypto-snapshot.json
        state: absent
```

### Playbook: Validate Crypto Configuration

```yaml
---
# validate-crypto-config.yml
- name: Validate crypto configuration
  hosts: webservers
  
  tasks:
    - name: Take crypto snapshot
      command: /usr/local/bin/crypto-tracer snapshot --output /tmp/snapshot.json
    
    - name: Read snapshot
      slurp:
        src: /tmp/snapshot.json
      register: snapshot_data
    
    - name: Parse snapshot
      set_fact:
        snapshot: "{{ snapshot_data.content | b64decode | from_json }}"
    
    - name: Validate nginx uses libssl
      assert:
        that:
          - snapshot.processes | selectattr('name', 'equalto', 'nginx') | list | length > 0
          - snapshot.processes | selectattr('name', 'equalto', 'nginx') | map(attribute='libraries') | flatten | select('search', 'libssl') | list | length > 0
        fail_msg: "nginx not using libssl"
        success_msg: "nginx crypto configuration valid"
```

## Integration with Docker

Run crypto-tracer in containers to monitor containerized applications.

### Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY crypto-tracer /usr/local/bin/crypto-tracer
RUN chmod +x /usr/local/bin/crypto-tracer

ENTRYPOINT ["/usr/local/bin/crypto-tracer"]
CMD ["snapshot"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  crypto-tracer:
    image: crypto-tracer:latest
    privileged: true
    volumes:
      - /sys/kernel/debug:/sys/kernel/debug:ro
      - ./output:/output
    command: monitor --output /output/events.json
```

### Run in Container

```bash
# Build image
docker build -t crypto-tracer .

# Run snapshot (no privileges needed)
docker run --rm crypto-tracer snapshot

# Run monitor (needs privileges)
docker run --rm --privileged \
  -v /sys/kernel/debug:/sys/kernel/debug:ro \
  -v $(pwd)/output:/output \
  crypto-tracer monitor --duration 60 --output /output/events.json
```

---

**Previous:** [Performance](12-performance.md) | **Next:** [FAQ](14-faq.md)
