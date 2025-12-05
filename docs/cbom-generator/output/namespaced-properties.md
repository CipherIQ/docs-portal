# Namespaced Properties (cbom:*)

Extended properties using the `cbom:*` namespace provide additional detail.

---

## Algorithm Properties

```json
{
  "name": "cbom:algo:primitive",
  "value": "block-cipher"
},
{
  "name": "cbom:algo:key_size",
  "value": "256"
},
{
  "name": "cbom:algo:is_weak",
  "value": "false"
}
```

---

## Certificate Properties

```json
{
  "name": "cbom:cert:signature_algorithm_oid",
  "value": "1.2.840.113549.1.1.11"
},
{
  "name": "cbom:cert:validity_state",
  "value": "active"
},
{
  "name": "cbom:cert:revocation_status",
  "value": "GOOD"
}
```

| Property | Values |
|----------|--------|
| `validity_state` | pre-activation, active, deactivated |
| `revocation_status` | GOOD, REVOKED, UNKNOWN |

---

## Key Properties

```json
{
  "name": "cbom:key:type",
  "value": "RSA"
},
{
  "name": "cbom:key:size",
  "value": "2048"
},
{
  "name": "cbom:key:storage_security",
  "value": "encrypted"
},
{
  "name": "cbom:key:is_weak",
  "value": "false"
}
```

| storage_security | Description |
|------------------|-------------|
| `plaintext` | Unencrypted file |
| `encrypted` | Password-protected |
| `hsm` | Hardware Security Module |
| `tpm` | Trusted Platform Module |
| `keyring` | OS keyring/keychain |

---

## Protocol Properties

```json
{
  "name": "cbom:proto:type",
  "value": "TLS"
},
{
  "name": "cbom:proto:version",
  "value": "1.3"
},
{
  "name": "cbom:proto:security_profile",
  "value": "MODERN"
}
```

| security_profile | Description |
|------------------|-------------|
| `MODERN` | TLS 1.3 only, strong ciphers |
| `INTERMEDIATE` | TLS 1.2+, good ciphers |
| `OLD` | TLS 1.0/1.1, weak ciphers |

---

## Service Properties

```json
{
  "name": "cbom:svc:name",
  "value": "Apache HTTPD"
},
{
  "name": "cbom:svc:version",
  "value": "2.4.52"
},
{
  "name": "cbom:svc:is_running",
  "value": "true"
},
{
  "name": "cbom:svc:port",
  "value": "443"
},
{
  "name": "cbom:svc:config_file",
  "value": "/etc/apache2/sites-enabled/default-ssl.conf"
}
```

---

## Application Properties

```json
{
  "name": "cbom:app:role",
  "value": "service"
},
{
  "name": "cbom:app:binary_path",
  "value": "/usr/sbin/nginx"
},
{
  "name": "cbom:app:detection_method",
  "value": "BINARY_SCAN_PARALLEL"
}
```

| role | Description |
|------|-------------|
| `service` | Network daemon |
| `client` | Client application |
| `utility` | Command-line tool |

---

## PQC Properties

```json
{
  "name": "cbom:pqc:status",
  "value": "TRANSITIONAL"
},
{
  "name": "cbom:pqc:alternative",
  "value": "ML-DSA-65"
},
{
  "name": "cbom:pqc:migration_urgency",
  "value": "HIGH"
},
{
  "name": "cbom:pqc:break_estimate",
  "value": "2035"
},
{
  "name": "cbom:pqc:rationale",
  "value": "Quantum-vulnerable but meets current classical security standards"
}
```

| status | Description |
|--------|-------------|
| `SAFE` | Post-quantum secure |
| `TRANSITIONAL` | Classically strong, quantum-vulnerable |
| `DEPRECATED` | Broken/weak algorithms |
| `UNSAFE` | Quantum-vulnerable + weak |

---

## Context Properties

Detection provenance information:

```json
{
  "name": "cbom:ctx:detection_method",
  "value": "FILE_CONTENT"
},
{
  "name": "cbom:ctx:confidence",
  "value": "0.95"
},
{
  "name": "cbom:ctx:scanner_name",
  "value": "certificate_scanner"
}
```

| Detection Method | Description | Confidence |
|------------------|-------------|------------|
| `FILE_CONTENT` | File parsing | 0.95-1.0 |
| `BINARY_SCAN_PARALLEL` | ELF analysis | 0.85-0.90 |
| `KERNEL_CRYPTO_API` | AF_ALG sockets | 0.80 |
| `STATIC_LINKED` | Go/Rust crypto | 0.75-0.85 |
| `SYMBOL_ANALYSIS` | Symbol table | 0.70-0.80 |

---

## Common Queries

### Find Weak Components

```bash
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:key:is_weak" and .value == "true")) |
    .name'
```

### Find by Security Profile

```bash
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:proto:security_profile" and .value == "OLD")) |
    .name'
```

### Find by PQC Status

```bash
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "DEPRECATED")) |
    .name'
```
