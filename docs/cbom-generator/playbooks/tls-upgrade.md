---
hide:
  - toc
---
# TLS Upgrade Guide

Migrate from unsafe and deprecated TLS 1.0/1.1 to TLS 1.2/1.3 for improved security.


## Prerequisites

- CBOM Generator installed
- Root access for service configuration
- Modern OpenSSL (1.1.1+ for TLS 1.3)

---

## Step 1: Inventory Current TLS Versions

Run CBOM scan with service discovery:

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output tls-baseline.json
```

### Find Services with Deprecated TLS

```bash
cat tls-baseline.json | jq -r '.components[] |
    select(.properties[]? |
        select(.name == "cbom:proto:security_profile" and .value == "OLD")) |
    "\(.name) - \(.properties[] | select(.name == "cbom:svc:config_file").value // "N/A")"'
```

### List TLS Version Distribution

```bash
cat tls-baseline.json | jq '[.components[] |
    select(.cryptoProperties?.protocolProperties?.type == "tls") |
    .cryptoProperties.protocolProperties.version] |
    group_by(.) |
    map({version: .[0], count: length})'
```

---

## Step 2: Identify TLS 1.0/1.1 Services

### Apache HTTPD

```bash
grep -r "SSLProtocol" /etc/apache2/
```

### Nginx

```bash
grep -r "ssl_protocols" /etc/nginx/
```

### Postfix

```bash
grep "smtpd_tls_protocols\|smtp_tls_protocols" /etc/postfix/main.cf
```

---

## Step 3: Update Service Configurations

### Apache HTTPD

Edit SSL configuration:

```bash
sudo nano /etc/apache2/sites-available/default-ssl.conf
```

Update:

```apache
# Disable TLS 1.0/1.1, enable TLS 1.2/1.3
SSLProtocol -all +TLSv1.2 +TLSv1.3

# Modern cipher suite
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384

# Server preference
SSLHonorCipherOrder on
```

### Nginx

Edit server block:

```bash
sudo nano /etc/nginx/sites-available/default
```

Update:

```nginx
# TLS 1.2 and 1.3 only
ssl_protocols TLSv1.2 TLSv1.3;

# Modern cipher suite
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

# Server preference
ssl_prefer_server_ciphers on;
```

### Postfix

Edit main.cf:

```bash
sudo nano /etc/postfix/main.cf
```

Update:

```
# TLS 1.2+ for both SMTP submission and relay
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
```

---

## Step 4: Verify Cipher Suite Strength

### Check for Weak Ciphers

```bash
cat tls-baseline.json | jq '.components[] |
    select(.["bom-ref"] | startswith("cipher:")) |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "DEPRECATED")) |
    .name'
```

### Recommended Cipher Suites

| Profile | TLS 1.3 | TLS 1.2 |
|---------|---------|---------|
| Modern | TLS_AES_256_GCM_SHA384 | ECDHE-ECDSA-AES256-GCM-SHA384 |
| Modern | TLS_CHACHA20_POLY1305_SHA256 | ECDHE-RSA-AES256-GCM-SHA384 |
| Modern | TLS_AES_128_GCM_SHA256 | ECDHE-ECDSA-AES128-GCM-SHA256 |

---

## Step 5: Restart Services

```bash
# Test configurations first
sudo apachectl configtest
sudo nginx -t
sudo postfix check

# Restart services
sudo systemctl restart apache2
sudo systemctl restart nginx
sudo systemctl restart postfix
```

---

## Step 6: Validate with CBOM Scan

Re-run the scan:

```bash
./build/cbom-generator \
    --discover-services \
    --plugin-dir plugins \
    --format cyclonedx --cyclonedx-spec 1.7 \
    --no-personal-data \
    --output tls-after-upgrade.json
```

### Verify No OLD Security Profiles

```bash
cat tls-after-upgrade.json | jq '[.components[] |
    select(.properties[]? |
        select(.name == "cbom:proto:security_profile")).properties[] |
    select(.name == "cbom:proto:security_profile").value] |
    group_by(.) |
    map({profile: .[0], count: length})'
```

Expected: No "OLD" profiles, all "MODERN" or "INTERMEDIATE"

---

## Step 7: External Validation

Test with SSL Labs or testssl.sh:

```bash
# Using testssl.sh
./testssl.sh --protocols --cipher-per-proto https://your-server.example.com

# Or use nmap
nmap --script ssl-enum-ciphers -p 443 your-server.example.com
```

---

## Rollback Plan

Keep backup of original configs:

```bash
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.backup
```

To rollback:

```bash
sudo cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
sudo systemctl restart nginx
```

---
