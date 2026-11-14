-- Q11. Which categories combine high revenue with poor satisfaction?
-- These are the categories where fixing quality/logistics pays off most.
-- Techniques: multiple CTEs, joins across 5 tables, comparison to overall average.

WITH latest_review AS (
    SELECT order_id, review_score
    FROM (
        SELECT
            order_id,
            review_score,
            ROW_NUMBER() OVER (
                PARTITION BY order_id
                ORDER BY CAST(review_answer_timestamp AS TIMESTAMP) DESC
            ) AS rn
        FROM order_reviews
    )
    WHERE rn = 1
),
order_category AS (
    -- One row per order and category (an order can contain several categories).
    SELECT
        i.order_id,
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
        SUM(i.price)         AS revenue,
        SUM(i.freight_value) AS freight
    FROM order_items i
    JOIN v_delivered_orders d ON d.order_id = i.order_id
    JOIN products p           ON p.product_id = i.product_id
    LEFT JOIN category_translation t
           ON t.product_category_name = p.product_category_name
    GROUP BY 1, 2
),
category_stats AS (
    SELECT
        oc.category,
        COUNT(*)                                                    AS orders,
        SUM(oc.revenue)                                             AS revenue,
        AVG(r.review_score)                                         AS avg_review_score,
        100.0 * COUNT(*) FILTER (WHERE r.review_score <= 2)
              / NULLIF(COUNT(r.review_score), 0)                    AS bad_review_pct,
        100.0 * SUM(oc.freight) / NULLIF(SUM(oc.revenue), 0)        AS freight_to_revenue_pct
    FROM order_category oc
    LEFT JOIN latest_review r ON r.order_id = oc.order_id
    GROUP BY oc.category
    HAVING COUNT(*) >= 100
)
SELECT
    category,
    orders,
    ROUND(revenue, 2)                AS revenue,
    ROUND(avg_review_score, 2)       AS avg_review_score,
    ROUND(avg_review_score - AVG(avg_review_score) OVER (), 2) AS score_vs_category_avg,
    ROUND(bad_review_pct, 1)         AS bad_review_pct,
    ROUND(freight_to_revenue_pct, 1) AS freight_to_revenue_pct
FROM category_stats
ORDER BY avg_review_score ASC, revenue DESC;
