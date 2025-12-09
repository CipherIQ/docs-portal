---
hide:
  - toc
---
# CBOM Explorer

A browser-based dashboard for exploring Cryptography Bills of Materials and assessing Post-Quantum Cryptography readiness.
                                                                                                                   
## What It Does                                                                                                       
                                                                                                                   
The CBOM Visualizer transforms JSON output from the CBOM Generator into interactive charts and reports. 
                                                                                                                   
- Assess quantum readiness with PQC status scoring and break year timelines                                        
- Track certificate expirations using visual heatmaps                                                              
- Analyze algorithm usage across your cryptographic inventory                                                      
- Plan migrations with timeline views and priority recommendations                                                 
- Search and export filtered subsets of your CBOM                                                                  
                                                                                                                   
## Quick Start                                                                                                        

### Repo
[CBOM Explorer Github](https://github.com/CipherIQ/cbom-explorer)
### 1. Generate a CBOM 
```                                                                                              
./cbom-generator /etc/ssl /usr/sbin \
    --format cyclonedx --cyclonedx-spec 1.7 \
    -o my-cbom.json
```
### 2. Open the visualizer
```
xdg-open cbom-explorer/cbom-viz.html   # Linux
open cbom-explorer/cbom-viz.html       # macOS
```
### 3. Upload your CBOM using the file picker

Dashboard Views

| View         | Purpose                                                       |
|--------------|---------------------------------------------------------------|
| Dashboard    | Overall PQC readiness score, risk level, and priority actions |
| Certificates | Expiration heatmap showing certificates by time to expiry     |
| Algorithms   | Distribution charts by type, key size, and frequency          |
| Timeline     | PQC migration milestones from 2025 to 2035+                   |
| Explorer     | Search, filter, and export individual components              |
| Summary      | Executive report for stakeholders                             |

### Understanding PQC Status

The visualizer uses color-coded categories based on NIST IR 8413: 

| Status       | Color  | Meaning                                                        |
|--------------|--------|----------------------------------------------------------------|
| SAFE         | Green  | Quantum-resistant algorithms (ML-KEM, ML-DSA, SLH-DSA)         |
| TRANSITIONAL | Yellow | Classical algorithms with adequate key sizes for near-term use |
| UNSAFE       | Red    | Vulnerable to quantum attacks, migration required              |
| DEPRECATED   | Red    | Weak by classical standards, replace immediately               |

### Break Year Estimates

Based on NSA CNSA 2.0 guidance for when algorithms become unsafe: 

| Algorithm              | Break Year |
|------------------------|------------|
| RSA-1024, small ECC    | 2030       |
| RSA-2048, standard ECC | 2035       |
| RSA-3072               | 2040       |
| RSA-4096               | 2045       |

### Key Features

- **Zero dependencies** - Single HTML file, works offline
- **Privacy-first** - All processing happens in your browser
- **Dark mode** - Toggle between light and dark themes
- **Export** - Download filtered results as JSON
- **Responsive** - Works on desktop, tablet, and mobile

### Supported Formats

- CycloneDX 1.6
- CycloneDX 1.7

### Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

### Testing the Visualizer

Test files are included in `cbom-explorer/test-cases/`:

| File             | Description                                | 
|------------------|--------------------------------------------| 
| ubuntu-cbom.json  | Large dataset for performance testing     | 

## Troubleshooting
                                                                                                                        
**"Invalid JSON" error**

Verify your file is valid CycloneDX:
```
cat your-cbom.json | jq '.specVersion'
```
Should output: "CycloneDX"

**Charts not rendering**

Open browser console (F12) and check for JavaScript errors. Ensure your CBOM contains components with cryptoProperties.

**Slow performance**

For CBOMs with 1000+ components, use the Explorer's filters to reduce the displayed set. Pagination limits display to 20 items per page.

**Certificates show "N/A" for expiration**

The asset is likely a Certificate Signing Request (CSR) or key file rather than an issued certificate.

### Architecture

The visualizer is a single HTML file (~2,500 lines) with embedded CSS and JavaScript:
```
cbom-viz.html
├── HTML Structure
│   ├── File upload interface
│   ├── Tab navigation (6 views)
│   └── Dynamic content areas
├── CSS (~800 lines)
│   ├── CipherIQ brand colors
│   ├── Dark mode support
│   └── Responsive breakpoints
└── JavaScript (~1,500 lines)
    ├── CBOMParser - Data parsing and queries
    ├── SVGChart - Pie and bar chart rendering
    └── View classes (Dashboard, Heatmap, etc.)
```
---
Copyright (c) 2025 Graziano Labs Corp.
