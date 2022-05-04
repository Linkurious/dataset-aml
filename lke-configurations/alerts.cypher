// /*
//  * Name: UNNAMED #1
//  * Desc: find Mortgage Loans with a Realtor or a broker in a different state
//  *
//  * Custom columns:
//  *   name   | Name    | text
//  *   b.name | Broker  | text
//  *   r.name | Realtor | text
//  */

MATCH (b:Company)<-[hb:HAS_BROKER]-(m:MortgageLoan)<-[hl:HAS_LOAN]-(p)
MATCH (m)-[hr:HAS_REALTOR]->(r:Company)
WITH m, p, b, r, hl, hb, hr, split(m.address, ",") as ma, split(b.address, ",") as ba, split(r.address, ",") as ra
WHERE ma[size(ma)-1] <> ba[size(ba)-1] OR ma[size(ma)-1] <> ba[size(ra)-1]
RETURN m, p, b, r, hl, hb, hr,  coalesce(p.full_name, p.name)as name, b.name, r.name



// /*
//  * Name: Common Clients
//  * Desc: find group of bank clients (more than 3) involved in Mortgage Loans that share the same Loaners and Brokers
//  *
//  * Custom columns:
//  *   b.name | Broker        | text
//  *   r.name | Realtor       | text
//  *   len    | N. of clients | number
//  */

MATCH (p{is_client:true})-[hl:HAS_LOAN]->(m:MortgageLoan)
MATCH (r:Company)<-[hr:HAS_REALTOR]-(m)-[hb:HAS_BROKER]->(b:Company)
WITH r, b, collect(p) as col, collect(hl) + collect(hr) + collect(hb) as rel
WHERE size(col) > 3
RETURN r, b, size(col) as len, r.name, b.name,  col, rel



// /*
//  * Name: Early Redemption
//  * Desc: find People with an early redeption of the loan with a money transer 100 times bigger than the usual montly loan reimbursment
//  *
//  * Custom columns:
//  *   name      | Name             | text
//  *   m.address | Property address | text
//  */

MATCH (b:BankAccount)<-[hb:HAS_BANKACCOUNT]-(p)-[hl:HAS_LOAN]->(m:MortgageLoan)
MATCH (b)-[mt:HAS_TRANSFERED]->(:BankAccount{contract_id:"00000-00-0000000"})
WITH b, hb, hl, p, m, max(mt.amount) as max
WHERE toFloat(m.monthly_instalment)*100 < max
RETURN p, m, hb, hl, coalesce(p.full_name, p.name) as name, m.address
