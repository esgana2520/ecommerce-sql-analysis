"""Run every analysis query in sql/ and export the results to output/ as CSV.

Usage:
    python scripts/run_analysis.py            # run all queries
    python scripts/run_analysis.py 03 04      # run only the queries starting with 03 and 04
"""
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "olist.duckdb"
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "output"


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit("Database not found. Run: python scripts/load_data.py")

    prefixes = sys.argv[1:]
    queries = sorted(p for p in SQL_DIR.glob("*.sql") if not p.name.startswith("00_"))
    if prefixes:
        queries = [p for p in queries if p.name.startswith(tuple(prefixes))]
    if not queries:
        raise SystemExit("No matching queries found in sql/.")

    OUT_DIR.mkdir(exist_ok=True)
    con = duckdb.connect(str(DB_PATH), read_only=True)

    for path in queries:
        df = con.execute(path.read_text(encoding="utf-8")).df()
        out = OUT_DIR / f"{path.stem}.csv"
        df.to_csv(out, index=False)
        print(f"\n=== {path.name}  ({len(df)} rows -> output/{out.name}) ===")
        print(df.head(15).to_string(index=False))

    con.close()


if __name__ == "__main__":
    main()
