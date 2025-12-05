# Multi-Site MkDocs Documentation Portal Setup

Instructions for setting up a CipherIQ documentation portal on GitHub Pages with custom domain `docs.cipheriq.io`.

## Architecture

```
docs.cipheriq.io/                    # Landing page (portal)
├── index.html                       # Links to all projects
├── cbom-generator/                  # Built from cryptoBOM repo
├── other-project/                   # Built from other-project repo
└── another-project/                 # Built from another-project repo
```

Each project:
- Has its own `mkdocs.yml` in its repo
- Builds independently via `mkdocs build`
- Deploys to a subdirectory on the docs site

---

## Step 1: Create the Portal Repository

Create a new GitHub repo: `cipheriq/docs-portal`

```bash
mkdir -p ~/Development/cipheriq/docs-portal
cd ~/Development/cipheriq/docs-portal
git init
```

---

## Step 2: Create Portal Files

### `mkdocs.yml`

```yaml
site_name: CipherIQ Documentation
site_description: Documentation portal for CipherIQ products
site_url: https://docs.cipheriq.io/

docs_dir: docs
site_dir: site

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
  palette:
    - scheme: default
      primary: indigo
      accent: indigo

nav:
  - Home: index.md

extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/cipheriq

copyright: Copyright &copy; 2025 Graziano Labs Corp.
```

### `docs/index.md`

```markdown
# CipherIQ Documentation

Welcome to the CipherIQ documentation portal.

---

## Products

### [CBOM Generator](./cbom-generator/)

Cryptographic Bill of Materials Generator for Post-Quantum Cryptography (PQC) readiness assessment.

- Inventories cryptographic assets on Linux systems
- CycloneDX 1.6/1.7 output format
- Service discovery with YAML plugins
- Privacy-by-default (GDPR/CCPA compliant)

---

## Quick Links

- [GitHub Organization](https://github.com/cipheriq)
- [Support](mailto:support@cipheriq.io)
```

### `requirements.txt`

```
mkdocs>=1.5
mkdocs-material>=9.0
mkdocs-minify-plugin>=0.7
```

### `scripts/build-portal.sh`

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTAL_DIR="$(dirname "$SCRIPT_DIR")"
SITE_DIR="$PORTAL_DIR/site"

echo "Building portal landing page..."
cd "$PORTAL_DIR"
mkdocs build

echo "Building CBOM Generator docs..."
cd ~/Development/cipheriq/cryptoBOM
mkdocs build
cp -r site "$SITE_DIR/cbom-generator"

# Add more projects here:
# echo "Building Other Project docs..."
# cd ~/Development/cipheriq/other-project
# mkdocs build
# cp -r site "$SITE_DIR/other-project"

echo "Portal built at $SITE_DIR"
echo "Run: python -m http.server -d $SITE_DIR 8000"
```

Make it executable:

```bash
chmod +x scripts/build-portal.sh
```

---

## Step 3: Create GitHub Actions Workflow

### `.github/workflows/deploy.yml`

```yaml
name: Deploy Docs Portal
on:
  push:
    branches: [main]
  workflow_dispatch:  # Manual trigger for rebuilds

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write

    steps:
      - name: Checkout portal repo
        uses: actions/checkout@v4

      - name: Checkout CBOM Generator docs
        uses: actions/checkout@v4
        with:
          repository: cipheriq/cryptoBOM
          path: projects/cryptoBOM
          sparse-checkout: |
            docs/pages
            mkdocs.yml

      # Add more project checkouts here:
      # - name: Checkout Other Project
      #   uses: actions/checkout@v4
      #   with:
      #     repository: cipheriq/other-project
      #     path: projects/other-project

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Build portal landing page
        run: mkdocs build

      - name: Build CBOM Generator docs
        run: |
          cd projects/cryptoBOM
          mkdocs build -d ../../site/cbom-generator

      # Add more project builds here:
      # - name: Build Other Project docs
      #   run: |
      #     cd projects/other-project
      #     mkdocs build -d ../../site/other-project

      - name: Add CNAME for custom domain
        run: echo "docs.cipheriq.io" > site/CNAME

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: site

      - name: Deploy to GitHub Pages
        uses: actions/deploy-pages@v4
```

---

## Step 4: Update CBOM Generator's mkdocs.yml

Add `site_url` to ensure links work when deployed to subdirectory:

```yaml
site_url: https://docs.cipheriq.io/cbom-generator/
```

---

## Step 5: Configure GitHub Pages

In the `cipheriq/docs-portal` repo settings:

1. Go to **Settings → Pages**
2. Source: **GitHub Actions**
3. Custom domain: `docs.cipheriq.io`
4. Enforce HTTPS: ✓

---

## Step 6: Configure DNS

At your DNS provider, add one of these records:

### Option A: CNAME record (recommended)

```
docs.cipheriq.io  CNAME  cipheriq.github.io
```

### Option B: A records (if CNAME not supported)

```
docs.cipheriq.io  A  185.199.108.153
docs.cipheriq.io  A  185.199.109.153
docs.cipheriq.io  A  185.199.110.153
docs.cipheriq.io  A  185.199.111.153
```

---

## Testing Locally

```bash
cd ~/Development/cipheriq/docs-portal
pip install -r requirements.txt
./scripts/build-portal.sh
python -m http.server -d site 8000
# Visit http://localhost:8000
```

---

## Manual Rebuild

When project docs change, trigger a rebuild:

```bash
# Via GitHub CLI
gh workflow run deploy.yml --repo cipheriq/docs-portal

# Or via web: Actions → Deploy Docs Portal → Run workflow
```

---

## Adding New Projects

1. Add checkout step in `.github/workflows/deploy.yml`
2. Add build step in the workflow
3. Add link in `docs/index.md`
4. Trigger rebuild
