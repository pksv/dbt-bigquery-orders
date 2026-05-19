with source as (
    select * from {{ source('raw', 'products') }}
),

renamed as (
    select
        id as product_id,
        name as product_name,
        category,
        brand,
        department,
        sku,
        cost,
        retail_price,

        -- derived
        round(retail_price - cost, 2) as gross_margin,
        round(safe_divide(retail_price - cost, retail_price) * 100, 2) as margin_pct

    from source
    where id is not null
)

select * from renamed