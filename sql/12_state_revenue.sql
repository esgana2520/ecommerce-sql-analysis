-- Q12. Where is the revenue? Geographic concentration by customer state.
-- Techniques: aggregation, ranking, share and cumulative share.

WITH by_state AS (
    SELECT
        customer_state,
        COUNT(*)                           AS orders,
        COUNT(DISTINCT customer_unique_id) AS customers,
        SUM(revenue)                       AS revenue,
        AVG(revenue)                       AS avg_order_value
    FROM v_order_revenue
    GROUP BY customer_state
)
SELECT
    RANK() OVER (ORDER BY revenue DESC)               AS revenue_rank,
    customer_state,
    orders,
    customers,
    ROUND(revenue, 2)                                 AS revenue,
    ROUND(avg_order_value, 2)                         AS avg_order_value,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)  AS revenue_share_pct,
    ROUND(
        100.0 * SUM(revenue) OVER (ORDER BY revenue DESC, customer_state)
        / SUM(revenue) OVER (),
        1
    )                                                 AS cumulative_share_pct
FROM by_state
ORDER BY revenue DESC, customer_state;
