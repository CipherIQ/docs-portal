# Filtering and Options

This section covers all filtering capabilities and command-line options available in **crypto-tracer**.

## Overview

**crypto-tracer** provides powerful filtering to focus on specific processes, libraries, or files. Filters can be combined using AND logic - all specified filters must match for an event to be displayed.

## Process Filtering

### Filter by PID (Process ID)

Monitor a specific process by its PID.

**Syntax:**
```bash
--pid PID
-p PID
```

**Example:**
```bash
sudo crypto-tracer monitor --pid 1234
sudo crypto-tracer profile --pid 1234 --duration 30
```

**Characteristics:**

- Exact match on process ID
- Only monitors that specific process
- Fast and efficient

**Limitation:**

- **Child processes have different PIDs!**
- If a process spawns children, their events won't be captured
- Example: A bash script that runs `cat` to read a file - the file access happens in the child process

**When to use:**

- Monitoring a specific long-running process
- When you know the exact PID
- Process doesn't spawn children

### Filter by Name

Monitor all processes matching a name pattern.

**Syntax:**
```bash
--name NAME
-n NAME
```

**Example:**
```bash
sudo crypto-tracer monitor --name nginx
sudo crypto-tracer profile --name apache2 --duration 60
```

**Characteristics:**

- Substring match on process name
- Matches all processes with that name
- Catches child processes with same name
- Case-sensitive

**Examples of matching:**

- `--name nginx` matches: `nginx`, `nginx-worker`, `nginx-master`
- `--name python` matches: `python`, `python3`, `python3.10`
- `--name java` matches: `java`, `javac`

**When to use:**

- **Recommended for most use cases**
- Applications that spawn child processes
- When you don't know the exact PID
- Monitoring multiple related processes

### Choosing Between PID and Name

| Scenario | Use | Reason |
|----------|-----|--------|
| Web server (nginx, apache) | `--name` | Spawns worker processes |
| Application server | `--name` | May spawn children |
| Shell script | `--name` | Spawns many children |
| Single daemon | `--pid` or `--name` | Either works |
| Known PID, no children | `--pid` | Most specific |

## Library Filtering

Filter events by cryptographic library name.

**Syntax:**
```bash
--library LIB
-l LIB
```

**Example:**
```bash
sudo crypto-tracer monitor --library libssl
sudo crypto-tracer libs --library libcrypto --duration 60
```

**Matching Behavior:**

- Substring match on library path
- Case-sensitive
- Matches any part of the path

**Examples:**
```bash
--library libssl        # Matches: libssl.so, libssl.so.1.1, libssl.so.3
--library libcrypto     # Matches: libcrypto.so, libcrypto.so.1.1
--library gnutls        # Matches: libgnutls.so, libgnutls.so.30
--library .so.1.1       # Matches: libssl.so.1.1, libcrypto.so.1.1
```

**Use Cases:**

- Focus on specific crypto library
- Verify correct library version
- Track OpenSSL vs GnuTLS usage
- Audit library usage patterns

## File Filtering

Filter events by file path using glob patterns.

**Syntax:**
```bash
--file PATTERN
-F PATTERN
```

**Example:**
```bash
sudo crypto-tracer monitor --file "*.pem"
sudo crypto-tracer files --file "/etc/ssl/certs/*" --duration 60
```

**Glob Pattern Syntax:**

| Pattern | Matches | Example |
|---------|---------|---------|
| `*` | Any characters | `*.pem` matches `cert.pem`, `key.pem` |
| `?` | Single character | `cert?.pem` matches `cert1.pem`, `certA.pem` |
| `[abc]` | One of a, b, c | `cert[123].pem` matches `cert1.pem`, `cert2.pem` |
| `[a-z]` | Range | `[a-z]*.pem` matches files starting with lowercase |
| `[!abc]` | Not a, b, or c | `[!0-9]*.pem` matches files not starting with digit |

**Common Patterns:**

```bash
# All .pem files
--file "*.pem"

# All .crt files
--file "*.crt"

# All files in /etc/ssl/
--file "/etc/ssl/*"

# Specific directory and extension
--file "/etc/ssl/certs/*.pem"

# Files containing "server"
--file "*server*"

# Multiple extensions (requires multiple runs or combine in shell)
--file "*.pem" --file "*.crt"  # Won't work - only last is used
# Instead: --file "*.{pem,crt}" or run twice
```

**Important Notes:**

- Patterns are matched against full file path
- Case-sensitive
- Quote patterns to prevent shell expansion
- Only one pattern per command (combine in pattern if needed)

## Combining Filters

Filters use **AND logic** - all specified filters must match.

**Examples:**

```bash
# Monitor nginx processes accessing .pem files
sudo crypto-tracer monitor --name nginx --file "*.pem"
# Shows events where: process name contains "nginx" AND file matches "*.pem"

# Profile specific PID loading libssl
sudo crypto-tracer profile --pid 1234 --library libssl
# Shows events where: PID is 1234 AND library contains "libssl"

# Monitor specific process and file type
sudo crypto-tracer monitor --pid 1234 --file "/etc/ssl/*" --duration 60
# Shows events where: PID is 1234 AND file path starts with "/etc/ssl/"
```

**Filter Evaluation:**

1. Event is generated
2. Each filter is checked in order
3. If any filter doesn't match, event is discarded (early termination)
4. If all filters match, event is output

## Duration Control

Specify how long to monitor.

**Syntax:**
```bash
--duration SECONDS
-d SECONDS
```

**Examples:**
```bash
# Monitor for 60 seconds
sudo crypto-tracer monitor --duration 60

# Profile for 2 minutes
sudo crypto-tracer profile --pid 1234 --duration 120

# Monitor for 1 hour
sudo crypto-tracer monitor --duration 3600
```

**Default Behavior:**

- `monitor`, `libs`, `files`: Unlimited (until Ctrl+C)
- `profile`: 30 seconds
- `snapshot`: N/A (instant)

**Special Values:**
```bash
--duration 0    # Unlimited (explicit)
# No --duration  # Uses command default
```

**Stopping Early:**

- Press `Ctrl+C` to stop before duration expires
- Graceful shutdown processes buffered events
- Output is flushed and files are closed properly

## Output Control

### Output Destination

**Syntax:**
```bash
--output FILE
-o FILE
```

**Examples:**
```bash
# Write to file
sudo crypto-tracer monitor --output events.json

# Write to file with timestamp
sudo crypto-tracer monitor --output events-$(date +%Y%m%d-%H%M%S).json

# Default: stdout
sudo crypto-tracer monitor
```

**Behavior:**

- Creates file if doesn't exist
- Overwrites existing file
- Default: stdout (terminal)
- Errors go to stderr (not affected by --output)

### Output Format

**Syntax:**
```bash
--format FORMAT
-f FORMAT
```

**Available Formats:**

- `json-stream` - One JSON per line (default for stream commands)
- `json-array` - JSON array
- `json-pretty` - Pretty-printed JSON (default for document commands)
- `summary` - Text summary (snapshot only)

**Examples:**
```bash
# Pretty output for viewing
sudo crypto-tracer monitor --format json-pretty --duration 10

# Stream format for processing
sudo crypto-tracer monitor --format json-stream --duration 60

# Array format for batch processing
sudo crypto-tracer monitor --format json-array --duration 30
```

See [Output Formats](07-output-formats.md) for detailed format documentation.

## Verbosity Control

### Verbose Mode

Enable detailed debug output.

**Syntax:**
```bash
--verbose
-v
```

**Example:**
```bash
sudo crypto-tracer monitor --verbose
```

**What it shows:**

- eBPF program loading details
- Event processing statistics
- Filter evaluation details
- Performance metrics
- Debug messages

**When to use:**

- Troubleshooting issues
- Understanding what's happening
- Debugging filters
- Performance analysis

### Quiet Mode

Suppress non-essential output.

**Syntax:**
```bash
--quiet
-q
```

**Example:**
```bash
sudo crypto-tracer monitor --quiet
```

**What it shows:**

- Only errors and warnings
- No informational messages
- No statistics
- Just event output

**When to use:**

- Scripts and automation
- Clean output needed
- Piping to other tools
- Minimal logging

**Note:** `--verbose` and `--quiet` are mutually exclusive.

## Privacy Control

### Path Redaction

Control whether paths are redacted for privacy.

**Default Behavior (Redaction Enabled):**
```bash
sudo crypto-tracer monitor
```

User paths are redacted:
- `/home/alice/key.pem` → `/home/USER/key.pem`
- `/root/cert.pem` → `/home/ROOT/cert.pem`

System paths are preserved:
- `/etc/ssl/certs/ca.crt` → `/etc/ssl/certs/ca.crt`

### Disable Redaction

**Syntax:**
```bash
--no-redact
```

**Example:**
```bash
sudo crypto-tracer monitor --no-redact
```

Shows actual paths without redaction.

**When to use:**

- Debugging specific path issues
- When privacy is not a concern
- Detailed troubleshooting
- Internal use only

**When to keep enabled (default):**

- Sharing output with others
- Compliance and audit reports
- Public demonstrations
- Documentation

## Advanced Filtering Techniques

### Multiple Criteria

Combine multiple filters for precise targeting:

```bash
# Monitor specific app accessing specific files
sudo crypto-tracer monitor \
    --name myapp \
    --file "/etc/ssl/certs/*" \
    --duration 300 \
    --output myapp-certs.json
```

### Post-Processing Filters

Use jq for additional filtering after capture:

```bash
# Capture everything, filter later
sudo crypto-tracer monitor --duration 60 --output all-events.json

# Filter for specific conditions
cat all-events.json | jq 'select(.file_type == "private_key")'
cat all-events.json | jq 'select(.uid == 0)'  # Root only
cat all-events.json | jq 'select(.process | startswith("nginx"))'
```

### Time-Based Filtering

Filter events by time in post-processing:

```bash
# Capture with timestamps
sudo crypto-tracer monitor --duration 3600 --output events.json

# Filter by time range
cat events.json | jq 'select(.timestamp >= "2024-12-08T10:00:00Z" and 
                              .timestamp <= "2024-12-08T11:00:00Z")'
```

## Option Compatibility

### Command-Specific Options

| Option | monitor | profile | snapshot | libs | files |
|--------|---------|---------|----------|------|-------|
| `--pid` | ✓ | ✓ | ✗ | ✗ | ✗ |
| `--name` | ✓ | ✓ | ✗ | ✗ | ✗ |
| `--library` | ✓ | ✗ | ✗ | ✓ | ✗ |
| `--file` | ✓ | ✗ | ✗ | ✗ | ✓ |
| `--duration` | ✓ | ✓ | ✗ | ✓ | ✓ |
| `--follow-children` | ✗ | ✓* | ✗ | ✗ | ✗ |

\* Framework only, not yet implemented

### Global Options

Available for all commands:

- `--output` / `-o`
- `--format` / `-f`
- `--verbose` / `-v`
- `--quiet` / `-q`
- `--no-redact`
- `--help` / `-h`

## Quick Reference

### Common Filter Combinations

```bash
# Monitor specific app
sudo crypto-tracer monitor --name nginx --duration 60

# Monitor specific files
sudo crypto-tracer monitor --file "*.pem" --duration 60

# Monitor app accessing specific files
sudo crypto-tracer monitor --name myapp --file "/etc/ssl/*"

# Profile with library filter
sudo crypto-tracer profile --pid 1234 --library libssl

# Track specific library loads
sudo crypto-tracer libs --library libssl --duration 60

# Track specific file access
sudo crypto-tracer files --file "/etc/ssl/private/*" --duration 60
```

### Output Control

```bash
# Save to file
--output events.json

# Pretty format
--format json-pretty

# Verbose output
--verbose

# Quiet mode
--quiet

# No redaction
--no-redact
```

---

**Previous:** [Output Formats](07-output-formats.md) | **Next:** [Privacy and Security](09-privacy-security.md)
