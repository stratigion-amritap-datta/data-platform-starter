{#
    Incremental strategy: merge on order_id.

    The first run builds the whole table. Later runs re-merge only orders
    whose source updated_at falls inside the lookback window:
    max(updated_at) already in this table, minus orders_lookback_days
    (default 2). Merge updates a matched order_id and inserts a new one.
    Rows outside the window are left as stored, including dbt_updated_at.

    A filter of updated_at > max(updated_at) would miss a late fulfillment
    correction whose timestamp is already behind the watermark. Two days
    covers a missed daily run plus a day of late extracts. Widen
    orders_lookback_days, or full-refresh, when the window cannot reach
    the rows that changed.
#}

{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='order_id',
        on_schema_change='sync_all_columns'
    )
}}

with enriched as (

    select * from {{ ref('int_orders_enriched') }}

),

-- Lookback predicate. Applied only after the table exists.
windowed as (

    select * from enriched

    {% if is_incremental() %}
    where updated_at >= (
        select
            coalesce(
                max(updated_at) - interval '{{ var("orders_lookback_days") }} days',
                timestamp '1900-01-01'
            )
        from {{ this }}
    )
    {% endif %}

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
    recognized_revenue_amount,
    is_cancelled,
    is_returned,
    is_revenue_eligible,
    days_since_signup,
    updated_at,
    cast(current_timestamp as timestamp) as dbt_updated_at

from windowed
