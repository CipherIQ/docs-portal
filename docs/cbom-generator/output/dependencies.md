---
hide:
  - toc
---
# Dependencies Array

The `dependencies` array shows provider/consumer relationships between components.


## Structure

```json
{
  "dependencies": [
    {
      "ref": "service:nginx",
      "dependsOn": [
        "protocol:tls",
        "library:openssl"
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

## Fields

| Field | Description |
|-------|-------------|
| `ref` | Consumer component ID (bom-ref) |
| `dependsOn` | Array of provider component IDs |

---

## Human-Readable References 
all refs use human-readable identifiers. 

For instance:

- `service:nginx` 
- `algo:aes-256-gcm-256`

This makes dependency graphs self-documenting.

---

## Dependency Chains

### Service to Algorithm

```
service:nginx
  └── dependsOn → protocol:tls
                      └── dependsOn → cipher:tls-ecdhe-rsa-with-aes-256-gcm-sha384
                                          └── dependsOn → algo:aes-256-gcm-256
                                          └── dependsOn → algo:sha384
```

### Application to Library

```
app:curl
  └── dependsOn → library:openssl
                      └── dependsOn → algo:rsa
                      └── dependsOn → algo:aes-256-gcm-256
```

---

## Semantics

| Direction | Meaning |
|-----------|---------|
| `A` → `B` | A depends on B (A is consumer, B is provider) |
| Service → Protocol | Service uses protocol |
| Protocol → Cipher | Protocol provides cipher suite |
| Cipher → Algorithm | Cipher uses algorithm |
| App → Library | Application links to library |

---

## Validation

Dependencies are validated:

- **No dangling refs**: All refs must exist as components
- **No self-dependencies**: A component cannot depend on itself
- **Sorted arrays**: dependsOn arrays sorted alphabetically for determinism

---

## Common Queries

### Find All Service Dependencies

```bash
cat cbom.json | jq '.dependencies[] | select(.ref | startswith("service:"))'
```

### Trace Algorithm Usage

```bash
cat cbom.json | jq '.dependencies[] |
    select(.dependsOn[]? | contains("algo:sha256")) |
    .ref'
```

### Count Dependencies per Component

```bash
cat cbom.json | jq '.dependencies[] |
    {ref: .ref, count: (.dependsOn | length)}'
```

### Find Components with Most Dependencies

```bash
cat cbom.json | jq '.dependencies |
    sort_by(.dependsOn | length) |
    reverse |
    .[0:10] |
    map({ref, count: (.dependsOn | length)})'
```

### Full Dependency Tree for a Service

```bash
SERVICE="service:nginx"
cat cbom.json | jq --arg svc "$SERVICE" '
    .dependencies[] | select(.ref == $svc) |
    {service: .ref, dependencies: .dependsOn}'
```

---

## Statistics

Dependency counts are included in metadata:

```json
{
  "properties": [
    { "name": "cbom:relationships:total", "value": "537" },
    { "name": "cbom:dependencies:count", "value": "149" }
  ]
}
```
