---
hide:
  - toc
---
# Relationships Array

The `relationships` array provides typed edges with confidence scores.



## Structure

```json
{
  "relationships": [
    {
      "type": "USES",
      "source": "service|apache",
      "target": "protocol|TLS",
      "confidence": "0.95"
    },
    {
      "type": "PROVIDES",
      "source": "protocol|TLS",
      "target": "cipher-suite-123",
      "confidence": "0.95"
    },
    {
      "type": "evidence",
      "source": "/etc/ssl/cert.pem",
      "target": "component-456"
    }
  ]
}
```

---

## Fields

| Field | Description |
|-------|-------------|
| `type` | Relationship type |
| `source` | Source component or file path |
| `target` | Target component |
| `confidence` | Confidence score (0.0-1.0) |

---

## Relationship Types

| Type | Description | Example |
|------|-------------|---------|
| `USES` | Consumer uses provider | Service uses protocol |
| `PROVIDES` | Provider offers capability | Protocol provides cipher |
| `DEPENDS_ON` | Direct dependency | App depends on library |
| `AUTHENTICATES_WITH` | Authentication | Service uses certificate |
| `CONFIGURES` | Configuration | Service configures protocol |
| `SIGNS` | Signing | CA signs certificate |
| `ISSUED_BY` | Issuance | Cert issued by CA |
| `evidence` | File evidence | File contains component |

---

## Confidence Scores

| Range | Meaning | Example |
|-------|---------|---------|
| 0.95-1.0 | Very high | Direct file parsing |
| 0.85-0.95 | High | Dynamic library analysis |
| 0.75-0.85 | Medium | Static analysis |
| 0.70-0.80 | Lower | Heuristic detection |

---

## Relationship Examples

### Service Uses Protocol

```json
{
  "type": "USES",
  "source": "service|nginx",
  "target": "protocol|TLS",
  "confidence": "0.95"
}
```

### Protocol Provides Cipher Suite

```json
{
  "type": "PROVIDES",
  "source": "protocol|TLS",
  "target": "cipher:tls-aes-256-gcm-sha384",
  "confidence": "0.95"
}
```

### Application Depends on Library

```json
{
  "type": "DEPENDS_ON",
  "source": "app|curl",
  "target": "library|openssl",
  "confidence": "0.90"
}
```

### Evidence Relationship

```json
{
  "type": "evidence",
  "source": "/etc/ssl/certs/ca-certificates.crt",
  "target": "cert:digicert-global-root-ca"
}
```

---

## Dependencies vs Relationships

| Feature | dependencies | relationships |
|---------|--------------|---------------|
| Format | Array of arrays | Array of objects |
| Types | Implicit "depends on" | Explicit type field |
| Confidence | Not included | Included |
| Purpose | CycloneDX standard | Extended detail |

Both represent the same graph, but `relationships` provides more detail.

---

## Common Queries

### Find All USES Relationships

```bash
cat cbom.json | jq '.relationships[] | select(.type == "USES")'
```

### Find High-Confidence Relationships

```bash
cat cbom.json | jq '.relationships[] |
    select(.confidence | tonumber > 0.9)'
```

### Find Evidence for a Component

```bash
cat cbom.json | jq '.relationships[] |
    select(.type == "evidence" and .target | contains("digicert"))'
```

### Count Relationships by Type

```bash
cat cbom.json | jq '[.relationships[].type] |
    group_by(.) |
    map({type: .[0], count: length})'
```

---

## Statistics

Relationship counts in metadata:

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
