#!/bin/bash
#
# Download WikiSQL dataset for SQL parser testing
# https://github.com/salesforce/WikiSQL
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/tests/data/wikisql"

echo "Downloading WikiSQL dataset..."

# Create directory if needed
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# WikiSQL URLs
BASE_URL="https://github.com/salesforce/WikiSQL/raw/master/data"

# Check if already downloaded
if [ -f "train.jsonl" ] && [ -f "dev.jsonl" ] && [ -f "test.jsonl" ]; then
    echo "WikiSQL dataset already exists in $DATA_DIR"
    echo "To re-download, remove the directory first: rm -rf $DATA_DIR"
    exit 0
fi

# Download files
download_file() {
    local filename=$1
    echo "  Downloading $filename..."
    if command -v wget &> /dev/null; then
        wget -q "$BASE_URL/$filename.gz" -O "$filename.gz"
    elif command -v curl &> /dev/null; then
        curl -sL "$BASE_URL/$filename.gz" -o "$filename.gz"
    else
        echo "Please install wget or curl"
        exit 1
    fi
    gunzip -f "$filename.gz"
}

download_file "train.jsonl"
download_file "dev.jsonl"
download_file "test.jsonl"
download_file "train.tables.jsonl"
download_file "dev.tables.jsonl"
download_file "test.tables.jsonl"

# Verify
if [ -f "train.jsonl" ] && [ -f "dev.jsonl" ] && [ -f "test.jsonl" ]; then
    echo "✓ WikiSQL dataset downloaded successfully"
    echo "  Location: $DATA_DIR"
    echo "  Files:"
    ls -la *.jsonl
    echo ""
    echo "  Query counts:"
    echo "    train: $(wc -l < train.jsonl) queries"
    echo "    dev:   $(wc -l < dev.jsonl) queries"
    echo "    test:  $(wc -l < test.jsonl) queries"
else
    echo "✗ Download may have failed - expected files not found"
    exit 1
fi
