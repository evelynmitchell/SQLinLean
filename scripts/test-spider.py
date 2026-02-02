#!/usr/bin/env python3
"""
Test SQLinLean parser against Spider dataset.

Usage:
    python3 scripts/test-spider.py [--limit N] [--categorize]
"""

import json
import subprocess
import argparse
from collections import Counter
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
SPIDER_DATA = PROJECT_ROOT / "tests/data/spider/train_spider.json"
PARSER_BIN = PROJECT_ROOT / ".lake/build/bin/sqlinlean"


def test_query(query: str) -> bool:
    """Return True if query parses successfully."""
    result = subprocess.run(
        [str(PARSER_BIN), "--parse"],
        input=query,
        capture_output=True,
        text=True
    )
    return result.returncode == 0


def categorize_failure(query: str) -> str:
    """Categorize why a query likely failed."""
    q = query.upper()

    # Check for subquery (nested SELECT)
    if 'SELECT' in q and '(' in q:
        paren_idx = q.index('(')
        if paren_idx + 1 < len(q):
            after_paren = q[paren_idx + 1:]
            if 'SELECT' in after_paren:
                return 'Subquery'

    if ' EXCEPT ' in q:
        return 'EXCEPT'
    if ' UNION ' in q:
        return 'UNION'
    if ' INTERSECT ' in q:
        return 'INTERSECT'
    if 'CASE ' in q or ' WHEN ' in q:
        return 'CASE/WHEN'
    if ' || ' in q:
        return 'String concat (||)'
    # Check for problematic double-quote usage: empty quotes or unbalanced quotes
    if '""' in query or (query.count('"') % 2 != 0):
        return 'Double-quoted strings'

    return 'Other'


def main():
    parser = argparse.ArgumentParser(description='Test SQLinLean against Spider')
    parser.add_argument('--limit', type=int, default=500, help='Number of queries to test')
    parser.add_argument('--categorize', action='store_true', help='Categorize failures')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show failed queries')
    args = parser.parse_args()

    if not SPIDER_DATA.exists():
        print(f"Error: Spider data not found at {SPIDER_DATA}")
        print("Run: ./scripts/download-spider.sh")
        return 1

    if not PARSER_BIN.exists():
        print(f"Error: Parser not built. Run: lake build sqlinlean")
        return 1

    with open(SPIDER_DATA) as f:
        data = json.load(f)

    total = 0
    passed = 0
    failures = []

    limit = min(args.limit, len(data))

    for item in data[:limit]:
        query = item['query']
        total += 1

        if test_query(query):
            passed += 1
        else:
            failures.append(query)

        if total % 100 == 0:
            print(f"Tested {total}/{limit}... ({passed} passed, {100*passed/total:.1f}%)")

    # Results
    print(f"\n{'='*50}")
    print(f"Spider Corpus Test Results")
    print(f"{'='*50}")
    print(f"Total:  {total}")
    print(f"Passed: {passed} ({100*passed/total:.1f}%)")
    print(f"Failed: {len(failures)} ({100*len(failures)/total:.1f}%)")

    if args.categorize and failures:
        print(f"\n{'='*50}")
        print("Failure Categories")
        print(f"{'='*50}")
        categories = Counter(categorize_failure(q) for q in failures)
        for cat, count in categories.most_common():
            print(f"  {cat}: {count} ({100*count/len(failures):.1f}% of failures)")

    if args.verbose and failures:
        print(f"\n{'='*50}")
        print(f"Sample Failures (first 20)")
        print(f"{'='*50}")
        for q in failures[:20]:
            print(f"  - {q[:100]}{'...' if len(q) > 100 else ''}")

    return 0


if __name__ == '__main__':
    exit(main())
