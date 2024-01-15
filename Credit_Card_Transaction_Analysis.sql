SELECT * FROM credit_card_transcations
SELECT DISTINCT exp_type FROM credit_card_transcations


--CHANGING THE DATA TYPE OF COLUMN TO MAKE IT COMPATIBLE
ALTER TABLE credit_card_transcations
ALTER COLUMN amount DECIMAL(5,2)

ALTER TABLE credit_card_transcations
ALTER COLUMN transaction_date DATE


1---write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

WITH totalamount_cte AS
(
    SELECT 
        city,
        SUM(amount) AS total_city_spend,
        SUM(SUM(amount)) OVER ( ) AS total_amount
    FROM 
        credit_card_transcations
    GROUP BY 
        city
)

SELECT TOP 5
    city,
    total_city_spend,
	total_amount,
    ROUND((total_city_spend * 100.00) / (total_amount),2) AS percentage_spend
FROM 
    totalamount_cte
ORDER BY 
    total_city_spend DESC;


--2- write a query to print highest spend month and amount spent in that month for each card type

WITH cte1 as
(
SELECT
card_type,
DATEPART(year,transaction_date) as yo,
DATENAME(MONTH,transaction_date) as mth,
SUM(amount) as amount_spend
FROM credit_card_transcations
GROUP BY 
card_type,
DATEPART(year,transaction_date),
DATENAME(MONTH,transaction_date)

)
, rank_cte as
(
SELECT 
*,
RANK() OVER (PARTITION BY card_type order by amount_spend desc,mth) as rnk
FROM
cte1)
SELECT * FROM rank_cte
WHERE rnk =1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
WITH cum_sum_cte as
(SELECT 
*,
SUM(amount) over(partition by card_type order by transaction_date, transaction_id) as cumm_sum
from credit_card_transcations

),
 high_cum_sum_cte as
(
SELECT *,
rank() over (partition by card_type order by cumm_sum asc ) as rnk
FROM
cum_sum_cte
WHERE cumm_sum > 1000000
)
SELECt * 
from 
high_cum_sum_cte
WHERE rnk =1

--4- write a query to find city which had lowest percentage spend for gold card type
SELECT TOP 1
city,
sum(amount) as total_spend,
SUM(CASE WHEN card_type = 'Gold' THEN AMOUNT ELSE 0 END) as gol_spend,
ROUND(SUM(CASE WHEN card_type = 'Gold' THEN AMOUNT ELSE 0 END)*1.00/sum(amount)*100.00 ,2)as gold_contribution
FROM credit_card_transcations
GROUP BY city
having sum(case when card_type='Gold' then amount else 0 end) > 0
order by gold_contribution 

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
WITH top_bottom_cte as

(
SELECT
city,
exp_type,
sum(amount) as total_expense,
rank() over (partition by city order by sum(amount))  as bottom_rank,
rank() over (partition by city order by sum(amount) desc) as top_rank

FROM
credit_card_transcations
GROUP BY
city,
exp_type
)
SELECT
city,
MAX(CASE WHEN bottom_rank = 1  then exp_type end) as lowest_expense_type,
MAX(CASE WHEN top_rank = 1  then exp_type end) as Highestt_expense_type
FROM top_bottom_cte
GROUP BY city

--6- write a query to find percentage contribution of spends by females for each expense type
SELECT
exp_type,
SUM(amount) as total_spend,
SUM(CASE WHEN gender = 'f' then amount END) as female_contributor,
ROUND(SUM(CASE WHEN gender = 'f' then amount END)*1.00/(SUM(amount))*100,2) as female_percentage_contributor
FROM
credit_card_transcations
GROUP BY exp_type

--7- which card and expense type combination saw highest month over month growth in Jan-2014

WITH growth_cte as
(
SELECT 
card_type,
exp_type,
month(transaction_date) as mth,
year(transaction_date) as yer,
sum(amount) as totl_amount 
FROM
credit_card_transcations
WHERE 
year(transaction_date) in (2013,2014)
GROUP BY
card_type,
exp_type,
month(transaction_date),
year(transaction_date)
)
SELECT TOP 1 *, (a.totl_amount-a.previous_amount) as mom_growth
FROM
(
SELECT
*,
lag(totl_amount,1) over (PARTITION BY card_type,exp_type order by yer, mth) as previous_amount
FROM 
growth_cte
)A
where  previous_amount is not null and yer = 2014 and mth = 1
order by mom_growth desc



---during weekends which city has highest total spend to total no of transcations ratio 

SELECT TOP 1 *, total_spend*1.0/no_of_transaction as spend_transaction_ratio
FROM
(
SELECT
city,
sum(amount)/count(*) as total_spend,
count(*) as no_of_transaction,
DATENAME(WEEKDAY,transaction_date) as dat_name
FROM
credit_card_transcations
where DATENAME(WEEKDAY,transaction_date) in ('Saturday','Sunday')
GROUP BY
city,
DATENAME(WEEKDAY,transaction_date)
) A
ORDER BY spend_transaction_ratio desc

----which city took least number of days to reach its 500th transaction after the first transaction in that city

With cte as
(
SELECT
*,
row_number() over (partition by city order by transaction_date,transaction_id) as rn
FROM
credit_card_transcations
)
SELECT 
city,
min(transaction_date) as minimum_transaction_date,max(transaction_date) as maximum_transaction_date,
DATEDIFF(day,min(transaction_date),max(transaction_date)) as day_to_500
FROM cte
WHERE rn in (1,500)
GROUP BY city
HAVING count(*) >=2
ORDER BY day_to_500


