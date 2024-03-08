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
    where not type(r) in ["HAS_TRANSFERED"]
)

return p;


// /*
//  * Name: Get UBOs
//  * Desc: Allows to quickly reach the ultimate beneficial owners of a company without having to expand every successive intermediate nodes.
//  */
match (a) where id(a) = {{"Company":node:"Company"}}
match p = (a)<-[:HAS_CONTROL*..10]-(b)
return p;


// /*
//  * Name: Collusion between realtor and broker
//  * Desc: Show realtors and brokers who have at least 3 clients in common
//  */
MATCH (p{is_client:true})-[hl:HAS_LOAN]->(m:MortgageLoan)
MATCH (r:Company)<-[hr:HAS_REALTOR]-(m)-[hb:HAS_BROKER]->(b:Company)
WITH r, b, collect(p) + collect(m) as col, collect(hl) + collect(hr) + collect(hb) as rel
WHERE size(col) > 3
RETURN r, b, size(col) as len, r.name, b.name,  col, rel


// /*
//  * Name: Return companies at same address
//  * Desc: Returns companies at same address
//  */
MATCH (n) where id(n) = {{"Node":node:"Company"}}
MATCH (same_address:Company) 
WHERE same_address.address = n.address 
RETURN same_address
