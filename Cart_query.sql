select *  
from sales

select *  
from orders

select *  
from customers

select *  
from products
------------Add column ------------------------------------------------------------------------------------------------
ALTER TABLE sales
ADD COLUMN total_sale float;

UPDATE sales
SET total_sale = price_per_unit * quantity;
----------------------------------------------------------------------------------------------------------------------
SELECT customer_id, customer_name, age,
  CASE 
    WHEN Age BETWEEN 20 AND 29 THEN '20-29'
    WHEN Age BETWEEN 30 AND 39 THEN '30-39'
    WHEN Age BETWEEN 40 AND 49 THEN '40-49'
    WHEN Age BETWEEN 50 AND 59 THEN '50-59'
    WHEN Age BETWEEN 60 AND 69 THEN '60-69'
    WHEN Age BETWEEN 70 AND 80 THEN '70-80'
  END AS AgeRange
FROM customers;
------------Add column

ALTER TABLE customers
ADD COLUMN Age_range VARCHAR(10);

UPDATE customers
SET Age_range = 
  CASE 
    WHEN Age BETWEEN 20 AND 29 THEN '20-29'
    WHEN Age BETWEEN 30 AND 39 THEN '30-39'
    WHEN Age BETWEEN 40 AND 49 THEN '40-49'
    WHEN Age BETWEEN 50 AND 59 THEN '50-59'
    WHEN Age BETWEEN 60 AND 69 THEN '60-69'
    WHEN Age BETWEEN 70 AND 80 THEN '70-80'
  END;

-----------------------------------------------------------------------------------------------------------------------
select order_id, sum(price_per_unit * quantity) as total_price 
from sales
GROUP BY order_id 
order by total_price desc

------------------------------------------------------------------
select gender, count(*) as count_gender
from customers
group by gender
order by count_gender DESC

------------------------------------------------------------------
select state, count(*) as count_state
from customers
group by state
order by count_state DESC

-----------------------------------------------------------------------------------------------------------------------
select product_id, sum(price_per_unit * quantity) as total_price 
from sales
GROUP BY product_id 
order by total_price desc

-----------------------------------------------------------------------------------------------------------------------
select sales.order_id,
       products.product_name,
	   sum(sales.price_per_unit * sales.quantity) as total_sale
from sales
join products
	on products.product_id = sales.product_id
group by sales.order_id, products.product_name
order by total_sale DESC

-----------------------------------------------------------------------------------------------------------------------
SELECT 
  Age_range, 
  COUNT(*) AS Count,
  (COUNT(*) / SUM(COUNT(*)) OVER()) * 100 AS Percentage
FROM customers
GROUP BY Age_range
ORDER BY Age_range ASC;

-----------------------------------------------------------------------------------------------------------------------
select c.state,
	   sum(s.total_sale) as total_sale
from customers c
join orders o
	on o.customer_id = c.customer_id
join sales s
	on o.order_id = s.order_id
group by c.state
order by total_sale DESC

-----------------------------------------------------------------------------------------------------------------------
select c.city,
	   sum(s.total_sale) as total_sale
from customers c
join orders o
	on o.customer_id = c.customer_id
join sales s
	on o.order_id = s.order_id
group by c.city
order by total_sale DESC

-----------------------------------------------------------------------------------------------------------------------
-- Business Queation -------------------------------------------------------------------------------------------------|
-- 1. How many total transactions were there for each year in the dataset?--------------------------------------------|
----------------------------------------------------------------------------------------------------------------------|
c
-- Answers March, January and july This more transactions of year

--Other
SELECT EXTRACT(dow from order_date) as day_number,
       CASE EXTRACT(dow from order_date)
           WHEN 0 THEN 'Sun'
           WHEN 1 THEN 'Mon'
           WHEN 2 THEN 'Tue'
           WHEN 3 THEN 'Wed'
           WHEN 4 THEN 'Thu'
           WHEN 5 THEN 'Fri'
           WHEN 6 THEN 'Sat'
       END as day_name
FROM orders;
----------------------------------------------------------------------------------------------------------------------|
-- 2.What is the total sales for each region for each month?----------------------------------------------------------|
----------------------------------------------------------------------------------------------------------------------|
SELECT c.state as Region,
	   sum(s.total_sale) as total_sale 
from customers c
	join orders o
		on o.customer_id = c.customer_id
	join sales s
		on s.order_id = o.order_id
group by Region
order by Total_sale DESC;
-- Answers South Australia , Queensland , New South Wales

----------------------------------------------------------------------------------------------------------------------|
-- 3.What product is the total sales for each?------------------------------------------------------------------------|
----------------------------------------------------------------------------------------------------------------------|
select sales.order_id,
       products.product_name,
	   sum(sales.price_per_unit * sales.quantity) as total_sale
from sales
join products
	on products.product_id = sales.product_id
group by sales.order_id, products.product_name
order by total_sale DESC
-- Answers South Australia , Queensland , New South Wales


----------------------------------------------------------------------------------------------------------------------|
-- 4.What is the percentage of sales by demographic for each year in the dataset?-------------------------------------|
----------------------------------------------------------------------------------------------------------------------|
SELECT c.gender,
	   SUM(s.total_sale) AS total_sale,
	   (SUM(s.total_sale) / SUM(SUM(s.total_sale)) OVER ()) * 100 AS pct
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN sales s ON s.order_id = o.order_id
GROUP BY c.gender
ORDER BY pct DESC;

-- Answers Female 14.09% , 
--         genderfluid 13.76%,
--         Male 13.47%,

----------------------------------------------------------------------------------------------------------------------|
-- 5.What is the product best seller?---------------------------------------------------------------------------------|
----------------------------------------------------------------------------------------------------------------------|
select DISTINCT(p.product_name),
	   count(p.product_name) as count_product,
	   sum(s.total_sale) as Total_sale,
	   min(s.total_sale) as Min_sale,
	   max(s.total_sale) as Max_sale,
	   AVG(s.total_sale) as Avg_Sale
from products p
	join sales s
		on s.product_id = p.product_id
group by product_name
order by Total_sale DESC;

-- Answers Denim , 
--         cassual Silm fit ,
--         Trench ,
----------------------------------------------------------------------------------------------------------------------|
-- 5.What is the product top 10 sales by cities?----------------------------------------------------------------------|
----------------------------------------------------------------------------------------------------------------------|
WITH CTEs as (
	SELECT c.city,
	   p.product_name,
	   sum(s.total_sale) as Total,
	   row_number() over(partition by c.city) as Row_num
	FROM customers c
		LEFT JOIN orders o 
			ON o.customer_id = c.customer_id
		JOIN sales s 
			ON s.order_id = o.order_id
		JOIN products p
			ON p.product_id = s.product_id
	GROUP BY c.city, p.product_name
)
select *
from CTEs 
where Row_num BETWEEN 1 and 10;
---------------------------------------------------------------------------
-- Join sale For calculate MoM OR DoD
-- Using lag() and lead() Fucntion

with cte as
(
	Select EXTRACT(month from o.order_date) as mont,
	   	   sum(s.total_sale) as Sum_Sale,
	       min(s.total_sale) as Min_sale,
	       max(s.total_sale) as Max_sale,
	       AVG(s.total_sale) as Avg_Sale,
	       count(o.order_date) as Count_Order
	FROM Sales s
	JOIN orders o
		on o.order_id = s.order_id
	group by mont
	order by mont ASC
), cte2 as 
(
	select mont,
	   Sum_Sale,
	   Min_sale,
	   Max_sale,
	   Avg_Sale,
	   Count_Order,
	   LAG(Sum_Sale,1) over(order by mont) previous_Month_sales
	FROM cte
), cte3 AS
(
select mont,
	   Sum_Sale,
	   Min_sale,
	   Max_sale,
	   Avg_Sale,
	   Count_Order,
	   previous_Month_sales - Sum_Sale as MoM,
	   (previous_Month_sales - Sum_Sale)/Sum_Sale * 100 as MoM_Percentage
FROM cte2
) 
SELECT * from cte3

---------------------------------------------------------------------------
-- What product customer buy frist and last
SELECT
    c.customer_name,
    SUM(s.total_sale) AS total_spent,
    MIN(p.product_name) AS first_product,
	Max(p.product_name) AS last_product
FROM
    customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN sales s ON o.order_id = s.order_id
    INNER JOIN products p ON s.product_id = p.product_id
GROUP BY
    c.customer_name;

------------------------------------------------------------------------------
