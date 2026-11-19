with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

enriched as (

    select
        orders.order_id,
        orders.customer_id,
        customers.country as customer_country,
        customers.signup_date as customer_signup_date,
        orders.ordered_at,
        cast(orders.ordered_at as date) as order_date,
        orders.order_status,
        orders.payment_method,
        orders.currency_code,
        orders.subtotal_amount,
        orders.discount_amount,
        orders.tax_amount,
        orders.shipping_amount,
        orders.subtotal_amount
            - orders.discount_amount
            + orders.tax_amount
            + orders.shipping_amount as order_total_amount,
        orders.refund_amount,
        orders.order_status = 'cancelled' as is_cancelled,
        orders.order_status = 'returned' as is_returned,
        orders.order_status in ('paid', 'shipped', 'delivered', 'returned') as is_revenue_eligible,
        date_diff(
            'day',
            customers.signup_date,
            cast(orders.ordered_at as date)
        ) as days_since_signup,
        orders.updated_at

    from orders
    left join customers
        on orders.customer_id = customers.customer_id

)

select
    order_id,
    customer_id,
    customer_country,
    customer_signup_date,
    ordered_at,
    order_date,
    order_status,
    payment_method,
    currency_code,
    subtotal_amount,
    discount_amount,
    tax_amount,
    shipping_amount,
    order_total_amount,
    refund_amount,
    case
        when is_cancelled then cast(0 as decimal(12, 2))
        else order_total_amount - refund_amount
    end as recognized_revenue_amount,
    is_cancelled,
    is_returned,
    is_revenue_eligible,
    days_since_signup,
    updated_at

from enriched
