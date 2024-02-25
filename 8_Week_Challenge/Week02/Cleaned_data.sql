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

SELECT * FROM customer_orders_temp;

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

SELECT * FROM runner_orders_temp;

-- pizza_recipies Table:

Drop Table  If Exists pizza_recipies_temp;

CREATE Temporary Table pizza_recipies_temp as

SELECT t.pizza_id, json_array_elements_text(array_to_json(regexp_split_to_array(t.toppings, ','))) AS topping
FROM pizza_runner.pizza_recipes t;

SELECT * FROM pizza_recipies_temp;

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

