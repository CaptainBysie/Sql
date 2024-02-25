-- #Case Study 02

-- Cleaning Tables
-- customer_orders Table:

DROP TABLE IF EXISTS customer_orders_temp;

CREATE TEMPORARY TABLE customer_orders_temp AS
SELECT order_id,
       customer_id,
       pizza_id,
       CASE
           WHEN exclusions = '' THEN NULL
           WHEN exclusions = 'null' THEN NULL
           ELSE exclusions
       END AS exclusions,
       CASE
           WHEN extras = '' THEN NULL
           WHEN extras = 'null' THEN NULL
           ELSE extras
       END AS extras,
       order_time
FROM pizza_runner.customer_orders;

-- Dropping Duplicates

CREATE TEMP TABLE customer_orders_temp_unique AS
SELECT DISTINCT * FROM customer_orders_temp;

DROP TABLE customer_orders_temp;

ALTER TABLE customer_orders_temp_unique RENAME TO customer_orders_temp;



-- runner_orders Table:

DROP TABLE IF EXISTS runner_orders_temp;

CREATE TEMPORARY TABLE runner_orders_temp AS

SELECT order_id,
       runner_id,
       CASE
           WHEN pickup_time LIKE 'null' THEN NULL
           ELSE pickup_time
       END AS pickup_time,
       CASE
           WHEN distance LIKE 'null' THEN NULL
           ELSE CAST(regexp_replace(distance, '[a-z]+', '') AS FLOAT)
       END AS distance,
       CASE
           WHEN duration LIKE 'null' THEN NULL
           ELSE CAST(regexp_replace(duration, '[a-z]+', '') AS FLOAT)
       END AS duration,
       CASE
           WHEN cancellation LIKE '' THEN NULL
           WHEN cancellation LIKE 'null' THEN NULL
           ELSE cancellation
       END AS cancellation
FROM pizza_runner.runner_orders;

-- pizza_recipies Table:

Drop Table  If Exists pizza_recipes_temp;

CREATE Temporary Table pizza_recipes_temp as

SELECT t.pizza_id, cast(json_array_elements_text(array_to_json(regexp_split_to_array(t.toppings, ','))) as int) AS topping
FROM pizza_runner.pizza_recipes t;

-- Pizza Metrics

-- Question 01

Select count(x.pizza_id) as total_pizzas_ordered from
(
select distinct * from customer_orders_temp
	)x;

-- Question 02

select count(distinct order_id) as Number_of_unique_orders from customer_orders_temp;
	
-- Question 03

select runner_id, count(order_id) as Successful_orders from runner_orders_temp
where cancellation not like '%Cancellation' or cancellation isNull
group by runner_id
order by runner_id;

-- Question 04

select x.pizza_id, x.pizza_name, count(x.order_id) from
(
select c.order_id, p.pizza_id, p.pizza_name from customer_orders_temp c
join pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
join runner_orders_temp r on c.order_id = r.order_id
	where r.cancellation not like '%Cancellation' or cancellation isNull
	)x
	group by x.pizza_id, x.pizza_name;

-- Question 05

select customer_id, pizza_name, count(pizza_name) as orders_count from
(
select c.customer_id, p.pizza_name from customer_orders_temp c
join pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
	)
	group by customer_id, pizza_name
	order by customer_id;
	
-- Question 06

with cte as
(
select c.customer_id, c.order_id, p.pizza_id, p.pizza_name from customer_orders_temp c
join pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
join runner_orders_temp r on c.order_id = r.order_id
	where r.cancellation not like '%Cancellation' or cancellation isNull
)

SELECT customer_id,
       order_id,
       count(order_id) AS pizza_count
FROM cte
GROUP BY customer_id, order_id
ORDER BY pizza_count DESC
LIMIT 1;

-- Question 07

with cte as
(
select c.*, p.pizza_name from customer_orders_temp c
join pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
join runner_orders_temp r on c.order_id = r.order_id
	where r.cancellation not like '%Cancellation' or cancellation ISNull
)

select customer_id,
sum(case when exclusions not like '' or extras not like '' then 1
	else 0 end) as change_in_pizza,
sum(case when exclusions ISNULL and extras ISNULL then 1
    else 0 end) as no_change_in_pizza
from cte
group by customer_id
order by customer_id;

--Question 08

with cte as
(
select c.*, p.pizza_name from customer_orders_temp c
join pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
join runner_orders_temp r on c.order_id = r.order_id
	where r.cancellation not like '%Cancellation' or cancellation ISNull
)

select customer_id, count(pizza_id) as pizzas_delivered from cte
where exclusions is not null and extras is not null
group by customer_id;

-- Question 09

select EXTRACT(HOUR FROM order_time) as hr,
count(order_id) as orders,
round(100*count(order_id)/sum(count(order_id)) over(),2) as volume_of_pizzas
from customer_orders_temp
group by hr
order by hr;

-- Question 10

select TO_CHAR(order_time, 'Day') AS day_name,
count(order_id) as orders,
round(100*count(order_id)/sum(count(order_id)) over(),2) as volume_of_pizzas
from customer_orders_temp
group by day_name
order by orders desc;

-- Runner and Customer Experience

-- Question 01

SELECT 
  FLOOR(EXTRACT('day' FROM age(registration_date, DATE '2021-01-01')) / 7) AS week_period,
  COUNT(runner_id) AS registered_count
FROM pizza_runner.runners
GROUP BY week_period
ORDER BY week_period;

-- Question 02

SELECT 
  runner_id,
  ROUND(AVG(EXTRACT(EPOCH FROM (CAST(pickup_time AS timestamp) - CAST(order_time AS timestamp))) / 60), 2) AS avg_runner_pickup_time
FROM 
  runner_orders_temp
INNER JOIN 
  customer_orders_temp USING (order_id)
WHERE 
  cancellation IS NULL
GROUP BY 
  runner_id;

-- Question 03

select x.pizza_count,  round(avg(x.prep_time),2) as avg_prep_time from (
select order_id, count(pizza_id) as pizza_count, round(avg(EXTRACT(EPOCH from cast(pickup_time as timestamp)- cast(order_time as timestamp))/60),2) as prep_time 
from customer_orders_temp INNER JOIN runner_orders_temp using (order_id)
where cancellation is null
group by order_id )x 
group by x.pizza_count;

-- Question 04

select x.customer_id, round(avg(x.duration)) as avg_dist from (
select c.order_id, c.customer_id, r.duration from customer_orders_temp c
join runner_orders_temp r using (order_id)
	)x
	group by customer_id
	order by customer_id;
	
-- Question 05

select (max(duration) - min(duration)) as diff_delivery_time from runner_orders_temp;

-- Question 06

select runner_id, round(cast((distance*60/duration) as numeric),2) as avg_speed from runner_orders_temp
where cancellation isnull
order by runner_id;

-- Question 07

select runner_id, round(avg(status)*100,2) as percentage_success from
(
select runner_id, 
case when cancellation isnull then 1
else 0 end as status
from runner_orders_temp
	)x 
	group by runner_id
	order by runner_id;

-- Ingredient Optimization

-- customer_orders_temp

DROP TABLE IF EXISTS split_customer_orders_temp;

CREATE TEMPORARY TABLE split_customer_orders_temp AS
SELECT 
  s.order_id, 
  s.customer_id, 
  s.pizza_id, 
  s.order_time, 
  s.exclusions,
  s.extras,
  exclusion.value::INTEGER AS exclusion,
  extra.value::INTEGER AS extra
FROM 
  customer_orders_temp s
LEFT JOIN LATERAL json_array_elements_text(CASE WHEN s.exclusions <> '' THEN array_to_json(regexp_split_to_array(s.exclusions, ',')) ELSE '[]'::JSON END) exclusion(value) ON TRUE
LEFT JOIN LATERAL json_array_elements_text(CASE WHEN s.extras <> '' THEN array_to_json(regexp_split_to_array(s.extras, ',')) ELSE '[]'::JSON END) extra(value) ON TRUE;

-- Question 01

SELECT 
  p.pizza_id, 
  p.pizza_name, 
  STRING_AGG(t.topping_name, ',') AS standard_ingredients
FROM 
  pizza_runner.pizza_names p 
JOIN 
  pizza_recipes_temp r USING (pizza_id)
JOIN 
  pizza_runner.pizza_toppings t ON r.topping = t.topping_id
GROUP BY 
  p.pizza_id, 
  p.pizza_name
ORDER BY 
  p.pizza_id;

-- Question 02

select topping_name, count(extra) as purchase_count from (
select order_id, extra, topping_name from split_customer_orders_temp s join pizza_runner.pizza_toppings t on s.extra = t.topping_id)x
group by topping_name
order by purchase_count desc limit 1;

-- Question 03

select topping_name, count(exclusion) as purchase_count from (
select order_id, exclusion, topping_name from split_customer_orders_temp s join pizza_runner.pizza_toppings t on s.exclusion = t.topping_id)x
group by topping_name
order by purchase_count desc limit 1;

-- Question 04

WITH order_summary AS (
    SELECT 
        s.order_id, 
        p.pizza_name, 
        s.customer_id, 
        STRING_AGG(t.topping_name, ',') AS exclusion_name,
        STRING_AGG(t1.topping_name, ',') AS extra_name
    FROM 
        split_customer_orders_temp s 
        LEFT JOIN pizza_runner.pizza_toppings t ON s.exclusion = t.topping_id
        LEFT JOIN pizza_runner.pizza_toppings t1 ON s.extra = t1.topping_id
        LEFT JOIN pizza_runner.pizza_names p USING (pizza_id)
    GROUP BY 
        s.order_id, p.pizza_name, s.customer_id
)

SELECT 
    order_id,
    customer_id,
    CASE 
        WHEN exclusion_name IS NULL AND extra_name IS NULL THEN pizza_name
        WHEN exclusion_name IS NOT NULL AND extra_name IS NULL THEN CONCAT(pizza_name, ' - Exclude ', exclusion_name)
        WHEN exclusion_name IS NULL AND extra_name IS NOT NULL THEN CONCAT(pizza_name, ' - Include ', extra_name)
        ELSE CONCAT(pizza_name, ' - Exclude ', exclusion_name, ' - Include ', extra_name)
    END AS order_item 
FROM 
    order_summary;
	
-- Question 05

With rel_ingredient as 
(
select p.pizza_id, t.topping_id, concat('2x',t.topping_name) as relevant_ingredient from pizza_recipes_temp p 
join pizza_runner.pizza_toppings t on p.topping = t.topping_id
),

ingredient as
(
    SELECT  Distinct
        s.order_id, 
		p.pizza_name, 
		s.extra,
        t1.topping_name as ext_name,
		r.relevant_ingredient
    FROM 
        split_customer_orders_temp s 
        LEFT JOIN pizza_runner.pizza_toppings t1 ON s.extra = t1.topping_id
        LEFT JOIN pizza_runner.pizza_names p USING (pizza_id)
		LEFT JOIN rel_ingredient r ON (s.pizza_id = r.pizza_id AND s.extra = r.topping_id)
	ORDER BY order_id
	),

a as
(select order_id, pizza_name, 
STRING_AGG(CASE WHEN relevant_ingredient IS NULL then ext_name 
ELSE relevant_ingredient END, ',') as ing
FROM  ingredient
GROUP BY order_id, pizza_name)

SELECT order_id,CONCAT(pizza_name,' : ',ing) as ingredients
from a
GROUP BY order_id,pizza_name,ing 
order by order_id;

-- Question 06

WITH orders as (
SELECT  Distinct
        s.order_id, 
		p.pizza_name, 
		s.extra,
        t1.topping_name as ext_name
    FROM 
        split_customer_orders_temp s 
        LEFT JOIN pizza_runner.pizza_toppings t1 ON s.extra = t1.topping_id
        LEFT JOIN pizza_runner.pizza_names p USING (pizza_id)
	ORDER BY order_id
)

SELECT order_id, pizza_name, count(extra) as qty, ext_name from orders
GROUP BY order_id, pizza_name, ext_name
order by qty desc;

-- Pricing and Ratings

-- Question 01

WITH deliveries as 
(
select s.order_id, pizza_name, runner_id from split_customer_orders_temp s 
left join runner_orders_temp using (order_id)
left join pizza_runner.pizza_names using (pizza_id)
where cancellation ISNULL
	)
	
SELECT runner_id, 
CONCAT('$' || SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12
	ELSE 10 END)) as earnings
	FROM deliveries
	GROUP BY runner_id
	ORDER BY runner_id;
	
-- Question 02

WITH deliveries AS (
    SELECT
        s.order_id,
        p.topping_name,
        pn.pizza_name,
        ro.runner_id
    FROM 
        split_customer_orders_temp s 
    LEFT JOIN 
        runner_orders_temp ro ON s.order_id = ro.order_id
    LEFT JOIN 
        pizza_runner.pizza_names pn ON s.pizza_id = pn.pizza_id
    LEFT JOIN 
        pizza_runner.pizza_toppings p ON s.extra = p.topping_id 
    WHERE 
        ro.cancellation IS NULL
)

SELECT 
    runner_id,
    CONCAT('$', SUM(CASE
        WHEN pizza_name = 'Meatlovers' THEN 
            CASE 
                WHEN topping_name = 'Cheese' THEN 13
                ELSE 12
            END
        WHEN pizza_name = 'Vegetarian' THEN
            CASE 
                WHEN topping_name = 'Cheese' THEN 11
                ELSE 10
            END
        ELSE 0 
    END)) AS earnings
FROM 
    deliveries
GROUP BY 
    runner_id
ORDER BY 
    runner_id;

-- Question 03


CREATE TABLE pizza_runner.runner_ratings (
    rating_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    runner_id INTEGER NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    rating_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO pizza_runner.runner_ratings (order_id, runner_id, rating)
VALUES
  (1, 1, 5),
  (2, 1, 4),
  (3, 1, 3),
  (4, 2, 2),
  (5, 3, 5),
  (7, 2, 4),
  (8, 2, 4),
  (10, 1, 3);

select * from pizza_runner.runner_ratings;

-- Question 04

WITH tab as (
select s.order_id, s.customer_id, r.runner_id, s.order_time, r.pickup_time, 
round(avg(EXTRACT(EPOCH from cast(r.pickup_time as timestamp)- cast(s.order_time as timestamp))/60),2) as prep_time,
r.duration as delivery_duration, round(cast((r.distance*60/r.duration) as numeric),2) as avg_speed, count(s.pizza_id) as pizzas 
from split_customer_orders_temp s join
runner_orders_temp r using (order_id)
where r.cancellation isnull
group by s.order_id, s.customer_id,s.order_time,r.runner_id, r.pickup_time, r.duration, r.distance
	)
	
SElECT t.*, r.rating FROM tab t JOIN pizza_runner.runner_ratings r on t.order_id = r.order_id AND t.runner_id = r.runner_id;

-- Question 05

SELECT runner_id, 
('$'|| SUM(CASE WHEN pizza_name like 'Meatlovers' THEN (12+0.3*distance)
		  ELSE (10+0.3*distance) END)) AS earnings FROM (
SELECT s.order_id, p.pizza_name, r.runner_id, r.distance FROM
split_customer_orders_temp s JOIN pizza_runner.pizza_names p USING (pizza_id)
JOIN runner_orders_temp r USING (order_id)
WHERE r.cancellation ISNULL)x
GROUP BY runner_id
ORDER BY runner_id;