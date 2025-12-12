# Introduction 

## What is crypto-tracer?

crypto-tracer is a standalone command-line tool for monitoring and analyzing cryptographic operations on Linux systems. It uses eBPF (Extended Berkeley Packet Filter) technology to observe crypto-related activity at the kernel level with minimal performance impact.

## Key Features

- **Real-time monitoring** of cryptographic file access and library loading
- **Process profiling** with detailed crypto usage statistics
- **System snapshots** for instant crypto inventory
- **Privacy-first design** with automatic path redaction
- **Lightweight operation** with <0.5% CPU overhead and <50MB memory footprint
- **Safe and non-invasive** - read-only operation with no system modifications
- **Cross-kernel compatible** - works on Linux 4.15+ with automatic adaptation

## Who Should Use This Tool?

- **Security Researchers** - Analyze cryptographic behavior and identify security issues
- **System Administrators** - Troubleshoot certificate and key loading problems
- **DevOps Engineers** - Validate crypto configurations in CI/CD pipelines
- **Compliance Officers** - Generate crypto inventory reports for audits and PQC readiness
- **Developers** - Verify applications load correct crypto assets

## What crypto-tracer Monitors

crypto-tracer tracks three main types of cryptographic activity:

### 1. File Access
Opening of crypto files:
- Certificates (`.crt`, `.cer`, `.pem`)
- Private keys (`.key`, `.pem`)
- Keystores (`.p12`, `.pfx`, `.jks`, `.keystore`)

### 2. Library Loading
Loading of crypto libraries:
- OpenSSL (`libssl`, `libcrypto`)
- GnuTLS (`libgnutls`)
- libsodium (`libsodium`)
- NSS (`libnss3`)
- mbedTLS (`libmbedtls`)

### 3. Process Activity
Process execution and termination related to crypto operations

## How It Works

crypto-tracer uses eBPF (Extended Berkeley Packet Filter) to monitor system activity:

1. **eBPF Programs** run in the Linux kernel and observe system calls
2. **Tracepoints** capture file opens, library loads, and process events
3. **Ring Buffer** efficiently transfers events from kernel to user-space
4. **Event Processing** filters, enriches, and formats events
5. **JSON Output** provides structured data for analysis

This architecture ensures minimal performance impact while providing comprehensive visibility into cryptographic operations.

## Documentation Structure

This manual is organized into the following sections:

- **Getting Started** - Quick start guide and system requirements
- **Installation** - How to install and set up crypto-tracer
- **Basic Concepts** - Understanding events, file types, and output modes
- **Commands Reference** - Detailed documentation for all commands
- **Common Use Cases** - Real-world scenarios and solutions
- **Output Formats** - Understanding different output formats
- **Filtering and Options** - How to use filters and command options
- **Privacy and Security** - Privacy features and security considerations
- **Troubleshooting** - Solutions to common problems
- **Advanced Usage** - Scripting, automation, and integration
- **Performance** - Performance considerations and optimization
- **Integration** - Integrating with other tools and systems
- **FAQ** - Frequently asked questions
- **Support** - Getting help and contributing

---

**Next:** [Getting Started](02-getting-started.md)
