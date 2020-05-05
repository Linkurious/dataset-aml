// /*
//  * Name: Expand Edges
//  * Desc: Expand all the connections of the relevant type between two nodes connected by an aggregated connection. Useful to unfold aggregated transactions created with Aggregate all transactions.
//  */
match (n)-[e]->(m) where id(e) = {{"EdgeID":number}}

match (n)-[e2]->(m)
where
	type(e2) = replace(type(e), "_AGG", "")
	and type(e2) <> type(e)
return n, e2, m;


// /*
//  * Name: Aggregate All Transactions
//  * Desc: Allows to merge every single transaction between two nodes into one edge, representing the aggregated amount of every transactions. Useful to get a synthetic view of financial activity between two bank accounts.
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
//  * Name: Check Real Estate Value
//  * Desc: Compute analysis on a set of Real Estate to check whether the transactions are UNDER or OVER price
//  */
match (loan) where id(loan) in {{"Real Estate":nodeset:"MortgageLoan"}}
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
//  * Name: 4-Level Connection
//  * Desc: Allows the analyst to unfold in 1 click connections to a node up to 4 jumps. The use is to quickly expand the network around a node without having to go through incremental expand.
//  */
match (a) where id(a) = {{"Person":node:"Person"}}

match p = (a)-[*..4]-(b)
where all(
    r in relationships(p)
    where not type(r) in ["HAS_TRANSFERED", "HAS_TRANSFERED_AGG"]
)

return p;


// /*
//  * Name: Get UBOs
//  * Desc: Allows to quickly reach the ultimate beneficial owners of a company without having to expand every successive intermediate nodes.
//  */
match (a) where id(a) = {{"Company":node:"Company"}}
match p = (a)<-[:HAS_CONTROL*..10]-(b)
return p;
