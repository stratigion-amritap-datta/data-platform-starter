with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_stats as (

    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(*) as lifetime_order_count,
        count(*) filter (where not is_cancelled) as lifetime_non_cancelled_order_count,
        sum(order_total_amount) as lifetime_order_total_amount,
        sum(recognized_revenue_amount) as lifetime_recognized_revenue_amount

    from orders
    group by customer_id

)

select
    customers.customer_id,
    customers.first_name,
    customers.last_name,
    customers.first_name || ' ' || customers.last_name as full_name,
    customers.email,
    customers.country,
    customers.signup_date,
    order_stats.first_order_date,
    order_stats.last_order_date,
    coalesce(order_stats.lifetime_order_count, 0) as lifetime_order_count,
    coalesce(order_stats.lifetime_non_cancelled_order_count, 0) as lifetime_non_cancelled_order_count,
    cast(
        coalesce(order_stats.lifetime_order_total_amount, 0) as decimal(12, 2)
    ) as lifetime_order_total_amount,
    cast(
        coalesce(order_stats.lifetime_recognized_revenue_amount, 0) as decimal(12, 2)
    ) as lifetime_recognized_revenue_amount,
    order_stats.customer_id is not null as has_ordered,
    customers.updated_at

from customers
left join order_stats
    on customers.customer_id = order_stats.customer_id
