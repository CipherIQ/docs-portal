---
hide:
  - toc
---
# Service Dependencies

The Service Discovery Scanner automatically detects running services and maps their complete cryptographic dependency chains.



## 4-Level Dependency Architecture

```
SERVICE → PROTOCOL → CIPHER_SUITE → ALGORITHM
```

This architecture enables complete PQC readiness assessment by tracing every algorithm used by each service.

---

## Supported Services (69+ Total)

**Built-in Scanners (4)**:

- Apache HTTPD, Nginx
- OpenSSH
- Postfix

**YAML Plugins (65+)**:

| Category | Services |
|----------|----------|
| Databases | PostgreSQL, MySQL, MongoDB, MariaDB, Redis, Cassandra, Elasticsearch |
| Web Servers | Caddy, Traefik, HAProxy, lighttpd |
| Containers | Docker, Kubernetes, K3s, containerd, Podman |
| VPN | OpenVPN, WireGuard, strongSwan, tinc |
| Mail | Dovecot, Exim, Sendmail |
| Message Brokers | RabbitMQ, Kafka, ActiveMQ, mosquitto |
| Monitoring | Prometheus, Grafana, Fluentd |

---

## Detection Methods

Services are discovered using multiple methods:

| Method | How It Works |
|--------|--------------|
| Process | Scanning `/proc` for running daemons |
| Port | Analyzing `/proc/net/tcp` for listening services |
| Config File | Finding configuration files in standard paths |
| Systemd | Querying `systemctl` for active services |
| Package | Checking installed packages (dpkg/rpm/pacman) |

---

## Security Profiles

Services are automatically classified based on their configuration:

| Profile | Criteria | Risk Level |
|---------|----------|------------|
| **MODERN** | TLS 1.3 only, no weak ciphers | Low |
| **INTERMEDIATE** | TLS 1.2+ with strong ciphers | Medium |
| **OLD** | TLS 1.0/1.1 or weak ciphers | **HIGH RISK** |
| **CUSTOM** | Custom configuration | Varies |

---

## Example Dependency Chain

**Apache HTTPD with TLS 1.2**:

```
service:apache-httpd (Apache HTTPD 2.4.52)
  |-- USES --> protocol:tls (TLS 1.2)
      |-- PROVIDES --> cipher:tls-ecdhe-rsa-with-aes-256-gcm-sha384
          |-- USES --> algo:ecdhe (ECDHE key exchange)
          |-- USES --> algo:rsa (RSA authentication)
          |-- USES --> algo:aes-256-gcm-256 (AES-256-GCM encryption)
          |-- USES --> algo:sha384 (SHA384 MAC)
```

**OpenSSH with PQC KEX**:

```
service:openssh (OpenSSH 8.9p1)
  |-- USES --> protocol:ssh-2 (SSH 2.0)
      |-- USES --> algo:curve25519-sha256 (X25519 KEX)
      |-- USES --> algo:sntrup761x25519-sha512-openssh-com (PQC HYBRID KEX) [PQC SAFE]
```

---

## CycloneDX Dependencies Array

The complete dependency graph appears in the `dependencies` array:

```json
{
  "dependencies": [
    {
      "ref": "service:apache-httpd",
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
        "algo:ecdhe",
        "algo:rsa",
        "algo:aes-256-gcm-256",
        "algo:sha384"
      ]
    }
  ]
}
```

---

## Service Properties

```json
{
  "type": "operating-system",
  "name": "Apache HTTPD",
  "bom-ref": "service:apache-httpd",
  "properties": [
    { "name": "cbom:svc:name", "value": "Apache HTTPD" },
    { "name": "cbom:svc:version", "value": "2.4.52" },
    { "name": "cbom:svc:is_running", "value": "true" },
    { "name": "cbom:svc:port", "value": "443" },
    { "name": "cbom:svc:config_file", "value": "/etc/apache2/sites-enabled/default-ssl.conf" },
    { "name": "cbom:pqc:status", "value": "UNSAFE" }
  ]
}
```

---

## Common Queries

### Finding Services by Security Profile

```bash
# List all services with OLD security profile (high risk)
./build/cbom-generator --discover-services --output cbom.json
cat cbom.json | jq -r '.components[] |
    select(.type == "operating-system") |
    select(.properties[]? | select(.name == "cbom:proto:security_profile" and .value == "OLD")) |
    "\(.name) - \(.properties[] | select(.name == "cbom:svc:config_file").value)"'
```

### Mapping Service Crypto Dependencies

```bash
# Show complete dependency chain for services
cat cbom.json | jq '.dependencies[] | select(.ref | startswith("service:"))'
```

### Finding PQC-Ready Services

```bash
# List services using PQC/hybrid algorithms
cat cbom.json | jq -r '.components[] |
    select(.type == "operating-system") |
    select(.properties[]? | select(.name == "cbom:pqc:status" and .value == "SAFE")) |
    .name'
```
