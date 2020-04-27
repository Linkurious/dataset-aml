// /*
//  * OKR Initiative - Q1 2020
//  * AML DataSet import script
//  *
//  * Contraint rules:
//  * - Each element has a `uid` attribute to uniquely identify the object
//  * - Nodes uids are computed as n.uid = apoc.util.md5([list of primary keys])
//  * - Edge uids are computed as e.uid = apoc.util.md5([source.uid, target.uid, e.identifier])
//  * - Edge identifiers are computed as e.identifier = apoc.util.md5([list of primary keys])
//  * 
//  */


// Empty db
    // match (n) detach delete n;


// Internal info
    merge (internal_bank:Company { uid: apoc.util.md5(['00-0000000']) })
    set
        internal_bank.reg_number = '00-0000000',
        internal_bank.name = 'My Bank Name',
        internal_bank.industry = 'Bank'
    
    // merge (industry:Industry { uid: apoc.util.md5(['Bank']) })
    // set industry.name = 'Bank'
    // 
    // merge (internal_bank)-[:HAS_INDUSTRY { uid: apoc.util.md5([internal_bank.uid, industry.uid]) }]->(industry)
    with internal_bank, null as industry

    merge (internal_account:BankAccount { uid: apoc.util.md5(['00000-00-0000000']) })
    set
        internal_account.contract_id = '00000-00-0000000',
        internal_account.open_date = '2015-01-01',
        internal_account.close_date = null,
        internal_account.close_balance = null
    
    merge (internal_bank)-[:HAS_BANKACCOUNT { uid: apoc.util.md5([internal_bank.uid, internal_account.uid]) }]->(internal_account)
    
    return internal_bank, industry, internal_account;

// Person
    :auto using periodic commit 500
    load csv with headers from replace('https://raw.githubusercontent.com/Linkurious/dataset-aml/master/csv/Dataset AML Demo - Person.csv', ' ', '%20') as row
    with row

    merge (client:Person { uid: apoc.util.md5([row.`Internal id`]) })
    set
        client.client_id = row.`Internal id`,
        client.profession = row.`Profession`,
        client.first_name = row.`first_name`,
        client.last_name = row.`last_name`,
        client.full_name = row.`full_name`,
        client.annual_revenues = toFloat(row.`Annual revenues`),
        client.address = row.`address`,
        client.longitude = toFloat(row.`Longitude`),
        client.latitude = toFloat(row.`Latitude`)
    
    with row, client

    call apoc.do.when(exists(row.`Employer Reg number`), '
        merge (company:Company { uid: apoc.util.md5([row.`Employer Reg number`]) })
        set
            company.reg_number = row.`Employer Reg number`,
            company.name = row.`Employer`
        
        merge (client)-[:IS_EMPLOYEE_OF { uid: apoc.util.md5([client.uid, company.uid])}]->(company)

        return row, company
    ', 'return row, null as company', { row: row, client: client }) yield value
    with row, client, value.company as company

    // call apoc.do.when(exists(row.`Profession`), '
    //     merge (profession:Profession { uid: apoc.util.md5([row.`Profession`]) })
    //     set profession.name = row.`Profession`

    //     merge (client)-[:HAS_PROFESSION { uid: apoc.util.md5([client.uid, profession.uid])}]->(profession)

    //     return row, profession
    // ', 'return row, null as profession', { row: row, client: client }) yield value
    with row, client, company, null as profession
    
    call apoc.do.when(exists(row.`email`), '
        merge (email:Email { uid: apoc.util.md5([row.`email`]) })
        set email.email = row.`email`

        merge (client)-[:HAS_EMAIL { uid: apoc.util.md5([client.uid, email.uid])}]->(email)

        return row, email
    ', 'return row, null as email', { row: row, client: client }) yield value
    with row, client, company, profession, value.email as email

    call apoc.do.when(exists(row.`phone`), '
        merge (phone:Phone { uid: apoc.util.md5([row.`phone`]) })
        set phone.number = row.`phone`

        merge (client)-[:HAS_PHONE { uid: apoc.util.md5([client.uid, phone.uid])}]->(phone)
        
        return row, phone
    ', 'return row, null as phone', { row: row, client: client }) yield value
    with row, client, company, profession, email, value.phone as phone

    return client, company, profession, email, phone;
    

// Company
    :auto using periodic commit 500
    load csv with headers from replace('https://raw.githubusercontent.com/Linkurious/dataset-aml/master/csv/Dataset AML Demo - Company.csv', ' ', '%20') as row
    with row

    merge (company:Company { uid: apoc.util.md5([row.`Registration number`]) })
    set
        company.reg_number = row.`Registration number`,
        company.name = row.`Name`,
        company.annual_turnover = toFloat(row.`Annual Turnover`),
        company.industry = row.`Industry`,
        company.address = row.`address`,
        company.longitude = toFloat(row.`Longitude`),
        company.latitude = toFloat(row.`Latitude`)
    
    with row, company
    
    // call apoc.do.when(exists(row.`Industry`), '
    //     merge (industry:Industry { uid: apoc.util.md5([row.`Industry`]) })
    //     set industry.name = row.`Industry`
        
    //     merge (company)-[:HAS_INDUSTRY { uid: apoc.util.md5([company.uid, industry.uid]) }]->(industry)
        
    //     return row, industry
    // ', 'return row, null as industry', { row: row, company: company }) yield value
    with row, company, null as industry

    call apoc.do.when(exists(row.`Ultimate Beneficiary id`), '
        merge (ubo:Person { uid: apoc.util.md5([row.`Ultimate Beneficiary id`]) })
        
        merge (ubo)-[:HAS_CONTROL { uid: apoc.util.md5([ubo.uid, company.uid])}]->(company)
        
        return row, ubo
    ', 'return row, null as ubo', { row: row, company: company }) yield value
    with row, company, industry, value.ubo as ubo
    
    return company, industry, ubo;


// Company: Broker
    :auto using periodic commit 500
    load csv with headers from replace('https://raw.githubusercontent.com/Linkurious/dataset-aml/master/csv/Dataset AML Demo - Company_Broker.csv', ' ', '%20') as row
    with row

    merge (company:Company { uid: apoc.util.md5([row.`Registration number`]) })
    set
        //company:Broker,
        company.reg_number = row.`Registration number`,
        company.name = row.`Legal name`,
        company.industry = row.`Industry`,
        company.address = row.`address`,
        company.longitude = toFloat(row.`Longitude`),
        company.latitude = toFloat(row.`Latitude`)
    
    with row, company
    
    // call apoc.do.when(exists(row.`Industry`), '
    //     merge (industry:Industry { uid: apoc.util.md5([row.`Industry`]) })
    //     set industry.name = row.`Industry`
        
    //     merge (company)-[:HAS_INDUSTRY { uid: apoc.util.md5([company.uid, industry.uid]) }]->(industry)
        
    //     return row, industry
    // ', 'return row, null as industry', { row: row, company: company }) yield value
    with row, company, null as industry

    return company, industry;


// Company: Realtor
    :auto using periodic commit 500
    load csv with headers from replace('https://raw.githubusercontent.com/Linkurious/dataset-aml/master/csv/Dataset AML Demo - Company_Realtor.csv', ' ', '%20') as row
    with row

    merge (company:Company { uid: apoc.util.md5([row.`Registration number`]) })
    set
        //company:Realtor,
        company.reg_number = row.`Registration number`,
        company.name = row.`Legal name`,
        company.industry = row.`Industry`,
        company.address = row.`address`,
        company.longitude = toFloat(row.`Longitude`),
        company.latitude = toFloat(row.`Latitude`)
    
    with row, company
    
    // call apoc.do.when(exists(row.`Industry`), '
    //     merge (industry:Industry { uid: apoc.util.md5([row.`Industry`]) })
    //     set industry.name = row.`Industry`
        
    //     merge (company)-[:HAS_INDUSTRY { uid: apoc.util.md5([company.uid, industry.uid]) }]->(industry)
        
    //     return row, industry
    // ', 'return row, null as industry', { row: row, company: company }) yield value
    with row, company, null as industry

    return company, industry;


// Real Estate Value sheet
    :auto using periodic commit 500
    load csv with headers from replace('https://raw.githubusercontent.com/Linkurious/dataset-aml/master/csv/Dataset AML Demo - US_RealEstate_value.csv', ' ', '%20') as row
    with row
    
    merge (re:RealEstateValue { uid: apoc.util.md5(['USA', 'Florida', row.`City`, row.`Type`]) })
    set
        re.country = 'USA',
        re.state = 'Florida',
        re.city = row.`City`,
        re.type = row.`Type`,
        re.sqft_usd_low = toFloat(row.`price / sq feet - Low`),
        re.sqft_usd_median = toFloat(row.`price / sq feet - Median`),
        re.sqft_usd_high = toFloat(row.`price / sq feet - High`)
    
    return re;


// Mortage Loan: Person
    :auto using periodic commit 500
    load csv with headers from replace('https://raw.githubusercontent.com/Linkurious/dataset-aml/master/csv/Dataset AML Demo - MortgageLoans_Person.csv', ' ', '%20') as row
    with row

    merge (loan:MortageLoan { uid: apoc.util.md5([row.`contract id`]) })
    set
        loan.contract_id = row.`contract id`,
        loan.loan_amount = toFloat(row.`Initial amount`),
        loan.signature_date = row.`Date of signature`,
        loan.duration = toInteger(row.`Duration`),
        loan.monthly_instalment = row.`monthly instalment`,
        loan.type = row.`Type`,
        loan.city = row.`City`,
        loan.address = row.`address`,
        loan.longitude = toFloat(row.`Longitude`),
        loan.latitude = toFloat(row.`Latitude`),
        loan.purchase_price = toFloat(row.`Purchase price`),
        loan.sqft = toInteger(row.`Superficy feet`)
    
    merge (client:Person { uid: apoc.util.md5([row.`Owner id`]) }) set client:Client, client.`is_client` = true
    merge (client)-[:HAS_LOAN { uid: apoc.util.md5([client.uid, loan.uid]) }]->(loan)
    
    with row, loan, client
    
    call apoc.do.when(exists(row.`Guarantor id`), '
        merge (guarantor:Person { uid: apoc.util.md5([row.`Guarantor id`]) }) set guarantor:Guarantor, guarantor.`is_guarantor` = true
        merge (loan)-[:HAS_GUARANTOR { uid: apoc.util.md5([loan.uid, guarantor.uid]) }]->(guarantor)
        
        return row, guarantor
    ', 'return row, null as guarantor', { row: row, loan: loan }) yield value
    with row, loan, client, value.guarantor as guarantor

    call apoc.do.when(exists(row.`Realtor reg`), '
        merge (realtor:Company { uid: apoc.util.md5([row.`Realtor reg`]) }) set realtor:Realtor, realtor.`is_realtor` = true
        merge (loan)-[:HAS_REALTOR { uid: apoc.util.md5([loan.uid, realtor.uid]) }]->(realtor)
        
        return row, realtor
    ', 'return row, null as realtor', { row: row, loan: loan }) yield value
    with row, loan, client, guarantor, value.realtor as realtor
    
    call apoc.do.when(exists(row.`Broker reg`), '
        merge (broker:Company { uid: apoc.util.md5([row.`Broker reg`]) }) set broker:Broker, broker.`is_broker` = true
        merge (loan)-[:HAS_BROKER { uid: apoc.util.md5([loan.uid, broker.uid]) }]->(broker)
        
        return row, broker
    ', 'return row, null as broker', { row: row, loan: loan }) yield value
    with row, loan, client, guarantor, realtor, value.broker as broker

    return row, loan, client, guarantor, realtor, broker;


// Mortage Loan: Company
    :auto using periodic commit 500
    load csv with headers from replace('https://raw.githubusercontent.com/Linkurious/dataset-aml/master/csv/Dataset AML Demo - MortgageLoans_Company.csv', ' ', '%20') as row
    with row

    merge (loan:MortageLoan { uid: apoc.util.md5([row.`contract id`]) })
    set
        loan.contract_id = row.`contract id`,
        loan.loan_amount = toFloat(row.`Initial amount`),
        loan.signature_date = row.`Date of signature`,
        loan.duration = toInteger(row.`Duration`),
        loan.monthly_instalment = toFloat(row.`monthly instalment`),
        loan.type = row.`Type`,
        loan.address = row.`address`,
        loan.city = row.`City`,
        loan.longitude = toFloat(row.`Longitude`),
        loan.latitude = toFloat(row.`Latitude`),
        loan.purchase_price = toFloat(row.`Purchase price`),
        loan.sqft = toInteger(row.`Superficy feet`)

    merge (client:Company { uid: apoc.util.md5([row.`Registration number`]) }) set client:Client, client.`is_client` = true
    merge (client)-[:HAS_LOAN { uid: apoc.util.md5([client.uid, loan.uid]) }]->(loan)

    with row, loan, client
    
    call apoc.do.when(exists(row.`Realtor reg`), '
        merge (realtor:Company { uid: apoc.util.md5([row.`Realtor reg`]) }) set realtor:Realtor, realtor.`is_realtor` = true
        merge (loan)-[:HAS_REALTOR { uid: apoc.util.md5([loan.uid, realtor.uid]) }]->(realtor)
        
        return row, realtor
    ', 'return row, null as realtor', { row: row, loan: loan }) yield value
    with row, loan, client, value.realtor as realtor

    call apoc.do.when(exists(row.`Broker reg`), '
        merge (broker:Company { uid: apoc.util.md5([row.`Broker reg`]) }) set broker:Broker, broker.`is_broker` = true
        merge (loan)-[:HAS_BROKER { uid: apoc.util.md5([loan.uid, broker.uid]) }]->(broker)
        
        return row, broker
    ', 'return row, null as broker', { row: row, loan: loan }) yield value
    with row, loan, client, realtor, value.broker as broker
    
    return loan, client, realtor, broker;


// Schema Cleanup
    match (n:Client) remove n:Client;
    match (n:Guarantor) remove n:Guarantor;
    match (n:Realtor) remove n:Realtor;
    match (n:Broker) remove n:Broker;
// Schema Filling
    match (n:Person)  where not exists(n.is_client) set n.is_client = false;
    match (n:Person)  where not exists(n.is_guarantor) set n.is_guarantor = false;
    match (n:Company) where not exists(n.is_client) set n.is_client = false;
    match (n:Company) where not exists(n.is_broker) set n.is_broker = false;
    match (n:Company) where not exists(n.is_realtor) set n.is_realtor = false;


// Create Bank accounts / Transactions
    match (client:Person)-[:HAS_LOAN]->(loan:MortageLoan)
    with client, loan order by client.uid, loan.signature_date
    with client, loan, coalesce(client.reg_number, client.client_id) as owner_id, collect(loan.signature_date)[0] as initial_date

    merge (internal_account:BankAccount { uid: apoc.util.md5(['00000-00-0000000']) })

    merge (bank:BankAccount { uid: apoc.util.md5([loan.contract_id + '-' + owner_id]) })
    on create set
        bank.contract_id = loan.contract_id + '-' + owner_id,
        bank.open_date = initial_date,
        bank.close_date = null,
        bank.close_balance = null
    
    merge (client)-[:HAS_BANKACCOUNT { uid: apoc.util.md5([client.uid, bank.uid]) }]->(bank)

    merge (internal_account)-[rx:HAS_TRANSFERED { uid: apoc.util.md5([internal_account.uid, bank.uid, apoc.util.md5([internal_account.uid, bank.uid, loan.signature_date, loan.loan_amount])]) }]->(bank)
    set
        rx.identifier = apoc.util.md5([internal_account.uid, bank.uid, loan.signature_date, toFloat(loan.loan_amount)]),
        rx.date = loan.signature_date,
        rx.amount = toFloat(loan.loan_amount),
        rx.reason_for_payment = 'Initial transfer for loan #' + loan.contract_id
    
    with loan, client, internal_account, bank, rx, date(loan.signature_date) as sigdate, loan.duration * 12 as duration_months

    foreach (m in range(1, case when duration.between(sigdate, date()).months < duration_months then duration.between(sigdate, date()).months else duration_months end) |
        merge (bank)-[tx:HAS_TRANSFERED { uid: apoc.util.md5([bank.uid, internal_account.uid, apoc.util.md5([bank.uid, internal_account.uid, toString(sigdate + duration({ months: m })), toFloat(loan.monthly_instalment)])]) }]->(internal_account)
        set
            tx.identifier = apoc.util.md5([bank.uid, internal_account.uid, toString(sigdate + duration({ months: m })), toFloat(loan.monthly_instalment)]),
            tx.date = toString(sigdate + duration({ months: m })),
            tx.amount = toFloat(loan.monthly_instalment),
            tx.reason_for_payment = 'Reimbursement of loan #' + loan.contract_id + " - transfer " + m + " of " + duration_months
    )
    
    return loan, client, internal_account, bank, rx;


// Inject specific patterns
    // Create Early loan reimboursement
    with '2020-04-20' as early_redemption_date
    match (client:Person { uid: apoc.util.md5(['71-2031902']) })-[:HAS_LOAN]->(loan:MortageLoan)

    match (client)-[:HAS_BANKACCOUNT]->(bank)-[t:HAS_TRANSFERED]->(internal_account:BankAccount { uid: apoc.util.md5(['00000-00-0000000']) })
    
    with
        early_redemption_date, client, loan, bank, internal_account,
        reduce(amount = 0, tx in collect(t) | case when tx.date < early_redemption_date then amount + tx.amount else amount end) as current_reimboursement,
        reduce(txs = collect(null), tx in collect(t) | case when tx.date >= early_redemption_date then txs + tx else txs end) as txs_to_delete
    
    merge (bank)-[tx:HAS_TRANSFERED { uid: apoc.util.md5([bank.uid, internal_account.uid, apoc.util.md5([bank.uid, internal_account.uid, early_redemption_date, loan.loan_amount - current_reimboursement])]) }]->(internal_account)
    set
        tx.identifier = apoc.util.md5([bank.uid, internal_account.uid, early_redemption_date, loan.loan_amount - current_reimboursement]),
        tx.date = early_redemption_date,
        tx.amount = loan.loan_amount - current_reimboursement,
        tx.reason_for_payment = 'Early redempion of loan #' + loan.contract_id
    
    with client, loan, bank, internal_account, tx, txs_to_delete
    unwind txs_to_delete as extra_tran delete extra_tran

    return client, loan, bank, internal_account, tx;


// Build Aggregated Transactions
    match (src:BankAccount)-[t:HAS_TRANSFERED]->(dst:BankAccount)
    with src, dst, sum(t.amount) as amount, count(t) as num

    merge (src)-[t2:HAS_TRANSFERED_AGG { uid: apoc.util.md5([src.uid, dst.uid]) }]->(dst)
    set
        t2.amount = amount,
        t2.number_transactions = num

    return src, t2, dst;
