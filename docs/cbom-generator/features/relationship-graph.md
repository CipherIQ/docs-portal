---
hide:
  - toc
---
# Relationship Graph

The CBOM Generator builds a complete dependency graph showing how cryptographic components relate to each other.


## Relationship Types

| Relationship | Description | Example |
|--------------|-------------|---------|
| **USES** | Consumer uses provider | Service uses Protocol |
| **PROVIDES** | Provider offers capability | Protocol provides Cipher Suite |
| **DEPENDS_ON** | Direct dependency | Application depends on Library |
| **AUTHENTICATES_WITH** | Authentication relationship | nginx authenticates with server.crt |
| **CONFIGURES** | Configuration relationship | apache2 configures TLS 1.3 |
| **SIGNS** | Signing relationship | CA signs end-entity certificate |
| **ISSUED_BY** | Issuance relationship | Certificate issued by CA |

---

## Dependency Chains

### Service to Algorithm Chain

```
SERVICE → PROTOCOL → CIPHER_SUITE → ALGORITHM
```

Example:
```
nginx
  └── USES → TLS 1.3
                └── PROVIDES → TLS_AES_256_GCM_SHA384
                                   └── USES → AES-256-GCM
                                   └── USES → SHA384
```

### Application to Library Chain

```
APPLICATION → LIBRARY → ALGORITHM
```

Example:
```
curl
  └── DEPENDS_ON → OpenSSL
                       └── PROVIDES → RSA
                       └── PROVIDES → ECDSA
                       └── PROVIDES → AES-256-GCM
```

### Certificate Chain

```
END_ENTITY_CERT → INTERMEDIATE_CA → ROOT_CA
```

Example:
```
server.crt
  └── ISSUED_BY → Intermediate CA
                      └── ISSUED_BY → Root CA
                                          └── SELF_SIGNED
```

---

## CycloneDX Dependencies Array

The dependency graph is represented in the `dependencies` array:

```json
{
  "dependencies": [
    {
      "ref": "service:nginx",
      "dependsOn": ["protocol:tls"]
    },
    {
      "ref": "protocol:tls",
      "dependsOn": [
        "cipher:tls-ecdhe-rsa-with-aes-256-gcm-sha384"
      ]
    },
    {
      "ref": "cipher:tls-ecdhe-rsa-with-aes-256-gcm-sha384",
      "dependsOn": [
        "algo:aes-256-gcm-256",
        "algo:ecdhe",
        "algo:rsa",
        "algo:sha384"
      ]
    }
  ]
}
```

---

## Provider Properties

Components that provide services include `cbom:provides` property:

```json
{
  "name": "TLS",
  "type": "protocol",
  "properties": [
    {
      "name": "cbom:provides",
      "value": "cipher-suite-1, cipher-suite-2"
    }
  ]
}
```

---

## Common Queries

### Finding All Dependencies of a Service

```bash
cat cbom.json | jq '.dependencies[] | select(.ref == "service:nginx")'
```

### Tracing Algorithm Usage

```bash
# Find all components that use a specific algorithm
cat cbom.json | jq '.dependencies[] |
    select(.dependsOn[]? | contains("algo:aes-256-gcm")) |
    .ref'
```

### Building Full Dependency Tree

```bash
# Show complete dependency chain for a service
SERVICE="service:nginx"
cat cbom.json | jq --arg svc "$SERVICE" '
    .dependencies[] |
    select(.ref == $svc or .ref as $r |
        (.dependencies[] | select(.ref == $svc).dependsOn[]?) == $r)'
```

### Finding Orphan Components

```bash
# Components not referenced in any dependency
cat cbom.json | jq '
    [.dependencies[].ref, .dependencies[].dependsOn[]] | flatten | unique as $refs |
    .components[].["bom-ref"] |
    select(. as $br | $refs | index($br) | not)'
```

---

## Relationship Statistics

The CBOM includes relationship counts in metadata:

```json
{
  "properties": [
    { "name": "cbom:relationships:total", "value": "537" },
    { "name": "cbom:relationships:uses", "value": "245" },
    { "name": "cbom:relationships:provides", "value": "189" },
    { "name": "cbom:relationships:depends_on", "value": "103" }
  ]
}
```
