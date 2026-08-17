# CRM Sales Performance Analytics

An end-to-end data analytics project analyzing 3,000 CRM sales opportunities — from raw data cleaning through SQL analysis to an interactive Power BI dashboard. Built to answer real sales-operations questions: which regions and lead sources drive revenue, how long deals take to close, and where the sales team should focus effort.

## Business Questions Answered

1. What is total revenue and deal volume by region?
2. Which lead source (Website, Referral, Cold Call, Trade Show, Partner, Social Media) converts best?
3. Which companies have generated the most revenue?
4. How long does the average sales cycle take, by industry?
5. Is quarterly revenue growing or shrinking over time?
6. Which lead source has the highest win rate?

## Tools Used

- **PostgreSQL** — relational database, data storage and querying
- **SQL** — data extraction, aggregation, and business-question analysis (joins, `CASE WHEN` conditional logic, window-style aggregations, `GROUP BY`/`ORDER BY`)
- **Python (Pandas, NumPy)** — data cleaning: fixing inconsistent text casing/whitespace, handling missing values via industry-median imputation, feature engineering (`is_won`, `sales_cycle_days`)
- **Power BI Desktop** — interactive dashboard connected live to PostgreSQL via DirectQuery/Import

## Data

Synthetic but realistic CRM/sales opportunity data (3,000 records) modeled on a Salesforce-style export, including intentional data-quality issues (inconsistent casing, missing values, whitespace) to practice real-world cleaning. Fields: deal ID, company name, region, industry, lead source, sales rep, deal stage, deal amount, created date, close date.

## Data Cleaning Approach

- Standardized text fields (region, industry, company name) — fixed inconsistent casing and stripped whitespace, since duplicate category values (e.g., `"south"` vs `"South"`) silently break `GROUP BY` aggregations
- Imputed missing deal amounts using the **industry median** rather than mean (deal sizes are right-skewed, so median is more representative and not distorted by outlier deals) or a global fill value (industry-level context matters since typical deal size varies significantly by industry)
- Engineered two features: `is_won` (boolean flag) and `sales_cycle_days` (days between deal creation and close), enabling the win-rate and cycle-time analysis below

##Data Cleaning using python 
```python
import pandas as pd

df = pd.read_csv("crm_sales_raw.csv")

# Check what's dirty first — run this and look at the output
print(df.isna().sum())
print(df["region"].unique())
print(df["industry"].unique())
# Fix casing and whitespace
df["region"] = df["region"].str.strip().str.title()
df["industry"] = df["industry"].str.strip().str.title()
df["company_name"] = df["company_name"].str.strip().str.title()

# Fill missing amounts with industry median (a defensible, explainable choice)
df["amount_usd"] = df["amount_usd"].fillna(df.groupby("industry")["amount_usd"].transform("median"))
```
## Key Findings


- **Revenue by region:** ["South"] led with [2456300.00] in closed-won revenue, followed by [North] at [1932000.00].
- **Best-converting lead source:** [Cold Call] had the highest win rate at [61.9]%, compared to [Partner] at [61.0]% — suggesting the team should prioritize [insight/recommendation].
- **Sales cycle length:** ["Finance"] deals closed fastest on average ([42] days), while [IT Service] took longest ([44] days).
- **Top revenue driver:** ["Orbit Corp"] was the single largest account, contributing [218200.00] in closed-won revenue.
- **Quarterly trend:** Revenue [declined] from [15M] in [Quarter1] to [11M] in [Quarter4].

## SQL Analysis

All 6 queries are in [`sql/analysis_queries.sql`](sql/analysis_queries.sql). Example — win rate by lead source, using conditional aggregation:

```sql
SELECT
    lead_source,
    SUM(CASE WHEN stage = 'Closed Won' THEN 1 ELSE 0 END) AS won_count,
    SUM(CASE WHEN stage = 'Closed Lost' THEN 1 ELSE 0 END) AS lost_count,
    ROUND(
        SUM(CASE WHEN stage = 'Closed Won' THEN 1 ELSE 0 END)::numeric
        / NULLIF(SUM(CASE WHEN stage IN ('Closed Won', 'Closed Lost') THEN 1 ELSE 0 END), 0)
        * 100, 1
    ) AS win_rate_pct
FROM opportunities
WHERE stage IN ('Closed Won', 'Closed Lost')
GROUP BY lead_source
ORDER BY win_rate_pct DESC;
```

## Dashboard

Interactive Power BI dashboard connected live to PostgreSQL, with region and industry slicers for on-the-fly filtering.


**Visuals included:**
- Revenue by Region (bar chart, Closed Won only)
- Win Rate by Lead Source (bar chart, calculated via DAX `DIVIDE`/`CALCULATE`)
- Quarterly Revenue Trend (line chart, Closed Won only)
- Top 10 Companies by Revenue (bar/table, ranked)

The full `.pbix` file is in [`dashboard/crm_sales_dashboard.pbix`](dashboard/crm_sales_dashboard.pbix).

## How to Reproduce

1. Clone this repo
2. Load `data/crm_sales_clean.csv` into a PostgreSQL database:
   ```
   \copy opportunities FROM 'data/crm_sales_clean.csv' DELIMITER ',' CSV HEADER;
   ```
3. Run the queries in `sql/analysis_queries.sql` to reproduce the analysis
4. Open `dashboard/crm_sales_dashboard.pbix` in Power BI Desktop, and update the data source connection to point to your local PostgreSQL instance

## Repo Structure

```
crm-sales-analytics/
├── data/
│   └── crm_sales_clean.csv
├── sql/
│   └── analysis_queries.sql
├── dashboard/
│   ├── crm_sales_dashboard.pbix
│   └── dashboard_screenshot.png
└── README.md
```

---

*Built as a self-directed portfolio project to practice the full analytics workflow: data cleaning, SQL analysis, and BI dashboard design.*
