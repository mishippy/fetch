-- Barcodes in receipt items don't match with barcodes from brands table.
with barcode_matches as (
    select
        receipt_items.barcode,
        case when brands.id is null then 'No Match'
            when brands.id is not null then 'Match'
            else null
        end as match,
        count(*) as record_ct
    from
        fetch.staging.receipt_items
        left join fetch.staging.brands
            on brands.barcode = receipt_items.barcode
    group by all
    order by 3 desc
)
select
    match,
    sum(record_ct) as total_records
from barcode_matches
group by 1
;


/* 
There are also receipt item list entries without barcodes and without brandcodes.
While there are other fields with nulls, these fields are valuable beacause
they are potential links to the Brands table.
*/
select
    count(*) as row_count,
    sum(case when barcode is null then 1 else 0 end) as null_barcodes, 
    sum(case when brandcode is null then 1 else 0 end) as null_brand_codes
from
    fetch.staging.receipt_items
;


/*
The users table has duplicate records (70 out of 212 records have duplicates)
I excluded duplicate rows in my creation of a users table for analysis.
*/
select
    _id:"$oid"::varchar as id,
    active,
    to_timestamp(createddate:"$date"::varchar) as created_date,
    to_timestamp(lastlogin:"$date"::varchar) as last_login,
    role,
    signupsource as signup_source,
    state,
    count(*) as record_count
from
    fetch.raw.users
group by all
having record_count > 1
;


/*
Barcodes in the Brands table are not unique.
Some barcodes are reused for different brands.
*/
select
    count(*),
    count(distinct id),
    count(distinct barcode)
from
    fetch.staging.brands
;

-- Details of barcodes that are reused
with reused_barcodes as (
    select
        barcode,
        count(*) row_ct
    from
        fetch.staging.brands
    group by 1
    having row_ct > 1
)
select
    brands.*
from
    fetch.staging.brands
    inner join reused_barcodes
        on brands.barcode = reused_barcodes.barcode
order by brands.barcode
;


-- The brands table contains duplicate names and brand_codes
with duplicate_brand_codes as (
    select
        brand_code,
        count(*) as row_ct
    from
        fetch.staging.brands
    where
        brand_code is not null
        and brand_code != ''
    group by 1
    having row_ct > 1
)
select
    brands.*
from
    fetch.staging.brands
    inner join duplicate_brand_codes
        on brands.brand_code = duplicate_brand_codes.brand_code
order by brand_code
;


with duplicate_brand_names as (
    select
        name,
        count(*) as row_ct
    from
        fetch.staging.brands
    where
        name is not null
        and name != ''
    group by 1
    having row_ct > 1
)
select
    brands.*
from
    fetch.staging.brands
    inner join duplicate_brand_names
        on brands.name = duplicate_brand_names.name
order by name
;

-- Do receipt item prices add up to receipt totals?
select
    receipt_id,
    sum(finalprice) as total_item_price,
    max(toal_spent) as receipt_price,
    sum(quantitypurchased) as total_items,
    max(purchased_item_count) as receipt_items,
    total_item_price - receipt_price as price_delta,
    total_items - receipt_items as item_ct_delta
from
    fetch.staging.receipt_items
    left join fetch.staging.receipts
        on receipts.id = receipt_items.receipt_id
where needsfetchreview != TRUE
group by 1
having
    price_delta != 0
    or item_ct_delta != 0
;


