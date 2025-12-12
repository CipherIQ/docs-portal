# Basic Concepts

Understanding these core concepts will help you use **crypto-tracer** effectively.

## Event Types

**crypto-tracer** generates several types of events as it monitors your system. Each event represents a specific cryptographic operation.

### file_open Event

Triggered when a process opens a cryptographic file (certificate, key, or keystore).

**Example:**
```json
{
  "event_type": "file_open",
  "timestamp": "2024-12-08T10:30:45.123456Z",
  "pid": 1234,
  "uid": 1000,
  "process": "nginx",
  "file": "/etc/ssl/certs/server.crt",
  "file_type": "certificate",
  "flags": "O_RDONLY"
}
```

**Fields:**

- `event_type` - Always "file_open"
- `timestamp` - When the file was opened (ISO 8601 format, UTC)
- `pid` - Process ID that opened the file
- `uid` - User ID of the process
- `process` - Process name
- `file` - Full path to the file (may be redacted)
- `file_type` - Classification: certificate, private_key, keystore, or unknown
- `flags` - File open flags (e.g., O_RDONLY, O_RDWR)

### lib_load Event

Triggered when a process loads a cryptographic library.

**Example:**
```json
{
  "event_type": "lib_load",
  "timestamp": "2024-12-08T10:30:45.234567Z",
  "pid": 1234,
  "process": "nginx",
  "library": "/usr/lib/x86_64-linux-gnu/libssl.so.1.1",
  "library_name": "libssl"
}
```

**Fields:**

- `event_type` - Always "lib_load"
- `timestamp` - When the library was loaded
- `pid` - Process ID that loaded the library
- `process` - Process name
- `library` - Full path to the library
- `library_name` - Extracted library name (e.g., "libssl")

### process_exec Event

Triggered when a new process starts.

**Example:**
```json
{
  "event_type": "process_exec",
  "timestamp": "2024-12-08T10:30:45.345678Z",
  "pid": 1234,
  "ppid": 1000,
  "process": "openssl",
  "cmdline": "openssl version"
}
```

**Fields:**

- `event_type` - Always "process_exec"
- `timestamp` - When the process started
- `pid` - Process ID of the new process
- `ppid` - Parent process ID
- `process` - Process name
- `cmdline` - Command line arguments

### process_exit Event

Triggered when a process terminates.

**Example:**
```json
{
  "event_type": "process_exit",
  "timestamp": "2024-12-08T10:30:50.456789Z",
  "pid": 1234,
  "process": "openssl",
  "exit_code": 0
}
```

**Fields:**

- `event_type` - Always "process_exit"
- `timestamp` - When the process exited
- `pid` - Process ID that exited
- `process` - Process name
- `exit_code` - Exit status code (0 = success)

## File Type Classification

**crypto-tracer** automatically classifies cryptographic files into categories:

### certificate

X.509 certificates used for authentication and encryption.

**File extensions:** `.crt`, `.cer`, `.pem` (with CERTIFICATE header)

**Examples:**

- `/etc/ssl/certs/ca-certificates.crt`
- `/etc/ssl/certs/server.cer`
- `/etc/pki/tls/certs/ca-bundle.crt`

### private_key

Private keys used for decryption and signing.

**File extensions:** `.key`, `.pem` (with PRIVATE KEY header)

**Examples:**

- `/etc/ssl/private/server.key`
- `/home/USER/id_rsa`
- `/etc/pki/tls/private/server.key`

### keystore

Containers that hold multiple certificates and keys.

**File extensions:** `.p12`, `.pfx`, `.jks`, `.keystore`

**Examples:**

- `/opt/app/keystore.jks`
- `/etc/ssl/keystore.p12`
- `/home/USER/identity.pfx`

### unknown

Files with crypto-related extensions but unrecognized format.

**Note:** **crypto-tracer** classifies files based on extension and, for `.pem` files, by reading the first few bytes to detect the header (CERTIFICATE vs PRIVATE KEY).

## Crypto Libraries

**crypto-tracer** recognizes these cryptographic libraries:

### OpenSSL
- **Libraries:** `libssl.so`, `libcrypto.so`
- **Usage:** Most common crypto library on Linux
- **Provides:** TLS/SSL, certificates, encryption, hashing

### GnuTLS
- **Library:** `libgnutls.so`
- **Usage:** Alternative to OpenSSL
- **Provides:** TLS/SSL, certificates, encryption

### libsodium
- **Library:** `libsodium.so`
- **Usage:** Modern crypto library
- **Provides:** Encryption, signatures, hashing

### NSS (Network Security Services)
- **Library:** `libnss3.so`
- **Usage:** Used by Firefox and other Mozilla products
- **Provides:** TLS/SSL, certificates, crypto operations

### mbedTLS
- **Library:** `libmbedtls.so`
- **Usage:** Lightweight crypto library for embedded systems
- **Provides:** TLS/SSL, certificates, encryption

## Output Modes

**crypto-tracer** operates in two distinct output modes depending on the command:

### Stream Mode

Used by: `monitor`, `libs`, `files` commands

**Characteristics:**

- Events output in real-time as they occur
- One JSON object per line (json-stream format)
- Continuous output until duration expires or Ctrl+C
- Suitable for long-running monitoring
- Can be piped to other tools for processing

**Example:**
```bash
sudo crypto-tracer monitor --duration 60 > events.json
```

**Output:**
```json
{"event_type":"file_open","timestamp":"...","pid":1234,...}
{"event_type":"lib_load","timestamp":"...","pid":1234,...}
{"event_type":"file_open","timestamp":"...","pid":5678,...}
```

### Document Mode

Used by: `profile`, `snapshot` commands

**Characteristics:**

- Complete JSON document generated at end
- Aggregated statistics and summaries
- Single output when command completes
- Suitable for reports and analysis
- Structured with metadata and summary sections

**Example:**
```bash
sudo crypto-tracer profile --pid 1234 --duration 30 > profile.json
```

**Output:**
```json
{
  "profile_version": "1.0",
  "generated_at": "2024-12-08T10:30:45.123456Z",
  "process": {...},
  "libraries": [...],
  "files_accessed": [...],
  "statistics": {...}
}
```

## Timestamps

All timestamps in **crypto-tracer** use **ISO 8601 format with microsecond precision in UTC**:

**Format:** `YYYY-MM-DDTHH:MM:SS.ffffffZ`

**Example:** `2024-12-08T10:30:45.123456Z`

**Components:**

- `2024-12-08` - Date (YYYY-MM-DD)
- `T` - Separator between date and time
- `10:30:45` - Time (HH:MM:SS)
- `.123456` - Microseconds
- `Z` - UTC timezone indicator

**Converting to local time:**
```bash
# Using date command
date -d "2024-12-08T10:30:45.123456Z" "+%Y-%m-%d %H:%M:%S %Z"

# Using Python
python3 -c "from datetime import datetime; print(datetime.fromisoformat('2024-12-08T10:30:45.123456Z'.replace('Z', '+00:00')).astimezone())"
```

## Filtering Concepts

**crypto-tracer** supports multiple types of filters that can be combined:

### Process Filters

**By PID (Process ID):**

- Exact match on process ID
- Only monitors that specific process
- **Limitation:** Child processes have different PIDs

**By Name:**

- Substring match on process name
- Monitors all processes with matching names
- Catches child processes with same name
- **Recommended** for applications that spawn children

### Library Filters

- Substring match on library path
- Case-sensitive
- Matches any part of the library path

**Example:** `--library libssl` matches:

- `/usr/lib/libssl.so`
- `/usr/lib/x86_64-linux-gnu/libssl.so.1.1`
- `/opt/openssl/lib/libssl.so.3`

### File Filters

- Supports glob patterns
- Matches against full file path
- Case-sensitive

**Glob patterns:**

- `*` - Matches any characters
- `?` - Matches single character
- `[abc]` - Matches a, b, or c
- `[a-z]` - Matches range

**Examples:**

- `*.pem` - All .pem files
- `/etc/ssl/*` - All files in /etc/ssl/
- `*server*` - Files containing "server"

### Filter Logic

When multiple filters are specified, they use **AND logic** - all filters must match:

```bash
# Monitors nginx processes accessing .pem files
sudo crypto-tracer monitor --name nginx --file "*.pem"
```

This will only show events where:

- Process name contains "nginx" AND
- File path matches "*.pem"

## Privacy and Redaction

**crypto-tracer** protects sensitive information by default through path redaction.

### Default Behavior (Redaction Enabled)

User home directories are redacted:

| Original Path | Redacted Path |
|--------------|---------------|
| `/home/alice/key.pem` | `/home/USER/key.pem` |
| `/home/bob/cert.pem` | `/home/USER/cert.pem` |
| `/root/secret.key` | `/home/ROOT/secret.key` |

System paths are preserved:

| Path | Preserved |
|------|-----------|
| `/etc/ssl/certs/ca.crt` | ✓ |
| `/usr/lib/libssl.so` | ✓ |
| `/var/lib/ssl/cert.pem` | ✓ |

### Disabling Redaction

Use `--no-redact` flag to see actual paths:

```bash
sudo crypto-tracer monitor --no-redact
```

**When to disable:**

- Debugging specific path issues
- When privacy is not a concern
- For detailed troubleshooting

**When to keep enabled:**

- Sharing output with others
- Compliance and audit reports
- Public demonstrations

## Performance Characteristics

Understanding **crypto-tracer**'s performance helps set expectations:

### CPU Usage
- **Average:** <0.5% per core
- **Peak:** <2% per core during event bursts
- **Application impact:** <1% overhead on monitored processes

### Memory Usage
- **Typical:** 20-30MB RSS
- **Maximum:** <50MB RSS
- **Event buffer:** 10MB pre-allocated

### Event Processing
- **Capacity:** Up to 5,000 events/second
- **Latency:** <5ms per event (including enrichment)
- **Startup time:** <2 seconds

### Scalability
- Handles high-traffic servers (nginx, apache)
- Supports long-running monitoring (24+ hours)
- Efficient with large event volumes (1M+ events)

## Key Terminology

**eBPF** - Extended Berkeley Packet Filter, Linux kernel technology for safe in-kernel programs

**CO-RE** - Compile Once Run Everywhere, portability technology for eBPF programs

**BTF** - BPF Type Format, kernel structure information for CO-RE

**Ring Buffer** - Efficient kernel-to-userspace data transfer mechanism

**Tracepoint** - Kernel instrumentation point for observing events

**Enrichment** - Adding process metadata from /proc to events

**Redaction** - Hiding sensitive path information for privacy

---

**Previous:** [Installation](03-installation.md) | **Next:** [Commands Reference](05-commands-reference.md)
