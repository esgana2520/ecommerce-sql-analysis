-- Q8. How do customers pay, and do installments go with bigger baskets?
-- Techniques: aggregation, share of total, bucketing.

WITH order_payment AS (
    -- One row per order: its main payment type (largest amount) and totals.
    SELECT
        p.order_id,
        arg_max(p.payment_type, p.payment_value) AS main_payment_type,
        MAX(p.payment_installments)              AS installments,
        SUM(p.payment_value)                     AS paid
    FROM order_payments p
    JOIN v_delivered_orders d ON d.order_id = p.order_id
    GROUP BY p.order_id
)
SELECT
    main_payment_type,
    CASE
        WHEN main_payment_type <> 'credit_card' THEN 'n/a'
        WHEN installments <= 1  THEN '1 (single payment)'
        WHEN installments <= 3  THEN '2-3'
        WHEN installments <= 6  THEN '4-6'
        ELSE '7+'
    END                                                    AS installments_bucket,
    COUNT(*)                                               AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)     AS order_share_pct,
    ROUND(SUM(paid), 2)                                    AS total_paid,
    ROUND(100.0 * SUM(paid) / SUM(SUM(paid)) OVER (), 1)   AS paid_share_pct,
    ROUND(AVG(paid), 2)                                    AS avg_order_paid
FROM order_payment
GROUP BY 1, 2
ORDER BY total_paid DESC;
