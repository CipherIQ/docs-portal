---
hide:
  - toc
---
# Service Discovery Options

YAML plugin-driven service discovery for detecting running services and extracting their cryptographic configurations.


### `--discover-services`

Enable YAML plugin-driven service discovery pipeline.

**What it does**:

1. **Phase 1**: Loads YAML plugins from plugins/ directory
2. **Phase 2**: Discovers running services via process, port, config file, systemd, and package detection
3. **Phase 3**: Extracts TLS/SSL configuration from each detected service
4. **Phase 4**: Generates CycloneDX components with full crypto metadata and PQC assessment

**Supported Services** (built-in plugins include):

- **Databases**: PostgreSQL, MySQL, MariaDB, MongoDB, Redis, CouchDB
- **Web Servers**: Nginx, Apache HTTPD, Caddy
- **Message Queues**: RabbitMQ, Apache Kafka
- **VPN**: OpenVPN, WireGuard
- **SSH**: OpenSSH

```bash
# Discover all services and generate CBOM
./build/cbom-generator --discover-services --output discovered.json

# With privacy mode (recommended)
./build/cbom-generator --discover-services --no-personal-data --output cbom.json

# With custom plugin directory
./build/cbom-generator --discover-services --plugin-dir /custom/plugins --output cbom.json
```

**Output**:
```
INFO: Phase 1: Loading YAML plugins...
INFO:   Loaded 13 YAML plugins from 'plugins/'
INFO: Phase 2: Discovering services...
INFO:   Discovered 3 service(s)
INFO: Phase 3: Extracting crypto configurations...
INFO:   Processing service: PostgreSQL SSL/TLS Scanner
INFO:     Certificates: 1, Keys: 1, TLS: yes
INFO:     Components generated successfully
INFO: Extracted configs for 3/3 services
INFO: Phase 4.5 pipeline complete
```

**Detection Methods**:

| Method | How It Works |
|--------|--------------|
| Process | Scans /proc for process names and command patterns |
| Port | Checks listening ports with optional TLS handshake probe |
| Config File | Glob pattern matching for config file presence |
| Systemd | Queries systemd for active services |
| Package | Checks if service packages are installed |

**Component Generation**:

- Creates SERVICE components for each discovered service
- Creates CERTIFICATE components from extracted cert paths
- Creates PROTOCOL components (TLS 1.2, TLS 1.3, SSH)
- Creates CIPHER_SUITE components from config
- Builds relationship graph: SERVICE→CERT→PROTOCOL→CIPHER

---

### `--plugin-dir DIR`

Specify custom directory for YAML plugins.

**Default**: `plugins/` (relative to current directory)

```bash
# Use custom plugin directory
./build/cbom-generator --discover-services --plugin-dir /etc/cbom/plugins

# Use absolute path
./build/cbom-generator --discover-services --plugin-dir /opt/cbom-plugins

# Use embedded plugins for Yocto/IoT
./build/cbom-generator --discover-services --plugin-dir plugins/embedded
```

**Plugin File Format**: YAML files (.yaml or .yml extension)

---

### `--list-plugins`

List all loaded plugins and exit.

```bash
# List all plugins
./build/cbom-generator --list-plugins

# List plugins from custom directory
./build/cbom-generator --list-plugins --plugin-dir /custom/plugins
```

**Output**:
```
Loaded 13 YAML plugins from 'plugins/'

=== CBOM Generator Plugins ===

Built-in Scanners (5):
  1. builtin_cert_scanner v1.0.0 - Certificate Scanner
  2. builtin_key_scanner v1.0.0 - Key Scanner
  3. builtin_package_scanner v1.0.0 - Package Scanner
  4. builtin_service_scanner v1.0.0 - Service Scanner
  5. builtin_fs_scanner v1.0.0 - Filesystem Scanner

YAML Plugins (13 loaded)

Total: 18 plugins (5 built-in + 13 YAML)
```

---

## Creating Custom Plugins

**YAML Plugin Structure**:

```yaml
# plugins/myservice.yaml
plugin:
  plugin_schema_version: "1.0"
  name: "My Service TLS Scanner"
  version: "1.0.0"
  category: "custom"
  description: "Detects My Service and extracts TLS config"

detection:
  methods:
    - type: process
      names: ["myservice"]
    - type: port
      ports: [8443]
      check_ssl: true

config_extraction:
  files:
    - path: "/etc/myservice/config.yaml"
      parser: "yaml"
      crypto_directives:
        - key: "tls.cert"
          type: "path"
          maps_to: "certificate.path"
```

**Supported Parsers**:

| Parser | Use For |
|--------|---------|
| `ini` | INI/properties format (PostgreSQL, MySQL, Redis) |
| `apache` | Apache HTTPD config format |
| `nginx` | Nginx config format |
| `yaml` | YAML format (MongoDB, Kubernetes) |
| `json` | JSON format (Caddy, modern apps) |
| `openssl_cipher` | OpenSSL cipher string expansion |
