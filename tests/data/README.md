# SQL Test Corpora

Real-world SQL datasets for testing the SQLinLean parser.

## Datasets

| Directory | Dataset | Description | Size |
|-----------|---------|-------------|------|
| `spider/` | [Spider](https://yale-lily.github.io/spider) | Text-to-SQL benchmark, 200 DBs | 10K+ queries |
| `wikisql/` | [WikiSQL](https://github.com/salesforce/WikiSQL) | Single-table queries | 80K queries |
| `github-samples/` | GitHub scrape | .sql files from open source | Variable |
| `custom/` | Manual tests | Hand-crafted edge cases | - |

## Setup

```bash
# Download Spider dataset
./scripts/download-spider.sh

# Download WikiSQL dataset
./scripts/download-wikisql.sh
```

## Usage

Run parser against a corpus:
```bash
lake build
./scripts/test-corpus.sh spider
```

## Data Format

### Spider
```
spider/
├── database/           # Schema DDL for each database
│   ├── academic/
│   ├── concert_singer/
│   └── ...
├── train_spider.json   # Training queries with labels
├── dev.json            # Development set
└── tables.json         # Schema metadata
```

### WikiSQL
```
wikisql/
├── train.jsonl
├── dev.jsonl
└── test.jsonl
```

## Statistics Tracking

After running tests, results are saved to:
- `results/spider-results.json`
- `results/wikisql-results.json`

Track:
- Parse success rate
- Failure categories (lexer vs parser)
- Unsupported features (which SQL constructs fail)
