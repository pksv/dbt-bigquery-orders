with source as (
    select * from {{ source('raw', 'order_items') }}
),

renamed as (
    select
        id as order_item_id,
        order_id,
        user_id,
        product_id,
        inventory_item_id,
        status,
        created_at,
        shipped_at,
        delivered_at,
        returned_at,
        sale_price,

        -- derived
        round(sale_price, 2) as sale_price_usd,
        date(created_at) as order_date

    from source
    where id is not null
      and order_id is not null
)

select * from renamed