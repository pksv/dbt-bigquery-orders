with source as (
    select * from {{ source('raw', 'users') }}
),

renamed as (
    select
        id as user_id,
        first_name,
        last_name,
        email,
        age,
        gender,
        city,
        state,
        country,
        postal_code,
        latitude,
        longitude,
        traffic_source,
        created_at,
        date(created_at) as signup_date

    from source
    where id is not null
)

select * from renamed