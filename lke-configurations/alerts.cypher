// /*
//  * Name: Common Clients
//  * Desc: Find group of bank clients (more than 3) involved in Mortgage Loans that share the same Loaners and Brokers
//  *
//  * Target: r
//  *
//  * Custom columns:
//  *   Broker        | b.name | text
//  *   Realtor       | r.name | text
//  *   N. of clients | len    | number
//  */


// Model 1
MATCH (p{is_client:true})-[hl:HAS_LOAN]->(m:MortgageLoan)
MATCH (r:Company)<-[hr:HAS_REALTOR]-(m)-[hb:HAS_BROKER]->(b:Company)
WITH r, b, collect(p) + collect(m) as col, collect(hl) + collect(hr) + collect(hb) as rel
WHERE size(col) > 3
RETURN r, b, col, rel

// Query calculating case attributes
MATCH (r:Company)<-[hr:HAS_REALTOR]-(m)-[hb:HAS_BROKER]->(b:Company)
WHERE id(r) in {{"target":nodeset}} and id(b) in {{"context":nodeset}}
RETURN b,r,count(m) as len

// /*
//  * Name: Early Redemption
//  * Desc: Find People with an early redemption of the loan with a money transfser 100 times bigger than the usual monthly loan reimbursement
//  *
//  * Target: p
//  *
//  * Custom columns:
//  *   Name             | name      | text
//  *   Property address | address | text
//  */

// Model 1
MATCH (b:BankAccount)<-[hb:HAS_BANKACCOUNT]-(p)-[hl:HAS_LOAN]->(m:MortgageLoan)
MATCH (b)-[mt:HAS_TRANSFERED]->(:BankAccount{contract_id:"00000-00-0000000"})
WITH b, hb, hl, p, m, max(mt.amount) as max
WHERE toFloat(m.monthly_instalment)*100 < max
RETURN p, m, hb, hl

// Query calculating case attributes
MATCH (p:Person) WHERE id(p) in {{"target":nodeset}}
MATCH (m:MortgageLoan) WHERE id(m) in {{"context":nodeset}}
RETURN coalesce(p.full_name, p.name) as name, collect(m.address) as address


// ########################################################################################
// ################################## MULTI MODEL ALERT  ##################################
// ########################################################################################

// /*
//  * Name: AML real estate - individuals
//  * Desc: Alert documentation example
//  *
//  * Target: p
//  *
//  * Custom columns:
//  *   Full name             | p.full_name             | text
//  *   ID                    | p.client_id             | text
//  *   Nationality           | p.nationality           | text
//  *   Total properties value| total_properties_value  | number
//  *   Total loans count     | total_loans             | number
//  *   Average loan duration | average_loan_duration   | number
//  *   Available dept ratio  | available_debt_ratio    | number
//  *   Average distance      | average_distance        | number
//  */


// Model 1
// Name: Discrepancy income and loan
// Desc: A discrepancy between the usual income of the owner and the property: the most expensive property of the city is owned by an individual with no income or wealth that would not allow them to purchase such a property. 

MATCH (l:MortgageLoan)<-[e:HAS_LOAN]-(p:Person) 
with e,l,p,p.annual_revenues/36 as max_monthly_instalment
WHERE  max_monthly_instalment < toFloat(l.monthly_instalment)
RETURN l,p,e


// Model 2
// Name: Risky country
// Desc: The customer is from a country at risk

MATCH (p:Person)-[e:HAS_LOAN]->(l:MortgageLoan)
WHERE p.nationality in ["Russia","China","North Korea"]
RETURN l,p,e


// Model 3
// Name: Location mismatch
// Desc: The location of the property (represented by location where the loan is done) is not in relation with the buyer location. 

MATCH (l:MortgageLoan)<-[e:HAS_LOAN]-(p:Person)
WHERE point.distance(point(l),point(p))/1000 > 300
RETURN l,p,e


// Model 4
// Name: Red flagged industry (Company has loan)
// Desc: The company the buyer owns works for an industry that's red flagged.

MATCH (l:MortgageLoan)<-[e:HAS_LOAN]-(c:Company)<-[control:HAS_CONTROL]-(p:Person)
WHERE c.industry in ["Military/Government/Technical","Oil/Gas Transmission"]
RETURN l,c,p,e,control


// Model 5
// Name: Red flagged industry (Person has loan)
// Desc: The company the buyer owns works for an industry that's red flagged.

MATCH (l:MortgageLoan)<-[e:HAS_LOAN]-(p:Person)-[control:HAS_CONTROL]->(c:Company)
WHERE c.industry in ["Military/Government/Technical","Oil/Gas Transmission"]
RETURN l,c,p,e,control


// Query calculating case attributes
MATCH (p:Person) WHERE id(p) in {{"target":nodeset}}
WITH p, p.annual_revenues / 36 as max_monthly_instalment
MATCH (l:MortgageLoan) WHERE id(l) in {{"context":nodeset}} 
WITH p,max_monthly_instalment,
	sum(point.distance(point(l),point(p))) as total_distances,
	collect(l) as loans,
	sum(toFloat(l.monthly_instalment)) as debt_ratio,
	sum(l.purchase_price) as total_properties_value, 
	sum(l.duration) as loans_duration,
    count (l) as total_loans
WITH p,
	 loans,
	 total_properties_value, 
	 total_loans, 
	 loans_duration,
     total_distances/total_loans as average_distance,
	 loans_duration/total_loans as average_loan_duration,
	 max_monthly_instalment - debt_ratio as available_debt_ratio
RETURN p, total_properties_value, total_loans, average_loan_duration, average_distance, available_debt_ratio