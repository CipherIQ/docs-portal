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