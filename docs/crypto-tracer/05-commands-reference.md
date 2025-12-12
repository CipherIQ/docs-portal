# Commands Reference

This section provides detailed documentation for all crypto-tracer commands.

## Command Overview

crypto-tracer provides five main commands for different monitoring scenarios:

| Command | Purpose | Privileges | Output Mode |
|---------|---------|------------|-------------|
| `monitor` | Real-time system-wide monitoring | Required | Stream |
| `profile` | Detailed process profiling | Required | Document |
| `snapshot` | Instant system inventory | **Not required** | Document |
| `libs` | Library loading tracking | Required | Stream |
| `files` | File access tracking | Required | Stream |

Additional commands:
- `help` - Display help information
- `version` - Show version information

---

## monitor - Real-time Monitoring

Monitor all cryptographic activity system-wide in real-time.

### Syntax

```bash
crypto-tracer monitor [options]
```

### Description

The `monitor` command provides real-time visibility into cryptographic operations across your entire system. It captures file access, library loading, and process events as they occur, streaming them as JSON events.

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-d, --duration SECONDS` | Monitor for specified duration | Unlimited |
| `-p, --pid PID` | Monitor specific process ID | All processes |
| `-n, --name NAME` | Monitor processes matching name | All processes |
| `-l, --library LIB` | Filter by library name | All libraries |
| `-F, --file PATTERN` | Filter by file path (glob) | All files |
| `-o, --output FILE` | Write output to file | stdout |
| `-f, --format FORMAT` | Output format | json-stream |
| `-v, --verbose` | Enable verbose output | Disabled |
| `-q, --quiet` | Quiet mode | Disabled |
| `--no-redact` | Disable path redaction | Enabled |

### Examples

**Basic monitoring for 60 seconds:**
```bash
sudo crypto-tracer monitor --duration 60
```

**Monitor specific process by PID:**
```bash
sudo crypto-tracer monitor --pid 1234
```

**Monitor by process name:**
```bash
sudo crypto-tracer monitor --name nginx
```

**Filter by file type:**
```bash
sudo crypto-tracer monitor --file "*.pem"
sudo crypto-tracer monitor --file "/etc/ssl/*"
```

**Save to file with pretty formatting:**
```bash
sudo crypto-tracer monitor --duration 30 --output events.json --format json-pretty
```

**Monitor specific library:**
```bash
sudo crypto-tracer monitor --library libssl --duration 60
```

**Combine filters:**
```bash
sudo crypto-tracer monitor --name nginx --file "*.crt" --duration 120
```

### Use Cases

- **Real-time security monitoring** - Watch for unexpected crypto activity
- **Debugging certificate issues** - See which certificates are being accessed
- **Application behavior analysis** - Understand crypto usage patterns
- **Incident response** - Capture crypto activity during security events

### Output

Streams JSON events in real-time (one per line with json-stream format):

```json
{"event_type":"file_open","timestamp":"2024-12-08T10:30:45.123456Z","pid":1234,"process":"nginx","file":"/etc/ssl/certs/server.crt","file_type":"certificate"}
{"event_type":"lib_load","timestamp":"2024-12-08T10:30:45.234567Z","pid":1234,"process":"nginx","library":"/usr/lib/libssl.so.1.1","library_name":"libssl"}
```

### Notes

- Requires elevated privileges (CAP_BPF or root)
- Press Ctrl+C to stop monitoring before duration expires
- Use filters to reduce event volume
- Default format (json-stream) is most efficient

---

## profile - Process Profiling

Generate a detailed profile of a specific process's cryptographic usage.

### Syntax

```bash
crypto-tracer profile [options]
```

### Description

The `profile` command creates a comprehensive report of a process's cryptographic activity over a specified time period. It aggregates all crypto operations and generates statistics, making it ideal for detailed analysis.

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-p, --pid PID` | Target process ID | **Required*** |
| `-n, --name NAME` | Target process name | **Required*** |
| `-d, --duration SECONDS` | Profile duration | 30 seconds |
| `--follow-children` | Include child processes | Disabled** |
| `-o, --output FILE` | Write profile to file | stdout |
| `-f, --format FORMAT` | Output format | json-stream |
| `-v, --verbose` | Enable verbose output | Disabled |
| `--no-redact` | Disable path redaction | Enabled |

\* Either `--pid` or `--name` is required  
\** Framework only, not yet implemented

### Examples

**Profile by PID:**
```bash
sudo crypto-tracer profile --pid 1234
```

**Profile by name:**
```bash
sudo crypto-tracer profile --name nginx --duration 60
```

**Save profile to file:**
```bash
sudo crypto-tracer profile --pid 1234 --output profile.json --format json-pretty
```

**Profile with custom duration:**
```bash
sudo crypto-tracer profile --name apache2 --duration 120
```

### Profile Output Structure

```json
{
  "profile_version": "1.0",
  "generated_at": "2024-12-08T10:30:45.123456Z",
  "duration_seconds": 30,
  "process": {
    "pid": 1234,
    "name": "nginx",
    "exe": "/usr/sbin/nginx",
    "cmdline": "nginx: master process /usr/sbin/nginx",
    "uid": 0,
    "start_time": "2024-12-08T10:30:15.000000Z"
  },
  "libraries": [
    {
      "name": "libssl",
      "path": "/usr/lib/x86_64-linux-gnu/libssl.so.1.1",
      "load_time": "2024-12-08T10:30:16.123456Z"
    }
  ],
  "files_accessed": [
    {
      "path": "/etc/ssl/certs/server.crt",
      "type": "certificate",
      "access_count": 5,
      "first_access": "2024-12-08T10:30:20.123456Z",
      "last_access": "2024-12-08T10:30:45.123456Z",
      "mode": "read"
    }
  ],
  "statistics": {
    "total_events": 150,
    "libraries_loaded": 2,
    "files_accessed": 3,
    "api_calls_made": 0
  }
}
```

### Use Cases

- **Application crypto analysis** - Understand what crypto resources an app uses
- **Troubleshooting** - Debug specific process crypto issues
- **Compliance documentation** - Generate detailed crypto usage reports
- **Configuration verification** - Confirm correct crypto setup

### Important Notes

- Requires either `--pid` or `--name` (not both)
- Default duration is 30 seconds
- If process exits during profiling, partial results are returned
- **Child process limitation:** Child processes have different PIDs - use `--name` to catch related processes
- Libraries loaded before profiling starts won't be captured

---

## snapshot - System Inventory

Take an instant snapshot of all processes using cryptography on the system.

### Syntax

```bash
crypto-tracer snapshot [options]
```

### Description

The `snapshot` command quickly scans your system to identify all processes currently using cryptographic libraries or files. It reads from the `/proc` filesystem and requires no special privileges.

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-o, --output FILE` | Write snapshot to file | stdout |
| `-f, --format FORMAT` | Output format | json-pretty |
| `-v, --verbose` | Enable verbose output | Disabled |
| `--no-redact` | Disable path redaction | Enabled |

### Examples

**Basic snapshot:**
```bash
crypto-tracer snapshot
```

**Human-readable summary:**
```bash
crypto-tracer snapshot --format summary
```

**Save to file:**
```bash
crypto-tracer snapshot --output inventory.json --format json-pretty
```

**Daily inventory:**
```bash
crypto-tracer snapshot --output crypto-inventory-$(date +%Y%m%d).json
```

### Snapshot Output Structure

```json
{
  "snapshot_version": "1.0",
  "generated_at": "2024-12-08T10:30:45.123456Z",
  "hostname": "webserver01",
  "kernel": "5.15.0-91-generic",
  "processes": [
    {
      "pid": 1234,
      "name": "nginx",
      "exe": "/usr/sbin/nginx",
      "libraries": [
        "/usr/lib/x86_64-linux-gnu/libssl.so.1.1",
        "/usr/lib/x86_64-linux-gnu/libcrypto.so.1.1"
      ],
      "open_crypto_files": [
        "/etc/ssl/certs/server.crt",
        "/etc/ssl/private/server.key"
      ],
      "running_as": "root"
    }
  ],
  "summary": {
    "total_processes": 5,
    "total_libraries": 8,
    "total_files": 12
  }
}
```

### Use Cases

- **Quick crypto inventory** - See what's using crypto right now
- **Compliance audits** - Document crypto usage for reports
- **CI/CD validation** - Verify expected crypto configuration
- **Baseline establishment** - Create baseline for monitoring
- **System documentation** - Document crypto infrastructure

### Important Notes

- **No special privileges required!** Works without sudo
- Completes in under 5 seconds
- Shows current state only (not historical)
- Scans all running processes
- Uses `/proc` filesystem (no eBPF needed)

---

## libs - Library Tracking

Monitor cryptographic library loading events.

### Syntax

```bash
crypto-tracer libs [options]
```

### Description

The `libs` command focuses specifically on tracking when processes load cryptographic libraries. It's useful for understanding which processes use which crypto libraries.

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-l, --library LIB` | Filter by library name | All libraries |
| `-d, --duration SECONDS` | Monitor duration | Unlimited |
| `-o, --output FILE` | Write output to file | stdout |
| `-f, --format FORMAT` | Output format | json-stream |
| `-v, --verbose` | Enable verbose output | Disabled |
| `--no-redact` | Disable path redaction | Enabled |

### Examples

**Monitor all library loads:**
```bash
sudo crypto-tracer libs --duration 60
```

**Filter by library name:**
```bash
sudo crypto-tracer libs --library libssl
```

**Save to file:**
```bash
sudo crypto-tracer libs --duration 30 --output libs.json
```

### Use Cases

- **Library usage tracking** - See which processes load crypto libraries
- **Version verification** - Confirm correct library versions
- **Unexpected library detection** - Find processes loading unexpected libraries
- **Audit crypto library usage** - Document library usage patterns

### Output

Streams lib_load events:

```json
{"event_type":"lib_load","timestamp":"2024-12-08T10:30:45.234567Z","pid":1234,"process":"nginx","library":"/usr/lib/libssl.so.1.1","library_name":"libssl"}
```

---

## files - File Access Tracking

Monitor access to cryptographic files.

### Syntax

```bash
crypto-tracer files [options]
```

### Description

The `files` command tracks when processes access cryptographic files such as certificates, keys, and keystores.

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-F, --file PATTERN` | Filter by file path (glob) | All files |
| `-d, --duration SECONDS` | Monitor duration | Unlimited |
| `-o, --output FILE` | Write output to file | stdout |
| `-f, --format FORMAT` | Output format | json-stream |
| `-v, --verbose` | Enable verbose output | Disabled |
| `--no-redact` | Disable path redaction | Enabled |

### Examples

**Monitor all crypto file access:**
```bash
sudo crypto-tracer files --duration 60
```

**Filter by file pattern:**
```bash
sudo crypto-tracer files --file "*.pem"
sudo crypto-tracer files --file "/etc/ssl/certs/*"
```

**Save to file:**
```bash
sudo crypto-tracer files --duration 30 --output files.json
```

### Use Cases

- **Certificate access tracking** - Monitor certificate usage
- **Key access auditing** - Track private key access
- **File verification** - Confirm correct files are accessed
- **Unauthorized access detection** - Find unexpected file access

### Output

Streams file_open events:

```json
{"event_type":"file_open","timestamp":"2024-12-08T10:30:45.123456Z","pid":1234,"process":"nginx","file":"/etc/ssl/certs/server.crt","file_type":"certificate","flags":"O_RDONLY"}
```

---

## help - Command Help

Display help information for commands.

### Syntax

```bash
crypto-tracer help [command]
crypto-tracer <command> --help
crypto-tracer --help
```

### Examples

**General help:**
```bash
crypto-tracer --help
crypto-tracer help
```

**Command-specific help:**
```bash
crypto-tracer help monitor
crypto-tracer monitor --help
```

---

## version - Version Information

Display version and build information.

### Syntax

```bash
crypto-tracer --version
crypto-tracer version
```

### Output

```
crypto-tracer version 1.0.0
Build date: Dec  8 2024 10:30:45
Kernel support: Linux 4.15+
License: GPL-3.0-or-later
Copyright (c) 2025 Graziano Labs Corp.
```

---

## Common Options

These options are available for most commands:

### Output Options

**`-o, --output FILE`** - Write output to file instead of stdout

**`-f, --format FORMAT`** - Output format:
- `json-stream` - One JSON per line (default for stream commands)
- `json-array` - JSON array
- `json-pretty` - Pretty-printed JSON (default for document commands)
- `summary` - Text summary (snapshot only)

### Verbosity Options

**`-v, --verbose`** - Enable verbose output (debug information)

**`-q, --quiet`** - Quiet mode (minimal output, errors only)

**Note:** `--verbose` and `--quiet` are mutually exclusive

### Privacy Options

**`--no-redact`** - Disable path redaction (show actual paths)

---

**Previous:** [Basic Concepts](04-basic-concepts.md) | **Next:** [Common Use Cases](06-common-use-cases.md)
