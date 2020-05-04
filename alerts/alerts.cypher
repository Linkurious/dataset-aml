//UNNAMED: find Mortgage Loans with a Realtor or a broker in a different state

MATCH (b:Company)<-[hb:HAS_BROKER]-(m:MortgageLoan)<-[hl:HAS_LOAN]-(p:Person)
MATCH (m)-[hr:HAS_REALTOR]->(r:Company)
WITH m, p, b, r, hl, hb, hr, split(m.address, ",") as ma, split(b.address, ",") as ba, split(r.address, ",") as ra
WHERE ma[size(ma)-1] <> ba[size(ba)-1] OR ma[size(ma)-1] <> ba[size(ra)-1]
RETURN m, p, b, r, hl, hb, hr,  p.full_name, b.name, r.name



//UNNAMED: find group of bank clients (more than 3) involved in Mortgage Loans  that share the same Loaners and Brokers

MATCH (p:Person{is_client:true})-[hl:HAS_LOAN]->(m:MortgageLoan)
MATCH (r:Company)<-[hr:HAS_REALTOR]-(m)-[hb:HAS_BROKER]->(b:Company)
WITH r, b, collect(p) as col, collect(hl) + collect(hr) + collect(hb) as rel
WHERE size(col) > 3
RETURN r, b, size(col) as len, r.name, b.name,  col, rel



//EARLY REDEMPTION: find People with an early redeption of the loan with a money transer 100 times bigger than the usual montly loan reimbursments

MATCH (b:BankAccount)<-[hb:HAS_BANKACCOUNT]-(p:Person)-[hl:HAS_LOAN]->(m:MortgageLoan)
MATCH (b)-[mt:HAS_TRANSFERED]->(:BankAccount{contract_id:"00000-00-0000000"})
UNWIND mt.amount as val
WITH b, hb, hl, p, m,  min(val) as min, max(val) as max
WHERE min < 100*max
RETURN p, m, hb, hl, p.full_name, m.address
