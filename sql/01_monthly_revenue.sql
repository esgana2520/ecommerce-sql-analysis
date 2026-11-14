-- Q1. How are revenue, order volume and average order value evolving month by month?
-- Techniques: aggregation, window function (LAG) for month-over-month growth.

WITH monthly AS (
    SELECT
        purchase_month,
        COUNT(*)                    AS orders,
        COUNT(DISTINCT customer_unique_id) AS customers,
        ROUND(SUM(revenue), 2)      AS revenue,
        ROUND(AVG(revenue), 2)      AS avg_order_value
    FROM v_order_revenue
    GROUP BY purchase_month
)
SELECT
    purchase_month,
    orders,
    customers,
    revenue,
    avg_order_value,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY purchase_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY purchase_month), 0),
        1
    ) AS revenue_mom_growth_pct,
    ROUND(SUM(revenue) OVER (ORDER BY purchase_month), 2) AS cumulative_revenue
FROM monthly
ORDER BY purchase_month;
