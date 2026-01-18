#!/bin/bash
#
# Test SQLinLean parser against a SQL corpus
#
# Usage:
#   ./scripts/test-corpus.sh spider    # Test against Spider dataset
#   ./scripts/test-corpus.sh wikisql   # Test against WikiSQL dataset
#   ./scripts/test-corpus.sh all       # Test all datasets
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/tests/data"
RESULTS_DIR="$PROJECT_DIR/tests/data/results"

mkdir -p "$RESULTS_DIR"

CORPUS=${1:-all}

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure parser is built
echo "Building SQLinLean..."
cd "$PROJECT_DIR"
lake build sqlinlean

test_spider() {
    echo ""
    echo "Testing Spider dataset..."

    if [ ! -f "$DATA_DIR/spider/train_spider.json" ]; then
        echo -e "${YELLOW}Spider dataset not found. Run: ./scripts/download-spider.sh${NC}"
        return 1
    fi

    # Extract queries from Spider JSON and test each
    # Spider format: {"query": "SELECT ...", "db_id": "...", ...}

    local total=0
    local passed=0
    local failed=0
    local failed_queries=""

    echo "Extracting queries from train_spider.json..."

    # Use Python to extract queries (more reliable JSON parsing)
    python3 -c "
import json
import sys

with open('$DATA_DIR/spider/train_spider.json') as f:
    data = json.load(f)

for item in data[:500]:  # Test first 500 for speed
    print(item['query'])
" | while read -r query; do
        ((total++)) || true

        # Test parsing (capture output)
        if echo "$query" | ./.lake/build/bin/sqlinlean --parse 2>/dev/null; then
            ((passed++)) || true
        else
            ((failed++)) || true
            failed_queries="$failed_queries\n$query"
        fi

        # Progress
        if [ $((total % 100)) -eq 0 ]; then
            echo "  Tested $total queries..."
        fi
    done

    echo ""
    echo "Spider Results:"
    echo "  Total:  $total"
    echo -e "  ${GREEN}Passed: $passed${NC}"
    echo -e "  ${RED}Failed: $failed${NC}"

    # Save results
    echo "{\"dataset\": \"spider\", \"total\": $total, \"passed\": $passed, \"failed\": $failed}" > "$RESULTS_DIR/spider-results.json"
}

test_wikisql() {
    echo ""
    echo "Testing WikiSQL dataset..."

    if [ ! -f "$DATA_DIR/wikisql/dev.jsonl" ]; then
        echo -e "${YELLOW}WikiSQL dataset not found. Run: ./scripts/download-wikisql.sh${NC}"
        return 1
    fi

    local total=0
    local passed=0
    local failed=0

    echo "Testing queries from dev.jsonl..."

    # WikiSQL format: {"sql": {"sel": 0, "conds": [...], "agg": 0}, "question": "..."}
    # Need to reconstruct SQL from the structured format or use a converter

    # For now, test with a simple extraction
    python3 -c "
import json
import sys

# WikiSQL stores SQL in structured form, not as strings
# We'll need to reconstruct or use their provided SQL strings
with open('$DATA_DIR/wikisql/dev.jsonl') as f:
    for i, line in enumerate(f):
        if i >= 500:  # Test first 500
            break
        item = json.loads(line)
        # WikiSQL has a 'query' field with the SQL string in some versions
        if 'query' in item:
            print(item['query'])
" 2>/dev/null | head -500 | while read -r query; do
        ((total++)) || true

        if echo "$query" | ./.lake/build/bin/sqlinlean --parse 2>/dev/null; then
            ((passed++)) || true
        else
            ((failed++)) || true
        fi
    done

    echo ""
    echo "WikiSQL Results:"
    echo "  Total:  $total"
    echo -e "  ${GREEN}Passed: $passed${NC}"
    echo -e "  ${RED}Failed: $failed${NC}"

    echo "{\"dataset\": \"wikisql\", \"total\": $total, \"passed\": $passed, \"failed\": $failed}" > "$RESULTS_DIR/wikisql-results.json"
}

case "$CORPUS" in
    spider)
        test_spider
        ;;
    wikisql)
        test_wikisql
        ;;
    all)
        test_spider
        test_wikisql
        ;;
    *)
        echo "Usage: $0 {spider|wikisql|all}"
        exit 1
        ;;
esac

echo ""
echo "Results saved to: $RESULTS_DIR/"
