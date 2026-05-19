{{
    config(
        materialized='table',
        partition_by={
            'field': 'first_order_date',
            'data_type': 'date',
            'granularity': 'month'
        },
        cluster_by=['country', 'customer_segment']
    )
}}

with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

-- rest of the model stays exactly the same as before
customer_orders as (
    select
        user_id,
        first_name,
        last_name,
        email,
        country,
        gender,
        age,
        traffic_source,
        signup_date,

        approx_count_distinct(order_id)      as total_orders,
        sum(order_value)                      as total_revenue,
        avg(order_value)                      as avg_order_value,
        min(order_date)                       as first_order_date,
        max(order_date)                       as last_order_date,
        countif(status = 'returned')          as total_returns,
        countif(is_late_delivery = true)      as late_deliveries,

        date_diff(
            max(order_date),
            min(order_date),
            day
        ) as customer_lifespan_days

    from orders
    where user_id is not null
    group by
        user_id, first_name, last_name, email,
        country, gender, age, traffic_source, signup_date
),

final as (
    select
        *,
        case
            when total_revenue >= 500  then 'high value'
            when total_revenue >= 200  then 'mid value'
            when total_revenue >= 50   then 'low value'
            else 'at risk'
        end as customer_segment,

        round(avg_order_value, 2)  as avg_order_value_usd,
        round(total_revenue, 2)    as total_revenue_usd

    from customer_orders
)

select * from final