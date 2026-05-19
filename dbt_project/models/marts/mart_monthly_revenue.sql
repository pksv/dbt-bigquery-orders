{{
    config(
        materialized='incremental',
        unique_key='revenue_month',
        partition_by={
            'field': 'revenue_month',
            'data_type': 'date',
            'granularity': 'month'
        }
    )
}}

with orders as (
    select * from {{ ref('int_orders_enriched') }}

    {% if is_incremental() %}
        -- on incremental runs, only process the last 3 months
        -- to catch any late-arriving data
        where order_date >= date_sub(current_date(), interval 3 month)
    {% endif %}
),

monthly as (
    select
        date_trunc(order_date, month)         as revenue_month,
        count(distinct order_id)              as total_orders,
        count(distinct user_id)               as unique_customers,
        round(sum(order_value), 2)            as total_revenue,
        round(avg(order_value), 2)            as avg_order_value,
        countif(status = 'returned')          as total_returns,
        countif(is_late_delivery = true)      as late_deliveries,
        round(safe_divide(
            countif(is_late_delivery = true),
            count(order_id)
        ) * 100, 2)                           as late_delivery_pct

    from orders
    where order_date is not null
      and status not in ('cancelled')
    group by revenue_month
),

final as (
    select
        *,
        lag(total_revenue) over (
            order by revenue_month
        ) as prev_month_revenue,

        round(safe_divide(
            total_revenue - lag(total_revenue) over (order by revenue_month),
            lag(total_revenue) over (order by revenue_month)
        ) * 100, 2) as revenue_growth_pct

    from monthly
)

select * from final
order by revenue_month