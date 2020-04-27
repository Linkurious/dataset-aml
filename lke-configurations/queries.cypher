// /*
//  * Expand Edges
//  */
match (n)-[e]->(m) where id(e) = {{"EdgeID":number}}

match (n)-[e2]->(m)
where
	type(e2) = replace(type(e), "_AGG", "")
	and type(e2) <> type(e)
return n, e2, m;


// /*
//  * Aggregate All Transactions
//  */
with {{"Bank Accounts":nodeset:"BankAccount"}} as list
unwind list as src_id
unwind list as dst_dst

match (src:BankAccount)-[t:HAS_TRANSFERED]->(dst:BankAccount)
where
	id(src) = src_id
    and id(dst) = dst_dst

with src, dst, sum(t.amount) as amount, count(t) as num

MERGE (src)-[t2:HAS_TRANSFERED_AGG { uid: apoc.util.md5([src.uid, dst.uid]) }]->(dst)
SET
	t2.amount = amount,
    t2.number_transactions = num

return src, t2, dst;


// /*
//  * Get Similar Real Estate
//  * 
//  * /!\ OBSOLETE /!\
//  */
match (loan) where id(loan) = {{"Real Estate":node:"MortageLoan"}}
with loan, collect(apoc.create.vNode(['REALESTATE_TRANSACTION'], {
        id: id(loan),
        contract_id: loan.contract_id,
        transaction_date: loan.signature_date,
        type: loan.type,
        city: loan.city,
        address: loan.address,
        sqft: loan.sqft,
        purchase_price: loan.purchase_price,
        sqft_price: toInteger(loan.purchase_price / loan.sqft * 100) / 1000.0
    })) as results

// match (re:RealEstateValue) where re.city = loan.city and re.type = loan.type

match (related_loan:MortageLoan)
where related_loan.city = loan.city and related_loan.type = loan.type

with results, related_loan order by related_loan.purchase_price / related_loan.sqft

with results + collect(apoc.create.vNode(['REALESTATE_TRANSACTION'], {
        id: id(related_loan),
        contract_id: related_loan.contract_id,
        transaction_date: related_loan.signature_date,
        type: related_loan.type,
        city: related_loan.city,
        address: related_loan.address,
        sqft: related_loan.sqft,
        purchase_price: related_loan.purchase_price,
        sqft_price: toInteger(related_loan.purchase_price / related_loan.sqft * 100) / 100.0
    })) as results

return results;


// /*
//  * Check Real Estate Value
//  */
match (loan) where id(loan) in {{"Real Estate":nodeset:"MortageLoan"}} // 4185
match (re:RealEstateValue) where re.city = loan.city and re.type = loan.type

with loan, re, toInteger(loan.purchase_price / loan.sqft * 100) / 100.0 as avg_price
return apoc.create.vNode(['REALESTATE_TRANSACTION'], {
    id: id(loan),
    contract_id: loan.contract_id,
    transaction_date: loan.signature_date,
    type: loan.type,
    city: loan.city,
    address: loan.address,
    sqft: loan.sqft,
    purchase_price: loan.purchase_price,
    sqft_price: avg_price,
    avg_sqft_price: re.sqft_usd_median,
    price_range: coalesce(
        case when avg_price < re.sqft_usd_low then "UNDERPRICE" else null end,
        case when avg_price > re.sqft_usd_high then "OVERRPRICE" else null end,
        "NORMAL"
    )
}) as real_estates_value;


// /*
//  * 4-Level Connection
//  */
match (a) where id(a) = {{"Person":node:"Person"}}

match p = (a)-[*..4]-(b)
where all(
    r in relationships(p)
    where not type(r) in ["HAS_TRANSFERED"]
)

return p;


// /*
//  * Get UBOs
//  */
match (a) where id(a) = {{"Company":node:"Company"}}
match p = (a)<-[:HAS_CONTROL*..10]-(b)
return p;
