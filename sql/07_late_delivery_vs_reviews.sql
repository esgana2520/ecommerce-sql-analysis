-- Q7. Does late delivery hurt customer satisfaction?
-- Techniques: de-duplicating with ROW_NUMBER, bucketing, conditional aggregation.

WITH latest_review AS (
    -- An order can have more than one review: keep the most recent.
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
bucketed AS (
    SELECT
        r.review_score,
        date_diff('day', o.estimated_delivery_at, o.delivered_at) AS days_late,
        CASE
            WHEN o.delivered_at <= o.estimated_delivery_at                         THEN '1. On time or early'
            WHEN date_diff('day', o.estimated_delivery_at, o.delivered_at) <= 3    THEN '2. 1-3 days late'
            WHEN date_diff('day', o.estimated_delivery_at, o.delivered_at) <= 7    THEN '3. 4-7 days late'
            ELSE '4. More than 7 days late'
        END AS delivery_bucket
    FROM v_order_revenue o
    JOIN latest_review r ON r.order_id = o.order_id
    WHERE o.delivered_at IS NOT NULL
)
SELECT
    delivery_bucket,
    COUNT(*)                                                         AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)               AS order_share_pct,
    ROUND(AVG(review_score), 2)                                      AS avg_review_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 1) AS bad_review_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score = 5) / COUNT(*), 1)  AS five_star_pct
FROM bucketed
GROUP BY delivery_bucket
ORDER BY delivery_bucket;
