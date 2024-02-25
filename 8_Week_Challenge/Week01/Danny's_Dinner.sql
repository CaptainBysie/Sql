-- Question 01

select s.customer_id, ('$'||sum(m.price)) as total_spent from sales s join menu m 
on s.product_id = m.product_id group by s.customer_id
order by s.customer_id;

-- Question 02

select customer_id, count(distinct order_date) as num_visits from sales
group by customer_id;

-- Question 03

select customer_id, product_name from
(select s.*, m.product_name,
dense_rank() over (partition by s.customer_id order by s.order_date) as rn 
from sales s join menu m on s.product_id = m.product_id) x
where x.rn = 1
group by customer_id, product_name;

-- Question 04

select m.product_name as most_purchased_item, count(s.product_id) as times_purchased from sales s 
join menu m on s.product_id = m.product_id 
group by m.product_name
order by times_purchased desc limit 1;

-- Question 05

with order_details as 
(
	select s.customer_id, m.product_name, count(m.product_name) as order_count,
 rank() over(partition by customer_id order by count(m.product_name)) as rn
from sales s join menu m on s.product_id = m.product_id
group by s.customer_id, m.product_name
)
select customer_id, product_name as most_popular, order_count from order_details
where rn = 1

-- Question 06

with order_info as (
    select s.customer_id, s.order_date, m.product_name, mem.join_date,
	dense_rank() over(partition by s.customer_id order by s.order_date) as rn
    from sales s 
    join menu m on s.product_id = m.product_id
    join members mem on s.customer_id = mem.customer_id
	where s.order_date>=mem.join_date
)

select customer_id, product_name as first_purchased, order_date
from order_info
where rn = 1;

-- Question 07

with order_info as
(
select s.customer_id, s.order_date, m.product_name, mem.join_date,
rank() over(partition by s.customer_id order by s.order_date desc) as rn
from sales s
    join menu m on s.product_id = m.product_id
    join members mem on s.customer_id = mem.customer_id
	where order_date<join_date
)

select customer_id, product_name, order_date, join_date from order_info where rn = 1;

-- Question 08

with order_info as
(
select s.*, m.price , mem.join_date from sales s
join menu m on s.product_id = m.product_id
join members mem on s.customer_id = mem.customer_id
where order_date<join_date
)

select customer_id, count(product_id) as total_items, ('$'||sum(price)) as amount_spent
from order_info 
group by customer_id
order by customer_id asc;

-- Question 09

select customer_id, 
sum(case 
when product_name = 'sushi' then price*20 
else price*10
end) as points from 
(
select s.customer_id, s.product_id, m.product_name, m.price from sales s
join menu m on s.product_id = m.product_id
	)
	group by customer_id
	order by customer_id;
	
-- Question 10

select customer_id, 
sum(case
when (order_date-join_date)<7 then price*20
else (case
	 when product_name = 'sushi' then price*20 
else price*10
	 end)
end) as points from
(
select s.*, m.product_name, m.price , mem.join_date from sales s
join menu m on s.product_id = m.product_id
join members mem on s.customer_id = mem.customer_id
where order_date>=join_date
	)
where order_date<='2021-01-31'
group by customer_id
order by customer_id;