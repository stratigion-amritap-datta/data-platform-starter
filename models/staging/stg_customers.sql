with source as (

    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        cast(customer_id as varchar) as customer_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(email)) as email,
        trim(country) as country,
        cast(signup_date as date) as signup_date,
        cast(updated_at as timestamp) as updated_at

    from source

)

select * from renamed
