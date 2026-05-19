with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        order_id,
        user_id,
        status,
        gender,
        created_at,
        returned_at,
        shipped_at,
        delivered_at,
        num_of_item,

        -- derived columns
        date(created_at) as order_date,
        date(delivered_at) as delivered_date,
        date_diff(date(delivered_at), date(created_at), day) as days_to_deliver,

        case
            when delivered_at > shipped_at then true
            else false
        end as is_delivered

    from source
    where order_id is not null
)

select * from renamed