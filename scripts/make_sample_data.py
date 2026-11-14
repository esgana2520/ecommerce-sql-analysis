"""Generate a small SYNTHETIC dataset with the same schema as the Olist CSVs.

This is only for smoke-testing the pipeline and the SQL queries without a
Kaggle account. The numbers it produces are random and mean nothing:
all findings in the README come from the real Olist dataset.

Usage:
    python scripts/make_sample_data.py            # writes to data/raw/
    python scripts/make_sample_data.py --orders 5000
"""
import argparse
import csv
import random
import uuid
from datetime import datetime, timedelta
from pathlib import Path

RAW_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"

STATES = ["SP", "RJ", "MG", "RS", "PR", "SC", "BA", "PE", "CE", "AM"]
STATE_WEIGHTS = [42, 13, 12, 6, 5, 4, 4, 2, 2, 1]
CATEGORIES = {
    "beleza_saude": "health_beauty",
    "relogios_presentes": "watches_gifts",
    "cama_mesa_banho": "bed_bath_table",
    "esporte_lazer": "sports_leisure",
    "informatica_acessorios": "computers_accessories",
    "moveis_decoracao": "furniture_decor",
    "utilidades_domesticas": "housewares",
    "brinquedos": "toys",
}
PAYMENT_TYPES = ["credit_card", "boleto", "voucher", "debit_card"]
PAYMENT_WEIGHTS = [74, 19, 5, 2]
FMT = "%Y-%m-%d %H:%M:%S"


def uid() -> str:
    return uuid.uuid4().hex


def write(name: str, header: list[str], rows: list[list]) -> None:
    with open(RAW_DIR / name, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"{name:<45}{len(rows):>8,} rows")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--orders", type=int, default=3000)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    random.seed(args.seed)
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    existing = list(RAW_DIR.glob("olist_*.csv"))
    if existing:
        raise SystemExit(
            "data/raw/ already contains Olist CSV files. "
            "Refusing to overwrite them with synthetic data."
        )

    sellers = [[uid(), "01000", "sao paulo", random.choices(STATES, STATE_WEIGHTS)[0]]
               for _ in range(120)]
    write("olist_sellers_dataset.csv",
          ["seller_id", "seller_zip_code_prefix", "seller_city", "seller_state"], sellers)

    products = []
    for _ in range(400):
        cat = random.choice(list(CATEGORIES))
        products.append([uid(), cat, 40, 500, 2, random.randint(100, 5000), 20, 10, 15])
    write("olist_products_dataset.csv",
          ["product_id", "product_category_name", "product_name_lenght",
           "product_description_lenght", "product_photos_qty", "product_weight_g",
           "product_length_cm", "product_height_cm", "product_width_cm"], products)
    write("product_category_name_translation.csv",
          ["product_category_name", "product_category_name_english"],
          [[k, v] for k, v in CATEGORIES.items()])

    # ~8% of people buy more than once
    people = [(uid(), random.choices(STATES, STATE_WEIGHTS)[0])
              for _ in range(int(args.orders * 0.93))]
    # Sellers and products are unevenly popular (long tail)
    seller_w = [1 / (i + 1) for i in range(len(sellers))]
    product_w = [1 / (i + 1) ** 0.7 for i in range(len(products))]

    customers, orders, items, payments, reviews = [], [], [], [], []
    start = datetime(2017, 1, 1)
    for n in range(args.orders):
        person, state = people[n] if n < len(people) else random.choice(people)
        customer_id, order_id = uid(), uid()
        customers.append([customer_id, person, "01000", "cidade", state])

        purchased = start + timedelta(days=random.uniform(0, 600),
                                      hours=random.gauss(15, 4))
        status = random.choices(["delivered", "canceled", "shipped"], [96, 2, 2])[0]
        estimated = purchased + timedelta(days=random.randint(15, 30))
        delivery_days = max(1.0, random.gauss(12, 7) + (6 if state in ("AM", "CE", "PE", "BA") else 0))
        delivered = purchased + timedelta(days=delivery_days) if status == "delivered" else None
        orders.append([
            order_id, customer_id, status, purchased.strftime(FMT),
            (purchased + timedelta(hours=1)).strftime(FMT),
            (purchased + timedelta(days=2)).strftime(FMT),
            delivered.strftime(FMT) if delivered else "",
            estimated.strftime(FMT),
        ])

        total = 0.0
        for item_no in range(1, random.choices([1, 2, 3], [85, 12, 3])[0] + 1):
            product = random.choices(products, product_w)[0]
            seller = random.choices(sellers, seller_w)[0]
            price = round(random.lognormvariate(4.3, 0.8), 2)
            freight = round(random.uniform(8, 40), 2)
            total += price + freight
            items.append([order_id, item_no, product[0], seller[0],
                          (purchased + timedelta(days=5)).strftime(FMT), price, freight])

        ptype = random.choices(PAYMENT_TYPES, PAYMENT_WEIGHTS)[0]
        installments = random.choice([1, 1, 1, 2, 3, 4, 6, 8, 10]) if ptype == "credit_card" else 1
        payments.append([order_id, 1, ptype, installments, round(total, 2)])

        if status == "delivered" and random.random() < 0.97:
            late = delivered > estimated
            score = random.choices([1, 2, 3, 4, 5],
                                   [45, 12, 13, 12, 18] if late else [6, 3, 8, 20, 63])[0]
            created = delivered + timedelta(days=1)
            reviews.append([uid(), order_id, score, "", "",
                            created.strftime(FMT),
                            (created + timedelta(days=2)).strftime(FMT)])

    write("olist_customers_dataset.csv",
          ["customer_id", "customer_unique_id", "customer_zip_code_prefix",
           "customer_city", "customer_state"], customers)
    write("olist_orders_dataset.csv",
          ["order_id", "customer_id", "order_status", "order_purchase_timestamp",
           "order_approved_at", "order_delivered_carrier_date",
           "order_delivered_customer_date", "order_estimated_delivery_date"], orders)
    write("olist_order_items_dataset.csv",
          ["order_id", "order_item_id", "product_id", "seller_id",
           "shipping_limit_date", "price", "freight_value"], items)
    write("olist_order_payments_dataset.csv",
          ["order_id", "payment_sequential", "payment_type",
           "payment_installments", "payment_value"], payments)
    write("olist_order_reviews_dataset.csv",
          ["review_id", "order_id", "review_score", "review_comment_title",
           "review_comment_message", "review_creation_date",
           "review_answer_timestamp"], reviews)
    print("\nSynthetic sample written to data/raw/ (for testing only).")


if __name__ == "__main__":
    main()
