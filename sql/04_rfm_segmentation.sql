-- Q4. Who are the most valuable customers? RFM segmentation.
-- Recency  = days since last order (relative to the last date in the data)
-- Frequency = number of delivered orders
-- Monetary  = total revenue
-- Techniques: NTILE window functions, CASE-based segmentation.

WITH reference AS (
    SELECT MAX(purchased_at) AS max_date FROM v_order_revenue
),
rfm AS (
    SELECT
        o.customer_unique_id,
        date_diff('day', MAX(o.purchased_at), r.max_date) AS recency_days,
        COUNT(*)                                          AS frequency,
        SUM(o.revenue)                                    AS monetary
    FROM v_order_revenue o
    CROSS JOIN reference r
    GROUP BY o.customer_unique_id, r.max_date
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- 5 = most recent
        NTILE(5) OVER (ORDER BY monetary)          AS m_score,  -- 5 = highest spend
        -- Most customers buy once, so NTILE on frequency would split ties arbitrarily.
        CASE WHEN frequency >= 3 THEN 5
             WHEN frequency = 2 THEN 4
             ELSE 1 END                            AS f_score
    FROM rfm
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN f_score >= 4                                   THEN 'Loyal'
            WHEN r_score >= 4 AND m_score >= 4                  THEN 'High-value new'
            WHEN r_score >= 4                                   THEN 'Recent low-spend'
            WHEN r_score <= 2 AND m_score >= 4                  THEN 'At risk (high value)'
            WHEN r_score <= 2                                   THEN 'Lost'
            ELSE 'Needs attention'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                                             AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS customer_share_pct,
    ROUND(SUM(monetary), 2)                              AS revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS revenue_share_pct,
    ROUND(AVG(monetary), 2)                              AS avg_spend,
    ROUND(AVG(recency_days), 0)                          AS avg_recency_days,
    ROUND(AVG(frequency), 2)                             AS avg_orders
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;
