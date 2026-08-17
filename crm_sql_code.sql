DROP TABLE IF EXISTS opportunities;

CREATE TABLE opportunities (
    deal_id VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(100),
    region VARCHAR(20),
    industry VARCHAR(30),
    lead_source VARCHAR(30),
    sales_rep VARCHAR(50),
    stage VARCHAR(20),
    amount_usd NUMERIC(10,2),
    created_date DATE,
    close_date DATE,
    is_won BOOLEAN,
    sales_cycle_days Numeric(6,1)
);

SELECT COUNT(*) FROM opportunities;
SELECT * FROM opportunities LIMIT 5;

/* Query 1: Total revenue and win rate by region (Closed Won deals only)*/
select region,sum(amount_usd) from opportunities
where stage = 'Closed Won' 
group by region;

/*The business question: Of all deals that reached a final outcome (Won or Lost) in each region, what percentage were won?*/
SELECT 
    region,
    SUM(CASE WHEN stage = 'Closed Won' THEN 1 ELSE 0 END) AS won_count,
    SUM(CASE WHEN stage = 'Closed Lost' THEN 1 ELSE 0 END) AS lost_count
FROM opportunities
WHERE stage in ('Closed Won','Closed Lost')
GROUP BY region;

/*Query 3: Top 10 companies by deal value
Business question: Which companies have brought in the most revenue (Closed Won deals only)?*/
Select company_name, sum(amount_usd) as total_revenue
from opportunities
where stage = 'Closed Won'
group by company_name
order by total_revenue Desc 
limit 10;

/* Query 4: Average sales cycle length by industry

Business question: Which industries take longest to close a deal? (Useful for sales forecasting — a consulting firm like Deloitte would care about this.)*/
select industry, avg(sales_cycle_days) as avg_sales_cycle 
from opportunities
where stage in ('Closed Won','Closed Lost')
group by industry;

/*Query 5: Quarter-over-quarter revenue trend

Business question: Is revenue growing or shrinking over time? (Closed Won deals only.)*/
select created_date, sum(amount_usd) as quarterly_revenue from opportunities
where stage = 'Closed Won'
group by created_date
order by created_date asc; 

/*Query 6: Win rate by lead source

Business question: Which lead source (Website, Referral, Cold Call, Trade Show, Partner, Social Media) converts best? This tells the business where to invest marketing/sales effort*/

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
	
