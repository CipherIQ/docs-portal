# **CipherIQ: A Unified Cryptographic Observability Platform**

**Author:** Marco Graziano</br>
Graziano Labs Corp.  

## Abstract

The migration to post-quantum cryptography (PQC) requires comprehensive visibility into enterprise cryptographic posture—visibility that existing tools fail to provide. We present CipherIQ, an open-source cryptographic observability platform comprising four integrated tools:

- **cbom-generator**, a high-performance C11 multithreaded static scanner that generates Cryptographic Bills of Materials (CBOMs) from filesystems, firmware, and containers; 
- **cbom-explorer**, a browser-based visualization tool for CBOM analysis and PQC readiness assessment; 
- **crypto-tracer**, an eBPF-based runtime monitor that traces cryptographic operations at the kernel level with <0.5% CPU overhead; and 
- **pqc-flow**, a passive network analyzer that detects post-quantum key exchange negotiations in TLS 1.3, SSH, IKEv2, and QUIC protocols. 

The platform's key innovation is *cryptographic drift detection*—the systematic identification of discrepancies between configured cryptographic policy (static discovery) and actual runtime behavior (dynamic observation). We formalize the dual-layer observability model, present novel algorithms for service-agnostic cryptographic discovery via YAML plugin architecture, and describe the first practical approach to correlating CBOM inventories with live eBPF traces and network flows. 

Our implementation achieves 12,000+ files/minute throughput for static scanning, processes 10Gbps network traffic for PQC detection, and produces CycloneDX 1.6/1.7 compliant output suitable for regulatory compliance (FDA 524B, EU CRA, IEC 62443). We evaluate the platform against real-world embedded systems with 20-30 year operational lifespans, demonstrating 90%+ cryptographic asset coverage and detecting configuration drift in 23% of production TLS connections.

## 1. Introduction

### 1.1 The Cryptographic Visibility Gap

The post-quantum cryptography transition presents organizations with a fundamental observability challenge. NIST's finalization of ML-KEM (FIPS 203), ML-DSA (FIPS 204), and SLH-DSA (FIPS 205) in 2024 established the cryptographic primitives for quantum-resistant systems, but migration planning requires answering a deceptively simple question: *What cryptography are we actually using?*

Current approaches to cryptographic discovery suffer from fundamental limitations:

1. **Static-only analysis** examines configuration files and certificates but cannot reveal what cryptography is *actually negotiated* in production
2. **Runtime-only analysis** captures live behavior but misses dormant, misconfigured, or emergency-fallback cryptographic assets
3. **Source code analysis** (e.g., IBM CBOMkit) identifies cryptographic API calls but cannot observe compiled binaries, firmware, or container images without source access
4. **Network monitoring** observes protocol negotiations but lacks correlation with configuration intent

The consequence is a dangerous gap between *declared cryptographic policy* and *actual deployment behavior*—what we term **cryptographic drift**. Organizations believe they are quantum-ready based on configuration audits while their production infrastructure negotiates vulnerable cipher suites with legacy clients.

### 1.2 The Long-Lived Systems Challenge

The quantum threat timeline creates particular urgency for systems with extended operational lifespans:

- **IoT/OT devices:** 20-30 year operational lifetimes
- **Medical devices:** 10-15 year FDA-approved service periods  
- **Automotive ECUs:** 15-20 year vehicle lifespans
- **Industrial control systems:** 25-30 year production equipment cycles
- **Critical infrastructure:** 30+ year utility deployments

Data encrypted with RSA-2048 today and captured by adversaries will be vulnerable within the confidentiality requirements of these systems. The "harvest now, decrypt later" threat transforms PQC migration from a future concern into an immediate imperative for any system that cannot be easily updated post-deployment.

### 1.3 Contributions

This paper makes the following contributions:

1. **Dual-layer observability model** that formally defines the relationship between static cryptographic configuration and runtime behavior, enabling systematic drift detection

2. **cbom-generator:** A high-performance C11 multithreaded scanner achieving 12,000+ files/minute throughput with YAML-based plugin architecture for extensible service discovery

3. **crypto-tracer:** An eBPF-based runtime monitoring tool that traces cryptographic file access, library loading, and process activity with <0.5% CPU overhead and <50MB memory footprint

4. **pqc-flow:** A passive network analyzer that detects ML-KEM, ML-DSA, and hybrid key exchange in TLS 1.3, SSH, IKEv2, and QUIC without payload decryption

5. **cbom-explorer:** A browser-based visualization tool enabling interactive dependency graph exploration, PQC readiness dashboards, and CBOM diff analysis

6. **Cryptographic drift detection algorithm** that correlates static CBOM inventories with runtime observations to identify configuration violations, unexpected fallbacks, and shadow cryptography

7. **Privacy-preserving design** with GDPR/CCPA-compliant path redaction, hostname anonymization, and key material hashing that preserves analytical utility

8. **Experimental validation** on embedded Linux systems demonstrating 90%+ asset coverage and drift detection in real-world deployments

### 1.4 Paper Organization

Section 2 provides background on CBOM standards, PQC requirements, and the regulatory landscape. Section 3 formalizes the dual-layer observability model and drift detection problem. Section 4 presents the  **cbom-generator** architecture and algorithms. Section 5 describes the eBPF-based  **crypto-tracer** design. Section 6 covers the  **cpqc-flow** passive network analyzer. Section 7 presents the drift detection correlation algorithm. Section 8 provides experimental evaluation. Section 9 discusses related work, and Section 10 concludes.

---

## 2. Background and Motivation

### 2.1 Post-Quantum Cryptography Standards and Timeline

**2024-2025:** NIST finalizes PQC standards (ML-KEM/FIPS 203, ML-DSA/FIPS 204, SLH-DSA/FIPS 205)  
**2025-2030:** Adversaries harvest encrypted data for future quantum decryption  
**2027-2033:** NSA CNSA 2.0 mandates phased PQC migration for national security systems  
**2030-2035:** Cryptographically relevant quantum computers (CRQCs) potentially viable

The hybrid transition period introduces additional complexity. IETF TLS Hybrid KEX drafts specify X25519MLKEM768 (group 0x11EC) as the standardized hybrid key exchange, combining classical X25519 with ML-KEM-768 for defense-in-depth during migration.

### 2.2 Cryptographic Bill of Materials (CBOM)

The CycloneDX CBOM specification (v1.6/1.7) provides a machine-readable format for documenting cryptographic assets. Originally developed by IBM Research and now maintained by OWASP, CBOM extends the Software Bill of Materials (SBOM) concept to cryptographic primitives.

### Definition 2.1 (Cryptographic Asset)

A cryptographic asset **A** is a structured object:

```
A = ( type, name, bomRef, cryptoProperties, properties, 
      evidence, hashes, relationships )
```

where:

| Field | Type | Description |
|-------|------|-------------|
| `type` | T | Asset type from taxonomy (Definition 2.2) |
| `name` | string | Human-readable identifier |
| `bomRef` | string | Content-addressed identifier with type prefix |
| `cryptoProperties` | object | Type-specific CycloneDX attributes (Definition 2.4) |
| `properties` | P[ ] | Namespaced key-value pairs (Definition 2.5) |
| `evidence` | Evidence | Detection provenance (Definition 2.7) |
| `hashes` | Hash[ ] | Integrity digests (SHA-256) |
| `relationships` | R[ ] | Edges to other assets |

**bomRef Format:**

The `bomRef` uses a type-prefixed content-addressed scheme:

```
bomRef ::= <type-prefix>:<identifier>

type-prefix ∈ { algo, cert, key, library, protocol, service, app, cipher }
identifier  ::= <human-readable-slug> | hash-<sha256-prefix>
```

**Examples:**

- `algo:aes-256-gcm`
- `cert:digicert-assured-id-root-ca`
- `library:libssl.so.3`
- `protocol:tls-1-3`

---

### Definition 2.2 (Asset Type Taxonomy)

The asset type set **T** extends CycloneDX with operational types:

```
T = { algorithm, certificate, certificate-request, key, library,
      protocol, service, application, cipher-suite, unknown }
```

| Type | CycloneDX assetType | bomRef Prefix | Description |
|------|---------------------|---------------|-------------|
| `algorithm` | `algorithm` | `algo:` | Cryptographic primitive |
| `certificate` | `certificate` | `cert:` | X.509 or OpenPGP certificate |
| `certificate-request` | `related-crypto-material` | `csr:` | PKCS#10 CSR |
| `key` | `private-key`, `public-key`, `secret-key` | `key:` | Key material |
| `library` | — | `library:` | Crypto implementation library |
| `protocol` | `protocol` | `protocol:` | Cryptographic protocol |
| `service` | — | `service:` | Network service |
| `application` | — | `app:` | Application binary |
| `cipher-suite` | — | `cipher:` | TLS/SSH cipher suite |
| `unknown` | `unknown` | `unknown:` | Unclassified asset |

**Type Hierarchy:**

```
                    ┌─────────────────────────────────────────┐
                    │          Cryptographic Asset            │
                    └─────────────────────────────────────────┘
                                        │
           ┌────────────────────────────┼────────────────────────────┐
           │                            │                            │
    ┌──────┴──────┐             ┌───────┴───────┐            ┌───────┴───────┐
    │  Primitive  │             │   Material    │            │  Operational  │
    └─────────────┘             └───────────────┘            └───────────────┘
           │                            │                            │
    ┌──────┴──────┐             ┌───────┴───────┐            ┌───────┴───────┐
    │ algorithm   │             │ certificate   │            │ service       │
    │ protocol    │             │ cert-request  │            │ application   │
    │ cipher-suite│             │ key           │            │ library       │
    └─────────────┘             └───────────────┘            └───────────────┘
```

---

### Definition 2.3 (CBOM Dependency Graph)

A CBOM forms a **typed multigraph** `G = (V, E, τ, ω)` where:

| Symbol | Definition |
|--------|------------|
| V | Set of cryptographic assets |
| E ⊆ V × V | Set of directed edges |
| τ: E → R | Relationship type function |
| ω: E → [0,1] | Confidence weight function |

The relationship type set **R**:

```
R = { IMPLEMENTS, USES, DEPENDS_ON, PROVIDES, CONTAINS,
      CONFIGURES, LISTENS_ON, AUTHENTICATES_WITH, SIGNS, ISSUED_BY }
```

**Relationship Semantics:**

| Relationship | Notation | Semantics | Example |
|--------------|----------|-----------|---------|
| `IMPLEMENTS` | a ⟶ᵢ b | a implements algorithm b | libssl ⟶ᵢ AES-256-GCM |
| `USES` | a ⟶ᵤ b | a uses/consumes b | nginx ⟶ᵤ TLS-1.3 |
| `DEPENDS_ON` | a ⟶ᵈ b | a requires b | cert ⟶ᵈ private-key |
| `PROVIDES` | a ⟶ₚ b | a offers capability b | TLS-1.3 ⟶ₚ cipher-suite |
| `CONTAINS` | a ⟶ᶜ b | a contains b | package ⟶ᶜ library |
| `CONFIGURES` | a ⟶ᶠ b | a configures b | service ⟶ᶠ protocol |
| `AUTHENTICATES_WITH` | a ⟶ₐ b | a authenticates using b | sshd ⟶ₐ host-key |
| `SIGNS` | a ⟶ₛ b | a cryptographically signs b | CA-key ⟶ₛ certificate |
| `ISSUED_BY` | a ⟶ᵦ b | a issued by authority b | leaf-cert ⟶ᵦ CA-cert |
| `LISTENS_ON` | a ⟶ₗ b | a listens on endpoint b | nginx ⟶ₗ 0.0.0.0:443 |

**Graph Invariants:**

1. **Acyclicity for ISSUED_BY:** The subgraph induced by ISSUED_BY edges must be a DAG (certificate chains)
2. **Type constraints:** Certain relationships are only valid between specific asset types
3. **Confidence bounds:** `ω(e) ∈ [0.0, 1.0] for all e ∈ E`

**Typical Confidence Values:**

| Detection Method | Confidence |
|------------------|------------|
| Config file parsing | 0.95 |
| Process detection | 0.90 |
| Symbol table analysis | 0.85 |
| Heuristic matching | 0.70 |

---

### Definition 2.4 (CryptoProperties Structure)

The `cryptoProperties` object is polymorphic based on asset type:

```
cryptoProperties = {
  assetType: T,
  algorithmProperties?:              AlgorithmProps,
  certificateProperties?:            CertificateProps,
  protocolProperties?:               ProtocolProps,
  relatedCryptoMaterialProperties?:  KeyProps
}
```

#### 2.4.1 Algorithm Properties

```typescript
AlgorithmProps = {
  primitive: Primitive,
  parameterSetIdentifier?: string,
  curve?: Curve,
  executionEnvironment?: ExecutionEnv,
  implementationPlatform?: string,
  certificationLevel?: CertLevel[],
  mode?: Mode,
  padding?: Padding,
  cryptoFunctions?: CryptoFunction[]
}
```

**Primitive Enumeration (CycloneDX 1.7):**

```
Primitive = {
  ae,            // Authenticated Encryption (AES-GCM, ChaCha20-Poly1305)
  block-cipher,  // Block cipher (AES, DES, Camellia)
  stream-cipher, // Stream cipher (ChaCha20, RC4)
  hash,          // Hash function (SHA-256, SHA-3)
  mac,           // Message Authentication Code (HMAC, CMAC)
  signature,     // Digital signature (RSA, ECDSA, Ed25519)
  key-agree,     // Key agreement (ECDH, DH, X25519)
  kdf,           // Key derivation (PBKDF2, HKDF, Argon2)
  kem,           // Key encapsulation (ML-KEM, RSA-KEM)
  pke,           // Public key encryption (RSA-OAEP, ECIES)
  xof,           // Extendable output function (SHAKE128, SHAKE256)
  drbg,          // Deterministic random bit generator (HMAC-DRBG)
  combiner,      // Cryptographic combiner
  other,
  unknown
}
```

**Mode Enumeration:**

```
Mode = { cbc, ctr, gcm, ccm, ecb, ofb, cfb, xts, siv, ocb, wrap, ... }
```

**Curve Enumeration:**

```
Curve = {
  // NIST curves
  P-192, P-224, P-256, P-384, P-521,
  // SECG curves
  secp256k1, secp256r1, secp384r1, secp521r1,
  // Edwards curves
  Ed25519, Ed448, Curve25519, Curve448,
  // Brainpool
  brainpoolP256r1, brainpoolP384r1, brainpoolP512r1,
  ...
}
```

#### 2.4.2 Certificate Properties

```typescript
CertificateProps = {
  subjectName: string,                    // DN
  issuerName: string,                     // DN
  notValidBefore: ISO8601,
  notValidAfter: ISO8601,
  certificateFormat: "X.509" | "OpenPGP",
  serialNumber: string,
  fingerprint: {
    alg: "SHA-256",
    content: HexString
  },
  certificateState: [{
    state: "active" | "revoked" | "expired" | "unknown",
    stateReason?: string,
    activationDate?: ISO8601
  }],
  certificateExtensions: Extension[],
  signatureAlgorithmRef?: bomRef,
  subjectPublicKeyRef?: bomRef,
  relatedCryptographicAssets: [{ ref: bomRef }]
}
```

#### 2.4.3 Protocol Properties

```typescript
ProtocolProps = {
  type: "tls" | "ssh" | "ipsec" | "ike" | "sstp" | "wpa" | ...,
  version?: string,
  cipherSuites?: [{
    name: string,
    algorithms: bomRef[],
    identifiers: string[]
  }]
}
```

---

### Definition 2.5 (Property Namespaces)

Properties **P** use hierarchical namespaces for extensibility:

```
P = { (namespace:category:attribute, value) | value ∈ string }
```

**Namespace Hierarchy:**

```
cbom:
├── pqc:           # Post-Quantum Cryptography assessment
│   ├── status
│   ├── confidence
│   ├── source
│   ├── source_version
│   ├── migration_urgency
│   ├── alternative
│   ├── break_estimate
│   └── rationale
├── cert:          # Certificate metadata
│   ├── public_key_algorithm
│   ├── signature_algorithm_name
│   ├── signature_algorithm_oid
│   ├── public_key_oid
│   ├── public_key_size
│   ├── ec_curve_name
│   ├── ec_curve_oid
│   ├── trust_status
│   ├── validity_status
│   ├── revocation_status
│   ├── subject_rfc2253
│   ├── issuer_rfc2253
│   └── fingerprint_sha256
├── algo:          # Algorithm metadata
│   ├── primitive
│   ├── key_length
│   ├── security_bits
│   ├── oid
│   ├── parameters
│   ├── quantum_category
│   ├── pqc_safe
│   └── deprecated
├── ctx:           # Detection context
│   ├── detection_method
│   ├── confidence
│   ├── file_path
│   └── scanner_version
├── lib:           # Library metadata
│   ├── name
│   ├── version
│   ├── soname
│   └── fips_status
├── svc:           # Service metadata
│   ├── name
│   ├── port
│   ├── process_name
│   └── security_profile
└── provenance:    # Build provenance
    ├── tool_name
    ├── tool_version
    ├── git_commit
    ├── git_branch
    ├── build_timestamp
    ├── compiler
    ├── compiler_version
    └── openssl_version
```

**Prefixed Properties for Nested Algorithms:**

Certificates contain nested algorithm metadata with prefixes:

```
pubkey:cbom:algo:*   # Public key algorithm properties
sig:cbom:algo:*      # Signature algorithm properties
```

---

### Definition 2.6 (PQC Assessment Model)

The Post-Quantum Cryptography assessment model provides quantum readiness evaluation:

```
PQC_Assessment = (category, score, urgency, alternative, breakEstimate, source)
```

#### 2.6.1 Category Classification

```
Category = { SAFE, TRANSITIONAL, DEPRECATED, UNSAFE }
```

| Category | Definition | Examples |
|----------|------------|----------|
| `SAFE` | NIST-finalized PQC or quantum-resistant symmetric | ML-KEM, ML-DSA, AES-256 |
| `TRANSITIONAL` | Classical with sufficient strength, quantum-vulnerable | RSA-3072, ECDSA-P384, TLS-1.3 |
| `DEPRECATED` | Weak classical, not recommended | MD5, SHA-1, DES, RC4 |
| `UNSAFE` | Insufficient classical strength | RSA-1024, DES, Export ciphers |

#### 2.6.2 Scoring Function

The PQC readiness score is computed as:

```
score(B) = (Σ w(category(a)) for a ∈ components(B)) / |components(B)|
```

where the weight function **w**:

```
w(SAFE) = 100
w(TRANSITIONAL) = 60
w(DEPRECATED) = 20
w(UNSAFE) = 0
```

**Score Interpretation:**

| Score Range | Interpretation |
|-------------|----------------|
| 90-100 | Excellent PQC readiness |
| 70-89 | Good, minor migration needed |
| 50-69 | Moderate risk, plan migration |
| 30-49 | High risk, prioritize migration |
| 0-29 | Critical, immediate action required |

#### 2.6.3 Migration Urgency

```
Urgency = { NONE, LOW, MEDIUM, HIGH, CRITICAL }
```

| Urgency | Trigger Condition |
|---------|-------------------|
| `NONE` | PQC_SAFE algorithms only |
| `LOW` | PQC_TRANSITIONAL with break estimate > 2040 |
| `MEDIUM` | PQC_TRANSITIONAL with break estimate 2035-2040 |
| `HIGH` | PQC_TRANSITIONAL with break estimate < 2035 |
| `CRITICAL` | PQC_DEPRECATED or PQC_UNSAFE present |

#### 2.6.4 Break Year Estimation

Based on NIST IR 8413 and NSA CNSA 2.0 guidance:

| Algorithm | Estimated Break Year |
|-----------|---------------------|
| RSA-1024 | 2030 |
| RSA-2048 | 2035 |
| RSA-3072 | 2040 |
| RSA-4096 | 2045 |
| ECDSA-P256 | 2035 |
| ECDSA-P384 | 2040 |
| ECDSA-P521 | 2045 |

#### 2.6.5 PQC Alternatives Mapping

```
alternative: Algorithm → PQC_Algorithm

RSA-2048     → ML-DSA-44 (Dilithium-2)
RSA-3072     → ML-DSA-65 (Dilithium-3)
RSA-4096     → ML-DSA-87 (Dilithium-5)
ECDSA-P256   → ML-DSA-44
ECDSA-P384   → ML-DSA-65
ECDH-P256    → ML-KEM-768
ECDH-P384    → ML-KEM-1024
X25519       → X25519Kyber768
```

---

### Definition 2.7 (Detection Evidence)

Each asset includes provenance evidence for traceability:

```typescript
Evidence = {
  occurrences: [{
    location: FilePath,
    line?: number,
    offset?: number
  }],
  detectionMethod: DetectionMethod,
  confidence: float  // [0.0, 1.0]
}
```

**Detection Methods:**

```
DetectionMethod = {
  FILE_CONTENT,      // File content analysis (PEM parsing, ASN.1)
  PROCESS_MEMORY,    // Process memory scanning
  CONFIG_PARSE,      // Configuration file parsing
  PACKAGE_MANAGER,   // Package manager query (dpkg, rpm)
  NETWORK_PROBE,     // Network service detection
  SYMBOL_TABLE,      // ELF symbol table analysis
  PLUGIN_YAML        // YAML plugin detection
}
```

---

### Definition 2.8 (CBOM Document Structure)

A complete CBOM document **B**:

```typescript
CBOM = {
  bomFormat: "CycloneDX",
  specVersion: "1.6" | "1.7",
  serialNumber: URN,
  version: integer,
  metadata: Metadata,
  components: Asset[],
  dependencies: Dependency[],
  vulnerabilities?: Vulnerability[],
  compositions?: Composition[],
  externalReferences?: ExternalRef[]
}
```

#### 2.8.1 Metadata Structure

```typescript
Metadata = {
  timestamp: ISO8601,
  tools: {
    components: [{
      type: "application",
      name: string,
      version: string,
      supplier: { name: string }
    }]
  },
  component: {
    type: "operating-system",
    name: string,
    bom-ref: "host-system"
  },
  properties: Property[]  // Scan configuration and statistics
}
```

**Metadata Properties:**

| Property | Description |
|----------|-------------|
| `cbom:scan_completion_pct` | Overall scan completion (0-100) |
| `cbom:completion:filesystem` | Filesystem scan completion |
| `cbom:completion:certificates` | Certificate scan completion |
| `cbom:completion:packages` | Package scan completion |
| `cbom:host:cpu_arch` | Host CPU architecture |
| `cbom:host:cpu_cores` | Host CPU core count |
| `cbom:host:mem_total_mb` | Host memory in MB |
| `cbom:scan:scan_depth_limit` | Directory traversal depth limit |
| `cbom:scan:excluded_paths` | Excluded filesystem paths |

#### 2.8.2 Dependency Serialization

The graph **G** is serialized as adjacency lists:

```typescript
Dependency = {
  ref: bomRef,           // Source asset
  dependsOn: bomRef[]    // Target assets (DEPENDS_ON edges)
}
```

**Note:** Only `DEPENDS_ON` relationships are serialized in CycloneDX `dependencies`. Other relationship types are encoded via `provides` properties or component nesting.

---

===================================================================

## 3. Formal Properties

### 3.1 Determinism

For a given input **I** and configuration **C**, the CBOM generator produces deterministic output:

```
∀ I, C: generate(I, C, t₁) = generate(I, C, t₂)
```

This is achieved through:

- Deterministic asset sorting (by type, then ID, then name)
- Content-addressed IDs (SHA-256)
- Frozen locale/timezone (UTC)
- Sorted JSON keys

### 3.2 Completeness Metric

Scan completeness is computed per scope:

```
completeness(scope) = (scanned_items / total_items) × 100
```

The overall completion percentage:

```
overall = Σ (weight(scope) × completeness(scope)) / Σ weight(scope)
```

### 3.3 Deduplication Invariants

In SAFE deduplication mode:

```
∀ a₁, a₂ ∈ components:
  content_hash(a₁) = content_hash(a₂) → a₁.bomRef = a₂.bomRef
```

Multiple occurrences are merged into evidence arrays rather than duplicate components.

### 3.4. Examples
### 3.4.1 Algorithm Asset

```json
{
  "type": "cryptographic-asset",
  "name": "AES-GCM",
  "bom-ref": "algo:aes-gcm",
  "cryptoProperties": {
    "assetType": "algorithm",
    "algorithmProperties": {
      "primitive": "ae",
      "mode": "gcm",
      "executionEnvironment": "software-plain-ram",
      "implementationPlatform": "x86_64",
      "certificationLevel": ["none"]
    }
  },
  "properties": [
    { "name": "cbom:pqc:status", "value": "SAFE" },
    { "name": "cbom:pqc:rationale", "value": "Symmetric algorithm with 256-bit security" }
  ]
}
```

### 3.4.2 Certificate Asset

```json
{
  "type": "cryptographic-asset",
  "name": "C = US, O = DigiCert Inc, CN = DigiCert Root CA",
  "bom-ref": "cert:digicert-root-ca",
  "cryptoProperties": {
    "assetType": "certificate",
    "certificateProperties": {
      "subjectName": "C = US, O = DigiCert Inc, CN = DigiCert Root CA",
      "issuerName": "C = US, O = DigiCert Inc, CN = DigiCert Root CA",
      "notValidBefore": "2006-11-10T00:00:00Z",
      "notValidAfter": "2031-11-10T00:00:00Z",
      "certificateFormat": "X.509",
      "serialNumber": "0CE7E0E517D846FE8FE560FC1BF03039",
      "fingerprint": {
        "alg": "SHA-256",
        "content": "3e9099b5015e8f486c00bcea9d111ee721faba355a89bcf1df69561e3dc6325c"
      }
    }
  },
  "evidence": {
    "occurrences": [
      { "location": "/etc/ssl/certs/DigiCert_Root_CA.pem" }
    ]
  },
  "properties": [
    { "name": "cbom:cert:public_key_algorithm", "value": "RSA" },
    { "name": "cbom:cert:public_key_size", "value": "2048" },
    { "name": "cbom:pqc:status", "value": "TRANSITIONAL" },
    { "name": "cbom:pqc:break_estimate", "value": "2035" },
    { "name": "cbom:pqc:alternative", "value": "ML-DSA-44 (Dilithium-2)" }
  ]
}
```

### 3.4.3 Dependency Graph Example

```
┌─────────────┐     USES      ┌─────────────┐
│   nginx     │──────────────▶│   TLS-1.3   │
│  (service)  │               │  (protocol) │
└─────────────┘               └─────────────┘
       │                             │
       │ AUTHENTICATES_WITH          │ PROVIDES
       ▼                             ▼
┌─────────────┐               ┌─────────────┐
│  server.crt │               │ AES-256-GCM │
│   (cert)    │               │cipher-suite │
└─────────────┘               └─────────────┘
       │                             │
       │ DEPENDS_ON                  │ USES
       ▼                             ▼
┌─────────────┐               ┌─────────────┐
│  server.key │               │   AES-256   │
│    (key)    │               │ (algorithm) │
└─────────────┘               └─────────────┘
```


### 3.4.4 Relationship Type Matrix

Valid relationship types between asset type pairs:

| Source → Target | algorithm | certificate | key | library | protocol | service | cipher-suite |
|-----------------|-----------|-------------|-----|---------|----------|---------|--------------|
| **algorithm** | - | - | - | - | - | - | - |
| **certificate** | ✓ᵈ | ✓ᵦ | ✓ᵈ | - | - | - | - |
| **key** | - | ✓ₛ | - | - | - | - | - |
| **library** | ✓ᵢ | - | - | ✓ᵈ | ✓ᵢ | - | - |
| **protocol** | ✓ᵤ | - | - | - | - | - | ✓ₚ |
| **service** | - | ✓ₐ | ✓ₐ | ✓ᵈ | ✓ᵤ | - | - |
| **cipher-suite** | ✓ᵤ | - | - | - | - | - | - |

Legend: ᵢ=IMPLEMENTS, ᵤ=USES, ᵈ=DEPENDS_ON, ₚ=PROVIDES, ₐ=AUTHENTICATES_WITH, ₛ=SIGNS, ᵦ=ISSUED_BY

### 3.5 CipherIQ Suite Architecture

The CipherIQ suite consists of four complementary tools providing complete cryptographic observability:

| Tool | Layer | Function |
|------|-------|----------|
| **cbom-generator** | Static (S) | Filesystem, binary, certificate, configuration scanning |
| **cbom-explorer** | Visualization | Interactive CBOM exploration and comparison |
| **crypto-tracer** | Runtime (R) | eBPF-based kernel probe for live crypto operations |
| **pqc-flow** | Runtime (R) | Passive network flow analysis for PQC detection |

### 3.6 Dual-Layer Observability Model

**Definition 3.1 (Static Configuration Layer).** The static configuration layer **S** represents all cryptographic assets discoverable through filesystem analysis:

```
S = {a : a extractable from (files ∪ binaries ∪ configurations ∪ certificates)}
```

 **cbom-generator** implements the complete static layer with the following extraction capabilities:

| Source | Detection Method | Confidence |
|--------|------------------|------------|
| X.509/OpenPGP certificates | FILE_CONTENT (ASN.1/PEM parsing) | 1.0 |
| Configuration files | CONFIG_PARSE (nginx, apache, ssh, etc.) | 0.95 |
| ELF binaries | SYMBOL_TABLE, BINARY_SCAN | 0.85 |
| Package managers | PACKAGE_MANAGER (dpkg, rpm, pip) | 0.90 |
| Running processes | PROCESS_DETECTION (pgrep, /proc) | 0.90 |
| Listening ports | NETWORK_CONFIG (/proc/net/tcp) | 0.85 |

**Definition 3.2 (Runtime Behavior Layer).** The runtime behavior layer **R** represents all cryptographic assets observable during system operation:

```
R = {a : a observable in (syscalls ∪ library_calls ∪ network_handshakes)}
```

The runtime layer is implemented by  **crypto-tracer** and  **cpqc-flow**:

| Tool | Observation Method | Assets Captured |
|------|-------------------|-----------------|
| crypto-tracer | eBPF kernel probes | Cipher negotiations, key exchanges, RNG calls |
| pqc-flow | Passive packet inspection | TLS 1.3, SSH, IKEv2, QUIC handshakes |

**Definition 3.3 (Complete Cryptographic Posture).** The complete cryptographic posture **P** of a system is:

```
P = S ∪ R
```

where  **cbom-generator** provides **S** and  **crypto-tracer** +  **cpqc-flow** provide **R**.

### 3.7 Completeness Theorems

!!! theorem "Theorem 3.1 (Incompleteness of Single-Layer Analysis)."

    For any non-trivial system:
    
    S ⊂ P  and  R ⊂ P
    
That is, neither static analysis alone nor runtime monitoring alone captures the complete cryptographic posture.

*Proof sketch:*

- **S ⊂ P**: Static analysis misses dynamically negotiated parameters. Example: TLS cipher suite selection depends on client capabilities at connection time; the actual negotiated suite may differ from configured preferences.
- **R ⊂ P**: Runtime monitoring misses dormant configurations. Example: Emergency fallback ciphers configured but never negotiated under normal conditions; disaster recovery certificates not used until failover.

**Corollary 3.1 (cbom-generator Completeness Bound).** cbom-generator alone provides:

```
|S| / |P| ≤ completeness(cbom-generator) < 1.0
```

For typical systems, empirical measurements show S captures 70-90% of P, with the gap primarily in:
- Dynamically selected cipher suites
- Runtime key generation
- Protocol version negotiation outcomes

### 3.8 Cryptographic Drift

**Definition 3.4 (Cryptographic Drift).** Cryptographic drift **D** is the symmetric difference between static configuration and runtime behavior:

```
D = (S \ R) ∪ (R \ S)
```

Drift is categorized into three types:

| Type | Definition | Example | Detection |
|------|------------|---------|-----------|
| **CNO** (Configured-Not-Observed) | S \ R | TLS 1.3 configured but never negotiated |  **crypto-tracer** absence detection |
| **ONC** (Observed-Not-Configured) | R \ S | Legacy cipher accepted via undocumented fallback |  **crypto-tracer** anomaly detection |
| **PM** (Parameter Mismatch) | S ∩ R with differing properties | Config specifies RSA-4096, cert uses RSA-2048 |  **cbom-generator** validation |


!!! theorem "Theorem 3.2 (Drift Detection Requires Dual-Layer)."

    Complete drift detection requires both layers:
    detect(D) requires S ∧ R

*Proof:* CNO detection requires R to confirm absence; ONC detection requires S to confirm non-configuration; PM detection requires comparing S and R properties.

### 3.9 cbom-generator's Role in Drift Detection

While complete drift detection requires the full suite,  **cbom-generator** provides:

1. **Baseline establishment**: The static inventory S against which runtime is compared
2. **PM detection within S**: Mismatches between configuration files and deployed certificates
3. **Staleness detection**: Expired certificates, deprecated algorithms in configurations
4. **Policy validation**: Configured assets vs. organizational security policies

**Definition 3.5 (Static Drift).** Static drift **D_S** is detectable by cbom-generator alone:

```
D_S = {(config, deployed) : config ∈ S_config ∧ deployed ∈ S_deployed ∧ config ≠ deployed}
```

Examples:

- nginx.conf specifies `ssl_protocols TLSv1.3` but certificate uses RSA-1024
- sshd_config allows `diffie-hellman-group1-sha1` (deprecated)
- Service configured with certificate that expires in < 30 days

### 3.10 Threat Model and Security Goals

 **cbom-generator** operates under the following threat model:

**Assumptions:**

1. Read-only filesystem access (no system modifications)
2. Unprivileged execution for static scanning (root optional for process inspection)
3. Offline operation supported (`--no-network` default)

**Security Goals:**

| Goal | Mechanism |
|------|-----------|
| Complete cryptographic visibility | Multi-scanner architecture (cert, key, package, service, filesystem) |
| Configuration drift detection | Static layer comparison (config vs. deployed) |
| Audit-ready documentation | CycloneDX 1.6/1.7 compliant output |
| Privacy preservation | `--no-personal-data` default, path/hostname redaction |
| Integrity assurance | SHA-256 checksums, SLSA provenance |

**Non-Goals (Handled by Other Suite Tools):**

- Runtime cipher negotiation monitoring → crypto-tracer
- Network traffic analysis → pqc-flow
- Interactive visualization → cbom-explorer

### 6.7 Observability Coverage Matrix

| Asset Type | cbom-generator (S) | crypto-tracer (R) | pqc-flow (R) |
|------------|-------------------|-------------------|--------------|
| Certificates | ✅ Full | ⚠️ Usage only | ⚠️ Handshake only |
| Private keys | ✅ Metadata only | ✅ Usage events | ❌ |
| Algorithms (configured) | ✅ Full | ❌ | ❌ |
| Algorithms (negotiated) | ❌ | ✅ Full | ✅ Full |
| Cipher suites (configured) | ✅ Full | ❌ | ❌ |
| Cipher suites (negotiated) | ❌ | ✅ Full | ✅ Full |
| Libraries | ✅ Full | ✅ Load events | ❌ |
| Protocols (configured) | ✅ Full | ❌ | ❌ |
| Protocols (negotiated) | ❌ | ✅ Full | ✅ Full |
| Services | ✅ Full | ✅ Crypto calls | ⚠️ Network only |
| PQC support | ✅ Config only | ✅ Actual use | ✅ Negotiation |



---

## 4. cbom-generator: Static Cryptographic Discovery

### 4.1 Architecture Overview

 **cbom-generator** is a production-ready C11 multithreaded application optimized for high-throughput scanning of Linux filesystems, firmware images, and container rootfs.

```
┌─────────────────────────────────────────────────────────────┐
│                    cbom-generator                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Filesystem  │  │ Certificate │  │ Configuration       │  │
│  │ Walker      │  │ Parser      │  │ Analyzers           │  │
│  │ (parallel)  │  │ (X.509,PEM) │  │ (YAML plugins)      │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                    │             │
│         └────────────────┼────────────────────┘             │
│                          ▼                                  │
│              ┌───────────────────────┐                      │
│              │   Asset Store         │                      │
│              │   (thread-safe)       │                      │
│              └───────────┬───────────┘                      │
│                          ▼                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Relationship│  │ PQC         │  │ Privacy             │  │
│  │ Builder     │  │ Classifier  │  │ Redactor            │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         └────────────────┼────────────────────┘             │
│                          ▼                                  │
│              ┌───────────────────────┐                      │
│              │  CycloneDX 1.6/1.7    │                      │
│              │  CBOM Output          │                      │
│              └───────────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Parallel Filesystem Scanning

**Algorithm 1: Multithreaded Cryptographic Asset Scanner**

```
Input: Root paths P[], thread count k, YAML plugin database Π
Output: Asset store A

1:  A ← ThreadSafeAssetStore()
2:  Q ← ConcurrentPriorityQueue()
3:  
4:  // Initialize with priority paths
5:  for path p ∈ P do
6:      priority ← computePriority(p)  // /etc/ssl, /etc/pki get high priority
7:      Q.enqueue(p, priority)
8:  
9:  // Spawn worker threads
10: workers ← []
11: for i ∈ [1..k] do
12:     workers.append(spawn(ScanWorker, Q, A, Π))
13:
14: // Wait for completion
15: for w ∈ workers do
16:     w.join()
17:
18: return A

ScanWorker(Q, A, Π):
1:  while Q not empty do
2:      (path, _) ← Q.dequeue()
3:      if isDirectory(path) then
4:          for child ∈ listDirectory(path) do
5:              if not isExcluded(child) then
6:                  Q.enqueue(child, computePriority(child))
7:      else
8:          assets ← AnalyzeFile(path, Π)
9:          for a ∈ assets do
10:             A.addAtomic(a)
```

**Complexity Analysis:** With k worker threads scanning n files with average m pattern matches per file, the expected runtime is O(n·m/k) assuming uniform work distribution. The priority queue ensures high-value paths (/etc/ssl, /etc/pki, /etc/ssh) are scanned first.

### 4.3 YAML Plugin Architecture for Service Discovery

Rather than hardcoding service-specific detection logic,  **cbom-generator** uses a declarative YAML plugin system enabling extensibility without code modification.

**Plugin Schema:**
```yaml
service_name: "nginx"
version: "1.0"

detection:
  methods:
    - type: "process"
      config:
        process_names: ["nginx", "nginx.conf"]
    - type: "file_exists"
      config:
        paths: ["/etc/nginx/nginx.conf", "/usr/sbin/nginx"]
    - type: "package"
      config:
        names: ["nginx", "nginx-common"]

crypto_scan:
  config_files:
    - path: "/etc/nginx/nginx.conf"
      parser: "nginx_conf"
    - path: "/etc/nginx/conf.d/*.conf"
      parser: "nginx_conf"
      glob: true

  directives:
    - name: "ssl_protocols"
      type: "protocol_list"
      extraction: "ssl_protocols\\s+([^;]+)"
    - name: "ssl_ciphers"
      type: "cipher_suite_list"
      extraction: "ssl_ciphers\\s+['\"]?([^;'\"]+)"
    - name: "ssl_certificate"
      type: "certificate_path"
      extraction: "ssl_certificate\\s+([^;]+)"

relationships:
  - from: "service:nginx"
    to: "protocol:tls"
    type: "dependsOn"
```

**Algorithm 2: YAML Plugin Execution**

```
Input: Plugin definition π, filesystem F
Output: Service asset s with dependencies

1:  // Detection phase
2:  detected ← false
3:  for method m ∈ π.detection.methods do
4:      if evaluateMethod(m, F) then
5:          detected ← true
6:          break
7:  
8:  if not detected then return ∅
9:  
10: // Create service asset
11: s ← createServiceAsset(π.service_name)
12: 
13: // Scan configuration files
14: for config c ∈ π.crypto_scan.config_files do
15:     files ← resolveGlob(c.path, F)
16:     for f ∈ files do
17:         content ← readFile(f)
18:         for directive d ∈ π.crypto_scan.directives do
19:             matches ← extractRegex(content, d.extraction)
20:             for match ∈ matches do
21:                 asset ← createAsset(d.type, match)
22:                 s.dependencies.add(asset)
23: 
24: return s
```

!!! theorem "Theorem 4.1 (Plugin Extensibility)"

    The YAML plugin architecture achieves `O(p·f)` service detection complexity where `p` is active plugin count and `f` is average files per plugin, independent of total codebase size.

### 4.4 Multi-Format Certificate Parsing

 **cbom-generator** supports comprehensive certificate and key material detection:

| Format | Detection Method | Extracted Properties |
|--------|------------------|---------------------|
| X.509 PEM | `-----BEGIN CERTIFICATE-----` header | Subject, issuer, validity, key algorithm, extensions |
| X.509 DER | ASN.1 magic bytes (0x30 0x82) | Same as PEM |
| PKCS#12 | Magic bytes, file extension | Contained certificates and keys |
| OpenSSH | `ssh-rsa`, `ssh-ed25519` prefixes | Key type, bit length, fingerprint |
| PGP | `-----BEGIN PGP` header | Key ID, algorithm, creation date |
| JKS/JCEKS | Java keystore magic bytes | Aliases, certificate chains |

**Algorithm 3: Certificate Chain Reconstruction**

```
Input: Set of discovered certificates C
Output: Certificate chains with trust relationships

1:  chains ← []
2:  roots ← {c ∈ C : c.issuer = c.subject}  // Self-signed
3:  
4:  for cert c ∈ C \ roots do
5:      chain ← [c]
6:      current ← c
7:      while current.issuer ≠ current.subject do
8:          parent ← findBySubject(C, current.issuer)
9:          if parent = ∅ then break
10:         chain.append(parent)
11:         current ← parent
12:     chains.append(chain)
13:     
14:     // Create relationships
15:     for i ∈ [0..len(chain)-2] do
16:         createRelationship(chain[i], chain[i+1], "signedBy")
17: 
18: return chains
```

### 4.5 PQC Readiness Classification

 **cbom-generator** evaluates all discovered cryptographic assets against NIST PQC standards and quantum vulnerability timelines.

**Algorithm 4: PQC Classification Engine**

```
Input: Cryptographic asset a
Output: (pqcStatus, quantumBreakYear, migrationPriority)

1:  if a.type = ALGORITHM then
2:      family ← a.algorithmProperties.family
3:      
4:      // NIST PQC Standards (SAFE)
5:      if family ∈ {ML-KEM, ML-DSA, SLH-DSA, LMS, XMSS} then
6:          return (SAFE, ∞, MONITORING)
7:      
8:      // Symmetric cryptography (conditionally SAFE)
9:      if family ∈ {AES, ChaCha20, SHA-3} then
10:         if a.keySize ≥ 256 then
11:             return (SAFE, ∞, MONITORING)
12:         else
13:             return (TRANSITIONAL, 2035, MEDIUM)
14:     
15:     // Hash functions
16:     if family ∈ {SHA-2} then
17:         if a.outputSize ≥ 384 then
18:             return (SAFE, ∞, MONITORING)
19:         else
20:             return (TRANSITIONAL, 2035, LOW)
21:     
22:     // Classical asymmetric (UNSAFE)
23:     if family ∈ {RSA, ECDSA, ECDH, DSA, DH, ElGamal} then
24:         breakYear ← lookupQuantumTimeline(family, a.keySize)
25:         return (UNSAFE, breakYear, CRITICAL)
26:     
27:     return (UNKNOWN, UNKNOWN, REVIEW_REQUIRED)
28: 
29: // Composite assets inherit worst classification
30: if a.type ∈ {PROTOCOL, CIPHER_SUITE} then
31:     worstStatus ← SAFE
32:     earliestBreak ← ∞
33:     for dep ∈ a.dependencies do
34:         (status, breakYear, _) ← classify(dep)
35:         if status > worstStatus then
36:             worstStatus ← status
37:             earliestBreak ← min(earliestBreak, breakYear)
38:     return (worstStatus, earliestBreak, derivePriority(worstStatus))
```

**Table 1: PQC Classification Categories**

| Status | Definition | Quantum Timeline | Migration Action |
|--------|------------|------------------|------------------|
| **SAFE** | Quantum-resistant (NIST PQC or symmetric ≥256-bit) | N/A | Monitor for standard evolution |
| **TRANSITIONAL** | Acceptable near-term, plan migration | 2030-2040 | Schedule replacement by 2030 |
| **UNSAFE** | Vulnerable to Shor's algorithm | 2025-2035 | Immediate migration planning |
| **DEPRECATED** | Known weaknesses (MD5, DES, RC4) | Already broken | Urgent remediation |

### 4.6 Privacy-Preserving Output Generation

 **cbom-generator** implements GDPR/CCPA-compliant privacy controls:

**Algorithm 5: Privacy Redaction**

```
Input: Raw CBOM B, privacy configuration P
Output: Redacted CBOM B'

1:  B' ← deepCopy(B)
2:  salt ← generateSecureSalt()
3:  
4:  for component c ∈ B'.components do
5:      // Path redaction
6:      if P.redactPaths then
7:          for evidence e ∈ c.evidence do
8:              e.location ← hash(salt || e.location)[:16]
9:      
10:     // Hostname anonymization
11:     if P.anonymizeHostnames then
12:         c.name ← replaceHostname(c.name, generateUUID())
13:     
14:     // Key material protection
15:     if c.type = "private-key" then
16:         c.cryptoProperties.value ← "[REDACTED]"
17:         c.cryptoProperties.fingerprint ← hash(c.rawValue)
18: 
19: return B'
```
!!! theorem "Theorem 4.2 (Privacy Preservation)."

    Under the privacy-preserving configuration with cryptographically secure salt, no original file paths, hostnames, or private key material can be recovered from the generated CBOM, while cryptographic relationship structure and PQC classification remain fully preserved.

---

## 5.  **crypto-tracer**: eBPF Runtime Monitoring

### 5.1 Design Rationale

Static CBOM generation reveals what cryptography *could* be used; runtime monitoring reveals what *is* used. crypto-tracer bridges this gap using Extended Berkeley Packet Filter (eBPF) to observe cryptographic operations at the kernel level.

**Design Goals:**

1. **Minimal overhead:** <0.5% CPU, <50MB memory
2. **Zero application modification:** No code changes, no restarts
3. **Comprehensive coverage:** File access, library loading, process activity
4. **Production-safe:** Read-only observation, no system modification
5. **Correlation-ready:** Output format designed for CBOM comparison

### 5.2 eBPF Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Space                           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   crypto-tracer                        │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐  │ │
│  │  │ Event        │ │ Correlation  │ │ JSON           │  │ │
│  │  │ Consumer     │ │ Engine       │ │ Formatter      │  │ │
│  │  └──────┬───────┘ └──────────────┘ └────────────────┘  │ │
│  └─────────┼──────────────────────────────────────────────┘ │
│            │ Ring Buffer                                    │
├────────────┼────────────────────────────────────────────────┤
│            │              Kernel Space                      │
│  ┌─────────▼──────────────────────────────────────────────┐ │
│  │              eBPF Programs                             │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐  │ │
│  │  │ sys_openat   │ │ dlopen       │ │ execve         │  │ │
│  │  │ tracepoint   │ │ uprobe       │ │ tracepoint     │  │ │
│  │  └──────────────┘ └──────────────┘ └────────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 Cryptographic Event Categories

**Category 1: File Access Events**

```c
SEC("tracepoint/syscalls/sys_enter_openat")
int trace_crypto_file_open(struct trace_event_raw_sys_enter *ctx) {
    char filename[MAX_PATH_LEN];
    bpf_probe_read_user_str(filename, sizeof(filename), 
                             (void *)ctx->args[1]);
    
    // Pattern matching for crypto files
    if (is_crypto_file(filename)) {
        struct crypto_event evt = {
            .type = CRYPTO_FILE_OPEN,
            .pid = bpf_get_current_pid_tgid() >> 32,
            .timestamp = bpf_ktime_get_ns(),
        };
        bpf_probe_read_str(evt.path, sizeof(evt.path), filename);
        bpf_get_current_comm(evt.comm, sizeof(evt.comm));
        
        bpf_ringbuf_output(&events, &evt, sizeof(evt), 0);
    }
    return 0;
}

static __always_inline bool is_crypto_file(const char *path) {
    // Certificates
    if (str_endswith(path, ".crt") || str_endswith(path, ".cer") ||
        str_endswith(path, ".pem") || str_endswith(path, ".der"))
        return true;
    
    // Keys
    if (str_endswith(path, ".key") || str_endswith(path, ".p12") ||
        str_endswith(path, ".pfx") || str_endswith(path, ".jks"))
        return true;
    
    // Known crypto paths
    if (str_startswith(path, "/etc/ssl/") ||
        str_startswith(path, "/etc/pki/") ||
        str_startswith(path, "/.ssh/"))
        return true;
    
    return false;
}
```

**Category 2: Library Loading Events**

```c
SEC("uprobe/libc.so.6:dlopen")
int trace_crypto_library_load(struct pt_regs *ctx) {
    char lib_path[MAX_PATH_LEN];
    bpf_probe_read_user_str(lib_path, sizeof(lib_path), 
                             (void *)PT_REGS_PARM1(ctx));
    
    struct crypto_lib lib_type = classify_crypto_library(lib_path);
    if (lib_type.is_crypto) {
        struct crypto_event evt = {
            .type = CRYPTO_LIB_LOAD,
            .pid = bpf_get_current_pid_tgid() >> 32,
            .timestamp = bpf_ktime_get_ns(),
            .lib_type = lib_type.type,
        };
        bpf_probe_read_str(evt.path, sizeof(evt.path), lib_path);
        
        bpf_ringbuf_output(&events, &evt, sizeof(evt), 0);
    }
    return 0;
}
```

**Table 2: Monitored Cryptographic Libraries**

| Library | Detection Pattern | Algorithms Provided |
|---------|-------------------|---------------------|
| OpenSSL | `libssl.so`, `libcrypto.so` | TLS, RSA, ECDSA, AES, SHA |
| GnuTLS | `libgnutls.so` | TLS, X.509, PKCS#11 |
| libsodium | `libsodium.so` | NaCl, ChaCha20, Ed25519 |
| NSS | `libnss3.so` | TLS, S/MIME, PKCS#11 |
| mbedTLS | `libmbedtls.so` | TLS, X.509, AES |
| wolfSSL | `libwolfssl.so` | TLS, DTLS, PQC (liboqs) |
| liboqs | `liboqs.so` | ML-KEM, ML-DSA, SLH-DSA |

### 5.4 Performance Optimization

**Ring Buffer Design:**

- Per-CPU ring buffers eliminate cross-CPU synchronization
- Batch event submission reduces syscall overhead
- Back-pressure handling drops events under extreme load

**Measured Performance:**

| Metric | Value |
|--------|-------|
| CPU overhead (idle) | <0.1% |
| CPU overhead (moderate crypto activity) | <0.5% |
| Memory footprint | 48 MB typical |
| Event latency (kernel → userspace) | <100 µs |
| Maximum event throughput | 100,000 events/sec |

---

## 6. pqc-flow: Passive Network PQC Detection

### 6.1 Design Overview

**pqc-flow** performs passive inspection of network traffic to detect post-quantum cryptography support and negotiation without requiring payload decryption.

**Supported Protocols:**

- TLS 1.3 (including DTLS 1.3)
- SSH (OpenSSH 9.0+ with PQC extensions)
- IKEv2 (RFC 9370 PQC extensions)
- QUIC (with TLS 1.3 handshake)

### 6.2 TLS 1.3 PQC Detection

**Algorithm 6: TLS ClientHello PQC Analysis**

```
Input: TLS ClientHello packet P
Output: PQC capability assessment

1:  // Parse supported_groups extension (type 10)
2:  groups ← parseExtension(P, SUPPORTED_GROUPS)
3:  
4:  pqc_groups ← []
5:  hybrid_groups ← []
6:  classical_groups ← []
7:  
8:  for group_id g ∈ groups do
9:      switch g:
10:         case 0x11EC:  // X25519MLKEM768
11:             hybrid_groups.append("X25519MLKEM768")
12:         case 0x11EB:  // SecP256r1MLKEM768
13:             hybrid_groups.append("SecP256r1MLKEM768")
14:         case 0x0200..0x02FF:  // NIST PQC reserved range
15:             pqc_groups.append(lookupPQCGroup(g))
16:         case 0x001D:  // X25519
17:             classical_groups.append("X25519")
18:         case 0x0017:  // secp256r1
19:             classical_groups.append("secp256r1")
20:         // ... additional groups
21: 
22: // Analyze key_share extension for offered keys
23: key_shares ← parseExtension(P, KEY_SHARE)
24: offered_pqc ← any(ks.group ∈ pqc_groups ∪ hybrid_groups for ks ∈ key_shares)
25: 
26: return PQCAssessment(
27:     supports_pqc = len(pqc_groups ∪ hybrid_groups) > 0,
28:     offers_pqc_key = offered_pqc,
29:     hybrid_groups = hybrid_groups,
30:     pqc_groups = pqc_groups,
31:     classical_fallback = classical_groups
32: )
```

**Algorithm 7: TLS ServerHello PQC Negotiation Analysis**

```
Input: TLS ServerHello packet P, client capabilities C
Output: Negotiation result

1:  selected_group ← parseExtension(P, KEY_SHARE).group
2:  
3:  if selected_group ∈ C.hybrid_groups then
4:      return NegotiationResult(
5:          status = PQC_HYBRID,
6:          algorithm = lookupGroup(selected_group),
7:          classical_component = extractClassical(selected_group),
8:          pqc_component = extractPQC(selected_group)
9:      )
10: 
11: if selected_group ∈ C.pqc_groups then
12:     return NegotiationResult(
13:         status = PQC_ONLY,
14:         algorithm = lookupGroup(selected_group)
15:     )
16: 
17: if selected_group ∈ C.classical_groups then
18:     // Server downgraded to classical despite PQC support
19:     return NegotiationResult(
20:         status = CLASSICAL_DOWNGRADE,
21:         algorithm = lookupGroup(selected_group),
22:         drift_indicator = true
23:     )
24: 
25: return NegotiationResult(status = UNKNOWN)
```

### 6.3 SSH PQC Detection

OpenSSH 9.0+ supports post-quantum key exchange via `sntrup761x25519-sha512@openssh.com`.

**Algorithm 8: SSH KEX Algorithm Analysis**

```
Input: SSH Key Exchange Init packet P
Output: SSH PQC assessment

1:  kex_algorithms ← parseNameList(P.kex_algorithms)
2:  
3:  pqc_kex ← []
4:  hybrid_kex ← []
5:  
6:  for alg ∈ kex_algorithms do
7:      if alg contains "sntrup" or alg contains "mlkem" then
8:          if alg contains "x25519" or alg contains "ecdh" then
9:              hybrid_kex.append(alg)
10:         else
11:             pqc_kex.append(alg)
12: 
13: return SSHPQCAssessment(
14:     supports_pqc = len(pqc_kex ∪ hybrid_kex) > 0,
15:     hybrid_algorithms = hybrid_kex,
16:     pqc_algorithms = pqc_kex
17: )
```

### 6.4 Network Flow Processing

**Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│                        pqc-flow                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐                                           │
│  │ Packet       │ libpcap / AF_PACKET / eBPF XDP            │
│  │ Capture      │                                           │
│  └──────┬───────┘                                           │
│         ▼                                                   │
│  ┌──────────────┐                                           │
│  │ Protocol     │ TCP reassembly, UDP, QUIC                 │
│  │ Dissector    │                                           │
│  └──────┬───────┘                                           │
│         ▼                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐ │
│  │ TLS 1.3      │  │ SSH          │  │ IKEv2              │ │
│  │ Analyzer     │  │ Analyzer     │  │ Analyzer           │ │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬─────────┘ │
│         └────────────────┬──────────────────────┘           │
│                          ▼                                  │
│              ┌───────────────────────┐                      │
│              │ PQC Assessment        │                      │
│              │ Aggregator            │                      │
│              └───────────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

**Performance Characteristics:**

| Metric | Value |
|--------|-------|
| Throughput | 10 Gbps sustained |
| Latency | <1 ms per packet |
| Memory (flow table) | ~100 bytes/flow |
| Maximum concurrent flows | 1M+ |

---

## 7. Drift Detection: Correlating Static and Runtime Observations

### 7.1 Correlation Framework

The drift detection algorithm correlates three data sources:

1. **Static CBOM** from  **cbom-generator**
2. **Runtime traces** from  **crypto-tracer**
3. **Network observations** from  **cpqc-flow**

**Algorithm 9: Multi-Source Drift Detection**

```
Input: Static CBOM S, Runtime traces T, Network observations N
Output: Drift report D

1:  D ← []
2:  
3:  // Build canonical asset indices
4:  S_idx ← buildIndex(S, canonicalKey)
5:  T_idx ← buildIndex(T, canonicalKey)
6:  N_idx ← buildIndex(N, canonicalKey)
7:  
8:  // Detect Configured-Not-Observed (CNO)
9:  for asset a ∈ S do
10:     key ← canonicalKey(a)
11:     if key ∉ T_idx and key ∉ N_idx then
12:         if a.expectedUsage = ACTIVE then  // Not dormant/emergency
13:             D.append(DriftRecord(
14:                 type = CNO,
15:                 asset = a,
16:                 severity = computeSeverity(a),
17:                 recommendation = "Verify configuration is being applied"
18:             ))
19: 
20: // Detect Observed-Not-Configured (ONC) - Shadow crypto
21: for trace t ∈ T do
22:     key ← canonicalKey(t)
23:     if key ∉ S_idx then
24:         D.append(DriftRecord(
25:             type = ONC,
26:             observation = t,
27:             severity = HIGH,
28:             recommendation = "Investigate undocumented crypto usage"
29:         ))
30: 
31: // Detect Parameter Mismatches (PM)
32: for asset a ∈ S do
33:     key ← canonicalKey(a)
34:     if key ∈ T_idx then
35:         t ← T_idx[key]
36:         mismatches ← compareParameters(a, t)
37:         if mismatches ≠ ∅ then
38:             D.append(DriftRecord(
39:                 type = PM,
40:                 configured = a,
41:                 observed = t,
42:                 parameters = mismatches
43:             ))
44: 
45: // Detect PQC Downgrade (from network)
46: for flow f ∈ N do
47:     if f.client_offered_pqc and not f.server_selected_pqc then
48:         D.append(DriftRecord(
49:             type = PQC_DOWNGRADE,
50:             flow = f,
51:             severity = CRITICAL,
52:             recommendation = "Server does not support PQC - upgrade required"
53:         ))
54: 
55: return D
```

### 7.2 Canonical Key Generation

Assets from different sources must be matched despite varying representations:

```
canonicalKey(asset):
    switch asset.source:
        case STATIC_CBOM:
            // Normalize from CBOM representation
            return normalize(asset.type, asset.name, asset.properties)
        
        case RUNTIME_TRACE:
            // Map runtime event to canonical form
            if asset.type = FILE_ACCESS:
                return ("certificate", extractCertId(asset.path))
            if asset.type = LIB_LOAD:
                return ("library", extractLibName(asset.path))
        
        case NETWORK_FLOW:
            // Map negotiated cipher to canonical form
            return ("cipher_suite", asset.negotiated_suite)
```

### 7.3 Severity Classification

| Drift Type | Severity | Criteria |
|------------|----------|----------|
| PQC_DOWNGRADE | CRITICAL | PQC offered but classical negotiated |
| ONC (Shadow crypto) | HIGH | Unknown crypto in production |
| PM (Weak algorithm observed) | HIGH | Weaker than configured |
| CNO (Critical asset unused) | MEDIUM | Security control not applied |
| PM (Version mismatch) | LOW | Minor version differences |

---

## 8. Experimental Evaluation

### 8.1 Experimental Setup

**Test Environment:**

- 12 embedded Linux systems (Yocto-based, ARM64 and x86_64)
- Target sectors: Automotive ECU, Medical device, Industrial PLC
- Services: OpenSSH, nginx, Apache, Mosquitto MQTT, OpenVPN
- Observation period: 7 days continuous monitoring

**Methodology:**

1. Generate baseline CBOM with  **cbom-generator**
2. Deploy  **crypto-tracer** for runtime monitoring
3. Capture network traffic with  **cpqc-flow**
4. Correlate sources and compute drift metrics

### 8.2 Static Discovery Results (cbom-generator)

**Table 3: Asset Discovery by Category**

| Asset Type | Discovered | With PQC Assessment | Coverage vs. Manual Audit |
|------------|------------|---------------------|---------------------------|
| Certificates | 187 | 187 (100%) | 94% |
| Private Keys | 23 | 23 (100%) | 100% |
| Algorithms | 412 | 412 (100%) | 91% |
| Protocols | 34 | 34 (100%) | 97% |
| Cipher Suites | 89 | 89 (100%) | 88% |
| Libraries | 47 | 47 (100%) | 100% |
| **Total** | **792** | **792** | **93%** |

**Performance Metrics:**

| Metric | Value |
|--------|-------|
| Files scanned | 2.4M |
| Scan throughput | 12,847 files/min |
| Peak memory | 87 MB |
| CBOM generation time | <100ms for 792 assets |

### 8.3 Runtime Monitoring Results (crypto-tracer)

**Table 4: Runtime Cryptographic Activity (7-day observation)**

| Event Category | Count | Unique Assets |
|----------------|-------|---------------|
| Certificate file access | 4,723 | 89 |
| Key file access | 1,247 | 23 |
| Library loading (OpenSSL) | 12,456 | 3 |
| Library loading (Other) | 892 | 5 |
| **Total events** | **19,318** | **120** |

**Resource Consumption:**

| Metric | Value |
|--------|-------|
| CPU overhead | 0.3% average |
| Memory footprint | 48 MB |
| Events dropped | 0 (no back-pressure) |

### 8.4 Network PQC Detection Results (pqc-flow)

**Table 5: TLS Connection Analysis**

| Metric | Value |
|--------|-------|
| Total TLS connections | 47,892 |
| Connections offering PQC | 8,234 (17.2%) |
| PQC successfully negotiated | 3,412 (7.1%) |
| PQC downgrade detected | 4,822 (10.1%) |
| Classical-only connections | 39,658 (82.8%) |

**PQC Algorithm Distribution (among PQC connections):**

| Algorithm | Client Offered | Server Selected |
|-----------|---------------|-----------------|
| X25519MLKEM768 | 8,012 | 3,287 |
| SecP256r1MLKEM768 | 222 | 125 |
| Pure ML-KEM-768 | 0 | 0 |

### 8.5 Drift Detection Results

**Table 6: Cryptographic Drift Analysis**

| Drift Type | Count | Example |
|------------|-------|---------|
| **Configured-Not-Observed** | 47 | TLS 1.3-only configured, TLS 1.2 negotiated |
| **Observed-Not-Configured** | 12 | Undocumented libgcrypt usage |
| **Parameter Mismatch** | 8 | RSA-4096 configured, RSA-2048 in certificate |
| **PQC Downgrade** | 4,822 | PQC offered, X25519 selected |
| **Total Drift Instances** | **4,889** | |

**Drift by Severity:**

| Severity | Count | Percentage |
|----------|-------|------------|
| CRITICAL | 4,822 | 98.6% |
| HIGH | 15 | 0.3% |
| MEDIUM | 47 | 1.0% |
| LOW | 5 | 0.1% |

### 8.6 PQC Readiness Assessment

**Table 7: Quantum Vulnerability Distribution**

| PQC Status | Asset Count | Percentage |
|------------|-------------|------------|
| SAFE | 127 | 16.0% |
| TRANSITIONAL | 398 | 50.3% |
| UNSAFE | 267 | 33.7% |

**Migration Priority:**

| Priority | Assets | Action Required |
|----------|--------|-----------------|
| CRITICAL | 267 | Immediate PQC migration planning |
| HIGH | 89 | Schedule migration by 2028 |
| MEDIUM | 309 | Schedule migration by 2030 |
| LOW | 127 | Monitor for standard evolution |

---

## 9. Related Work

### 9.1 CBOM Generation Tools

**IBM CBOMkit** (contributed to PQCA): Comprises CBOMkit-Hyperion (source code scanning via SonarQube), CBOMkit-Theia (container image scanning), and CBOMkit-Coeus (visualization). Focuses on source code analysis for Java/Python; does not address runtime monitoring or network analysis.

**CycloneDX Tool Center**: Lists 20+ SBOM/CBOM tools, primarily focused on dependency analysis rather than cryptographic primitive discovery.

**CipherIQ cbom-generator** (this work) differs by: (1) scanning compiled binaries and firmware without source access; (2) YAML plugin architecture for service extensibility; (3) integrated PQC classification; (4) cross-architecture support for embedded systems.

### 9.2 Runtime Cryptographic Monitoring

**Traditional approaches** use strace/ltrace for syscall tracing, incurring 50-100x overhead unsuitable for production.

**eBPF-based security tools** (Falco, Tracee) focus on general security monitoring; none specialize in cryptographic operation tracing.

**crypto-tracer** (this work) provides purpose-built cryptographic tracing with <0.5% overhead and correlation-ready output format.

### 9.3 Network Cryptographic Analysis

**SSL/TLS inspection proxies** (Palo Alto NGFW, Zscaler) can detect PQC but require inline deployment and certificate re-signing.

**Passive protocol analyzers** (Zeek, Wireshark) can parse TLS handshakes but lack PQC-specific analysis and drift correlation.

**pqc-flow** (this work) provides passive PQC detection without payload decryption, designed for drift correlation with static CBOMs.

### 9.4 Comparison Summary

| Capability | IBM CBOMkit | Qualys | Darktrace | **CipherIQ** |
|------------|-------------|--------|-----------|--------------|
| Source code scanning | ✓ | ✗ | ✗ | ✗ |
| Binary/firmware scanning | Limited | Certs only | ✗ | **✓** |
| Runtime eBPF monitoring | ✗ | ✗ | ✗ | **✓** |
| Network PQC detection | ✗ | ✗ | Limited | **✓** |
| Drift detection | ✗ | ✗ | ✗ | **✓** |
| PQC classification | Limited | ✗ | ✗ | **✓** |
| Embedded system support | ✗ | ✗ | ✗ | **✓** |

---

## 10. Discussion and Future Work

### 10.1 Limitations

1. **Binary analysis depth:** Current implementation relies on symbol tables and magic bytes; obfuscated or stripped binaries may escape detection. Future work will incorporate binary lifting and control flow analysis.

2. **Encrypted traffic correlation:**  **cpqc-flow** analyzes handshake metadata only; post-handshake cryptographic details are not observable with passive inspection when forward secrecy is employed.

3. **Cloud-native environments:** Current deployment model assumes host-level access; Kubernetes service mesh environments require sidecar injection patterns (planned for v2.0).

4. **Formal verification:** Drift detection correctness depends on canonical key generation accuracy. Future work will formalize the mapping and provide completeness proofs under stated assumptions.

### 10.2 Future Directions

1. **Machine learning for service classification:** Train models on behavioral patterns to detect cryptographic services without explicit plugins.

2. **Hybrid certificate detection:** As organizations deploy ML-DSA certificates during transition, extend parsing to detect and classify hybrid certificate chains.

3. **Continuous compliance monitoring:** Integrate with CI/CD pipelines for automated CBOM generation on every build, with drift alerts when production diverges from baseline.

4. **Hardware security module (HSM) integration:** Extend  **crypto-tracer** to observe PKCS#11 API calls for HSM-backed key operations.

5. **SBOM/CBOM correlation:** Merge software component inventory (SBOM) with cryptographic inventory (CBOM) for unified supply chain visibility.

---

## 11. Conclusion

We presented **CipherIQ**, a comprehensive cryptographic observability platform addressing the fundamental visibility gap that impedes post-quantum migration planning. By combining static CBOM generation (**cbom-generator**), eBPF runtime tracing (**crypto-tracer**), and passive network analysis (**pqc-flow**), CipherIQ enables organizations to answer definitively: "What cryptography are we *actually* using?"

Our key contributions include:

- The dual-layer observability model formalizing the relationship between static configuration and runtime behavior
- Cryptographic drift detection that identifies discrepancies invisible to single-layer analysis
- High-performance implementations achieving 12,000+ files/minute static scanning and 10Gbps network analysis
- Privacy-preserving design enabling CBOM sharing without exposing sensitive infrastructure details

Experimental evaluation on embedded Linux systems demonstrated 93% coverage against manual audits, detection of drift in 23% of TLS connections, and identification of 33.7% of cryptographic assets as quantum-vulnerable. For organizations deploying systems with 20-30 year operational lifespans, this visibility is essential infrastructure for the post-quantum transition.

**CipherIQ **is open-source (GPL-3.0) at [https://github.com/CipherIQ](https://github.com/CipherIQ) with commercial licensing available for proprietary integration.

---

## References

[1] NIST. FIPS 203: Module-Lattice-Based Key-Encapsulation Mechanism Standard. 2024.

[2] NIST. FIPS 204: Module-Lattice-Based Digital Signature Standard. 2024.

[3] NIST. FIPS 205: Stateless Hash-Based Digital Signature Standard. 2024.

[4] OWASP. CycloneDX Authoritative Guide to CBOM. 2024.

[5] NSA. CNSA 2.0: Cybersecurity Advisory on Commercial National Security Algorithm Suite 2.0. 2022.

[6] IBM Research. CBOMkit: A Toolset for Cryptography Bill of Materials. 2024. https://github.com/cbomkit/cbomkit

[7] Gregg, B. BPF Performance Tools: Linux System and Application Observability. Addison-Wesley, 2019.

[8] CycloneDX. Bill of Materials Standard Specification v1.6/1.7. https://cyclonedx.org

[9] Mosca, M. Cybersecurity in an Era with Quantum Computers: Will We Be Ready? IEEE Security & Privacy, 2018.

[10] Barker, E., et al. Recommendation for Key Management. NIST SP 800-57 Part 1 Rev 5. 2020.

[11] IETF. Hybrid Key Exchange in TLS 1.3. draft-ietf-tls-hybrid-design. 2024.

[12] OpenSSH. Release Notes - Post-Quantum Key Exchange. https://www.openssh.com/releasenotes.html

[13] EU. Cyber Resilience Act (CRA). Regulation 2024/XXX. 2024.

[14] FDA. Cybersecurity in Medical Devices: Quality System Considerations. 2023.

[15] IEC. IEC 62443: Industrial Communication Networks - Network and System Security. 2024.

---

## Appendix A: CycloneDX 1.7 CBOM Schema Extensions

[Detailed JSON schema for cryptographic asset representation]

## Appendix B: YAML Plugin Development Guide

[Complete specification for service discovery plugin authorship]

## Appendix C: eBPF Program Listings

[Full source code for crypto-tracer eBPF programs]

## Appendix D: Performance Tuning Guide

[Configuration parameters for optimizing throughput in enterprise deployments]


---
Copyright (c) 2025 Graziano Labs Corp.

<script>
document.addEventListener('DOMContentLoaded', function() {
  var links = document.querySelectorAll('a');
  for (var i = 0; i < links.length; i++) {
    if (links[i].hostname !== window.location.hostname) {
      links[i].target = '_blank';
      links[i].rel = 'noopener noreferrer';
    }
  }
});
</script>