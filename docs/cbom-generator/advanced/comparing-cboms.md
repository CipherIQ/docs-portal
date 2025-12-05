# Comparing CBOMs

Track changes in cryptographic assets over time.

---

## Use Cases

- Detect new/removed certificates
- Track algorithm changes
- Monitor PQC readiness progress
- Audit configuration drift

---

## Basic Comparison

### Hash Comparison

```bash
# Quick check if anything changed
sha256sum baseline.json current.json
```

### Component Count Comparison

```bash
echo "Baseline:"
cat baseline.json | jq '.components | length'

echo "Current:"
cat current.json | jq '.components | length'
```

---

## Detailed Comparisons

### Find New Components

```bash
# Extract component names
cat baseline.json | jq -r '.components[].name' | sort > baseline-names.txt
cat current.json | jq -r '.components[].name' | sort > current-names.txt

# Find additions
comm -13 baseline-names.txt current-names.txt
```

### Find Removed Components

```bash
# Find removals
comm -23 baseline-names.txt current-names.txt
```

### Find Changed Components

```bash
# Compare by bom-ref
cat baseline.json | jq -r '.components[] | "\(.["bom-ref"])|\(.name)"' | sort > baseline-refs.txt
cat current.json | jq -r '.components[] | "\(.["bom-ref"])|\(.name)"' | sort > current-refs.txt

diff baseline-refs.txt current-refs.txt
```

---

## PQC Progress Tracking

### Compare PQC Scores

```bash
echo "=== PQC Progress ==="

echo -n "Baseline: "
cat baseline.json | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value'

echo -n "Current:  "
cat current.json | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value'
```

### Compare Break Year Distribution

```bash
echo "=== Break Year Distribution ==="

for year in 2030 2035 2040 2045; do
    echo "Break $year:"
    echo -n "  Baseline: "
    cat baseline.json | jq -r ".metadata.properties[] | select(.name == \"cbom:pqc:break_${year}_count\") | .value // \"0\""
    echo -n "  Current:  "
    cat current.json | jq -r ".metadata.properties[] | select(.name == \"cbom:pqc:break_${year}_count\") | .value // \"0\""
done
```

---

## Certificate Tracking

### New Certificates

```bash
cat baseline.json | jq -r '.components[] | select(.cryptoProperties?.assetType == "certificate") | .name' | sort > baseline-certs.txt
cat current.json | jq -r '.components[] | select(.cryptoProperties?.assetType == "certificate") | .name' | sort > current-certs.txt

echo "New certificates:"
comm -13 baseline-certs.txt current-certs.txt
```

### Expired Certificates

```bash
cat current.json | jq -r '.components[] |
    select(.cryptoProperties?.certificateProperties?.certificateState[0]?.state == "deactivated") |
    "\(.name) - EXPIRED"'
```

---

## Automated Diff Script

```bash
#!/bin/bash
# cbom-diff.sh <baseline.json> <current.json>

BASELINE=$1
CURRENT=$2

echo "=== CBOM Comparison Report ==="
echo "Baseline: $BASELINE"
echo "Current:  $CURRENT"
echo ""

# Component counts
echo "=== Component Counts ==="
printf "%-20s %10s %10s\n" "Type" "Baseline" "Current"
printf "%-20s %10s %10s\n" "----" "--------" "-------"

for type in certificate algorithm key library service protocol; do
    BASELINE_COUNT=$(cat $BASELINE | jq "[.components[] | select(.cryptoProperties?.assetType == \"$type\")] | length")
    CURRENT_COUNT=$(cat $CURRENT | jq "[.components[] | select(.cryptoProperties?.assetType == \"$type\")] | length")
    printf "%-20s %10s %10s\n" "$type" "$BASELINE_COUNT" "$CURRENT_COUNT"
done

# PQC comparison
echo ""
echo "=== PQC Readiness ==="
BASELINE_PQC=$(cat $BASELINE | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value // "N/A"')
CURRENT_PQC=$(cat $CURRENT | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value // "N/A"')
echo "Baseline: $BASELINE_PQC%"
echo "Current:  $CURRENT_PQC%"
```

---

## Time-Series Analysis

### Store Historical CBOMs

```bash
# Daily scans with dated filenames
./build/cbom-generator --output /var/cbom/cbom-$(date +%Y%m%d).json

# Keep 30 days of history
find /var/cbom -name "cbom-*.json" -mtime +30 -delete
```

### Generate Trend Report

```bash
#!/bin/bash
# Show PQC readiness trend over last 7 days

echo "Date,PQC Score"
for file in /var/cbom/cbom-*.json; do
    date=$(basename $file | sed 's/cbom-\(.*\)\.json/\1/')
    score=$(cat $file | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value // "0"')
    echo "$date,$score"
done
```
