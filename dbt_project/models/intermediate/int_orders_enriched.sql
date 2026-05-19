with orders as (
    select * from {{ ref('stg_orders') }}
),

users as (
    select * from {{ ref('stg_users') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

-- aggregate order_items to order level first
order_revenue as (
    select
        order_id,
        sum(sale_price_usd)   as order_value,
        count(order_item_id)  as item_count
    from order_items
    group by order_id
),

-- join everything together
joined as (
    select
        o.order_id,
        o.user_id,
        o.status,
        o.order_date,
        o.delivered_date,
        o.days_to_deliver,
        o.is_delivered,
        o.num_of_item,

        -- user details
        u.first_name,
        u.last_name,
        u.email,
        u.age,
        u.gender,
        u.city,
        u.state,
        u.country,
        u.traffic_source,
        u.signup_date,

        -- revenue
        coalesce(r.order_value, 0) as order_value,
        coalesce(r.item_count, 0)  as item_count,

        -- is the order late? (delivered more than 7 days after order)
        case
            when o.days_to_deliver > 7 then true
            else false
        end as is_late_delivery

    from orders o
    left join users u
        on o.user_id = u.user_id
    left join order_revenue r
        on o.order_id = r.order_id
)

select * from joined