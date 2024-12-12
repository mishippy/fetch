-- Create Users table, with only unique rows from raw table.

create table if not exists fetch.staging.users as (
    select distinct
        _id:"$oid"::varchar as id,
        active,
        to_timestamp(createddate:"$date"::varchar) as created_date,
        to_timestamp(lastlogin:"$date"::varchar) as last_login,
        role,
        signupsource as signup_source,
        state
    from fetch.raw.users
)
;


-- Create Brands table

create table if not exists fetch.staging.brands as (
    select
        _id:"$oid"::varchar as id,
        barcode,
        category,
        brandcode as brand_code,
        categorycode as category_code,
        cpg:"$id":"$oid"::varchar as cpg_id,
        cpg:"$ref"::varchar as cpg_ref,
        name,
        topbrand as top_brand
    from fetch.raw.brand
)
;


-- Create Receipts table

create table if not exists fetch.staging.receipts as (
    select
        _id:"$oid"::varchar as id,
        bonuspointsearned as bonus_points_earned,
        bonuspointsearnedreason as bonus_points_reason,
        to_timestamp(createdate:"$date"::varchar) as created_date,
        to_timestamp(datescanned:"$date"::varchar) as date_scanned,
        to_timestamp(finisheddate:"$date"::varchar) as finished_date,
        to_timestamp(modifydate:"$date"::varchar) as modify_date,
        to_timestamp(pointsawardeddate:"$date"::varchar) as points_awarded_date,
        pointsearned as points_earned,
        to_timestamp(purchasedate:"$date"::varchar) as purchased_date,
        purchaseditemcount as purchased_item_count,
        -- reward list excluded to be broken out into its own table
        rewardsreceiptstatus as rewards_receipt_status,
        totalspent as toal_spent,
        userid as user_id
    from fetch.raw.receipts
)
;


/*
Create Receipt_items table.
This table unpacks the nested objects in the REWARDSRECEIPTITEMLIST column from the Receipts table.
It also acts as a mapping table between the Receipts and Brands tables.
*/

-- Column names and datatypes for the DDL query were retrieved with the commented out query below:

-- SELECT distinct
--     replace(REGEXP_REPLACE(f.path, '\\[[0-9]+\\]', ''), '.') AS key_name,
--   TYPEOF(f.value) AS datatype
-- FROM fetch.raw.receipts,
--     LATERAL FLATTEN(REWARDSRECEIPTITEMLIST, RECURSIVE=>true) f
-- where key_name != ''
-- ;

create table if not exists fetch.staging.receipt_items as (
    with flattened as (
        select
            _id:"$oid"::varchar as receipt_id,
            f.value::variant as json_item
        from
            fetch.raw.receipts,
            lateral flatten(input => REWARDSRECEIPTITEMLIST) f
    )
    select
        receipt_id,
        json_item:barcode::VARCHAR as barcode,
        json_item:description::VARCHAR as description,
        json_item:finalPrice::VARCHAR as finalPrice,
        json_item:itemPrice::VARCHAR as itemPrice,
        json_item:needsFetchReview::BOOLEAN as needsFetchReview,
        json_item:partnerItemId::VARCHAR as partnerItemId,
        json_item:preventTargetGapPoints::BOOLEAN as preventTargetGapPoints,
        json_item:quantityPurchased::INTEGER as quantityPurchased,
        json_item:userFlaggedNewItem::BOOLEAN as userFlaggedNewItem,
        json_item:userFlaggedQuantity::INTEGER as userFlaggedQuantity,
        json_item:pointsNotAwardedReason::VARCHAR as pointsNotAwardedReason,
        json_item:pointsPayerId::VARCHAR as pointsPayerId,
        json_item:rewardsProductPartnerId::VARCHAR as rewardsProductPartnerId,
        json_item:userFlaggedDescription::VARCHAR as userFlaggedDescription,
        json_item:originalMetaBriteBarcode::VARCHAR as originalMetaBriteBarcode,
        json_item:originalMetaBriteDescription::VARCHAR as originalMetaBriteDescription,
        json_item:discountedItemPrice::VARCHAR as discountedItemPrice,
        json_item:originalReceiptItemText::VARCHAR as originalReceiptItemText,
        json_item:originalFinalPrice::VARCHAR as originalFinalPrice,
        json_item:priceAfterCoupon::VARCHAR as priceAfterCoupon,
        json_item:metabriteCampaignId::VARCHAR as metabriteCampaignId,
        json_item:competitorRewardsGroup::VARCHAR as competitorRewardsGroup,
        json_item:originalMetaBriteQuantityPurchased::INTEGER as originalMetaBriteQuantityPurchased,
        json_item:pointsEarned::VARCHAR as pointsEarned,
        json_item:targetPrice::VARCHAR as targetPrice,
        json_item:originalMetaBriteItemPrice::VARCHAR as originalMetaBriteItemPrice,
        json_item:deleted::BOOLEAN as deleted,
        json_item:userFlaggedPrice::VARCHAR as userFlaggedPrice,
        json_item:needsFetchReviewReason::VARCHAR as needsFetchReviewReason,
        json_item:brandCode::VARCHAR as brandCode,
        json_item:itemNumber::VARCHAR as itemNumber,
        json_item:competitiveProduct::BOOLEAN as competitiveProduct,
        json_item:userFlaggedBarcode::VARCHAR as userFlaggedBarcode,
        json_item:rewardsGroup::VARCHAR as rewardsGroup
    from flattened
)
;

