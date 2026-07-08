# 🏦 Bank Transaction Data Cleaning & Analysis

## 📌 Problem Statement
Raw bank transaction data often contains inconsistencies — mixed date
formats, inconsistent text casing, typos, extra whitespace, and missing
values — that make direct analysis unreliable. This project cleans and
analyzes a messy transaction dataset to produce accurate, trustworthy
insights.

## 🎯 Objective
Clean a messy bank transaction dataset and analyze it to understand
transaction patterns by type, channel, customer occupation, and
account activity, while flagging potentially suspicious behavior.

## 🗂️ Dataset
- Raw file: `data/raw/FinServe_Bank_Transactions_Messy.csv`
- Cleaned file: `data/Processed/FinServe_bank_transactions_cleaned.csv`
- Rows: ~2,600 | Columns: 16
- Fields include: TransactionID, AccountID, TransactionAmount,
  TransactionDate, TransactionType, Location, Channel, CustomerAge,
  CustomerOccupation, AccountBalance, LoginAttempts, and more

## 🛠️ Tools Used
- **Python (Pandas, Matplotlib, Seaborn)** — data cleaning & exploratory analysis
- **SQL** — aggregation & pattern analysis

## 🔄 Project Workflow
1. Identified data quality issues in the raw dataset (inconsistent
   casing, mixed date formats, extra whitespace, typos, missing values)
2. Cleaned and standardized the data using Python
3. Saved a cleaned dataset for downstream analysis
4. Wrote SQL queries to analyze transaction patterns by type, channel,
   and customer segment

## 🧹 Data Cleaning Highlights
- Standardized inconsistent text casing across `TransactionType`,
  `Channel`, and `CustomerOccupation` (e.g., `Debit`/`DEBIT`/`debit` → `Debit`)
- Fixed typos in categorical fields (e.g., `Studnt` → `Student`)
- Removed extra whitespace from category fields (e.g., `"  ATM  "` → `ATM`)
- Parsed multiple inconsistent date formats (e.g., `11/4/2023`,
  `20-Nov-23`, `4-Nov-24`) into a single standard datetime format
- Handled missing values in `CustomerAge`, `CustomerOccupation`, and `AccountBalance`

👉 [View notebook](./Python/[your_notebook_filename].ipynb)

## 🧮 SQL Analysis
- Aggregated transaction counts and totals by transaction type and channel
- Analyzed average account balance by customer occupation
- Flagged transactions with multiple login attempts as potentially suspicious

👉 [View SQL file](./SQL/[your_sql_filename].sql)

## 💡 Key Insights
- Debit transactions account for 77% of all activity (2,021 of 2,622
  transactions), compared to 23% Credit — the dataset is heavily
  debit-skewed.
- ATM transactions have the highest average transaction amount (₹532),
  followed by Online (₹462) and Branch (₹371) — larger transactions
  tend to happen at ATMs rather than in-branch.
- Students hold the lowest average account balance (~₹1,572) but still
  transact frequently, suggesting high transaction-to-balance activity.
- 5% of transactions (131 of 2,622) show more than 1 login attempt,
  and this subset has a much higher average transaction amount (₹623
  vs ₹350 overall) and far more extreme outliers (max ₹44,541) —
  a pattern worth flagging for fraud review.
- The dataset contains notable data quality issues beyond simple
  casing/typos: some records show implausible values such as negative
  customer ages, an age of 999, and login attempt counts as high as 50–100
  — these are likely data entry errors or placeholder/error codes that
  need separate handling before any fraud model is built on this data.
## ✅ Business Recommendations
- Flag and manually review transactions with multiple login attempts
  (>1), especially high-value ones — this small 5% segment shows
  disproportionately large and volatile transaction amounts.
- Investigate the low average account balance among Student customers
  relative to their transaction frequency, to assess overdraft/credit
  risk exposure for this segment.
- Treat ATM as a higher-value channel in fraud monitoring, since it
  carries the highest average transaction size among all channels.
- Add validation rules at data entry (e.g., age range checks, login
  attempt caps) to prevent clearly invalid values (negative ages, age
  999, login attempts >10) from entering the system uncleaned.

## 🚀 Future Improvements
- Build a Power BI dashboard for interactive exploration of transaction patterns
- Apply anomaly detection techniques to more systematically flag suspicious transactions

## 📬 Contact
Kartik Dogra | www.linkedin.com/in/kartik-dogra-120019416 | kartikdogra229720@gmail.com
