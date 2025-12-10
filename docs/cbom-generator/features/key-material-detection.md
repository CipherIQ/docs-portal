---
hide:
  - toc
---
# Key Material Detection

The Key Material Scanner provides comprehensive discovery and security analysis of cryptographic keys.

---

## Supported Key Types

| Key Type | Description | Example Sizes |
|----------|-------------|---------------|
| **RSA** | RSA asymmetric keys | 1024, 2048, 3072, 4096 bits |
| **ECDSA** | Elliptic Curve DSA | P-256, P-384, P-521 |
| **Ed25519** | Edwards curve 25519 | 256 bits (fixed) |
| **Ed448** | Edwards curve 448 | 448 bits (fixed) |
| **DSA** | Digital Signature Algorithm (legacy) | 1024, 2048, 3072 bits |
| **DH** | Diffie-Hellman | 2048, 3072, 4096 bits |
| **AES** | AES symmetric keys | 128, 192, 256 bits |
| **ChaCha20** | ChaCha20 stream cipher | 256 bits |
| **HMAC** | HMAC keys | Variable |

---

## Supported Formats

- **PEM**: ASCII armor format with BEGIN/END markers
- **DER**: Binary Distinguished Encoding Rules
- **OpenSSH**: OpenSSH format (`ssh-rsa`, `ssh-ed25519`)
- **PKCS#8**: Private key information syntax
- **PKCS#1**: RSA private key format
- **SEC1**: EC private key format
- **RAW**: Raw key bytes

---

## Storage Security Detection

The scanner automatically detects how keys are protected:

| Storage Type | Description | Security Level |
|--------------|-------------|----------------|
| **HSM** | Hardware Security Module | Highest |
| **TPM** | Trusted Platform Module | High |
| **Encrypted** | Password-protected | Medium |
| **Keyring** | OS keyring/keychain | Medium |
| **Plaintext** | Unencrypted file | **LOW RISK** |

**Example Detection**:
```bash
# Scan for unencrypted private keys
./build/cbom-generator /etc/ssl/private --output cbom.json
cat cbom.json | jq '.components[] |
    select(.properties[]? |
    select(.name == "cbom:key:storage_security" and .value == "PLAINTEXT")) |
    .name'
```

---

## Key Lifecycle Tracking (NIST SP 800-57)

Keys are classified by their lifecycle state:

| State | Description |
|-------|-------------|
| **Pre-activation** | Generated but not yet in use |
| **Active** | Currently in use |
| **Suspended** | Temporarily disabled |
| **Deactivated** | No longer in use |
| **Compromised** | Known or suspected compromise |
| **Destroyed** | Securely deleted |

---

## Weakness Detection

The scanner automatically identifies weak keys:

- **RSA keys < 2048 bits** (NIST recommendation)
- **ECDSA keys < 256 bits** (NIST recommendation)
- **DSA keys** (deprecated algorithm)
- **DH keys < 2048 bits**

---

## CycloneDX Properties

Keys appear in the output with these properties:

```json
{
  "type": "cryptographic-asset",
  "name": "RSA-2048",
  "bom-ref": "key:rsa-2048-sha256:a1b2c3d4",
  "cryptoProperties": {
    "assetType": "related-crypto-material",
    "relatedCryptoMaterialProperties": {
      "type": "private-key",
      "state": "active",
      "size": 2048
    }
  },
  "properties": [
    { "name": "cbom:key:type", "value": "RSA" },
    { "name": "cbom:key:size", "value": "2048" },
    { "name": "cbom:key:format", "value": "PEM" },
    { "name": "cbom:key:classification", "value": "private" },
    { "name": "cbom:key:storage_security", "value": "ENCRYPTED" },
    { "name": "cbom:key:is_weak", "value": "false" },
    { "name": "cbom:pqc:status", "value": "UNSAFE" },
    { "name": "cbom:pqc:break_estimate", "value": "2035" }
  ]
}
```

---

## Common Use Cases

### Finding Unencrypted Private Keys

```bash
./build/cbom-generator /etc/ssl --output cbom.json
cat cbom.json | jq -r '.components[] |
    select(.cryptoProperties?.relatedCryptoMaterialProperties?.type == "private-key") |
    select(.properties[]? | select(.name == "cbom:key:storage_security" and .value == "PLAINTEXT")) |
    .evidence.occurrences[0].location'
```

### Identifying Weak Keys

```bash
./build/cbom-generator --output cbom.json
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:key:is_weak" and .value == "true")) |
    {name: .name, location: .evidence.occurrences[0].location}'
```

### HSM Inventory

```bash
./build/cbom-generator --output cbom.json
cat cbom.json | jq -r '.components[] |
    select(.properties[]? | select(.name == "cbom:key:storage_security" and .value == "HSM")) |
    "\(.name) - \(.evidence.occurrences[0].location)"'
```

---

## Security Note

The scanner **NEVER** stores raw key material. Only SHA-256 hashes of key content are stored for identification purposes.
