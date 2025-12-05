# Generating Reports

Create custom reports from CBOM output.

---

## Built-in PQC Report

Use `--pqc-report` for comprehensive migration report:

```bash
./build/cbom-generator \
    --pqc-report migration-report.txt \
    --output cbom.json
```

---

## Custom Report Scripts

### Executive Summary

```bash
#!/bin/bash
# executive-summary.sh <cbom.json>

CBOM=$1

echo "═══════════════════════════════════════════════"
echo "         CRYPTOGRAPHIC INVENTORY SUMMARY"
echo "═══════════════════════════════════════════════"
echo ""

# Scan info
echo "Scan Date: $(cat $CBOM | jq -r '.metadata.timestamp')"
echo ""

# Component counts
echo "COMPONENT INVENTORY"
echo "───────────────────"
TOTAL=$(cat $CBOM | jq '.components | length')
CERTS=$(cat $CBOM | jq '[.components[] | select(.cryptoProperties?.assetType == "certificate")] | length')
KEYS=$(cat $CBOM | jq '[.components[] | select(.cryptoProperties?.assetType == "related-crypto-material")] | length')
ALGOS=$(cat $CBOM | jq '[.components[] | select(.cryptoProperties?.assetType == "algorithm")] | length')
LIBS=$(cat $CBOM | jq '[.components[] | select(.type == "library")] | length')

printf "%-20s %10s\n" "Total Components:" "$TOTAL"
printf "%-20s %10s\n" "Certificates:" "$CERTS"
printf "%-20s %10s\n" "Keys:" "$KEYS"
printf "%-20s %10s\n" "Algorithms:" "$ALGOS"
printf "%-20s %10s\n" "Libraries:" "$LIBS"
echo ""

# PQC Assessment
echo "PQC READINESS"
echo "─────────────"
SCORE=$(cat $CBOM | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value // "N/A"')
SAFE=$(cat $CBOM | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:safe_count") | .value // "0"')
TRANS=$(cat $CBOM | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:transitional_count") | .value // "0"')
DEPR=$(cat $CBOM | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:deprecated_count") | .value // "0"')
UNSAFE=$(cat $CBOM | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:unsafe_count") | .value // "0"')

printf "%-20s %10s%%\n" "Readiness Score:" "$SCORE"
printf "%-20s %10s\n" "PQC Safe:" "$SAFE"
printf "%-20s %10s\n" "Transitional:" "$TRANS"
printf "%-20s %10s\n" "Deprecated:" "$DEPR"
printf "%-20s %10s\n" "Unsafe:" "$UNSAFE"
echo ""
echo "═══════════════════════════════════════════════"
```

### Certificate Expiration Report

```bash
#!/bin/bash
# cert-expiration-report.sh <cbom.json>

CBOM=$1

echo "CERTIFICATE EXPIRATION REPORT"
echo "============================="
echo ""

# Expired
echo "EXPIRED CERTIFICATES"
echo "--------------------"
cat $CBOM | jq -r '.components[] |
    select(.cryptoProperties?.certificateProperties?.certificateState[0]?.state == "deactivated") |
    "  - \(.name)"'
echo ""

# Expiring within 30 days
echo "EXPIRING WITHIN 30 DAYS"
echo "-----------------------"
EXPIRE_30=$(date -d "+30 days" --iso-8601)
cat $CBOM | jq -r --arg exp "$EXPIRE_30" '.components[] |
    select(.cryptoProperties?.certificateProperties?.notValidAfter < $exp) |
    select(.cryptoProperties?.certificateProperties?.certificateState[0]?.state == "active") |
    "  - \(.name) (expires: \(.cryptoProperties.certificateProperties.notValidAfter))"'
echo ""

# Expiring within 90 days
echo "EXPIRING WITHIN 90 DAYS"
echo "-----------------------"
EXPIRE_90=$(date -d "+90 days" --iso-8601)
cat $CBOM | jq -r --arg exp30 "$EXPIRE_30" --arg exp90 "$EXPIRE_90" '.components[] |
    select(.cryptoProperties?.certificateProperties?.notValidAfter > $exp30) |
    select(.cryptoProperties?.certificateProperties?.notValidAfter < $exp90) |
    select(.cryptoProperties?.certificateProperties != null) |
    "  - \(.name) (expires: \(.cryptoProperties.certificateProperties.notValidAfter))"'
```

### Weak Algorithm Report

```bash
#!/bin/bash
# weak-algorithm-report.sh <cbom.json>

CBOM=$1

echo "WEAK ALGORITHM DETECTION REPORT"
echo "================================"
echo ""

echo "DEPRECATED ALGORITHMS"
echo "---------------------"
cat $CBOM | jq -r '.components[] |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "DEPRECATED")) |
    "  - \(.name)"'
echo ""

echo "WEAK KEYS"
echo "---------"
cat $CBOM | jq -r '.components[] |
    select(.properties[]? | select(.name == "cbom:key:is_weak" and .value == "true")) |
    "  - \(.name) (\(.evidence.occurrences[0].location // "N/A"))"'
echo ""

echo "OLD SECURITY PROFILES"
echo "---------------------"
cat $CBOM | jq -r '.components[] |
    select(.properties[]? | select(.name == "cbom:proto:security_profile" and .value == "OLD")) |
    "  - \(.name)"'
```

---

## HTML Report Generation

```bash
#!/bin/bash
# html-report.sh <cbom.json> <output.html>

CBOM=$1
OUTPUT=$2

TOTAL=$(cat $CBOM | jq '.components | length')
SCORE=$(cat $CBOM | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value // "N/A"')
TIMESTAMP=$(cat $CBOM | jq -r '.metadata.timestamp')

cat > $OUTPUT << EOF
<!DOCTYPE html>
<html>
<head>
    <title>CBOM Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .metric { display: inline-block; padding: 20px; margin: 10px; background: #f5f5f5; border-radius: 5px; }
        .metric .value { font-size: 36px; font-weight: bold; }
        .metric .label { color: #666; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #333; color: white; }
    </style>
</head>
<body>
    <h1>Cryptographic Bill of Materials Report</h1>
    <p>Generated: $TIMESTAMP</p>

    <div class="metric">
        <div class="value">$TOTAL</div>
        <div class="label">Components</div>
    </div>
    <div class="metric">
        <div class="value">$SCORE%</div>
        <div class="label">PQC Readiness</div>
    </div>

    <h2>Components</h2>
    <table>
        <tr><th>Name</th><th>Type</th><th>PQC Status</th></tr>
EOF

cat $CBOM | jq -r '.components[] | "<tr><td>\(.name)</td><td>\(.cryptoProperties?.assetType // .type)</td><td>\([.properties[]? | select(.name == "cbom:pqc:status")][0].value // "N/A")</td></tr>"' >> $OUTPUT

cat >> $OUTPUT << EOF
    </table>
</body>
</html>
EOF

echo "Report generated: $OUTPUT"
```

---

## JSON to CSV Conversion

```bash
#!/bin/bash
# cbom-to-csv.sh <cbom.json> <output.csv>

CBOM=$1
OUTPUT=$2

echo "name,type,asset_type,pqc_status,location" > $OUTPUT

cat $CBOM | jq -r '.components[] |
    [
        .name,
        .type,
        (.cryptoProperties?.assetType // "N/A"),
        ([.properties[]? | select(.name == "cbom:pqc:status")][0].value // "N/A"),
        (.evidence.occurrences[0].location // "N/A")
    ] | @csv' >> $OUTPUT

echo "CSV exported: $OUTPUT"
```
