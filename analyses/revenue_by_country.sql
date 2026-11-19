select
    customer_country,
    currency_code,
    count(*) as order_count,
    count(*) filter (where not is_cancelled) as non_cancelled_order_count,
    sum(recognized_revenue_amount) as recognized_revenue_amount

from {{ ref('fct_orders') }}
group by 1, 2
order by recognized_revenue_amount desc
