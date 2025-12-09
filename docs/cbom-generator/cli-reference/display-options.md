---
hide:
  - toc
---
# Display Options

Control visual output and reporting.



## `--tui`

Enable Terminal User Interface with real-time progress display.

**Features**:

- Real-time progress bars for each scanner
- Live file counters and asset discovery counts
- Current directory being scanned
- Estimated completion percentage
- Asset breakdown by type (certs, keys, algorithms, libraries, protocols, services, cipher suites)
- Clean exit summary with PQC assessment

```bash
# Enable TUI mode
./build/cbom-generator --tui --output cbom.json

# TUI with specific directory
./build/cbom-generator --tui /etc/ssl

# TUI with multiple paths
./build/cbom-generator --tui --output cbom.json /etc/ssl /etc/pki /usr/share
```

**Display Layout**:
```
+- CBOM Generator ------------------------- CipherIQ v1.0.0 -+
| Progress: [####################] 100%       Time: 00:00:03 |
+- Scanning Progress ----------------------------------------+
| [X] Certificate Scanner  215000 files   193 certs          |
| [X] Key Scanner         216000 files     16 keys           |
| [X] Package Scanner     System-wide      125 pkgs          |
| [X] Service Scanner     System-wide      12 svcs           |
| [X] Filesystem Scanner  164000 files  3689 files           |
| [X] Output Generation   System-wide      1 output          |
+- Status ---------------------------------------------------|
| Total Assets: 289 (193 certs, 16 keys, 14 algos, ...)      |
| COMPLETE                                                   |
+-------------------------------------- Graziano Labs Corp. -+
  Press any key to exit
```

**Use when**:

- Interactive scans where you want to monitor progress
- Large directory scans (prevents "hanging" appearance)
- Demonstrations or presentations
- Real-time visibility into scanning status

**Note on Error Visibility**: In TUI mode, stderr is suppressed to prevent display corruption. </br>
Use `--error-log` to capture errors.

---

## `--pqc-report FILE`  

Generate comprehensive PQC migration report in human-readable text format.

**Features**:

- Executive summary with vulnerability breakdown
- Assets grouped by break year (2030/2035/2040/2045)
- Migration timeline with phased approach (2024-2045)
- NIST standards reference (FIPS 203/204/205)
- Prioritized recommendations and action items
- Risk assessment matrix
- Compliance guidance (NSA CNSA 2.0, FIPS 140-3)

```bash
# Generate CBOM + PQC migration report
./build/cbom-generator /etc/ssl/certs \
    --output cbom.json \
    --pqc-report migration-report.txt

# View migration priorities
cat migration-report.txt

# TUI mode with PQC report
./build/cbom-generator --tui \
    --output cbom.json \
    --pqc-report pqc-report.txt
```

**Sample Report Output**:
```
═══════════════════════════════════════════════════════════════
       POST-QUANTUM CRYPTOGRAPHY MIGRATION REPORT
═══════════════════════════════════════════════════════════════

EXECUTIVE SUMMARY
─────────────────
Total Cryptographic Assets: 351
PQC-Safe Assets: 1 (0.3%)
Quantum-Vulnerable Assets: 199 (56.7%)

VULNERABILITY BREAKDOWN BY BREAK YEAR
──────────────────────────────────────
CRITICAL (Break by 2030):    119 assets  [IMMEDIATE ACTION]
HIGH (Break by 2035):         64 assets  [PLAN MIGRATION NOW]
MEDIUM (Break by 2040):        0 assets  [MONITOR CLOSELY]
LOW (Break by 2045+):          0 assets  [LONG-TERM PLAN]
```

**Use Cases**:

- Executive briefings on quantum readiness
- Migration planning with timelines
- Compliance reporting (NSA CNSA 2.0 deadline tracking)
- Risk assessment and prioritization

---

## `--error-log FILE`

Write errors to a log file with timestamps (especially useful with `--tui`).

**Problem Solved**: In TUI mode, stderr output is suppressed to prevent display corruption. Without `--error-log`, errors are only visible in the final JSON output.

**Features**:

- ISO-8601 timestamps: `[YYYY-MM-DD HH:MM:SS]`
- Severity levels: `[error]`, `[warning]`
- Component name and detailed error message
- Immediate write with `fflush()` for real-time visibility
- Thread-safe operation

```bash
# TUI mode with error logging (recommended)
./build/cbom-generator --tui --error-log /tmp/cbom-errors.log --output cbom.json

# Monitor errors in real-time (separate terminal)
tail -f /tmp/cbom-errors.log

# Normal mode with error logging
./build/cbom-generator --error-log /tmp/cbom-errors.log --output cbom.json
```

**Error Log Format**:
```
[2025-11-15 14:33:01] [error] certificate_scanner: Certificate parsing failed: MEMORY_ERROR
[2025-11-15 14:33:02] [warning] key_scanner: Permission denied: /root/.ssh/id_rsa
```

**Real-Time Monitoring**:
```bash
# Start scan in one terminal
./build/cbom-generator --tui --error-log /tmp/errors.log --output cbom.json

# Monitor errors in another terminal
tail -f /tmp/errors.log
```
