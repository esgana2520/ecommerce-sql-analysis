-- Q6. Where is delivery slow or late? Performance by customer state.
-- Techniques: date arithmetic, conditional aggregation, HAVING.

SELECT
    customer_state,
    COUNT(*)                                                         AS orders,
    ROUND(AVG(date_diff('day', purchased_at, delivered_at)), 1)      AS avg_delivery_days,
    ROUND(MEDIAN(date_diff('day', purchased_at, delivered_at)), 1)   AS median_delivery_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delivered_at > estimated_delivery_at)
          / COUNT(*), 1)                                             AS late_pct,
    ROUND(AVG(freight), 2)                                           AS avg_freight,
    ROUND(100.0 * SUM(freight) / NULLIF(SUM(revenue), 0), 1)         AS freight_to_revenue_pct
FROM v_order_revenue
WHERE delivered_at IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 50          -- ignore states with too few orders to be meaningful
ORDER BY late_pct DESC;
