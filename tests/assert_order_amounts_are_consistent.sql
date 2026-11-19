-- Recognized revenue follows the mart rule, and component amounts stay consistent.
select
    order_id,
    order_total_amount,
    refund_amount,
    recognized_revenue_amount
from {{ ref('fct_orders') }}
where
    refund_amount > order_total_amount
    or discount_amount > subtotal_amount
    or order_total_amount < 0
    or recognized_revenue_amount < 0
    or days_since_signup < 0
    or recognized_revenue_amount <> case
        when is_cancelled then cast(0 as decimal(12, 2))
        else order_total_amount - refund_amount
    end
