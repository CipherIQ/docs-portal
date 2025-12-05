# Crypto Properties

The `cryptoProperties` block contains CycloneDX CBOM-specific fields.

---

## algorithmProperties

**For**: Algorithms and cipher suites

```json
{
  "cryptoProperties": {
    "assetType": "algorithm",
    "algorithmProperties": {
      "primitive": "ae",
      "parameterSetIdentifier": "256",
      "mode": "gcm",
      "classicalSecurityLevel": 256,
      "nistQuantumSecurityLevel": 5,
      "certificationLevel": ["fips140-2-l1"],
      "policy": "CNSA"
    }
  }
}
```

**Primitives**:

| Primitive | Description | Examples |
|-----------|-------------|----------|
| `ae` | Authenticated encryption | AES-GCM, ChaCha20-Poly1305 |
| `block-cipher` | Block cipher | AES, DES, 3DES |
| `stream-cipher` | Stream cipher | ChaCha20, RC4 |
| `hash` | Hash function | SHA-256, SHA-3, MD5 |
| `signature` | Digital signature | RSA, ECDSA, Ed25519, ML-DSA |
| `key-agree` | Key agreement | ECDH, DH, X25519 |
| `mac` | Message authentication | HMAC |
| `kdf` | Key derivation | PBKDF2, HKDF, scrypt |
| `kem` | Key encapsulation | ML-KEM (Kyber), NTRU |

---

## certificateProperties

**For**: X.509 certificates

```json
{
  "cryptoProperties": {
    "assetType": "certificate",
    "certificateProperties": {
      "subjectName": "CN=Example CA",
      "issuerName": "CN=Root CA",
      "notValidBefore": "2020-01-01T00:00:00Z",
      "notValidAfter": "2030-01-01T00:00:00Z",
      "certificateFormat": "X.509",
      "certificateState": [
        {
          "state": "active",
          "activationDate": "2020-01-01T00:00:00Z",
          "deactivationDate": null,
          "revocationDate": null,
          "reason": null
        }
      ]
    }
  }
}
```

**Certificate States**:

| State | Description |
|-------|-------------|
| `pre-activation` | Not yet valid (notValidBefore in future) |
| `active` | Currently valid |
| `deactivated` | Expired (past notValidAfter) |
| `revoked` | Revoked by CA |

---

## relatedCryptoMaterialProperties

**For**: Private keys, public keys, secrets

```json
{
  "cryptoProperties": {
    "assetType": "related-crypto-material",
    "relatedCryptoMaterialProperties": {
      "type": "private-key",
      "state": "active",
      "size": 2048,
      "format": "PEM",
      "creationDate": "2024-01-01T00:00:00Z",
      "activationDate": "2024-01-01T00:00:00Z",
      "expirationDate": "2034-01-01T00:00:00Z"
    }
  }
}
```

**Key Types**:

| Type | Description |
|------|-------------|
| `private-key` | Private key material |
| `public-key` | Public key material |
| `secret-key` | Symmetric secret key |
| `key` | Generic key |

**Key States** (NIST SP 800-57):

| State | Description |
|-------|-------------|
| `pre-activation` | Generated but not yet active |
| `active` | Currently in use |
| `suspended` | Temporarily disabled |
| `deactivated` | No longer used for protection |
| `compromised` | Known or suspected compromise |
| `destroyed` | Securely erased |

---

## protocolProperties

**For**: Communication protocols

```json
{
  "cryptoProperties": {
    "assetType": "protocol",
    "protocolProperties": {
      "type": "tls",
      "version": "1.3"
    }
  }
}
```

**Protocol Types**:

| Type | Description |
|------|-------------|
| `tls` | Transport Layer Security |
| `ssh` | Secure Shell |
| `ipsec` | IP Security |
| `dtls` | Datagram TLS |
| `wireguard` | WireGuard VPN |

---

## Common Queries

### Find Algorithms by Primitive

```bash
cat cbom.json | jq '.components[] |
    select(.cryptoProperties?.algorithmProperties?.primitive == "hash") |
    .name'
```

### Find Active Certificates

```bash
cat cbom.json | jq '.components[] |
    select(.cryptoProperties?.certificateProperties?.certificateState[0]?.state == "active") |
    .name'
```

### Find Keys by Size

```bash
cat cbom.json | jq '.components[] |
    select(.cryptoProperties?.relatedCryptoMaterialProperties?.size < 2048) |
    {name, size: .cryptoProperties.relatedCryptoMaterialProperties.size}'
```
