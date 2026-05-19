with source as (
    select * from {{ source('raw', 'inventory_items') }}
),

renamed as (
    select
        id as inventory_item_id,
        product_id,
        created_at,
        sold_at,
        cost,
        product_category,
        product_name,
        product_brand,
        product_department,
        product_sku,
        product_retail_price,

        -- derived
        case
            when sold_at is not null then true
            else false
        end as is_sold,

        date(created_at) as created_date,
        date(sold_at) as sold_date,
        date_diff(date(sold_at), date(created_at), day) as days_to_sell

    from source
    where id is not null
)

select * from renamed