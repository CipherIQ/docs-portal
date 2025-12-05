# Certificate Rotation

Plan and execute certificate lifecycle management using CBOM Generator.

---

## Prerequisites

- CBOM Generator installed
- Access to certificate authority or ACME provider
- Root access for certificate deployment

---

## Step 1: Identify Expiring Certificates

Run CBOM scan:

```bash
./build/cbom-generator \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output cert-inventory.json /etc/ssl /etc/pki
```

### Find Certificates Expiring Soon

```bash
# Certificates expiring within 30 days
EXPIRE_DATE=$(date -d "+30 days" --iso-8601)
cat cert-inventory.json | jq --arg exp "$EXPIRE_DATE" '.components[] |
    select(.cryptoProperties?.certificateProperties?.notValidAfter < $exp) |
    select(.cryptoProperties?.certificateProperties != null) |
    {name, expires: .cryptoProperties.certificateProperties.notValidAfter,
     location: .evidence.occurrences[0].location}'
```

### Find Already Expired Certificates

```bash
cat cert-inventory.json | jq '.components[] |
    select(.cryptoProperties?.certificateProperties?.certificateState[0]?.state == "deactivated") |
    {name, state: "EXPIRED", location: .evidence.occurrences[0].location}'
```

---

## Step 2: Plan Rotation Schedule

### Priority Matrix

| Expiration | Priority | Action |
|------------|----------|--------|
| < 7 days | Critical | Immediate rotation |
| 7-30 days | High | Schedule this week |
| 30-90 days | Medium | Schedule this month |
| > 90 days | Low | Plan future rotation |

### Export Rotation Candidates

```bash
cat cert-inventory.json | jq -r '.components[] |
    select(.cryptoProperties?.certificateProperties != null) |
    "\(.name),\(.cryptoProperties.certificateProperties.notValidAfter),\(.evidence.occurrences[0].location)"' \
    | sort -t',' -k2 > rotation-schedule.csv
```

---

## Step 3: Generate New Certificates

### Option A: Self-Signed (Development)

```bash
# Generate new private key
openssl genrsa -out new-server.key 2048

# Generate CSR
openssl req -new -key new-server.key -out new-server.csr \
    -subj "/CN=server.example.com"

# Self-sign (for testing)
openssl x509 -req -days 365 -in new-server.csr \
    -signkey new-server.key -out new-server.crt
```

### Option B: ACME/Let's Encrypt

```bash
# Using certbot
sudo certbot certonly --webroot -w /var/www/html \
    -d server.example.com \
    --cert-name server
```

### Option C: Enterprise CA

Follow your organization's certificate request process.

---

## Step 4: Deploy New Certificates

### Backup Existing Certificates

```bash
BACKUP_DIR="/etc/ssl/backup-$(date +%Y%m%d)"
sudo mkdir -p $BACKUP_DIR
sudo cp /etc/ssl/certs/server.crt $BACKUP_DIR/
sudo cp /etc/ssl/private/server.key $BACKUP_DIR/
```

### Deploy New Certificates

```bash
sudo cp new-server.crt /etc/ssl/certs/server.crt
sudo cp new-server.key /etc/ssl/private/server.key
sudo chmod 600 /etc/ssl/private/server.key
```

### Update Service Configurations (if needed)

Verify certificate paths in service configs:

```bash
# Nginx
grep ssl_certificate /etc/nginx/sites-enabled/*

# Apache
grep SSLCertificate /etc/apache2/sites-enabled/*
```

---

## Step 5: Restart Services

```bash
# Test configurations
sudo nginx -t
sudo apachectl configtest

# Restart services
sudo systemctl restart nginx
sudo systemctl restart apache2
```

---

## Step 6: Verify with CBOM Scan

Re-run inventory:

```bash
./build/cbom-generator \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output cert-after-rotation.json /etc/ssl /etc/pki
```

### Verify New Certificate Detected

```bash
cat cert-after-rotation.json | jq '.components[] |
    select(.name | contains("server.example.com")) |
    {name,
     valid_from: .cryptoProperties.certificateProperties.notValidBefore,
     valid_to: .cryptoProperties.certificateProperties.notValidAfter,
     state: .cryptoProperties.certificateProperties.certificateState[0].state}'
```

---

## Step 7: Verify External Connectivity

```bash
# Test TLS connection
openssl s_client -connect server.example.com:443 -servername server.example.com </dev/null 2>/dev/null | \
    openssl x509 -noout -dates

# Check certificate chain
openssl s_client -connect server.example.com:443 -servername server.example.com </dev/null 2>/dev/null | \
    openssl x509 -noout -text | grep -E "Subject:|Issuer:|Not Before:|Not After:"
```

---

## Automated Monitoring

### Set Up Expiration Alerts

Create a monitoring script:

```bash
#!/bin/bash
# cert-monitor.sh

./build/cbom-generator \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output /tmp/cert-check.json /etc/ssl /etc/pki 2>/dev/null

EXPIRE_DATE=$(date -d "+30 days" --iso-8601)
EXPIRING=$(cat /tmp/cert-check.json | jq --arg exp "$EXPIRE_DATE" \
    '[.components[] |
     select(.cryptoProperties?.certificateProperties?.notValidAfter < $exp) |
     select(.cryptoProperties?.certificateProperties != null)] | length')

if [ "$EXPIRING" -gt 0 ]; then
    echo "WARNING: $EXPIRING certificates expiring within 30 days"
    exit 1
fi
```

### Schedule with Cron

```bash
# Run weekly
0 0 * * 0 /path/to/cert-monitor.sh
```

---

## Rollback Plan

If issues occur after rotation:

```bash
# Restore from backup
sudo cp $BACKUP_DIR/server.crt /etc/ssl/certs/server.crt
sudo cp $BACKUP_DIR/server.key /etc/ssl/private/server.key

# Restart services
sudo systemctl restart nginx
sudo systemctl restart apache2
```

---

## Success Criteria

- [ ] All expiring certificates identified
- [ ] New certificates generated with adequate validity
- [ ] Certificates deployed to correct locations
- [ ] Services restarted successfully
- [ ] CBOM shows new certificates as "active"
- [ ] External connectivity verified
- [ ] Monitoring in place for future expirations
