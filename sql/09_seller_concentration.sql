-- Q9. How dependent is the marketplace on its top sellers?
-- Techniques: NTILE deciles, share-of-total windows.

WITH seller_revenue AS (
    SELECT
        i.seller_id,
        COUNT(DISTINCT i.order_id) AS orders,
        SUM(i.price)               AS revenue
    FROM order_items i
    JOIN v_delivered_orders d ON d.order_id = i.order_id
    GROUP BY i.seller_id
),
deciles AS (
    SELECT
        *,
        NTILE(10) OVER (ORDER BY revenue DESC) AS revenue_decile   -- 1 = top 10% of sellers
    FROM seller_revenue
)
SELECT
    revenue_decile,
    COUNT(*)                                                     AS sellers,
    ROUND(SUM(revenue), 2)                                       AS revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)   AS revenue_share_pct,
    ROUND(
        100.0 * SUM(SUM(revenue)) OVER (ORDER BY revenue_decile)
        / SUM(SUM(revenue)) OVER (),
        1
    )                                                            AS cumulative_share_pct,
    ROUND(AVG(revenue), 2)                                       AS avg_revenue_per_seller,
    ROUND(AVG(orders), 1)                                        AS avg_orders_per_seller
FROM deciles
GROUP BY revenue_decile
ORDER BY revenue_decile;
