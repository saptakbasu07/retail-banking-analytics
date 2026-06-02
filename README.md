# 🏦 Retail Banking Analytics

A business-oriented analytics project built using **PostgreSQL, Power BI, and Excel** to analyze customer behavior, deposit performance, loan risk, digital banking adoption, and customer service efficiency within a retail banking environment.

The project combines advanced SQL analysis with interactive Power BI dashboards to transform banking data into actionable business insights for customer retention, risk management, and operational decision-making.

---

## 📌 Business Objectives

* Identify high-value customer segments and deposit concentration patterns
* Monitor dormant accounts and customer engagement levels
* Analyze loan portfolio performance and default risk drivers
* Track digital banking adoption and channel usage trends
* Evaluate customer service performance and satisfaction metrics
* Detect potential churn-risk customers through behavioral indicators

---

## 📈 Executive Insights

* High-value customers contribute a significant share of the total deposit portfolio, highlighting both growth opportunities and concentration risk.
* Dormant accounts represent a measurable retention opportunity for targeted reactivation campaigns.
* Loan default rates are highest among customers with lower income-to-loan ratios, indicating elevated credit risk.
* Digital banking adoption continues to grow, with mobile channels showing the strongest engagement trends.
* Faster complaint resolution is consistently associated with higher customer satisfaction outcomes.

---

## 🛠 Technology Stack

| Tool            | Purpose                               |
| --------------- | ------------------------------------- |
| PostgreSQL      | Data Analysis & Business Querying     |
| Power BI        | Dashboard Development & Visualization |
| Microsoft Excel | Data Preparation & Validation         |

---

## 📊 Dashboard Overview

### Executive Summary

Provides a consolidated view of banking KPIs including customer base, deposits, loans, portfolio performance, risk indicators, and digital adoption metrics.

### Customer & Deposit Analytics

Analyzes customer segmentation, account behavior, balance distribution, dormant accounts, and deposit performance.

### Loan & Risk Analytics

Evaluates loan portfolio quality, default behavior, income-based risk segmentation, and lending performance.

---

## 🔍 Analytical Coverage

### Customer Analytics

* Customer segmentation
* High-value customer identification
* Customer tenure analysis

### Deposit Analytics

* Average balance analysis
* Deposit concentration analysis
* Dormant account monitoring

### Loan & Risk Analytics

* Loan default analysis
* Risk segmentation
* Income-to-loan ratio analysis

### Digital Banking Analytics

* Channel adoption trends
* Month-on-month transaction growth
* Digital engagement analysis

### Customer Service Analytics

* Resolution time analysis
* Customer satisfaction analysis
* Service quality monitoring

---

## 💡 SQL Highlights

* Common Table Expressions (CTEs)
* Window Functions (`LAG`, `RANK`, `DENSE_RANK`, `NTILE`)
* Customer Segmentation Analysis
* Month-on-Month Growth Calculations
* Loan Risk Assessment
* Churn Risk Identification
* Multi-Table Joins
* Advanced Aggregations & KPI Development

* --Who are the top 10% customers by total transaction volume 
--what is their occupation, city, and account type profile?

  
with txn as(			
select a.customer_id,
sum(t.amount) as total_transaction_amount
from accounts a  
join transactions t
on 
a.account_id=t.account_id 
where a.status='Active'
group by 1
),
ranked as(			
select c.occupation ,c.city , a.account_type ,
t.total_transaction_amount ,
ntile(10) over (order by t.total_transaction_amount desc) as decile
from customers c 
join txn t
on c.customer_id = t.customer_id
join accounts a
on 
c.customer_id = a.customer_id
)
select occupation, city, account_type,count(*) as total_customers
from ranked
where decile=1
group by 1,2,3
order by total_customers desc;


--Do customers who have been with the bank longer (older customer_since date
--) maintain higher balances and raise fewer complaints?


with tenure as(
select customer_id,
extract(year from age(Current_date,customer_since)) as tenure
from customers ),
profile as(		
select c.customer_id,
avg(a.balance) as average_balance,
count(s.ticket_id) as total_complaints
from customers c
left join accounts a 
on 
c.customer_id = a.customer_id
left join support_tickets s
on 
c.customer_id = s.customer_id
where a.status ='Active'
group by 1)
select t.tenure ,
round(avg(p.average_balance)::numeric,1) as average_balance_by_tenure,
round(avg(p.total_complaints ),1) as average_complaints_byt_tenure
from tenure t
join profile p
on 
t.customer_id =p.customer_id 
group by 1
order by 1 desc;

---

## 🚀 Skills Demonstrated

* SQL Analytics
* Business Intelligence
* Data Visualization
* KPI Development
* Risk Analytics
* Customer Analytics
* Banking Domain Analysis
* Dashboard Design
* Data Storytelling

---

## 👨‍💻 Author

**Saptak Basu**

Aspiring Data Analyst with hands-on experience in Banking, E-commerce, and Manufacturing Analytics using SQL, Power BI, and Excel.
