-- Q3. Do customers come back? Monthly cohort retention.
-- A cohort = customers whose FIRST delivered order was in that month.
-- Techniques: CTEs, date arithmetic, conditional aggregation.

WITH first_purchase AS (
    SELECT
        customer_unique_id,
        MIN(purchase_month) AS cohort_month
    FROM v_order_revenue
    GROUP BY customer_unique_id
),
activity AS (
    SELECT DISTINCT
        o.customer_unique_id,
        f.cohort_month,
        date_diff('month', f.cohort_month, o.purchase_month) AS months_since_first
    FROM v_order_revenue o
    JOIN first_purchase f USING (customer_unique_id)
)
SELECT
    cohort_month,
    COUNT(*) FILTER (WHERE months_since_first = 0) AS cohort_size,
    ROUND(100.0 * COUNT(*) FILTER (WHERE months_since_first = 1)
          / COUNT(*) FILTER (WHERE months_since_first = 0), 2) AS retained_m1_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE months_since_first = 2)
          / COUNT(*) FILTER (WHERE months_since_first = 0), 2) AS retained_m2_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE months_since_first = 3)
          / COUNT(*) FILTER (WHERE months_since_first = 0), 2) AS retained_m3_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE months_since_first = 6)
          / COUNT(*) FILTER (WHERE months_since_first = 0), 2) AS retained_m6_pct,
    ROUND(100.0 * COUNT(DISTINCT customer_unique_id) FILTER (WHERE months_since_first > 0)
          / COUNT(*) FILTER (WHERE months_since_first = 0), 2) AS ever_returned_pct
FROM activity
GROUP BY cohort_month
ORDER BY cohort_month;
