"""Download the Olist Brazilian E-Commerce dataset from Kaggle into data/raw/.

Requires a Kaggle API token at ~/.kaggle/kaggle.json
(Kaggle -> Settings -> API -> Create New Token).

If you prefer, download the ZIP manually from
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
and extract the CSV files into data/raw/.
"""
from pathlib import Path

RAW_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"
DATASET = "olistbr/brazilian-ecommerce"


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    try:
        from kaggle.api.kaggle_api_extended import KaggleApi
    except ImportError:
        raise SystemExit("Install requirements first: pip install -r requirements.txt")

    api = KaggleApi()
    api.authenticate()
    print(f"Downloading {DATASET} -> {RAW_DIR}")
    api.dataset_download_files(DATASET, path=str(RAW_DIR), unzip=True)
    files = sorted(p.name for p in RAW_DIR.glob("*.csv"))
    print(f"Done. {len(files)} CSV files:")
    for f in files:
        print("  -", f)


if __name__ == "__main__":
    main()
