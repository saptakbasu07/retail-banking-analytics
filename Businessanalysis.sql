--Which city and occupation segment generates the highest average account balance —
with all_over as(
select c.city,c.occupation,
round(avg(a.balance)::numeric,0) as average_balance
from customers c
join accounts a
on 
c.customer_id=a.customer_id 
where a.status='Active'
group by 1,2
)
select city,occupation,average_balance from(
select *,
dense_rank() over (order by average_balance desc) as ranking
from all_over
) t
where ranking=1;

--What percentage of accounts are dormant 
with dormant as(		
select 
count(account_id)::numeric as total_dormant
from accounts 
where status ='Dormant'
),
total as(
select
count(a.account_id) as total_accounts
from accounts a )
select 
d.total_dormant ,
t.total_accounts ,
round((d.total_dormant::decimal/t.total_accounts)*100,0) as percentage
from dormant d
cross join total t;

-- which account types (Savings / Salary / Current) have the highest dormancy rate?
select 
count(case when account_type='Savings' then 1 end) as savings_dormancy_account,
count(case when account_type='Salary' then 1 end) as salary_dormancy_account,
count(case when account_type='Current' then 1 end) as current_dormancy_account
from accounts 
where status='Dormant';
SELECT
    account_type,
    round(COUNT(CASE WHEN status='Dormant' THEN 1 END) * 100.0
    / COUNT(*),2) AS dormancy_rate
FROM accounts
GROUP BY account_type
ORDER BY dormancy_rate DESC;


--Which transaction channels (UPI, Mobile Banking, ATM, Branch, POS, Net Banking) are growing month-on-month
--2025
with channeling as(
select channel,
extract(month from transaction_date)  as transaction_month,
count(transaction_id ) as total_transactions
from transactions
where extract(year from transaction_date)= 2025
group by 1,2),
prev as(
select channel,
transaction_month ,
total_transactions ,
lag(total_transactions ) over (partition by channel order by transaction_month ) as previous_month_count
from channeling )
select 
    channel,
    transaction_month,
    total_transactions,
    lag(total_transactions) over (
        partition by channel order by transaction_month
    ) as previous_month_count,
    (total_transactions - lag(total_transactions) over (
        partition by channel order by transaction_month
    )) as growth_count,
    round(
        ( (total_transactions - lag(total_transactions) over (
            partition by channel order by transaction_month
        ))::decimal 
        / nullif(lag(total_transactions) over (
            partition by channel order by transaction_month
        ),0) ) * 100, 2
    ) as growth_percentage
from channeling
order by channel, transaction_month;


--Which loan types have the highest default rates 
with loan as(
select loan_type,
count(*) as loan_count
from loans
where loan_status='Default'
Group by 1)
select loan_type,loan_count from(
select loan_type,loan_count,
dense_rank() over(order by loan_count desc) as ranking
from loan)
t 
where ranking=1;

--and do customers with lower annual income or higher loan amounts default more often?
SELECT 
    SUM(CASE WHEN c.annual_income < 500000 THEN 1 ELSE 0 END) AS low_income_defaults,
    SUM(CASE WHEN c.annual_income >= 500000 THEN 1 ELSE 0 END) AS high_income_defaults,
    SUM(CASE WHEN l.loan_amount > 2500000 THEN 1 ELSE 0 END) AS high_loan_defaults,
    SUM(CASE WHEN l.loan_amount <= 2500000 THEN 1 ELSE 0 END) AS low_loan_defaults,
    COUNT(*) AS total_defaults
FROM customers c
JOIN loans l 
    ON c.customer_id = l.customer_id
WHERE l.loan_status = 'Default';

--Who are the top 10% customers by total transaction volume 
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


--Which issue categories take the longest to resolve —
select issue_category,
round(avg(resolution_days),1) as average_time_taken,
count(*) as total_tickets
from support_tickets 
group by 1
order by average_time_taken desc;
--and which categories have the worst customer satisfaction scores?
select issue_category,
round(avg(satisfaction_score),2)as average_rating,
count(*) as total_tickets
from support_tickets
group by 1
order by average_rating asc;

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

--Which of the 7 cities (Mumbai, Delhi, Bengaluru, etc.) has the highest average transaction amount — 
--and does the preferred channel differ by city?
with total as(		
select account_id,channel,
sum(amount) as total_Amount
from transactions 
group by 1,2
),
profile as(		
select c.city,a.account_id
from customers c
join accounts a 
using(customer_id)
where a.status='Active'),
average as(
select p.city,t.channel,
round(avg(t.total_amount)::numeric,0) as average_transaction_amount
from total t
join profile p
using(account_id)
group by 1,2
)
select  city,channel,average_transaction_amount from(
select city,channel,average_transaction_amount,
dense_rank() Over(partition by city order by average_transaction_amount desc) as ranking
from average )
t 
where ranking=1;


--Which customers have raised 3+ support tickets — 
--do they also have loan defaults or dormant accounts, suggesting they are at high churn risk?
with complaints as(
select customer_id,
count(*) as total_tickets
from support_tickets
group by 1
having count(*)>=3),
prof as(
select c.customer_id,
c.total_tickets,
case when exists ( select 1 
from loans l
where l.customer_id=c.customer_id 
and l.loan_status='Default'
) then 'Yes' else 'No' end as loan_defaults,
case when exists ( select 1 
from accounts a
where a.customer_id=c.customer_id 
and a.status ='Dormant'
) then 	'Yes' else 'No' end as dormant
from complaints c
)
SELECT 
    SUM(CASE WHEN loan_defaults='Yes' THEN 1 ELSE 0 END) AS defaults_count,
    SUM(CASE WHEN dormant='Yes' THEN 1 ELSE 0 END) AS dormant_count,
    COUNT(*) AS total_flagged
FROM prof;
