CREATE TABLE customers (
    customer_id         TEXT,
    signup_date          DATE,
    gender                TEXT,
    age                     NUMERIC,
    city                    TEXT,
    state                  TEXT,
    acquisition_channel     TEXT
);

CREATE TABLE products (
    product_id          TEXT,
    product_name          TEXT,
    category                TEXT,
    subcategory            TEXT,
    unit_price            NUMERIC,
    cost_price             NUMERIC
);

CREATE TABLE orders (
    order_id            TEXT,
    customer_id           TEXT,
    order_date              DATE,
    payment_method          TEXT,
    order_status            TEXT,
    discount_amount        NUMERIC,
    shipping_fee           NUMERIC
);

CREATE TABLE order_items (
    order_item_id       TEXT,
    order_id              TEXT,
    product_id             TEXT,
    quantity                NUMERIC,
    unit_price             NUMERIC
);
--- to check the total rows in each table--
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'products', COUNT(*) FROM products;
select*from order_items;
select *from orders;
select*from products;
----Section 1. Revenue Analysis-----
--1.1 Total Revenue-----
----What is the total revenue generated from completed orders?----

select round(sum(oi.quantity*oi.unit_price)) as total_revenue
from order_items oi
join (
select distinct order_id,customer_id,order_status
from orders
) o on oi.order_id = o.order_id
where order_status='Completed';

----1.2 Revenue Over Time-----------
---How does revenue change month by month?------

select 
to_char(o.order_date,'YYYY-MM') as months,
round(sum(oi.quantity*oi.unit_price),2)as revenue
from order_items oi 
join (select distinct order_id,customer_id,order_date,order_status from orders) o
on oi.order_id=o.order_id
where order_status='Completed'
group by to_char(o.order_date,'YYYY-MM')
order by months;

----1.3 Revenue by Product Category---------
----which product categories generate the most revenue?---------
select p.category,
round(sum(oi.quantity*oi.unit_price),2)as revenue
from order_items oi
join(select distinct order_id,customer_id,order_status
from orders
)o
on oi.order_id=o.order_id
join products p
on p.product_id=oi.product_id
where o.order_status='Completed'
group by p.category
order by revenue desc;

----1.4 Top 10 Customers by Revenue------
---- Which  10 customers generate the most revenue ?----
select 
o.customer_id,
round(sum(oi.quantity*oi.unit_price),2) as revenue
from order_items oi
join(select distinct order_id,customer_id,order_status from orders ) o
on o.order_id=oi.order_id
where o.order_status='Completed'
group by o.customer_id
order by revenue desc
limit 10;


----1.5 Pareto Analysis-----------
----Does a small percentage of customers generate a large percentage of total revenue?---------
with customer_revenue as(
select o.customer_id,
round(sum(oi.quantity*oi.unit_price),2) as revenue
from order_items oi
join(select distinct order_id,customer_id,order_status from orders)o
on o.order_id=oi.order_id
where o.order_status='Completed'
group by o.customer_id
),
ranked as(
select*,
row_number() over(order by revenue desc )as rank,
count(*) over() as total_customers
from customer_revenue)
select(
round(sum(revenue)*100/(select sum(revenue) from customer_revenue),2))as top_20_revenue_per
from ranked
where rank<=CEIL(total_customers * 0.20);



---- Section 2. Customer & Repeat Purchase Analysis----------
----2.1 How many customers have made at least one completed purchase?---------

select 
count(distinct customer_id) as customer_purchased
from orders
where order_status='Completed';

----2.2 How many customers are repeat customers?---------
select 
count(*) as repeated_customer
from(select
customer_id from orders
where order_status ='Completed'
group by customer_id
having count(distinct order_id)>=2
) as customer_orders;
 -----combine both ---------
 ---a customer who is first buyer or repeated customer----

select customer_id,count(distinct order_id) as order_count,
case 
when count(distinct order_id)=1 then 'first time buyer'
else
'repeated customers'
end as customer_type
from orders
where order_status='Completed'
group by customer_id;


----2.3 What percentage of purchasing customers are repeat customers?---
with customer_order as(
select customer_id,count(distinct order_id) as order_count
from orders
where order_status='Completed'
group by customer_id) 
select round(count(*) filter(where order_count>=2)*100/count(*),2) as repeated_cus_pec
from customer_order;

----2.4 What is the Average Order Value (AOV)?----------------
-----AOV = Total Revenue ÷ Number of Completed Orders--------
with complete_order as(
select order_id,order_status
from orders
where order_status='Completed'
)
select round (sum(oi.quantity*oi.unit_price)/COUNT(DISTINCT co.order_id),2)as average_order_revenue
from order_items oi
join complete_order co
on co.order_id=oi.order_id;

---2.5 How many completed orders does the average purchasing customer make?--------
with customer_order as (select customer_id,
count(distinct order_id)as order_count
from orders
where order_status='Completed'
group by customer_id)
select round(avg(order_count),2) as avg_pruchase_customer
from customer_order;


---- Section 3 Customer Segmentation & Acquisition--------
---3.1 Can we classify customers into Low, Medium, and High-value customers
------based on their total completed-order revenue?----------
CREATE VIEW customer_segments AS
with customer_revenue as(
select o.customer_id,
sum(oi.quantity*oi.unit_price)as revenue
from order_items oi
join(
select distinct order_id,customer_id,order_status
from orders
)o
on o.order_id=oi.order_id
where order_status='Completed'
group by o.customer_id
)
select
customer_id,round(revenue,2)as revenue,
case 
when revenue<1000 then 'Low value'
when revenue<=5000 then 'medium value'
else 'high value'
end as customer_argument
from customer_revenue;


----3.2 How many customers are in each segment?----------
select customer_argument,
count(*) as number_of_customers
from customer_segments
group by customer_argument;

----3.4 Which customer segment generates the most revenue?------
select customer_argument,
count(*) as number_of_customers,
round(sum(revenue),2)as total_revenue,
round(avg(revenue),2)as avg_revenue
from customer_segments
group by customer_argument
order by total_revenue desc;

---3.5  Which acquisition channel brings the highest-value customers?---------
select
 c.acquisition_channel,
 count(*) as customers,
 round(sum(cs.revenue), 2) as total_revenue,
 round(avg(cs.revenue), 2) as avg_revenue_per_customer
 from customers c
 join customer_segments cs
 on c.customer_id=cs.customer_id
 group by c.acquisition_channel
 order by total_revenue desc;



----- Section 4 Product Performance & Profitability--------

----4.1 Which individual products generate the most completed-order revenue?-----
-- create a sql query to use again and again using view---------
create view product_revenue as 
select p.product_id,p.product_name,p.category,
round(sum(oi.unit_price*oi.quantity),2)as revenue
from order_items oi
join products p
on p.product_id=oi.product_id
join(select distinct order_id,order_status
from orders
where order_status='Completed')o
on o.order_id=oi.order_id
group by 
p.product_id,p.product_name,p.category;

--4.1 Which products generate the most revenue--------
select product_name,revenue
from product_revenue
order by revenue desc;

------4.2 Which product categories generate the most revenue ?---------------
select category,
round(sum(revenue),2) as total_revenue
from product_revenue
group by category
order by total_revenue desc;


-----4.3 Which product categories generate the most profit?-------

-----4.4 Which products have high sales but low profit?--------

----- we will create a resuable table by the name of product_profit---

create view product_profit as 
select p.product_name,p.category,p.product_id,
sum(oi.quantity) as unit_sold,
round(sum(oi.unit_price*oi.quantity),2) as revenue,
round(sum((oi.unit_price - p.cost_price)*oi.quantity),2) as profit
from order_items oi
join products p
on p.product_id=oi.product_id
join(select distinct order_id,order_status
from orders
where order_status = 'Completed')o
on oi.order_id=o.order_id
group by
p.product_id,
p.product_name,p.category;

---4.3  product categories genrating most profit----
select category,
round(sum(profit),2) as total_profit
from product_profit
group by category
order by total_profit desc;

----4.4 products have high sales but low profit-----
select product_name,unit_sold,revenue,
profit
from product_profit
where unit_sold>100
order by profit;


----- Section 5 Customer 360 Insights--------------

----5.1 Who are our highest-value customers?---------

select o.customer_id,
count(distinct o.order_id) as total_orders,
round(sum(oi.quantity*oi.unit_price),2)as total_revenue
from (SELECT distinct order_id, customer_id, order_status from orders)O
join order_items oi
on o.order_id=oi.order_id
where o.order_status ='Completed'
group by o.customer_id
order by total_revenue desc
limit 10;

------5.2 Which customers are becoming inactive?--------
select *from orders;
select customer_id,max(order_date)as last_purchase_date
from orders
where order_status='Completed'
group by customer_id
having max(order_date)<DATE '2026-08-31'- INTERVAL '90 days'
order by last_purchase_date;
-----5.3 inactive customer count-------
SELECT COUNT(*) AS inactive_customer_count
FROM (
    SELECT
        customer_id,
        MAX(order_date) AS last_purchase_date
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
    HAVING MAX(order_date) < DATE '2026-08-31' - INTERVAL '90 days'
) x;






