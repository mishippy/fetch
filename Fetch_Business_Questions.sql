/* Questions
What are the top 5 brands by receipts scanned for most recent month?
How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
Which brand has the most spend among users who were created within the past 6 months?
Which brand has the most transactions among users who were created within the past 6 months?
*/

-- Questions:
-- What are the top 5 brands by receipts scanned for most recent month?
-- How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?

-- Answers:
-- Viva is the only named brand linked to receipts scanned in the most recent month (2/2021)
-- This brand did not appear in the top 5 brands for the previous month.
select
    year(date_scanned) as scanned_year,
    month(date_scanned) as scanned_month,
    brands.name as brand_name,
    count(*) receipts_scanned,
    rank() over(partition by scanned_year, scanned_month order by receipts_scanned desc) as monthly_rank
from
    fetch.staging.receipt_items
    left join fetch.staging.receipts
        on receipt_items.receipt_id = receipts.id
    left join fetch.staging.brands
        on brands.brand_code = receipt_items.brandcode
where
    brands.name is not null
group by all
qualify monthly_rank <= 5
order by scanned_year desc, scanned_month desc, monthly_rank asc
;

-- Questions:
-- When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
-- When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

-- Note:
-- The value 'Accepted' does not appear in the rewards_receipt_status column.
-- The value 'Finished was used in place of 'Accepted' for the purposes of this query.

-- Answers:
-- The average spend for 'Finished' receipts is higher than 'Rejected' receipts.
-- 'Finished' receipts also have a greater number of items purchased than 'Rejected' receipts.
select
    rewards_receipt_status,
    avg(toal_spent) as average_spend,
    sum(toal_spent) as total_spend,
    sum(purchased_item_count) as total_items
from
    fetch.staging.receipts
where
    rewards_receipt_status in ('REJECTED', 'FINISHED', 'ACCEPTED')
group by 1
order by 2 desc nulls last
;

-- Questions:
-- Which brand has the most spend among users who were created within the past 6 months?
-- Which brand has the most transactions among users who were created within the past 6 months?

-- Note:
-- The 6 month time window is anchored on the latest purchased_date in the receipts table.

-- Answers:
-- Cracker Barrel Cheese has the most spend among users created in the past 6 months.
-- Pepsi has the most transactions among those users.
with latest_transaction_date as (
    select
        max(purchased_date) as latest_purchase
    from
        fetch.staging.receipts
)
, distinct_brand_codes as (
    select
        brand_code,
        name
    from
        fetch.staging.brands
    where
        brand_code is not null
        and brand_code != ''
    qualify
        row_number() over(partition by brand_code order by category_code) = 1
)
select
    brands.name,
    count(distinct receipts.id) as transaction_count,
    sum(finalprice) as total_spend,
    rank() over(order by transaction_count desc) as transaction_count_rank,
    rank() over(order by total_spend desc) as spend_rank
from
    fetch.staging.receipt_items items
    left join distinct_brand_codes brands
        on brands.brand_code = items.brandcode
    left join fetch.staging.receipts
        on receipts.id = items.receipt_id
    left join fetch.staging.users
        on users.id = receipts.user_id
    join latest_transaction_date
where
    users.created_date >= dateadd(month, -6, latest_purchase)
    and brands.name is not null
group by 1
qualify
    transaction_count_rank = 1
    or spend_rank = 1
;
