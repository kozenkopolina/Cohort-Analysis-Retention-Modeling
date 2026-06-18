with users_parsed as (
select
   u.user_id,
   u.signup_datetime,
   u.promo_signup_flag,
    case
    when length(split_part(replace(replace(split_part(trim(u.signup_datetime), ' ', 1), '.', '-'), '/', '-'), '-', 3)) = 4
    then to_date(replace(replace(split_part(trim(u.signup_datetime), ' ', 1), '.', '-'), '/', '-'), 'dd-mm-yyyy')::timestamp
    else to_date(replace(replace(split_part(trim(u.signup_datetime), ' ', 1), '.', '-'), '/', '-'), 'dd-mm-yy')::timestamp
    end as signup_ts
    from cohort_users_raw u
    ),
events_parsed as (
select 
e.user_id,
e.event_type,
case
    when length(split_part(replace(replace(split_part(trim(e.event_datetime), ' ', 1), '.', '-'), '/', '-'), '-', 3)) = 4
    then to_date(replace(replace(split_part(trim(e.event_datetime), ' ', 1), '.', '-'), '/', '-'), 'dd-mm-yyyy')::timestamp
    else to_date(replace(replace(split_part(trim(e.event_datetime), ' ', 1), '.', '-'), '/', '-'), 'dd-mm-yy')::timestamp
    end as event_ts
from cohort_events_raw e
),
user_activity as (
select
u.user_id,
date_trunc('month', u.signup_ts)::date as cohort_month,
u.promo_signup_flag,
date_trunc('month', e.event_ts)::date as activity_month,
extract(month from age(date_trunc('month', e.event_ts), date_trunc('month', u.signup_ts))) as month_offset
from users_parsed u
join events_parsed e on u.user_id = e.user_id
where u.signup_ts is not null
and e.event_ts is not null
and e.event_type is not null
and e.event_type <> 'test_event'
)
select 
promo_signup_flag,
cohort_month,
month_offset,
count(distinct user_id) as users_total
from user_activity
where activity_month between '2025-01-01' and '2025-06-01'
group by promo_signup_flag,
cohort_month,
month_offset
order by promo_signup_flag, cohort_month, month_offset;
 

