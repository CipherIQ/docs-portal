<figure markdown="span">
  ![Image title](assets/cipheriq_logo_2x.png){ width="500" }
</figure>

## Cryptographic Observability for the Quantum Era
Modern organizations operate in an environment where cryptographic transparency, algorithm safety, and software supply-chain security are no longer optional. Regulatory bodies, international standards organizations, and sector-specific authorities now require a clear understanding of what cryptography is used within systems, how secure it is, and how organizations plan to transition to quantum-resistant alternatives.

**CipherIQ** is an open-source cryptographic observability platform that combines static asset discovery with runtime network monitoring to provide complete visibility into enterprise cryptographic posture.

As organizations face mandatory post-quantum cryptography (PQC) migration deadlines and the *harvest now, decrypt later* threat, CipherIQ solves the fundamental problem: **you cannot migrate what you cannot see.**

## The Quantum Timeline Problem

**2024-2025:** NIST finalizes PQC standards (ML-KEM, ML-DSA, SLH-DSA)  
**2025-2030:** Adversaries harvest encrypted data now for future decryption  
**2027-2033:** NSA CNSA 2.0 mandates phased PQC migration for national security systems  
**2030-2035:** Cryptographically relevant quantum computers potentially viable  

**Critical insight:** Data encrypted with RSA-2048 today and captured by adversaries will be vulnerable in 10-15 years which is well within the confidentiality requirements of:

- **IoT/OT devices** (20-30 year operational lifespans)
- **Medical records** (HIPAA: 50+ year retention)
- **Financial transactions** (SOX: 7+ year retention)
- **Government classified data** (decades of sensitivity)
- **Intellectual property** (patent terms: 20 years)


Organizations with long-lived data or devices cannot afford to wait. They need visibility into their cryptographic attack surface **now**.

### **[Relevant PQC-Specific Frameworks & Standards](compliance.md)↗**

## The Solution: Complete Cryptographic Observability

CipherIQ provides **dual-layer visibility** that closes the gap between configuration and reality:

### Layer 1: Static Discovery
**What cryptography COULD be used based on configuration**

Scan firmware, containers, and filesystems to inventory:

- Cryptographic libraries and their versions
- Embedded certificates and key materials
- Configuration files (TLS, SSH, VPN, IPsec)
- Binary dependencies and linked crypto modules

**CipherIQ Tools**: [cbom-generator](./cbom-generator/index.md) and [cbom-explorer](./cbom-explorer/index.md)

**Output:** Cryptography Bill of Material (CBOM) in JSON <a href="https://cyclonedx.org/" target="_blank">CycloneDX</a>↗ format documenting the complete cryptographic supply chain

### Layer 2: Runtime Monitoring 
**What cryptography IS actually being used in production**

Monitor live systems to observe:

- Actual cipher suite negotiations
- Key exchanges and certificate validations
- Protocol versions and algorithm selections
- Fallback behavior under real-world conditions

**CipherIQ Tools**: [crypto-tracer](./crypto-tracer/index.md) and [pqc-flow](./pqc-flow/index.md)

**Output:** Runtime telemetry showing production cryptographic behavior


### What You Configure ≠ What Runs in Production

Modern infrastructure has a dangerous gap between **declared cryptographic policy** and **actual runtime behavior**:

- **Static configuration files** say "TLS 1.3 only with quantum-safe ciphers"
- **Production reality** shows TLS 1.2 fallback with RSA-2048 still accepting connections
- **Certificate inventory** lists SHA-256 certificates
- **Network traffic** reveals SHA-1 still being negotiated with legacy clients
- **Security policies** mandate AES-256-GCM
- **Running systems** use weaker algorithms due to compatibility layers

**The result:** Organizations believe they're quantum-ready based on configuration audits, while their production infrastructure remains vulnerable to "harvest now, decrypt later" attacks.

### The Power of Correlation

**Compare static inventory against runtime behavior to detect:**

- **Configuration drift:** TLS 1.3 configured → TLS 1.2 negotiated
- **Unexpected fallbacks:** Modern ciphers available → Weak ciphers still in use
- **Certificate mismatches:** SHA-256 certs deployed → SHA-1 still accepted
- **Compliance violations:** Policy requires quantum-safe → Production uses vulnerable crypto
- **Shadow crypto:** Undocumented libraries → Discovered in runtime traces

This dual-layer approach transforms cryptographic security from **"we think we're safe"** to **"we can prove we're safe"** with verifiable evidence.


## CipherIQ Tools

### **1) cbom-generator**
**Static cryptographic asset discovery with PQC readiness assessment**

Scans Linux filesystems, firmware images, and containers to generate comprehensive Cryptography Bills of Materials (CBOMs) in CycloneDX format.

**Key capabilities:**

- **Deep discovery:** Finds cryptographic libraries, certificates, keys, and configuration files
- **PQC classifier:** Evaluates 48+ NIST algorithms against quantum threat timeline
- **Relationship mapping:** Tracks SERVICE → PROTOCOL → CIPHER → ALGORITHM chains
- **Embedded system support:** Optimized for resource-constrained IoT/OT devices
- **Privacy-preserving:** Hashes sensitive key material, never exposes secrets
- **Standards-based:** CycloneDX 1.6/1.7 CBOM output for tool ecosystem integration

**Perfect for:**

- IoT/OT manufacturers generating CBOMs for FDA/UN R155/IEC 62443 compliance
- DevSecOps teams integrating crypto inventory into CI/CD pipelines
- Security teams conducting quantum readiness assessments
- Compliance officers documenting cryptographic controls

 
**[Learn more →](./cbom-generator/index.md)** | **[GitHub →](https://github.com/CipherIQ/cbom-generator)**

### Yocto CBOM Sample 

??? note "Click to expand: Full first 200 lines of yocto-cbom.json"

    ```json linenums="1"
    --8<-- "https://raw.githubusercontent.com/CipherIQ/cbom-explorer/main/samples/yocto-cbom.json:1:200"
    ```

[View the full Yocto CBOM on GitHub (pretty-printed, searchable)](https://github.com/CipherIQ/cbom-explorer/blob/main/samples/yocto-cbom.json)↗

---

### **2) cbom-explorer**
**Web-based CBOM visualization and navigation**

Lightweight, browser-based tool for exploring Cryptography Bills of Materials. No installation required—runs entirely in your browser.

**Key capabilities:**

- **Interactive visualization:** Navigate cryptographic dependencies as graphs
- **PQC dashboard:** Visual readiness scoring with quantum vulnerability heat maps
- **Algorithm analysis:** Drill down into cipher suite compositions and primitives
- **Certificate chains:** Visualize trust paths and expiration timelines
- **Diff view:** Compare CBOMs across firmware versions to track changes
- **Export reports:** Generate compliance summaries for stakeholders

**Perfect for:**

- Security teams reviewing cryptographic inventory results
- Compliance officers presenting audit evidence
- Engineering managers tracking PQC migration progress
- Executives understanding quantum risk exposure

**[Learn more →](./cbom-explorer/index.md)** | **[GitHub →](https://github.com/CipherIQ/cbom-explorer)**

---

### **3) crypto-tracer**
**kernel-based runtime cryptographic operation monitoring**

Standalone command-line tool that uses Extended Berkeley Packet Filter (eBPF) to trace cryptographic operations on Linux systems in the kernel without modifying applications or requiring restarts.

**Key capabilities:**

- **Zero-overhead tracing:** eBPF kernel probes with minimal performance impact
- **OpenSSL/libcrypto monitoring:** Captures cipher negotiations, key exchanges, certificate usage
- **Real-time insights:** Observe actual algorithm selections as they happen
- **Correlation ready:** Output format designed for comparison with static CBOMs
- **Production-safe:** Read-only monitoring with no application changes required
- **Filtering support:** Focus on specific processes, connections, or crypto operations

**Perfect for:**

- Validating that static CBOM configurations match runtime behavior
- Detecting unexpected cryptographic fallbacks in production
- Investigating cryptographic incidents and anomalies
- Continuous compliance monitoring with runtime evidence
- Security research and cryptographic protocol analysis

**[Learn more →](./crypto-tracer/index.md)** | **[GitHub →](https://github.com/CipherIQ/crypto-tracer)**

---

### **4) pqc-flow**
**Passive network traffic analyzer for PQC detection**

Analyzes encrypted network flows to detect post-quantum cryptography support and negotiation in TLS 1.3, SSH, IKEv2, and QUIC protocols.

**Key capabilities:**

- **Passive inspection:** Analyzes first-flight packets without payload decryption
- **PQC detection:** Identifies ML-KEM, ML-DSA, and hybrid key exchange offers
- **Protocol support:** TLS 1.3, DTLS, SSH, IKEv2, QUIC
- **Minimal data capture:** Records handshake metadata only, not payload content
- **Real-time analysis:** Stream processing for live network monitoring
- **Pcap integration:** Works with existing packet capture infrastructure

**Perfect for:**

- Assessing PQC adoption across enterprise network infrastructure
- Monitoring quantum-safe migration progress at scale
- Identifying devices still using quantum-vulnerable key exchange
- Network security operations teams detecting cryptographic anomalies
- Incident response teams investigating TLS/SSH connection issues

**[Learn more →](./pqc-flow/index.md)** | **[GitHub →](https://github.com/CipherIQ/pqc-flow)**

---

## How They Work Together


### Complete Cryptographic Visibility Workflow

| Phase | Description |
|-------|-------------|
| **Phase 1: STATIC INVENTORY (Build/Deployment Time)** | cbom-generator scans firmware, containers, VM images<br>→ Output: firmware-v2.1.cbom.json<br>→ Contains: All crypto libraries, certs, keys, configs<br>→ PQC Score: 35/100 (HIGH RISK)<br>→ Shows what COULD be used |
| **Phase 2: VISUALIZATION & ANALYSIS** | cbom-explorer loads firmware-v2.1.cbom.json<br>→ Interactive graph: Shows nginx → TLS 1.3 → AES-256-GCM<br>→ Dashboard: 47 quantum-vulnerable assets flagged<br>→ Report: Generated for compliance team<br>→ Identifies: Priority remediation targets |
| **Phase 3: RUNTIME MONITORING (Production)** | crypto-tracer monitors device for 24 hours<br>→ Captures: Actual OpenSSL function calls<br>→ Discovers: TLS 1.2 negotiated despite TLS 1.3 config<br><br>pqc-flow analyzes network traffic<br>→ Detects: ClientHello offers ML-KEM, but server negotiates RSA<br>→ Records: 4,723 connections, 96% quantum-vulnerable |
| **Phase 4: DRIFT DETECTION & REMEDIATION** | Compare: firmware-v2.1.cbom.json (static)<br>vs: runtime-observations.json (actual behavior)<br><br>Finding: Configuration drift detected<br>- nginx.conf: TLS 1.3 required (SSLProtocol TLSv1.3)<br>- Runtime: 23% of connections negotiate TLS 1.2<br>- Root cause: Legacy load balancer allows protocol downgrade<br><br>Action: Update load balancer config, verify with pqc-flow |


### Real-World Example: Automotive Tier-1 Supplier

**Context:** Manufacturing ECU firmware for 15-year vehicle lifespan

**Step 1 - Build Phase:** Generate CBOM during firmware compilation
```bash
cbom-generator \
    --cross-arch --discover-services --plugin-dir plugins/embedded  \
    --crypto-registry registry/crypto-registry-yocto.yaml \
    --format cyclonedx --cyclonedx-spec=1.7  \
    --output ecu-v3.2.cbom..json  --rootfs-prefix $ROOTFS\
        $ROOTFS/usr/bin $ROOTFS/usr/sbin $ROOTFS/usr/lib $ROOTFS/etc
```

**Result:** CBOM shows OpenSSL 3.0.2 with RSA-2048 and ECDHE-P256 configured

**Step 2 - Pre-Release Review:** Visualize cryptographic architecture
```bash
xdg-open visualizer/cbom-viz.html
```
in the browser open: `ecu-v3.2.cbom.json`

**Insight:** Dashboard shows PQC readiness score: 40/100 (HIGH RISK for 15-year lifespan)

**Step 3 - Production Validation:** Monitor deployed test fleet
```bash
# On test vehicle gateway
crypto-tracer --duration 7days --output fleet-crypto.json

# On test lab network
pqc-flow -i eth0 --filter "host ecu-gateway" --duration 7days
```

**Discovery:** Despite TLS 1.3 configuration:
- 15% of dealer diagnostic connections still use TLS 1.2
- Root cause: Legacy scan tools from 2015 don't support TLS 1.3

**Action:** Document exception, plan dealer equipment upgrades, demonstrate compliance with runtime evidence

---

## Why CipherIQ?

### 1. **Built for Long-Lived Systems**

Unlike general-purpose security scanners, CipherIQ is purpose-built for organizations managing infrastructure with decade-plus lifespans:

- **IoT/OT devices:** 20-30 year operational lifetimes in the field
- **Medical devices:** 10-15 year FDA-approved service periods
- **Automotive ECUs:** 15-20 year vehicle lifespans
- **Industrial control systems:** 25-30 year production equipment cycles
- **Critical infrastructure:** 30+ year utility and telecommunications deployments

These systems cannot be easily updated and must be designed for quantum-resistance from day one.

### 2. **Standards-Based, Ecosystem-Friendly**

CipherIQ uses open standards to integrate seamlessly into existing workflows:

- **CycloneDX CBOM:** Industry-standard format compatible with SBOM ecosystems
- **JSON output:** Easy integration with SIEM, GRC, and vulnerability management tools
- **CI/CD plugins:** Native Yocto, Buildroot, OpenWrt, Docker, and Kubernetes integrations

### 3. **Privacy by Default**

CipherIQ is designed for security teams who respect user privacy:

- **Never exposes secrets:** Keys and passwords are hashed, not captured in plain text
- **Minimal data collection:** Only cryptographic metadata, not payload content
- **GDPR/CCPA compliant:** No personal data in CBOMs or runtime traces
- **On-premises deployment:** All tools run locally, no data sent to cloud services

### 4. **Open Source, Commercially Supported**

**GPL 3.0 licensed** - All four tools are free and open source

- Full-featured, production-ready code
- No proprietary "enterprise-only" limitations
- Community-driven development on GitHub
- Transparent roadmap and feature requests

**Commercial support available** - For organizations requiring:

- Professional SLA-backed support (email/Slack)
- Custom scanner development and integration services
- Compliance report templates (FDA, UN R155, IEC 62443, NIST)
- Priority feature requests and bug fixes
- Legal indemnification and warranties

---


## License

All CipherIQ tools are dual-licensed:


- **GPL 3.0** - Free for open-source use (copyleft applies when distributing)
- **Commercial license** -  For proprietary integration without copyleft obligations


### Open Source License

**GPL-3.0-or-later:**

- Free to use, modify, and distribute
- Must release modifications under GPL-3.0
- Source code must be made available
- See LICENSE file for full terms

**Key Points:**

- ✅ Use for any purpose
- ✅ Modify the source code
- ✅ Distribute copies
- ✅ Distribute modified versions
- ⚠️ Must disclose source
- ⚠️ Must use same license
- ⚠️ Must state changes

## Commercial License

**For proprietary use:**

- Use without GPL requirements
- No source code disclosure required
- Suitable for proprietary products
- Contact *sales@cipheriq.io* for pricing

### Regulatory Compliance Support

The commercial license provides the documentation, validation, and support necessary to 
demonstrate compliance with evolving cryptographic transparency mandates:

**FDA Section 524B (Medical Devices)**
- Since March 2023, FDA requires SBOMs for all "cyber devices" (network-capable medical 
  devices) as part of premarket submissions (510(k), PMA, De Novo)
- Submissions must document cryptographic controls, authentication mechanisms, and 
  encryption implementations per the Cybersecurity in Medical Devices guidance
- Submissions lacking adequate cybersecurity documentation receive Refuse to Accept (RTA) 
  letters, blocking market authorization
- CBOMs provide the cryptographic inventory needed to demonstrate compliance with FDA's 
  security architecture requirements and support total product lifecycle vulnerability management


**NIS2 Directive**
- Article 21 mandates formal policies for cryptography and encryption across 
  essential and important entities
- Requires supply chain security documentation and 24/72-hour incident reporting
- CBOMs enable rapid identification of vulnerable cryptographic components during incidents

**IEC 62443 (Industrial Cybersecurity)**
- IEC 62443-4-1 requires secure development lifecycle practices including cryptographic 
  asset documentation
- Security Levels 3 and 4 demand rigorous cryptographic controls and PKI management
- Our validated CBOMs support ISASecure® certification workflows


**EU Cyber Resilience Act (CRA)**
- The CRA requires manufacturers to document cryptographic components using SBOMs 
  in machine-readable formats (enforcement begins December 2027)
- Mandates state-of-the-art encryption and cryptographic lifecycle management
- Our commercial offering provides CRA-aligned CBOM outputs compliant with 
  BSI TR-03183-2 technical specifications

**Additional Frameworks**: OMB M-23-02, NIST SP 800-131A, PCI-DSS 4.0, DORA

#### Why Choose a Commercial License?

- **Compliance Documentation**: Pre-built attestation templates and audit-ready reports 
  aligned with CRA, NIS2, and IEC 62443 requirements
- **Validated Outputs**: CBOMs suitable for regulatory submissions, third-party audits, 
  and certification bodies
- **Enterprise Support**: Priority response SLAs, dedicated technical contacts, and 
  integration assistance
- **No Copyleft Obligations**: Integrate into proprietary products without GPL 
  disclosure requirements
- **Post-Quantum Readiness**: Continuous updates tracking NIST PQC standards and 
  cryptographic deprecation timelines
---

## Get Started

### Try the Tools

Each tool has its own documentation with installation guides, tutorials, and examples:

- **[cbom-generator Documentation →](./cbom-generator/index.md)**
- **[cbom-explorer Documentation →](./cbom-explorer/index.md)**
- **[crypto-tracer Documentation →](./crypto-tracer/index.md)**
- **[pqc-flow Documentation →](./pqc-flow/index.md)**

### Join the Community

- **GitHub Discussions:** Ask questions, share use cases at: [github.com/orgs/CipherIQ/discussions](https://github.com/orgs/CipherIQ/discussions)
- **Issue Trackers:** Report bugs or request features in individual repos as issues
- **Email:** *team@cipheriq.com*

### Commercial Support

For IoT/OT manufacturers and enterprises requiring a commercial license or professional support:

- **Email:** *sales@cipheriq.com*

## Further Resources

- [NIST Post-Quantum Cryptography Project](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [Open Quantum Safe Project](https://openquantumsafe.org/)
- [Cloudflare PQC Deployment](https://developers.cloudflare.com/ssl/post-quantum-cryptography/pqc-support/)
- [OpenSSH PQC Support](https://www.openssh.com/releasenotes.html)

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