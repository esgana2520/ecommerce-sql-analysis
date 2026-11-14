-- Q10. When do customers buy? Orders by weekday and time of day.
-- Useful for scheduling campaigns and customer-support staffing.
-- Techniques: date parts, bucketing, share within group (PARTITION BY).

WITH tagged AS (
    SELECT
        isodow(purchased_at)  AS weekday_num,          -- 1 = Monday ... 7 = Sunday
        dayname(purchased_at) AS weekday,
        CASE
            WHEN hour(purchased_at) < 6  THEN '1. Night (00-06)'
            WHEN hour(purchased_at) < 12 THEN '2. Morning (06-12)'
            WHEN hour(purchased_at) < 18 THEN '3. Afternoon (12-18)'
            ELSE '4. Evening (18-24)'
        END                   AS day_part,
        revenue
    FROM v_order_revenue
)
SELECT
    weekday_num,
    weekday,
    day_part,
    COUNT(*)                                                               AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                     AS share_of_all_orders_pct,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY weekday_num), 1) AS share_within_day_pct,
    ROUND(AVG(revenue), 2)                                                 AS avg_order_value
FROM tagged
GROUP BY weekday_num, weekday, day_part
ORDER BY weekday_num, day_part;
