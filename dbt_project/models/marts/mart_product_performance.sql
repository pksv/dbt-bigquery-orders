with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

inventory as (
    select * from {{ ref('stg_inventory_items') }}
),

-- aggregate order items to product level
product_sales as (
    select
        product_id,
        count(order_item_id)      as total_units_sold,
        sum(sale_price_usd)       as total_revenue,
        avg(sale_price_usd)       as avg_selling_price,
        countif(status = 'returned') as total_returns

    from order_items
    where status != 'cancelled'
    group by product_id
),

-- count inventory per product
product_inventory as (
    select
        product_id,
        count(inventory_item_id)          as total_inventory,
        countif(is_sold = true)           as inventory_sold,
        countif(is_sold = false)          as inventory_remaining

    from inventory
    group by product_id
),

-- join everything
joined as (
    select
        p.product_id,
        p.product_name,
        p.category,
        p.brand,
        p.department,
        p.cost,
        p.retail_price,
        p.gross_margin,
        p.margin_pct,

        -- sales metrics
        coalesce(s.total_units_sold, 0)   as total_units_sold,
        coalesce(s.total_revenue, 0)      as total_revenue,
        coalesce(s.total_returns, 0)      as total_returns,

        -- use safe_divide to avoid divide by zero
        round(safe_divide(
            s.total_revenue,
            s.total_units_sold
        ), 2)                              as avg_revenue_per_unit,

        round(safe_divide(
            s.total_returns,
            s.total_units_sold
        ) * 100, 2)                        as return_rate_pct,

        -- inventory metrics
        coalesce(i.total_inventory, 0)    as total_inventory,
        coalesce(i.inventory_remaining, 0) as inventory_remaining,

        -- sell through rate (how much of inventory was sold)
        round(safe_divide(
            i.inventory_sold,
            i.total_inventory
        ) * 100, 2)                        as sell_through_rate_pct

    from products p
    left join product_sales s
        on p.product_id = s.product_id
    left join product_inventory i
        on p.product_id = i.product_id
)

select * from joined