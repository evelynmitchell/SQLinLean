#!/bin/bash
#
# Download Spider dataset for SQL parser testing
# https://yale-lily.github.io/spider
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/tests/data/spider"

echo "Downloading Spider dataset..."

# Create directory if needed
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# Spider dataset URL (from the official source)
SPIDER_URL="https://drive.google.com/uc?export=download&id=1iRDVHLr4mX2wQKSgA9J8Pire73Jahh0m"

# Check if already downloaded
if [ -f "train_spider.json" ] && [ -f "dev.json" ]; then
    echo "Spider dataset already exists in $DATA_DIR"
    echo "To re-download, remove the directory first: rm -rf $DATA_DIR"
    exit 0
fi

# Try downloading with gdown (handles Google Drive)
if command -v gdown &> /dev/null; then
    echo "Using gdown to download from Google Drive..."
    gdown "$SPIDER_URL" -O spider.zip
elif command -v wget &> /dev/null; then
    echo "Attempting direct download with wget..."
    echo "Note: Google Drive downloads may require gdown (pip install gdown)"
    wget --no-check-certificate "$SPIDER_URL" -O spider.zip || {
        echo "Direct download failed. Please install gdown:"
        echo "  pip install gdown"
        echo "Or download manually from: https://yale-lily.github.io/spider"
        exit 1
    }
else
    echo "Please install wget or gdown to download the dataset"
    echo "  pip install gdown"
    exit 1
fi

# Extract
echo "Extracting..."
unzip -q spider.zip
mv spider/* .
rmdir spider
rm spider.zip

# Verify
if [ -f "train_spider.json" ] && [ -f "dev.json" ]; then
    echo "✓ Spider dataset downloaded successfully"
    echo "  Location: $DATA_DIR"
    echo "  Files:"
    ls -la *.json 2>/dev/null | head -5
    echo ""
    echo "  Databases: $(ls -d database/*/ 2>/dev/null | wc -l)"
else
    echo "✗ Download may have failed - expected files not found"
    exit 1
fi
