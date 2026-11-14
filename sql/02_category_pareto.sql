-- Q2. Which product categories drive revenue? How concentrated is it (Pareto)?
-- Techniques: multi-table joins, COALESCE, running total window.

WITH category_revenue AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
        COUNT(DISTINCT i.order_id) AS orders,
        SUM(i.price)               AS revenue
    FROM order_items i
    JOIN v_delivered_orders d ON d.order_id = i.order_id
    JOIN products p           ON p.product_id = i.product_id
    LEFT JOIN category_translation t
           ON t.product_category_name = p.product_category_name
    GROUP BY 1
)
SELECT
    RANK() OVER (ORDER BY revenue DESC)                          AS revenue_rank,
    category,
    orders,
    ROUND(revenue, 2)                                            AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)             AS revenue_share_pct,
    ROUND(
        100.0 * SUM(revenue) OVER (ORDER BY revenue DESC, category)
        / SUM(revenue) OVER (),
        1
    )                                                            AS cumulative_share_pct
FROM category_revenue
ORDER BY revenue DESC, category;
