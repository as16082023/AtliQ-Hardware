use gdb023;

/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

select distinct market
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";



/*2. What is the percentage of unique product increase in 2021 vs. 2020?*/

 with 
cte1 as
(select count(distinct(product_code)) as unique_products_2020
from fact_manufacturing_cost  f 
where cost_year=2020),
cte2 as
(select count(distinct(product_code)) as unique_products_2021
from fact_manufacturing_cost f
where cost_year=2021)

select *,
		concat(round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2),'%') as percentage_chg		
from cte1
cross join
cte2;


/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts*/

select segment, count(product_code)
from dim_product
group by segment
order by 2 desc;


/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020?*/

with cte1 as
(select p.segment,
       count(distinct p.product_code) as product_count_2020
from dim_product p
inner join fact_sales_monthly fs
on p.product_code = fs.product_code
where fs.fiscal_year = '2020'
group by p.segment),
cte2 as
(select p.segment,
       count(distinct p.product_code) as product_count_2021
from dim_product p
inner join fact_sales_monthly fs
on p.product_code = fs.product_code
where fs.fiscal_year = '2021'
group by p.segment)
select c1.segment, c1.product_count_2020, c2.product_count_2021,
       (product_count_2021 - product_count_2020) as difference
from cte1 c1
join cte2 c2
on c1.segment = c2.segment
order by difference desc;

/*5. Get the products that have the highest and lowest manufacturing costs.*/

select p.product_code,
       p.product,
       fm.manufacturing_cost
from dim_product p
join fact_manufacturing_cost fm
on p.product_code = fm.product_code
where fm.manufacturing_cost = ( select max(manufacturing_cost)
                                from fact_manufacturing_cost) 
or 
fm.manufacturing_cost =(select min(manufacturing_cost)
                        from fact_manufacturing_cost)
order by manufacturing_cost desc;
       
       


/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market*/

select c.customer_code, c.customer, 
       round(avg(fp.pre_invoice_discount_pct),4) as average_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions fp
on c.customer_code = fp.customer_code
where market = 'India'
and fiscal_year = '2021'
group by  c.customer_code, c.customer
order by average_discount_percentage desc
limit 5;


/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month.*/ 

select monthname(fs.date) as month,
       year(fs.date) as year,
       round(sum(fg.gross_price * fs.sold_quantity),2) as Gross_Sales_Amount
from fact_sales_monthly fs
join fact_gross_price fg
on fs.product_code = fg.product_code
join dim_customer c
on fs.customer_code = c.customer_code
where customer = 'Atliq Exclusive'
group by fs.date;



/*8. In which quarter of 2020, got the maximum total_sold_quantity?*/

select 
     case
         when month(date) in (9, 10, 11) then 'Q1'
         when month(date) in (12, 1, 2) then 'Q2'
         when month(date) in (3, 4, 5) then 'Q3'
         when month(date) in (6, 7, 8) then 'Q4'
         end as quarter,
         concat(format(sum(sold_quantity)/ 1000000, 2), ' ',  'M') as total_sold_quantity
from fact_sales_monthly 
where fiscal_year = '2020'
group by quarter 
order by  total_sold_quantity desc;
         


/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution?*/

with cte as
(select c.channel, 
concat(round(sum(fg.gross_price*fs.sold_quantity)/1000000, 2), 'M') as gross_sales_mln
from dim_customer c
join fact_sales_monthly fs
	on c.customer_code = fs.customer_code
join fact_gross_price fg
	on fs.product_code = fg.product_code
where fs.fiscal_year = '2021'
group by c.channel
order by gross_sales_mln desc)

select channel,
       gross_sales_mln,
       concat(round((gross_sales_mln*100) / sum(gross_sales_mln) over(), 2), '%') as percentage
from cte;



/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021?*/

with cte1 as
(select 
    p.division as division,
	p.product_code as product_code,
	p.product as product,
	sum(fs.sold_quantity) as total_sold_quantity
from fact_sales_monthly fs
join dim_product p
on fs.product_code = p.product_code
where fs.fiscal_year = '2021'
group by p.division, p.product_code, p.product
order by total_sold_quantity desc
),
cte2 as
(
select division, product_code, product, total_sold_quantity,
       dense_rank() over( partition by division order by total_sold_quantity desc) as rank_order
from cte1)
select * 
from cte2
where rank_order <=3;





