---
hide:
  - toc
---
# Advanced Usage

Expert features for power users and automation.



## Advanced Topics

| Topic | Description |
|-------|-------------|
| [Comparing CBOMs](comparing-cboms.md) | Diff CBOMs over time |
| [Filtering Output](filtering-output.md) | jq queries for analysis |
| [Generating Reports](generating-reports.md) | Custom report generation |
| [Container Scanning](container-scanning.md) | Container scanning workflow |


## Automation Examples

### CI/CD Integration

```bash
#!/bin/bash
# ci-cbom-check.sh

# Generate CBOM
./build/cbom-generator \
    --deterministic \
    --no-personal-data \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --output current-cbom.json

# Check PQC readiness threshold
SCORE=$(cat current-cbom.json | jq -r '.metadata.properties[] | select(.name == "cbom:pqc:readiness_score") | .value')
if (( $(echo "$SCORE < 10" | bc -l) )); then
    echo "FAIL: PQC readiness score $SCORE% below threshold"
    exit 1
fi

echo "PASS: PQC readiness score $SCORE%"
```

### Scheduled Scanning

```bash
# /etc/cron.weekly/cbom-scan
#!/bin/bash

DATE=$(date +%Y%m%d)
./build/cbom-generator \
    --discover-services \
    --plugin-dir /opt/cbom/plugins \
    --no-personal-data \
    --pqc-report /var/reports/pqc-$DATE.txt \
    --output /var/cbom/cbom-$DATE.json
```

### Container Scanning

```bash
# Extract and scan container filesystem
docker export container_id | tar -C /tmp/container-fs -xf -
./build/cbom-generator \
    --cross-arch \
    --crypto-registry crypto-registry-alpine.yaml \
    --output container-cbom.json \
    /tmp/container-fs
rm -rf /tmp/container-fs
```

[Container Scanning Workflow](container-scanning.md)

---


## Output Piping

```bash
# Stream to another tool
./build/cbom-generator --output - | tee cbom.json | jq '.components | length'

# Compress output
./build/cbom-generator --output - | gzip > cbom.json.gz

# Send to remote
./build/cbom-generator --output - | curl -X POST -d @- https://api.example.com/cbom
```
