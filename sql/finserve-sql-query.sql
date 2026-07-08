--creating database
Create database finserve_bank


Use finserve_bank
Create table bank_transactions (
 Transaction_ID      VARCHAR(20)     NOT NULL,
 Account_ID          VARCHAR(20)     NOT NULL,
 Transaction_Amount  DECIMAL(10,2)   NOT NULL,
 Transaction_Date    DATETIME        NOT NULL,
 Transaction_Type    VARCHAR(10)     NOT NULL,
 Location            VARCHAR(100),
  Device_ID           VARCHAR(20),
 IP_Address          VARCHAR(20),
 Merchant_ID         VARCHAR(20),
 Channel             VARCHAR(20),
 Customer_Age        INT,
 Customer_Occupation VARCHAR(50),
 Transaction_Duration INT,
 Login_Attempts      INT,
 Account_Balance     DECIMAL(12,2),
 Previous_Txn_Date   DATETIME,
 Fraud_Flag          INT,
    
    PRIMARY KEY (Transaction_ID))


-- loading the cleaned csv - everything comes in as text at this stage
Bulk insert bank_transactions
from 'C:\FinServe_Bank_Transactions_clean.csv'
with (
    Firstrow = 2,
    Fieldterminator = ',',
    Rowterminator = '\n',
    Tablock)

-- confirm the import actually loaded rows before doing anything else
select count(*) AS total_rows FROM bank_transactions

-- converting each column to its real data type now that rows are in the table
alter table bank_transactions
alter column Transaction_Amount decimal(10,2)

alter table bank_transactions
alter column Customer_Age int

alter table bank_transactions
alter column Account_Balance decimal(12,2)

alter table bank_transactions
alter column Transaction_Duration int

alter table bank_transactions
alter column Login_Attempts int

-- Fraud_Flag came in blank for every row in this dataset, so defaulting to 0
-- before converting to int (int can't hold a blank/empty string)
update bank_transactions
set Fraud_Flag = '0'

 alter table bank_transactions
alter column Fraud_Flag int

alter table bank_transactions
alter column Transaction_Date datetime

-- sanity check - confirms every column actually converted to the right type
select 
column_name,
data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'bank_transactions'

select * from bank_transactions

-- all debit transactions
select Transaction_ID,Account_ID,Transaction_Amount,Transaction_Date,Transaction_Type,
Location
from bank_transactions
where Transaction_Type = 'Debit'

-- debit transactions over 500 - higher-value debits specifically
select Transaction_ID,Account_ID,Transaction_Amount,Transaction_Date,Transaction_Type,
Location
from bank_transactions
where Transaction_Type = 'Debit'
and Transaction_Amount > 500

-- transactions made through either ATM or Online channels
select Transaction_ID,Account_ID,Transaction_Amount,Transaction_Date,Transaction_Type,
Location
from bank_transactions
where Channel = 'ATM'
or Channel = 'Online'

-- every transaction, largest amount first
select Transaction_ID,Account_ID,Transaction_Amount,Transaction_Date,Transaction_Type,
Location
from bank_transactions
ORDER BY Transaction_Amount DESC

-- chronological view of transactions
Select Transaction_ID,Transaction_Amount,Transaction_Date
from bank_transactions
order by Transaction_Date ASC

-- list of distinct locations - useful to check for typos/inconsistent naming
select distinct Location
from bank_transactions
order by Location ASC

-- how many unique customers (accounts) are in the dataset
select count(distinct Account_ID) as unique_customers
from bank_transactions

-- top 10 highest transactions with customer context attached
select top 10 Transaction_ID,Account_ID,Transaction_Amount, Transaction_Type,Channel,Customer_Age,Customer_Occupation
from bank_transactions
order by Transaction_Amount DESC

-- headline summary stats for the whole dataset
select count(*) as total_transactions,count(distinct Account_ID) as unique_customers,sum(Transaction_Amount) as total_volume,round(avg(Transaction_Amount),2)as avg_transaction,max(Transaction_Amount) as highest_transaction,min(Transaction_Amount) as lowest_transaction
FROM bank_transactions

-- performance breakdown by channel (ATM, Online, Branch etc)
select Channel,count(*) as transaction_count,
round(sum(Transaction_Amount), 2)   as total_volume,
round(avg(Transaction_Amount), 2) as avg_amount
from bank_transactions
group by Channel
order by total_volume desc

-- same as above, but only channels with meaningful volume (500+ transactions)
select Channel,count(*)as transaction_count,round(sum(Transaction_Amount), 2) as total_volume
from bank_transactions
group by Channel
having count(*) > 500
order by transaction_count desc

-- Categorise transactions by amount
SELECT 
    Transaction_ID,
    Account_ID,
    Transaction_Amount,
    Transaction_Type,
    Channel,
    CASE 
        WHEN Transaction_Amount < 100  THEN 'Low Value'
        WHEN Transaction_Amount < 500  THEN 'Medium Value'
        WHEN Transaction_Amount >= 500 THEN 'High Value'
        ELSE 'Unknown'
    END AS Amount_Category
FROM bank_transactions
ORDER BY Transaction_Amount DESC;

-- Count transactions in each value category
SELECT 
    CASE 
        WHEN Transaction_Amount < 100  THEN 'Low Value'
        WHEN Transaction_Amount < 500  THEN 'Medium Value'
        WHEN Transaction_Amount >= 500 THEN 'High Value'
        ELSE 'Unknown'
    END                               AS Amount_Category,
    COUNT(*)                          AS transaction_count,
    ROUND(SUM(Transaction_Amount), 2) AS total_volume,
    ROUND(AVG(Transaction_Amount), 2) AS avg_amount
FROM bank_transactions
GROUP BY 
    CASE 
        WHEN Transaction_Amount < 100  THEN 'Low Value'
        WHEN Transaction_Amount < 500  THEN 'Medium Value'
        WHEN Transaction_Amount >= 500 THEN 'High Value'
        ELSE 'Unknown'
    END
ORDER BY total_volume DESC;

-- Accounts starting with ACC - checking account ID naming convention held up
SELECT 
    Transaction_ID,
    Account_ID,
    Transaction_Amount,
    Transaction_Type
FROM bank_transactions
WHERE Account_ID LIKE 'ACC%';

-- any transaction tied to a location containing "York"
SELECT *
FROM bank_transactions
WHERE Location LIKE '%York%'

-- transactions where Merchant_ID follows the M-prefix naming pattern
SELECT *
FROM bank_transactions
WHERE Merchant_ID LIKE 'M%'

-- mid-range transactions, 200 to 500
SELECT 
    Transaction_ID,
    Transaction_Amount,
    Transaction_Type,
    Channel
FROM bank_transactions
WHERE Transaction_Amount BETWEEN 200 AND 500
ORDER BY Transaction_Amount DESC

-- transactions restricted to ATM or Online channels only
SELECT 
    Transaction_ID,
    Transaction_Amount,
    Transaction_Type,
    Channel
FROM bank_transactions
WHERE Channel IN ('ATM', 'Online')
ORDER BY Transaction_Amount DESC

-- Channel performance report
-- adds a plain-English label per channel, then restricts to higher-value
-- transactions within a specific year, and only channels with real volume
SELECT 
    Channel,
    CASE 
        WHEN Channel = 'ATM'     THEN 'Automated Machine'
        WHEN Channel = 'Online'  THEN 'Digital Banking'
        WHEN Channel = 'Branch'  THEN 'Physical Branch'
        ELSE 'Unrecorded'
    END                               AS Channel_Description,
    COUNT(*)                          AS transaction_count,
    ROUND(SUM(Transaction_Amount), 2) AS total_volume,
    ROUND(AVG(Transaction_Amount), 2) AS avg_amount,
    MAX(Transaction_Amount)           AS highest_transaction
FROM bank_transactions
WHERE Transaction_Amount > 500
AND Transaction_Date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY Channel
HAVING COUNT(*) > 100
ORDER BY total_volume DESC

-- small reference table to segment customers by occupation -
-- not in the original dataset, added manually to demonstrate joins
CREATE TABLE occupation_segments (
    Occupation      NVARCHAR(50),
    Segment_Type    NVARCHAR(50),
    Risk_Level      NVARCHAR(20),
    Avg_Income_Band NVARCHAR(20)
);

-- Insert reference data
INSERT INTO occupation_segments VALUES
('Doctor',   'Professional', 'Low',    'High Income'),
('Engineer', 'Professional', 'Low',    'High Income'),
('Retired',  'Senior',       'Medium', 'Fixed Income'),
('Student',  'Youth',        'High',   'Low Income')

-- inner join - only shows transactions where the occupation has a matching
-- segment defined above (drops any occupation not in the reference table)
SELECT 
    bt.Transaction_ID,
    bt.Account_ID,
    bt.Transaction_Amount,
    bt.Transaction_Type,
    bt.Customer_Occupation,
    os.Segment_Type,
    os.Risk_Level,
    os.Avg_Income_Band
FROM bank_transactions bt
INNER JOIN occupation_segments os
    ON bt.Customer_Occupation = os.Occupation
ORDER BY bt.Transaction_Amount DESC

-- left join - keeps every transaction regardless of whether the occupation
-- has a segment defined; unmatched occupations show NULLs for segment info
SELECT 
    bt.Transaction_ID,
    bt.Transaction_Amount,
    bt.Customer_Occupation,
    os.Segment_Type,
    os.Risk_Level,
    os.Avg_Income_Band
FROM bank_transactions bt
LEFT JOIN occupation_segments os
    ON bt.Customer_Occupation = os.Occupation
ORDER BY bt.Transaction_Amount DESC

-- test row inserted to confirm the insert statement/column order works
-- before trusting it - removed later with the DELETE statement below
INSERT INTO bank_transactions 
    (Transaction_ID, Account_ID, Transaction_Amount,
     Transaction_Date, Transaction_Type, Location,
     Device_ID, IP_Address, Merchant_ID, Channel,
     Customer_Age, Customer_Occupation, 
     Transaction_Duration, Login_Attempts,
     Account_Balance, Fraud_Flag)
VALUES
    ('TXN_TEST01', 'ACC_TEST01', 350.00,
     '2023-06-15', 'Debit', 'Mumbai',
     'DEV999', '192.168.1.1', 'MER999', 'ATM',
     35, 'Freelancer',
     120, 1,
     5000.00, 0)

-- confirms how many rows actually match between the two tables via inner join
SELECT COUNT(*) AS inner_join_count
FROM bank_transactions bt
INNER JOIN occupation_segments os
    ON bt.Customer_Occupation = os.Occupation

-- compares against the left join count - the gap between the two numbers
-- is exactly how many transactions have an occupation with no segment defined
SELECT COUNT(*) AS left_join_count
FROM bank_transactions bt
LEFT JOIN occupation_segments os
    ON bt.Customer_Occupation = os.Occupation

-- cleaning up the test row inserted above, now that the insert is confirmed working
DELETE FROM bank_transactions
WHERE Transaction_ID = 'TXN_TEST01'

-- transactions above the overall average amount - flags unusually large transactions
SELECT 
    Transaction_ID,
    Account_ID,
    Transaction_Amount,
    Transaction_Type,
    Channel,
    Customer_Occupation
FROM bank_transactions
WHERE Transaction_Amount > (
    SELECT AVG(Transaction_Amount) 
    FROM bank_transactions)

-- same idea as above but per-customer instead of overall: flags customers
-- whose total spend is above the average total spend across all customers.
-- written first as a nested subquery (harder to read), then rebuilt with a
-- CTE further down for comparison
SELECT 
    Account_ID,
    total_spent,
    CASE 
        WHEN total_spent > (
            SELECT AVG(total_spent) 
            FROM (
                SELECT Account_ID, 
                       SUM(Transaction_Amount) AS total_spent
                FROM bank_transactions
                GROUP BY Account_ID
            ) AS sub
        ) THEN 'High Value'
        ELSE 'Regular'
    END AS customer_tier
FROM (
    SELECT Account_ID, 
           SUM(Transaction_Amount) AS total_spent
    FROM bank_transactions
    GROUP BY Account_ID
) AS customer_totals

-- saved as a view so channel performance can be queried directly later
-- without rewriting the aggregation each time
GO
CREATE VIEW vw_channel_performance AS
SELECT 
    Channel,
    COUNT(*)                            AS transaction_count,
    ROUND(SUM(Transaction_Amount), 2)   AS total_volume,
    ROUND(AVG(Transaction_Amount), 2)   AS avg_amount,
    MAX(Transaction_Amount)             AS highest_transaction,
    MIN(Transaction_Amount)             AS lowest_transaction
FROM bank_transactions
GROUP BY Channel
GO

-- ranks every transaction within its own channel, highest amount first
SELECT 
    Transaction_ID,
    Account_ID,
    Transaction_Amount,
    Channel,
    Transaction_Type,
    ROW_NUMBER() OVER (
        PARTITION BY Channel 
        ORDER BY Transaction_Amount DESC
    ) AS rank_in_channel
FROM bank_transactions

-- comparing the three ranking functions side by side on the same data -
-- row_number always gives unique numbers, rank leaves gaps after ties,
-- dense_rank doesn't leave gaps after ties
SELECT 
    Transaction_ID,
    Transaction_Amount,
    Channel,
    ROW_NUMBER()  OVER (PARTITION BY Channel 
                        ORDER BY Transaction_Amount DESC) AS row_num,
    RANK()        OVER (PARTITION BY Channel 
                        ORDER BY Transaction_Amount DESC) AS rank_num,
    DENSE_RANK()  OVER (PARTITION BY Channel 
                        ORDER BY Transaction_Amount DESC) AS dense_rank
FROM bank_transactions

-- LAG: compares each transaction to the account's previous transaction,
-- to see how much the spend changed from one transaction to the next
SELECT 
    Transaction_ID,
    Account_ID,
    Transaction_Date,
    Transaction_Amount,
    LAG(Transaction_Amount, 1, 0) OVER (
        PARTITION BY Account_ID 
        ORDER BY Transaction_Date
    ) AS previous_amount,
    Transaction_Amount - 
    LAG(Transaction_Amount, 1, 0) OVER (
        PARTITION BY Account_ID 
        ORDER BY Transaction_Date
    ) AS amount_change
FROM bank_transactions
ORDER BY Account_ID, Transaction_Date

-- Running total by date - daily volume plus a cumulative total across
-- the whole dataset, useful for spotting overall growth over time
SELECT 
    CAST(Transaction_Date AS DATE)        AS txn_date,
    COUNT(*)                              AS daily_transactions,
    ROUND(SUM(Transaction_Amount), 2)     AS daily_volume,
    ROUND(SUM(SUM(Transaction_Amount)) OVER (
        ORDER BY CAST(Transaction_Date AS DATE)
    ), 2)                                 AS running_total
FROM bank_transactions
GROUP BY CAST(Transaction_Date AS DATE)
ORDER BY txn_date

-- final report: occupation-level stats, ranked by total volume, with a
-- segment label based on average transaction size. built with a CTE
-- instead of nested subqueries so each step reads top to bottom
WITH occupation_stats AS (
    SELECT 
        Customer_Occupation,
        COUNT(*)                          AS total_transactions,
        COUNT(DISTINCT Account_ID)        AS unique_customers,
        ROUND(SUM(Transaction_Amount), 2) AS total_volume,
        ROUND(AVG(Transaction_Amount), 2) AS avg_transaction,
        MAX(Transaction_Amount)           AS highest_transaction
    FROM bank_transactions
    GROUP BY Customer_Occupation
),
ranked AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_volume DESC) AS volume_rank,
        CASE 
            WHEN avg_transaction > 300 THEN 'Premium Segment'
            WHEN avg_transaction > 200 THEN 'Standard Segment'
            ELSE 'Budget Segment'
        END AS segment_label
    FROM occupation_stats
)
SELECT 
    volume_rank         AS [Rank],
    Customer_Occupation AS [Occupation],
    total_transactions  AS [Total Txns],
    unique_customers    AS [Unique Customers],
    total_volume        AS [Total Volume ($)],
    avg_transaction     AS [Avg Transaction ($)],
    highest_transaction AS [Highest Txn ($)],
    segment_label       AS [Segment]
FROM ranked
ORDER BY volume_rank
