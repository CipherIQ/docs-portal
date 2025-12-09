# PQC-Specific Frameworks & Standards


This document provides a narrative overview of the relevant PQC-specific frameworks and standards.


Together, these PQC-focused frameworks define the modern requirement:
organizations must know exactly what cryptography they use today in order to upgrade it tomorrow.


## **NIST PQC Standards (FIPS 203, 204, 205)**

**Domain:** Global Cryptographic Standardization

**Scope:**

* Defines approved PQC algorithms (ML-KEM, ML-DSA, SPHINCS+)
* Introduces hybrid PQC/classical models
* Establishes timelines for replacing RSA/ECC

**CipherIQ Support:**

* Identifies systems still using classical crypto
* Highlights upgrade paths to NIST-approved PQC algorithms
* Maps dependencies requiring PQC replacements

**URL:**

* FIPS 203 (ML-KEM): [https://csrc.nist.gov/pubs/fips/203/final](https://csrc.nist.gov/pubs/fips/203/final)
* FIPS 204 (ML-DSA): [https://csrc.nist.gov/pubs/fips/204/final](https://csrc.nist.gov/pubs/fips/204/final)
* FIPS 205 (SPHINCS+): [https://csrc.nist.gov/pubs/fips/205/final](https://csrc.nist.gov/pubs/fips/205/final)

---

## **NIST IR 8413 – PQC Migration Planning**

**Domain:** Enterprise & Government PQC Readiness

**Scope:**

* Requires inventory of all cryptography
* Defines PQC readiness categories (DEPRECATED / TRANSITIONAL / ACCEPTABLE)
* Requires PQC migration roadmap

**CipherIQ Support:**

* Built-in PQC classifications (`cbom:pqc:status`)
* Produces migration roadmap and priority matrix

**URL:**
[https://csrc.nist.gov/pubs/ir/8413/final](https://csrc.nist.gov/pubs/ir/8413/final)

---

## **NIST SP 800-208 – Stateful Hash-Based Signatures**

**Domain:** PQC Signature Implementation

**Scope:**

* Operational guidelines for XMSS and LMS
* Key rotation and state management requirements

**CipherIQ Support:**

* Detects classical signature usage (RSA/ECDSA)
* Flags lack of PQC-compliant signature mechanisms

**URL:**
[https://csrc.nist.gov/pubs/sp/800/208/final](https://csrc.nist.gov/pubs/sp/800/208/final)

---

## **NSA CNSA 2.0**

**Domain:** U.S. National Security Systems

**Scope:**

* Mandates hybrid PQC cryptography for TLS, SSH, IKEv2
* Deprecates classical ECC and RSA for NSS
* Requires crypto modernization evidence

**CipherIQ Support:**

* Identifies forbidden algorithms
* Shows missing PQC/hybrid crypto in stacks

**URL:**
[https://media.defense.gov/2022/sep/07/2003070283/-1/-1/0/cnsa_2.0_factsheet.pdf](https://media.defense.gov/2022/sep/07/2003070283/-1/-1/0/cnsa_2.0_factsheet.pdf)

---

## **ETSI PQC (ETSI TC CYBER QSC)**

**Domain:** Telecom & European Critical Infrastructure

**Scope:**

* PQC migration guidelines
* Quantum-safe key management
* PQC/QKD integration

**CipherIQ Support:**

* Flags classical cryptography in telecom systems
* Provides migration data for ETSI QSC compliance

**URL:**
[https://www.etsi.org/committee/cyber-qsc](https://www.etsi.org/committee/cyber-qsc)

---

## **EU NIS2 & Cyber Resilience Act (CRA)**

**Domain:** EU Critical Infrastructure & Software Security

**Scope:**

* Requires “crypto agility”
* Requires SBOMs including cryptographic components
* Mandatory vulnerability reporting linked to crypto and PQC readiness

**CipherIQ Support:**

* Provides crypto inventory for CRA-compliant SBOMs
* Highlights crypto that violates “crypto agility” requirements

**URL:**

* NIS2: [https://eur-lex.europa.eu/eli/dir/2022/2555/oj](https://eur-lex.europa.eu/eli/dir/2022/2555/oj)
* CRA: [https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:52022PC0454](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:52022PC0454)

---

## **ISO/IEC PQC Evolution (e.g., 14888, 18033)**

**Domain:** Global Cryptographic Standards

**Scope:**

* Defines classical algorithms being sunset
* Supports transition toward PQC alternatives

**CipherIQ Support:**

* Flags outdated ISO-standardized crypto requiring modernization

**URL:**

* ISO/IEC 14888 (Signatures): [https://www.iso.org/standard/58526.html](https://www.iso.org/standard/58526.html)
* ISO/IEC 18033 (Encryption): [https://www.iso.org/standard/54531.html](https://www.iso.org/standard/54531.html)

---

## **GSMA FS.31 / 3GPP PQC Guidance**

**Domain:** Telecom & Mobile Networks

**Scope:**

* Introduces quantum-safe recommendations for 5G/6G
* Requires strong authentication and crypto upgrades

**CipherIQ Support:**

* Identifies outdated crypto in telecom infrastructure

**URL:**

* GSMA FS.31: [https://www.gsma.com/security/wp-content/uploads/2022/06/FS.31-v1.0.pdf](https://www.gsma.com/security/wp-content/uploads/2022/06/FS.31-v1.0.pdf)
* 3GPP SA3 Specs: [https://www.3gpp.org/specifications](https://www.3gpp.org/specifications)

---

## **Singapore CSA CLS (IoT PQC-readiness)**

**Domain:** IoT Security Certification

**Scope:**

* Requires modern cryptography for IoT devices
* Introduces PQC-readiness expectations for advanced certification levels

**CipherIQ Support:**

* Generates cryptographic inventories for IoT firmware
* Flags weak/legacy crypto in embedded environments

**URL:**
[https://www.csa.gov.sg/cls](https://www.csa.gov.sg/cls)

---

## **HR 7535 – FISMA Modernization**

**Domain:** Federal Cybersecurity

**Scope:**

* Continuous crypto monitoring
* Cryptographic asset inventory
* Mandatory POA&M and reporting

**CipherIQ Support:**

* Full cryptographic inventory
* Automated POA&M generation

**URL:**
[https://www.congress.gov/bill/117th-congress/house-bill/7535](https://www.congress.gov/bill/117th-congress/house-bill/7535)

---

## **NSM-10 – National Security Memorandum on PQC**

**Domain:** Federal PQC Migration

**Scope:**

* Full discovery of all cryptography
* PQC risk classification
* Migration planning & prioritization

**CipherIQ Support:**

* PQC scoring built in
* Migration roadmap automation

**URL:**
[https://www.whitehouse.gov/wp-content/uploads/2022/05/NSM-10.pdf](https://www.whitehouse.gov/wp-content/uploads/2022/05/NSM-10.pdf)

---

## **EO 14028 – Improving the Nation’s Cybersecurity**

**Domain:** Federal Supply-Chain Security

**Scope:**

* Mandatory SBOMs with cryptographic detail
* Provenance & secure configurations

**CipherIQ Support:**

* CBOM as the cryptographic SBOM subset
* SLSA provenance

**URL:**
[https://www.whitehouse.gov/briefing-room/presidential-actions/2021/05/12/executive-order-on-improving-the-nations-cybersecurity/](https://www.whitehouse.gov/briefing-room/presidential-actions/2021/05/12/executive-order-on-improving-the-nations-cybersecurity/)

---

## **FedRAMP / StateRAMP**

**Domain:** Cloud Authorizations

**Scope:**

* Strong encryption requirements
* FIPS-validated modules

**CipherIQ Support:**

* Detects non-FIPS modules and weak crypto

**URL:**

* FedRAMP Baselines: [https://www.fedramp.gov/baselines/](https://www.fedramp.gov/baselines/)
* StateRAMP Framework: [https://stateramp.org/framework/](https://stateramp.org/framework/)

---

## **NIST SP 800-53 Rev5 / 800-175 A/B**

**Domain:** Security Controls & Approved Crypto

**Scope:**

* Approved algorithms only
* Certificate validation
* Key management visibility

**CipherIQ Support:**

* Algorithm/OID detection
* Certificate trust chain mapping

**URL:**

* SP 800-53 Rev5: [https://csrc.nist.gov/pubs/sp/800/53/r5/final](https://csrc.nist.gov/pubs/sp/800/53/r5/final)
* SP 800-175A: [https://csrc.nist.gov/pubs/sp/800/175/a/final](https://csrc.nist.gov/pubs/sp/800/175/a/final)
* SP 800-175B: [https://csrc.nist.gov/pubs/sp/800/175/b/final](https://csrc.nist.gov/pubs/sp/800/175/b/final)

---


## **DISA STIGs (OS, Network, Application)**

**Domain:** DoD Hardening Standards

**Scope:**

* Strict crypto configuration
* Disallowed ciphers & protocols

**CipherIQ Support:**

* Detects non-compliant ciphers automatically

**URL:**
[https://public.cyber.mil/stigs/](https://public.cyber.mil/stigs/)

---


## **PCI DSS 4.0**

**Domain:** Payment Security

**Scope:**

* Strong crypto only (TLS 1.2+)
* No weak ciphers or certs

**CipherIQ Support:**

* Flags deprecated ciphers and cert weaknesses

**URL:**
[https://www.pcisecuritystandards.org/document_library](https://www.pcisecuritystandards.org/document_library)

---

## **ISO/IEC 27001 / 27002**

**Domain:** Global Information Security

**Scope:**

* Crypto control documentation
* Software inventory

**CipherIQ Support:**

* CBOM for audit evidence

**URL:**

* ISO 27001: [https://www.iso.org/standard/82875.html](https://www.iso.org/standard/82875.html)
* ISO 27002: [https://www.iso.org/standard/75652.html](https://www.iso.org/standard/75652.html)

---

## **SOC 2 (AICPA Trust Services Criteria)**

**Domain:** Enterprise Audits

**Scope:**

* Encryption everywhere
* Control maturity evidence

**CipherIQ Support:**

* Machine-generated crypto documentation

**URL:**
[https://www.aicpa.org/resources/article/trust-services-criteria](https://www.aicpa.org/resources/article/trust-services-criteria)

---

## **CSA Cloud Controls Matrix (CCM)**

**Domain:** Cloud Security

**Scope:**

* Crypto lifecycle management
* Component visibility

**CipherIQ Support:**

* Cryptographic inventory for CCM controls

**URL:**
[https://cloudsecurityalliance.org/artifacts/cloud-controls-matrix-v4/](https://cloudsecurityalliance.org/artifacts/cloud-controls-matrix-v4/)

---


## **GDPR (Art. 32)**

**Domain:** EU Privacy Law

**Scope:**

* “State-of-the-art” encryption
* Risk-based security controls

**CipherIQ Support:**

* Detects outdated crypto violating GDPR expectations

**URL:**
[https://eur-lex.eu.eu/eli/reg/2016/679/oj](https://eur-lex.eu.eu/eli/reg/2016/679/oj)

---

## **HIPAA Security Rule**

**Domain:** U.S. Healthcare

**Scope:**

* Strong encryption for PHI
* Documented safeguards

**CipherIQ Support:**

* Provides evidence of crypto strength

**URL:**
[https://www.hhs.gov/hipaa/for-professionals/security/laws-regulations/index.html](https://www.hhs.gov/hipaa/for-professionals/security/laws-regulations/index.html)

---

## **FDA Cybersecurity in Medical Devices (2023 Final Guidance)**

**Domain:** Medical Device Regulation

**Scope:**

* SBOM including cryptographic components
* Documentation of crypto controls
* Patchability & lifecycle management

**CipherIQ Support:**

* CBOM + certificate analysis + algorithm mapping

**URL:**

Main cybersecurity guidance (SBOM + cryptography):
[https://www.fda.gov/cybersecurity-medical-devices-quality-system-considerations-and-content-premarket-submissions](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/cybersecurity-medical-devices-quality-system-considerations-and-content-premarket-submissions)


---

## **IEC 62443**

**Domain:** OT / Industrial Cybersecurity

**Scope:**

* Crypto lifecycle requirements
* Secure component inventory

**CipherIQ Support:**

* Embedded cryptographic mapping

**URL:**
[https://webstore.iec.ch/publication/34421](https://webstore.iec.ch/publication/34421)

---

## **ISO 21434 / UNECE WP.29**

**Domain:** Automotive Cybersecurity

**Scope:**

* Crypto controls for ECUs
* Software inventory and updateability

**CipherIQ Support:**

* Cryptographic dependency mapping in embedded devices

**URL:**

* ISO 21434: [https://www.iso.org/standard/70918.html](https://www.iso.org/standard/70918.html)
* UNECE WP.29: [https://unece.org/transport/documents/2021/03/standards/un-regulation-no-155-cyber-security](https://unece.org/transport/documents/2021/03/standards/un-regulation-no-155-cyber-security)

---

## **GSMA NESAS / 3GPP SA3**

**Domain:** Telecom Security

**Scope:**

* Mandatory strong cryptography
* Certificate validation

**CipherIQ Support:**

* Detects weak ciphers & certificates in telecom systems

**URL:**

* GSMA NESAS: [https://www.gsma.com/security/nesas/](https://www.gsma.com/security/nesas/)
* 3GPP SA3: [https://www.3gpp.org/specifications](https://www.3gpp.org/specifications)

---


## **SLSA (Supply-chain Levels for Software Artifacts)**

**Domain:** Build Integrity

**Scope:**

* Provenance
* Build transparency

**CipherIQ Support:**

* Signed CBOMs + SLSA metadata

**URL:**
[https://slsa.dev](https://slsa.dev)

---

## **NIST SSDF (Secure Software Development Framework)**

**Domain:** Secure Development Practices

**Scope:**

* Identify components
* Manage cryptographic dependencies

**CipherIQ Support:**

* Full crypto component discovery

**URL:**
[https://csrc.nist.gov/pubs/sp/800/218/final](https://csrc.nist.gov/pubs/sp/800/218/final)

---

## **OWASP SCVS**

**Domain:** Component Verification

**Scope:**

* Dependency and cryptographic validation

**CipherIQ Support:**

* Cryptographic dependency graph

**URL:**
[https://owasp.org/www-project-software-component-verification-standard/](https://owasp.org/www-project-software-component-verification-standard/)

---
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