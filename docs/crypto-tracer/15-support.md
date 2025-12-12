# Support and Resources

This section provides information about getting help, contributing, and additional resources for **crypto-tracer**.

## Documentation

### Available Documentation

**Technical Documentation:**

- **Man Page** - `man crypto-tracer` (after installation)
- **Build Documentation** - See `Makefile` and `BUILD_NOTES_ARM64.md`
- **API Documentation** - See source code headers

**Manual Sections:**

- [Introduction](index.md)
- [Getting Started](02-getting-started.md)
- [Installation](03-installation.md)
- [Basic Concepts](04-basic-concepts.md)
- [Commands Reference](05-commands-reference.md)
- [Common Use Cases](06-common-use-cases.md)
- [Output Formats](07-output-formats.md)
- [Filtering and Options](08-filtering-options.md)
- [Privacy and Security](09-privacy-security.md)
- [Troubleshooting](10-troubleshooting.md)
- [Advanced Usage](11-advanced-usage.md)
- [Performance](12-performance.md)
- [Integration](13-integration.md)
- [FAQ](14-faq.md)

## Online Resources

### GitHub Repository

**Main Repository:**

- URL: [https://github.com/cipheriq/crypto-tracer](https://github.com/cipheriq/crypto-tracer)
- Source code, issues, discussions, and releases

**Key Pages:**

- **Releases:** [https://github.com/cipheriq/crypto-tracer/releases](https://github.com/cipheriq/crypto-tracer/releases)
- **Issue Tracker:** [https://github.com/cipheriq/crypto-tracer/issues](https://github.com/cipheriq/crypto-tracer/issues)
- **Discussions:** [https://github.com/cipheriq/crypto-tracer/discussions](https://github.com/cipheriq/crypto-tracer/)discussions

### Download Locations

**Pre-built Binaries:**

- GitHub Releases (recommended)
- Static binaries for multiple architectures
- Includes man pages and documentation

**Source Code:**
```bash
# Clone repository
git clone https://github.com/cipheriq/crypto-tracer.git
cd crypto-tracer

# Build from source
make
```

## Community

### Getting Involved

**GitHub Discussions:**

- Ask questions
- Share use cases
- Discuss features
- Connect with other users

**Bug Reports:**

- Report bugs on GitHub Issues
- Include system information
- Provide reproduction steps
- Attach debug output

**Feature Requests:**

- Suggest new features on GitHub Issues
- Describe use case
- Explain expected behavior

### Security Issues

**For security vulnerabilities:**

- **DO NOT** open public GitHub issues
- Email: team@cipheriq.io
- Expect response within 48 hours

**Responsible Disclosure:**

1. Report vulnerability privately
2. Allow time for fix (typically 90 days)
3. Coordinate public disclosure
4. Credit will be given in release notes

## Getting Help

### Before Asking for Help

1. **Check the documentation:**

   - Read relevant manual sections
   - Check [FAQ](14-faq.md)
   - Review [Troubleshooting](10-troubleshooting.md)

2. **Search existing issues:**

   - Someone may have had the same problem
   - Solution might already exist

3. **Try verbose mode:**
   ```bash
   sudo ./crypto-tracer monitor --verbose
   ```

4. **Collect system information:**
   ```bash
   ./crypto-tracer --version
   uname -r
   cat /etc/os-release
   ```

### When Reporting Issues

**Include this information:**

1. **crypto-tracer version:**
   ```bash
   ./crypto-tracer --version
   ```

2. **Kernel version:**
   ```bash
   uname -r
   ```

3. **Distribution:**
   ```bash
   cat /etc/os-release
   ```

4. **Full error message:**
   - Copy complete error output
   - Include any warnings

5. **Steps to reproduce:**
   - Exact commands used
   - Expected behavior
   - Actual behavior

6. **Debug output:**
   ```bash
   sudo ./crypto-tracer monitor --verbose 2>&1 | tee debug.log
   ```

### Issue Template

```markdown
**Description:**
Brief description of the issue

**Environment:**
- crypto-tracer version: [output of --version]
- Kernel version: [output of uname -r]
- Distribution: [e.g., Ubuntu 22.04]
- Architecture: [e.g., x86_64]

**Steps to Reproduce:**
1. Run command: `sudo ./crypto-tracer monitor`
2. Observe error: [error message]

**Expected Behavior:**
What you expected to happen

**Actual Behavior:**
What actually happened

**Debug Output:**
```
[paste debug output here]
```

**Additional Context:**
Any other relevant information
```

## Commercial Support

### Professional Services

For organizations requiring professional support or a commercial license:

**Services Available:**

- Priority bug fixes
- Custom feature development
- Integration assistance
- Training and consulting
- SLA-backed support

**Contact:**

- Email: sales@cipheriq.io
- Website: https://www.cipheriq.io
- Response time: 1 business day

### Enterprise Features

**Available for commercial customers:**

- Extended support for older kernels
- Custom eBPF programs
- Integration with proprietary systems
- On-site training
- Dedicated support channel

## Contributing

### How to Contribute

Contributions are welcome! Here's how to get started:

1. **Read CONTRIBUTING.md:**
   - Code style guidelines
   - Development setup
   - Testing requirements
   - Pull request process

2. **Fork the repository:**
   ```bash
   # Fork on GitHub, then clone
   git clone https://github.com/cipheriq/crypto-tracer.git
   cd crypto-tracer
   ```

3. **Create a branch:**
   ```bash
   git checkout -b feature/my-feature
   ```

4. **Make changes:**
   - Follow code style
   - Add tests
   - Update documentation

5. **Test your changes:**
   ```bash
   make test
   make lint
   ```

6. **Submit pull request:**
   - Clear description
   - Reference related issues
   - Include test results

### Contribution Areas

**Code Contributions:**

- Bug fixes
- New features
- Performance improvements
- Test coverage

**Documentation:**

- Fix typos and errors
- Improve clarity
- Add examples
- Translate to other languages

**Testing:**

- Test on different distributions
- Test on different kernel versions
- Report compatibility issues
- Add test cases

**Community:**

- Answer questions in Discussions
- Help troubleshoot issues
- Share use cases
- Write blog posts

### Code Style

**C Code:**

- Follow existing style
- Use C11 standard
- Include license header
- Document functions

**License Header:**
```c
// SPDX-License-Identifier: GPL-3.0-or-later
/**
 * Copyright (c) 2025 Graziano Labs Corp.
 */
```

**Commit Messages:**
```
Short summary (50 chars or less)

Detailed explanation if needed. Wrap at 72 characters.
Reference issues with #123.

Signed-off-by: Your Name <your.email@example.com>
```

## License

### Open Source License

**GPL-3.0-or-later:**

- Free to use, modify, and distribute
- Must release modifications under GPL-3.0
- Source code must be made available
- See LICENSE file for full terms

**Key Points:**

- ✅ Use for any purpose
- ✅ Modify the source code
- ✅ Distribute copies
- ✅ Distribute modified versions
- ⚠️ Must disclose source
- ⚠️ Must use same license
- ⚠️ Must state changes

### Commercial License

**For proprietary use:**

- Use without GPL requirements
- No source code disclosure required
- Suitable for proprietary products
- Contact sales@cipheriq.io for pricing

**When you need commercial license:**

- Embedding in proprietary software
- Don't want to disclose source
- Need different license terms
- Require legal indemnification

## Appendix

### Exit Codes

**crypto-tracer** uses standard exit codes:

| Code | Name | Description |
|------|------|-------------|
| 0 | EXIT_SUCCESS | Successful execution |
| 1 | EXIT_GENERAL_ERROR | General runtime error |
| 2 | EXIT_ARGUMENT_ERROR | Invalid command-line arguments |
| 3 | EXIT_PRIVILEGE_ERROR | Insufficient privileges (need CAP_BPF or root) |
| 4 | EXIT_KERNEL_ERROR | Kernel compatibility issue (kernel too old) |
| 5 | EXIT_BPF_ERROR | eBPF program loading failure |

**Usage in scripts:**
```bash
#!/bin/bash
./crypto-tracer snapshot
EXIT_CODE=$?

case $EXIT_CODE in
    0)
        echo "Success"
        ;;
    2)
        echo "Invalid arguments"
        ;;
    3)
        echo "Need elevated privileges"
        ;;
    *)
        echo "Error: $EXIT_CODE"
        ;;
esac
```

### Environment Variables

**crypto-tracer** respects these environment variables:

| Variable | Description | Values | Default |
|----------|-------------|--------|---------|
| `LIBBPF_LOG_LEVEL` | libbpf logging verbosity | 0-4 | 0 |
| `CRYPTO_TRACER_DEBUG` | Enable debug mode | 0 or 1 | 0 |

**Examples:**
```bash
# Enable verbose libbpf logging
export LIBBPF_LOG_LEVEL=4
sudo ./crypto-tracer monitor --verbose

# Enable debug mode
export CRYPTO_TRACER_DEBUG=1
sudo ./crypto-tracer monitor
```

**Log Levels:**

- 0: No logging (default)
- 1: Errors only
- 2: Warnings and errors
- 3: Info, warnings, and errors
- 4: Debug (all messages)

### File Locations

**Default Installation Paths:**

| File | Location | Description |
|------|----------|-------------|
| Binary | `/usr/local/bin/crypto-tracer` | Main executable |
| Man page | `/usr/local/share/man/man1/crypto-tracer.1` | Manual page |
| Documentation | `/usr/local/share/doc/crypto-tracer/` | Additional docs |

**Runtime Files:**

- **eBPF programs:** Embedded in binary (no external files needed)
- **Output:** stdout or file specified with `--output`
- **Logs:** stderr

**Configuration:**

- No configuration files needed
- All options via command-line arguments

### Supported File Extensions

**Certificates:**

- `.crt` - X.509 certificate (DER or PEM)
- `.cer` - X.509 certificate (alternative extension)
- `.pem` - PEM-encoded certificate or key

**Private Keys:**

- `.key` - Private key (various formats)
- `.pem` - PEM-encoded private key

**Keystores:**

- `.p12` - PKCS#12 keystore
- `.pfx` - PKCS#12 keystore (alternative extension)
- `.jks` - Java KeyStore
- `.keystore` - Generic keystore

**Detection:**

- Extension-based classification
- Content-based detection for `.pem` files
- Looks for PEM headers (BEGIN CERTIFICATE, BEGIN PRIVATE KEY)

### Supported Crypto Libraries

**crypto-tracer** recognizes these cryptographic libraries:

**OpenSSL:**
- `libssl.so`, `libssl.so.1.1`, `libssl.so.3`
- `libcrypto.so`, `libcrypto.so.1.1`, `libcrypto.so.3`

**GnuTLS:**
- `libgnutls.so`, `libgnutls.so.30`

**libsodium:**
- `libsodium.so`, `libsodium.so.23`

**NSS (Network Security Services):**
- `libnss3.so`

**mbedTLS:**
- `libmbedtls.so`, `libmbedtls.so.14`

**Detection:**
- Substring matching on library path
- Case-insensitive matching
- Recognizes versioned libraries

### Glossary

**eBPF (Extended Berkeley Packet Filter)**

- Linux kernel technology for safe in-kernel programs
- Allows observability without kernel modifications
- Verified by kernel for safety

**CO-RE (Compile Once - Run Everywhere)**

- Portability technology for eBPF programs
- Single binary works across kernel versions
- Automatic adaptation to kernel structures

**BTF (BPF Type Format)**

- Kernel structure type information
- Enables CO-RE functionality
- Available in modern kernels (5.2+)

**Ring Buffer**

- Efficient kernel-to-userspace data transfer
- Lock-free, high-performance
- Used for event streaming

**Tracepoint**

- Kernel instrumentation point
- Stable API for observing kernel events
- Used by **crypto-tracer** for file and process events

**Uprobe (User-space Probe)**

- Dynamic instrumentation of user-space functions
- Used for library function tracing
- Optional in **crypto-tracer**

**CAP_BPF**

- Linux capability for loading eBPF programs
- Available in kernel 5.8+
- Minimal privilege for eBPF operations

**CAP_SYS_ADMIN**

- Linux capability for system administration
- Includes eBPF loading on older kernels
- Broader privilege than CAP_BPF

**CAP_PERFMON**

- Linux capability for performance monitoring
- Often needed alongside CAP_BPF
- Available in kernel 5.8+

**Skeleton**

- Generated C code embedding eBPF programs
- Created by bpftool
- Simplifies eBPF program loading

**vmlinux.h**

- Header file with kernel type definitions
- Generated from kernel BTF
- Enables CO-RE functionality

---

**End of User Manual**

*Last Updated: December 2024*  
*Version: 1.0*  
*Copyright © 2025 Graziano Labs Corp.*

**Previous:** [FAQ](14-faq.md) | **[Back to Introduction](index.md)**
