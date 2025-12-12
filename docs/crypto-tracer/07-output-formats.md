# Output Formats

**crypto-tracer** supports multiple output formats to suit different use cases, from real-time monitoring to human-readable reports.

## Available Formats

**crypto-tracer** provides four output formats:

| Format | Description | Best For | Commands |
|--------|-------------|----------|----------|
| `json-stream` | One JSON per line | Real-time processing, piping | monitor, libs, files |
| `json-array` | JSON array | Complete datasets, databases | monitor, libs, files, profile |
| `json-pretty` | Pretty-printed JSON | Human viewing, documentation | All commands |
| `summary` | Text summary | Quick overview, terminal | snapshot only |

## json-stream (Default for Stream Commands)

One JSON object per line, suitable for real-time processing and streaming.

### Format

```json
{"event_type":"file_open","timestamp":"2024-12-08T10:30:45.123456Z","pid":1234,...}
{"event_type":"lib_load","timestamp":"2024-12-08T10:30:45.234567Z","pid":1234,...}
{"event_type":"file_open","timestamp":"2024-12-08T10:30:45.345678Z","pid":5678,...}
```

### Characteristics

- Each line is a complete, valid JSON object
- No commas between lines
- No surrounding array brackets
- Streamable - can process line by line
- Efficient for large volumes

### Best For

- Real-time monitoring
- Piping to other tools
- Processing with jq or scripts
- Large event volumes
- Continuous monitoring

### Usage

```bash
# Default for monitor command
sudo crypto-tracer monitor --duration 60

# Explicit format specification
sudo crypto-tracer monitor --format json-stream --duration 60
```

### Viewing json-stream Output

**View raw:**
```bash
cat events.json | less
```

**Pretty-print each event:**
```bash
cat events.json | while read line; do 
    echo "$line" | python3 -m json.tool
    echo "---"
done | less
```

**Filter with jq:**
```bash
# Extract specific field
cat events.json | jq -r '.process'

# Filter events
cat events.json | jq 'select(.event_type == "file_open")'

# Count event types
cat events.json | jq -r '.event_type' | sort | uniq -c
```

**Process line by line:**
```bash
cat events.json | while read event; do
    # Each $event is a complete JSON object
    process=$(echo "$event" | jq -r '.process')
    echo "Process: $process"
done
```

## json-array

Valid JSON array containing all events.

### Format

```json
[
  {"event_type":"file_open","timestamp":"2024-12-08T10:30:45.123456Z",...},
  {"event_type":"lib_load","timestamp":"2024-12-08T10:30:45.234567Z",...},
  {"event_type":"file_open","timestamp":"2024-12-08T10:30:45.345678Z",...}
]
```

### Characteristics

- Valid JSON array
- Comma-separated objects
- Surrounded by `[` and `]`
- Complete document
- Standard JSON format

### Best For

- Complete event sets
- JSON parsers expecting arrays
- Importing into databases
- Standard JSON processing
- Batch analysis

### Usage

```bash
sudo crypto-tracer monitor --format json-array --duration 60 --output events.json
```

### Viewing json-array Output

**View with jq:**
```bash
cat events.json | jq '.'
```

**Access specific events:**
```bash
# First event
cat events.json | jq '.[0]'

# Last event
cat events.json | jq '.[-1]'

# Count events
cat events.json | jq 'length'
```

**Filter and process:**
```bash
# Filter by event type
cat events.json | jq '.[] | select(.event_type == "file_open")'

# Extract field from all events
cat events.json | jq -r '.[].process' | sort | uniq
```

## json-pretty

Pretty-printed JSON for human readability.

### Format

```json
[
  {
    "event_type": "file_open",
    "timestamp": "2024-12-08T10:30:45.123456Z",
    "pid": 1234,
    "process": "nginx",
    "file": "/etc/ssl/certs/server.crt",
    "file_type": "certificate"
  },
  {
    "event_type": "lib_load",
    "timestamp": "2024-12-08T10:30:45.234567Z",
    "pid": 1234,
    "process": "nginx",
    "library": "/usr/lib/libssl.so.1.1",
    "library_name": "libssl"
  }
]
```

### Characteristics

- Indented for readability
- One field per line
- Easy to read and understand
- Larger file size
- Standard JSON array format

### Best For

- Human viewing
- Demos and presentations
- Documentation
- Debugging
- Small to medium datasets

### Usage

```bash
# Monitor with pretty output
sudo crypto-tracer monitor --format json-pretty --duration 10

# Profile with pretty output (default)
sudo crypto-tracer profile --pid 1234 --format json-pretty

# Snapshot with pretty output (default)
crypto-tracer snapshot --format json-pretty
```

### Viewing json-pretty Output

**View directly:**
```bash
less events.json
```

**View with syntax highlighting:**
```bash
cat events.json | jq '.' | less -R
```

## summary (Snapshot Only)

Human-readable text summary for quick overview.

### Format

```
Crypto Snapshot Summary
Generated: 2024-12-08 10:30:45

Total Processes: 5
Total Libraries: 8
Total Files: 12

Processes Using Crypto:
  PID 1234: nginx (2 libraries, 3 files)
  PID 5678: apache2 (2 libraries, 2 files)
  PID 9012: sshd (1 library, 1 file)

Libraries:
  libssl.so.1.1 (3 processes)
  libcrypto.so.1.1 (3 processes)
  libgnutls.so.30 (1 process)

Files:
  /etc/ssl/certs/server.crt (2 processes)
  /etc/ssl/private/server.key (1 process)
```

### Characteristics

- Plain text format
- Human-readable
- Quick overview
- No JSON parsing needed
- Terminal-friendly

### Best For

- Quick overview
- Terminal output
- Reports
- Status checks
- Non-technical users

### Usage

```bash
crypto-tracer snapshot --format summary
```

## Converting Between Formats

### json-stream to json-array

```bash
# Using jq slurp mode
cat events-stream.json | jq -s '.' > events-array.json
```

### json-stream to json-pretty

```bash
# Slurp and pretty-print
cat events-stream.json | jq -s '.' > events-pretty.json
```

### json-array to json-stream

```bash
# Extract each element
cat events-array.json | jq -c '.[]' > events-stream.json
```

### Any JSON to pretty

```bash
cat events.json | jq '.' > events-pretty.json
```

## Format Selection Guide

### Choose json-stream when:
- Monitoring in real-time
- Processing events as they arrive
- Piping to other tools
- Handling large volumes
- Need streaming capability

### Choose json-array when:
- Need standard JSON format
- Importing to database
- Using JSON parsers
- Want complete dataset
- Batch processing

### Choose json-pretty when:
- Viewing output manually
- Creating documentation
- Debugging issues
- Demos and presentations
- Small datasets

### Choose summary when:
- Need quick overview
- Terminal display
- Non-technical audience
- Status checks
- Simple reports

## Working with Different Formats

### Processing json-stream in Scripts

```bash
#!/bin/bash
# process-events.sh

sudo crypto-tracer monitor --format json-stream --duration 60 | \
while read event; do
    # Process each event
    event_type=$(echo "$event" | jq -r '.event_type')
    
    case "$event_type" in
        file_open)
            file=$(echo "$event" | jq -r '.file')
            echo "File accessed: $file"
            ;;
        lib_load)
            lib=$(echo "$event" | jq -r '.library_name')
            echo "Library loaded: $lib"
            ;;
    esac
done
```

### Analyzing json-array Data

```bash
#!/bin/bash
# analyze-events.sh

# Generate statistics
cat events.json | jq '{
    total_events: length,
    event_types: group_by(.event_type) | map({type: .[0].event_type, count: length}),
    unique_processes: [.[].process] | unique | length,
    unique_files: [.[].file] | unique | length
}'
```

### Creating Reports from json-pretty

```bash
#!/bin/bash
# generate-report.sh

echo "Crypto Activity Report"
echo "====================="
echo ""

echo "Event Summary:"
cat events.json | jq -r '
    group_by(.event_type) | 
    map("\(.length) \(.[0].event_type) events") | 
    .[]'

echo ""
echo "Top Processes:"
cat events.json | jq -r '
    group_by(.process) | 
    map({process: .[0].process, count: length}) | 
    sort_by(.count) | 
    reverse | 
    limit(5; .[]) | 
    "\(.process): \(.count) events"'
```

## Format Compatibility

| Command | json-stream | json-array | json-pretty | summary |
|---------|-------------|------------|-------------|---------|
| monitor | ✓ (default) | ✓ | ✓ | ✗ |
| profile | ✓ | ✓ | ✓ (default) | ✗ |
| snapshot | ✗ | ✓ | ✓ (default) | ✓ |
| libs | ✓ (default) | ✓ | ✓ | ✗ |
| files | ✓ (default) | ✓ | ✓ | ✗ |

---

**Previous:** [Common Use Cases](06-common-use-cases.md) | **Next:** [Filtering and Options](08-filtering-options.md)
