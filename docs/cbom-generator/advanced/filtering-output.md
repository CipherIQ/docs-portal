---
hide:
  - toc
---
# Filtering Output

Use jq queries to extract specific information from CBOM output.


## Basic Queries

### Count Components

```bash
cat cbom.json | jq '.components | length'
```

### List Component Names

```bash
cat cbom.json | jq -r '.components[].name'
```

### Get Metadata Properties

```bash
cat cbom.json | jq '.metadata.properties'
```

---

## Filtering by Type

### Find Certificates

```bash
cat cbom.json | jq '.components[] | select(.cryptoProperties?.assetType == "certificate")'
```

### Find Algorithms

```bash
cat cbom.json | jq '.components[] | select(.cryptoProperties?.assetType == "algorithm")'
```

### Find Libraries

```bash
cat cbom.json | jq '.components[] | select(.type == "library")'
```

### Find Services

```bash
cat cbom.json | jq '.components[] | select(.type == "operating-system")'
```

---

## Filtering by Properties

### Find by PQC Status

```bash
# Find DEPRECATED algorithms
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "DEPRECATED"))'

# Find PQC SAFE components
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "SAFE"))'
```

### Find Weak Keys

```bash
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:key:is_weak" and .value == "true"))'
```

### Find by Security Profile

```bash
cat cbom.json | jq '.components[] |
    select(.properties[]? | select(.name == "cbom:proto:security_profile" and .value == "OLD"))'
```

---

## Extracting Specific Fields

### Component Summary

```bash
cat cbom.json | jq '.components[] | {name, type, "bom-ref"}'
```

### Certificate Details

```bash
cat cbom.json | jq '.components[] |
    select(.cryptoProperties?.assetType == "certificate") |
    {name,
     valid_from: .cryptoProperties.certificateProperties.notValidBefore,
     valid_to: .cryptoProperties.certificateProperties.notValidAfter}'
```

### Key Information

```bash
cat cbom.json | jq '.components[] |
    select(.cryptoProperties?.assetType == "related-crypto-material") |
    {name,
     type: .cryptoProperties.relatedCryptoMaterialProperties.type,
     size: .cryptoProperties.relatedCryptoMaterialProperties.size}'
```

---

## Aggregation Queries

### Count by Asset Type

```bash
cat cbom.json | jq '[.components[] | .cryptoProperties?.assetType] |
    group_by(.) |
    map({type: .[0], count: length})'
```

### Count by PQC Status

```bash
cat cbom.json | jq '[.components[] |
    [.properties[]? | select(.name == "cbom:pqc:status")][0].value] |
    group_by(.) |
    map({status: .[0], count: length})'
```

### Algorithm Distribution

```bash
cat cbom.json | jq '[.components[] |
    select(.cryptoProperties?.assetType == "algorithm") |
    .name] |
    group_by(.) |
    map({algorithm: .[0], count: length}) |
    sort_by(.count) |
    reverse'
```

---

## Dependency Queries

### Find Service Dependencies

```bash
cat cbom.json | jq '.dependencies[] | select(.ref | startswith("service:"))'
```

### Trace Algorithm Usage

```bash
cat cbom.json | jq '.dependencies[] |
    select(.dependsOn[]? | contains("algo:sha256")) |
    .ref'
```

### Find Components Using a Library

```bash
cat cbom.json | jq '.dependencies[] |
    select(.dependsOn[]? | contains("library:openssl")) |
    .ref'
```

---

## Output Formatting

### CSV Export

```bash
cat cbom.json | jq -r '.components[] | [.name, .type, .["bom-ref"]] | @csv'
```

### TSV Export

```bash
cat cbom.json | jq -r '.components[] | [.name, .type] | @tsv'
```

### Custom Format

```bash
cat cbom.json | jq -r '.components[] |
    select(.cryptoProperties?.assetType == "certificate") |
    "\(.name)\t\(.cryptoProperties.certificateProperties.notValidAfter)"'
```

---

## Complex Queries

### Certificates Expiring Within 30 Days

```bash
EXPIRE=$(date -d "+30 days" --iso-8601)
cat cbom.json | jq --arg exp "$EXPIRE" '.components[] |
    select(.cryptoProperties?.certificateProperties?.notValidAfter < $exp) |
    select(.cryptoProperties?.certificateProperties != null) |
    {name, expires: .cryptoProperties.certificateProperties.notValidAfter}'
```

### Services with Deprecated Protocols

```bash
cat cbom.json | jq '.dependencies[] |
    select(.ref | startswith("service:")) |
    select(.dependsOn[]? | test("protocol:tls-1\\.[01]")) |
    .ref'
```

### Complete Dependency Chain

```bash
# Get all dependencies for a service
SERVICE="service:nginx"
cat cbom.json | jq --arg svc "$SERVICE" '
    def deps($ref): .dependencies[] | select(.ref == $ref) | .dependsOn[];
    {service: $svc, chain: [deps($svc)]}
'
```
