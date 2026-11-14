"""Load the Olist CSV files from data/raw/ into a local DuckDB database.

Usage:
    python scripts/load_data.py
"""
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
DB_PATH = ROOT / "data" / "olist.duckdb"
VIEWS_SQL = ROOT / "sql" / "00_views.sql"

# table name -> CSV file name
TABLES = {
    "customers": "olist_customers_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}


def main() -> None:
    missing = [f for f in TABLES.values() if not (RAW_DIR / f).exists()]
    if missing:
        raise SystemExit(
            "Missing CSV files in data/raw/:\n  - "
            + "\n  - ".join(missing)
            + "\nRun scripts/download_data.py or see the README."
        )

    con = duckdb.connect(str(DB_PATH))
    for table, filename in TABLES.items():
        path = (RAW_DIR / filename).as_posix()
        con.execute(
            f"CREATE OR REPLACE TABLE {table} AS "
            f"SELECT * FROM read_csv_auto('{path}', header = true)"
        )
        rows = con.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
        print(f"{table:<22}{rows:>10,} rows")

    con.execute(VIEWS_SQL.read_text(encoding="utf-8"))
    print(f"\nViews created. Database ready: {DB_PATH.relative_to(ROOT)}")
    con.close()


if __name__ == "__main__":
    main()
