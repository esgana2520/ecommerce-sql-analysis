-- Base views shared by every analysis query.
-- Revenue = sum of item prices (GMV, excluding freight) on DELIVERED orders.

CREATE OR REPLACE VIEW v_delivered_orders AS
SELECT
    o.order_id,
    c.customer_unique_id,                      -- the real customer key (customer_id is per order)
    c.customer_state,
    CAST(o.order_purchase_timestamp AS TIMESTAMP)      AS purchased_at,
    CAST(o.order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
    CAST(o.order_estimated_delivery_date AS TIMESTAMP) AS estimated_delivery_at,
    CAST(date_trunc('month', CAST(o.order_purchase_timestamp AS TIMESTAMP)) AS DATE) AS purchase_month
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered';

CREATE OR REPLACE VIEW v_order_revenue AS
SELECT
    d.order_id,
    d.customer_unique_id,
    d.customer_state,
    d.purchased_at,
    d.delivered_at,
    d.estimated_delivery_at,
    d.purchase_month,
    SUM(i.price)         AS revenue,
    SUM(i.freight_value) AS freight,
    COUNT(*)             AS items
FROM v_delivered_orders d
JOIN order_items i ON i.order_id = d.order_id
GROUP BY ALL;
