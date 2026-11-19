with source as (

    select * from {{ ref('raw_orders') }}

),

renamed as (

    select
        cast(order_id as varchar) as order_id,
        cast(customer_id as varchar) as customer_id,
        cast(ordered_at as timestamp) as ordered_at,
        lower(trim(status)) as order_status,
        lower(trim(payment_method)) as payment_method,
        upper(trim(currency)) as currency_code,
        cast(subtotal_amount as decimal(12, 2)) as subtotal_amount,
        cast(discount_amount as decimal(12, 2)) as discount_amount,
        cast(tax_amount as decimal(12, 2)) as tax_amount,
        cast(shipping_amount as decimal(12, 2)) as shipping_amount,
        cast(refund_amount as decimal(12, 2)) as refund_amount,
        cast(updated_at as timestamp) as updated_at

    from source

)

select * from renamed
