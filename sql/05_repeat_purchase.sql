-- Q5. How much of the business comes from repeat customers?
-- Techniques: CTE, bucketing with CASE, share-of-total windows.

WITH per_customer AS (
    SELECT
        customer_unique_id,
        COUNT(*)     AS orders,
        SUM(revenue) AS revenue
    FROM v_order_revenue
    GROUP BY customer_unique_id
)
SELECT
    CASE WHEN orders = 1 THEN '1 order'
         WHEN orders = 2 THEN '2 orders'
         ELSE '3+ orders' END                                   AS purchase_frequency,
    COUNT(*)                                                    AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)          AS customer_share_pct,
    ROUND(SUM(revenue), 2)                                      AS revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2)  AS revenue_share_pct,
    ROUND(AVG(revenue), 2)                                      AS avg_lifetime_value
FROM per_customer
GROUP BY 1
ORDER BY 1;
