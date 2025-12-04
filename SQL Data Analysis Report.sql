create database project;
use project;
# showing all columns
SELECT * FROM coffee_sales;
# checking datatype of clumns
describe coffee_sales;
# rename column hour_of_day
alter table coffee_sales rename column ï»¿hour_of_day to hour_of_day;
# creating new data column because existing one have the text datatype
alter table  coffee_sales ADD COLUMN Date_new DATE;
set sql_safe_updates=0;
# update and set the date by using STR_TO_DATE function
update coffee_sales
set Date_new = STR_TO_DATE(Date, '%d-%m-%Y');
# drop the date column
alter table  coffee_sales drop COLUMN Date;
# rename Date_new to date
alter table  coffee_sales change Date_new Date DATE;

-- checking dublicate value based on Date, Time, coffee_name 
select Date, Time, coffee_name, COUNT(*) AS DuplicateCount
from coffee_sales
group by Date, Time, coffee_name
having count(*) >1;

-- Standardize inconsistent text (case-insensitive)
update Coffee_Sales
set coffee_name = CONCAT(ucase(left(coffee_name,1)),lcase(substring(coffee_name,2)));

-- Total sales by coffee_name,and month
select Month_name,coffee_name,sum(money) as total_sales
from Coffee_Sales
group by Month_name,coffee_name;

-- Top 5 most sold coffee types by revenue
select coffee_name, sum(money) as total_revenue
from Coffee_Sales
group by coffee_name
order by total_revenue desc
limit 5;

--  CTE — month-over-month growth rate
with monthlysales as (
select Monthsort,Month_name,sum(money) as total_sales
from Coffee_Sales
group by Monthsort,Month_name
),
Growth as (
select Month_name,total_sales,
lag(total_sales) over(order by Monthsort) as prevmonthsales,
round(((total_sales-lag(total_sales) over(order by Monthsort))/lag(total_sales) over(order by Monthsort))*100,2) as Growth_rate
from monthlysales)
select * from Growth;

-- CTE to find best-performing month
with Monthlysales as (
select Month_name, sum(money) as total_sales
from Coffee_Sales
group by Month_name
)
select Month_name, total_sales
from Monthlysales
where total_sales = (select max(total_sales) from Monthlysales);

-- Rank all coffee types
select coffee_name, sum(money) as total_revenue,
rank() over(order by sum(money) desc) as rank_by_revenue
from Coffee_Sales
group by coffee_name;

-- Monthly sales trend
select Month_name,sum(money) as total_sales
from Coffee_Sales
group by Month_name,Monthsort
order by Monthsort;

-- Product category performance
select coffee_name,sum(money) as total_sales
from Coffee_Sales
group by coffee_name
order by total_sales desc;

-- Procedure for sales summary in date range

DELIMITER //
CREATE PROCEDURE GetSalesSummary(in start_date date, in end_date date)
BEGIN
select sum(money) as total_sales,
count(*) as total_product,
(select coffee_name
from Coffee_Sales
where `Date` between start_date and end_date
group by coffee_name
order by sum(money) desc
limit 1) as top_product
from Coffee_Sales
where `Date` between start_date and end_date;
END //
DELIMITER ;
CALL GetSalesSummary('2024-03-01','2024-04-30');

-- Procedure for low-performing products
DELIMITER //
CREATE PROCEDURE LowPerformer(in sales_limit double)
BEGIN
select coffee_name, sum(money) as total_sales
from Coffee_Sales
group by coffee_name
having sum(money) < sales_limit;
END //
DELIMITER ;
 call LowPerformer(10000.00);
