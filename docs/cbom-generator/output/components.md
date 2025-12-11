---
hide:
  - toc
---
# Understanding Components

Every component in the CBOM represents a cryptographic asset.


## Component Structure

**Required Fields**:

| Field | Description |
|-------|-------------|
| `type` | Component type |
| `name` | Human-readable name |
| `bom-ref` | Unique identifier |

**Optional Fields**:

| Field | Description |
|-------|-------------|
| `version` | Component version |
| `cryptoProperties` | CycloneDX CBOM-specific fields |
| `properties` | Namespaced cbom:* properties |
| `evidence` | File locations and hashes |

---

## Human-Readable `bom-refs`

`bom-ref` values are human-readable:

```json
"bom-ref": "cert:swisssign-gold-ca-g2"
```

**bom-ref Format by Component Category**:

| Type | Format | Example |
|------|--------|---------|
| Certificate | `cert:<sanitized-cn>` | `cert:digicert-assured-id-root-ca` |
| Certificate Request | `csr:<sanitized-cn>` | `csr:myserver-request` |
| Algorithm | `algo:<algorithm>-<keysize>` | `algo:aes-256-gcm-256` |
| Key | `key:<algorithm>-<keysize>-<hash>` | `key:rsa-2048-a1b2c3d4` |
| Service | `service:<name>` | `service:apache-httpd` |
| Protocol | `protocol:<name>` | `protocol:tls` |
| Cipher Suite | `cipher:<name>` | `cipher:tls-ecdhe-rsa-with-aes-256-gcm-sha384` |
| Library | `library:<name>` | `library:openssl` |
| Application | `app:<name>` | `app:curl` |

---

## Component Types

### cryptographic-asset

Has a `cryptoProperties` block:

```json
{
  "type": "cryptographic-asset",
  "name": "AES-256-GCM",
  "bom-ref": "algo:aes-256-gcm-256",
  "cryptoProperties": {
    "assetType": "algorithm",
    "algorithmProperties": {
      "primitive": "ae",
      "parameterSetIdentifier": "256",
      "mode": "gcm"
    }
  }
}
```

**cryptoProperties.assetType Values**

Components with `type: "cryptographic-asset"` have a `cryptoProperties` block with one of these `assetType` values:

| assetType | Description | Example |
|-----------|-------------|---------|
| `algorithm` | Cryptographic algorithm | AES-256-GCM |
| `certificate` | X.509 certificate | CA root cert |
| `related-crypto-material` | Key material | RSA-2048 key |
| `protocol` | Communication protocol | TLS 1.3 |
| `cipher-suite` | TLS/SSL cipher suite | TLS_AES_256_GCM_SHA384 |

Other component types (`library`, `operating-system`, `application`) don't use `cryptoProperties`. See sections below.

### library

Crypto libraries tracked via package managers:

```json
{
  "type": "library",
  "name": "OpenSSL",
  "bom-ref": "library:openssl",
  "version": "3.0.2",
  "properties": [
    { "name": "cbom:lib:soname", "value": "libssl.so.3" },
    { "name": "cbom:lib:type", "value": "crypto" }
  ]
}
```

### operating-system

Services with network functionality:

```json
{
  "type": "operating-system",
  "name": "Apache HTTPD",
  "bom-ref": "service:apache-httpd",
  "properties": [
    { "name": "cbom:svc:port", "value": "443" },
    { "name": "cbom:svc:config_file", "value": "/etc/apache2/sites-enabled/default-ssl.conf" }
  ]
}
```

### application

Applications with crypto dependencies:

```json
{
  "type": "application",
  "name": "curl",
  "bom-ref": "app:curl",
  "properties": [
    { "name": "cbom:app:role", "value": "client" },
    { "name": "cbom:app:binary_path", "value": "/usr/bin/curl" }
  ]
}
```

---

## Evidence Section

Components include evidence of where they were found:

```json
{
  "evidence": {
    "occurrences": [
      {
        "location": "/etc/ssl/certs/DigiCert_Global_Root_CA.pem"
      },
      {
        "location": "/usr/share/ca-certificates/DigiCert_Global_Root_CA.crt"
      }
    ]
  }
}
```

---

## Common Queries

### List All Component Types

```bash
cat cbom.json | jq '[.components[].type] | unique'
```

### Find Components by bom-ref Prefix

```bash
cat cbom.json | jq '.components[] | select(.["bom-ref"] | startswith("cert:"))'
```

### Count Components by Asset Type

```bash
cat cbom.json | jq '[.components[] | .cryptoProperties?.assetType] |
    group_by(.) |
    map({type: .[0], count: length})'
```
