--Cafe Culture - Analysis 

select * from city;
select * from products;
select * from customers;
select * from sales;

-- 1. How many customers made purchases in each city? 

select a.city_id, a.city_name, count(distinct b.customer_id) as no_of_customers 
	FROM city as a inner join customers as b on a.city_id = b.city_id 
	group by a.city_id order by no_of_customers desc;
   -- Top 3 -> Jaipur, Delhi, Pune


-- 2. What is the total revenue across cities in the previous quarter?

select (extract (quarter from sale_date)) as quarter from sales where extract(year from sale_date) = 2024 
	order by quarter desc;   
       -- Since the fourth quarter has not yet been completed, let's consider the previous quarter as Q3 of 2024.
select c.city_id, c.city_name, sum(b.total) as total_sales
	from customers as a inner join sales as b on a.customer_id = b.customer_id 
	inner join city as c on a.city_id = c.city_id 
	where extract(year from b.sale_date) = 2024 and extract(quarter from b.sale_date) = 3 
	group by c.city_id order by total_sales desc;
	 -- Top 3 --> Pune, Chennai, Jaipur


-- 3. How many units of each product are sold?

select a.product_id, a.product_name, count(b.product_id) as units_sold 
	from products as a full join sales as b on a.product_id = b.product_id 
	group by a.product_id order by units_sold desc;    
	--Top 3 --> Cold Brew Coffee Pack (6 Bottles), Ground Espresso Coffee (250g), Instant Coffee Powder (100g)


-- 4. What is the average sales amount per customer in each city?

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_pr_cx
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;
   -- Top 3 --> Pune, Chennai, Bangalore

-- 5.	What are the top 3 selling products in each city?

SELECT * 
FROM 
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
	-- ORDER BY 1, 3 DESC
) as t1
WHERE rank <= 3

-- 6.	How many unique customers are there in each city?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1
ORDER BY 2 desc;
   --Jaipur, Delhi, Pune, chennai, Bangalore

--7.  Find each city’s average rent (per customer), average sale (per customer) and unique customer count.

select ci.city_name, count(distinct b.customer_id) as customer_count, 
	round(avg(ci.estimated_rent)::numeric / count(distinct b.customer_id) ::numeric) as Avg_rent_per_cust,
	round(avg(a.total)::numeric / count(distinct b.customer_id) ::numeric) as Avg_sale_per_cust
	from sales as a
	JOIN customers as b
	ON a.customer_id = b.customer_id
	JOIN city as ci
	ON ci.city_id = b.city_id
	group by ci.city_id
	order by Avg_sale_per_cust;
    --> Jaipur, Indore, Delhi

-- 8.	Calculate the percentage growth in sales over different months.

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	
order by growth_ratio desc;
   --> Surat, Indore, Kanpur, Mumbai, Delhi, Jaipur, Pune


-- 9.	Identify the top 3 average sales across cities.

select ci.city_name, round(avg(s.total)) 
	from sales as s join customers as b on s.customer_id = b.customer_id 
	join city as ci on b.city_id = ci.city_id 
	group by 1
	order by 2 desc
	limit 3;
     --> Kolkata, Ahmedabad, Indore

-- 10. Which cities have the highest percentage of revenue from rated products (Ratings above 4).

SELECT 
    c.city_name,
    round(SUM(CASE WHEN s.rating> 4 THEN s.total ELSE 0 END) * 100.0 / SUM(s.total)) AS high_rated_revenue_percentage
FROM 
    sales as s
JOIN 
    customers as cu ON s.customer_id = cu.customer_id
JOIN 
    city as c ON cu.city_id = c.city_id
GROUP BY 
    c.city_name
ORDER BY 
    high_rated_revenue_percentage DESC;

		--> Chennai, Pune, Bangalore


