---
hide:
  - toc
---
# Support

Getting help with CBOM Generator.


## Getting Help

### Documentation

- [Installation Guide](../getting-started/installation.md)
- [Quick Start](../getting-started/quick-start.md)
- [CLI Reference](../cli-reference/index.md)
- [Troubleshooting](../troubleshooting/index.md)

### Command-Line Help

```bash
./build/cbom-generator --help
./build/cbom-generator --version
```

---

## Reporting Issues

### GitHub Issues

Report bugs and feature requests at: [https://github.com/CipherIQ/cbom-generator/issues](https://github.com/CipherIQ/cbom-generator/issues)

### Issue Template

When reporting issues, include:

1. **CBOM Generator version**: `./build/cbom-generator --version`
2. **Operating system**: `uname -a`
3. **Command used**: Full command line
4. **Error message**: Complete error output
5. **Steps to reproduce**: Minimal steps to trigger the issue

---


## External References

### CycloneDX

- [CycloneDX Specification](https://cyclonedx.org/specification/overview/)
- [CBOM Extensions](https://cyclonedx.org/capabilities/cbom/)
- [Schema Downloads](https://cyclonedx.org/schema/)

### NIST Standards

- [NIST SP 800-57](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final) - Key Management
- [NIST IR 8413](https://csrc.nist.gov/publications/detail/ir/8413/final) - PQC Status Report
- [FIPS 140-3](https://csrc.nist.gov/publications/detail/fips/140/3/final) - Cryptographic Module Standards

### PQC Resources

- [NIST PQC Project](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [NSA CNSA 2.0](https://media.defense.gov/2022/Sep/07/2003071834/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF)

---

## License

CBOM Generator is licensed under GPL-3.0-or-later.

For commercial licensing options, contact: sales@cipheriq.io

---

## Contributing

Contributions are welcome! See [CONTRIBUTING](https://github.com/CipherIQ/cbom-generator/blob/main/CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone repository
git clone https://github.com/CipherIQ/cbom-generator.git
cd cbom-generator

# Build debug version
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug

# Run tests
cd build-debug && ctest
```

---

## Contact

- **Technical Support**: support@cipheriq.io
- **Sales**: sales@cipheriq.io
- **GitHub**: [https://github.com/CipherIQ/cbom-generator](https://github.com/CipherIQ/cbom-generator)

Copyright (c) 2025 Graziano Labs Corp.
<script>
document.addEventListener('DOMContentLoaded', function() {
  var links = document.querySelectorAll('a');
  for (var i = 0; i < links.length; i++) {
    if (links[i].hostname !== window.location.hostname) {
      links[i].target = '_blank';
      links[i].rel = 'noopener noreferrer';
    }
  }
});
</script>