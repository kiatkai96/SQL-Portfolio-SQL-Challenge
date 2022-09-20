-- A: Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT COUNT(order_id)
FROM pizza_runner.customer_orders

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id))
FROM pizza_runner.customer_orders

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id)
FROM
  (SELECT order_id, runner_id,
  CASE
  WHEN cancellation = 'NaN' THEN null
  WHEN cancellation = '' THEN null
  WHEN cancellation = 'null' THEN null
  ELSE cancellation
  END AS cancellation_fixed
  FROM pizza_runner.runner_orders) AS runner_orders_fixed 
WHERE cancellation_fixed IS null
GROUP BY runner_id

-- 4. How many of each type of pizza was delivered?
SELECT pizza_id, COUNT(pizza_id)
FROM pizza_runner.customer_orders
WHERE order_id IN
  (SELECT order_id
  FROM
      (SELECT order_id,
      CASE
      WHEN cancellation = 'NaN' THEN null
      WHEN cancellation = '' THEN null
      WHEN cancellation = 'null' THEN null
      ELSE cancellation
      END AS cancellation_fixed
      FROM pizza_runner.runner_orders) AS runner_orders_fixed 
   WHERE cancellation_fixed IS null)
GROUP BY pizza_id

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, COUNT(pizza_name)
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.pizza_names
USING (pizza_id)
GROUP BY customer_id, pizza_name
ORDER BY customer_id ASC

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(order_id)
FROM pizza_runner.customer_orders
INNER JOIN
    (SELECT order_id
     FROM
     (SELECT order_id,
      CASE
      WHEN cancellation = 'NaN' THEN null
      WHEN cancellation = '' THEN null
      WHEN cancellation = 'null' THEN null
      ELSE cancellation
      END AS cancellation_fixed
      FROM pizza_runner.runner_orders) AS runner_orders_fixed 
     WHERE cancellation_fixed IS null) AS runners_order_null
USING (order_id)
GROUP BY order_id
ORDER BY COUNT(order_id) DESC

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- No changes:
   SELECT COUNT(order_id)
     FROM
       (SELECT order_id,
        CASE
        WHEN exclusions = 'NaN' THEN null
        WHEN exclusions = '' THEN null
        WHEN exclusions = 'null' THEN null
        ELSE exclusions
        END AS exclusions_fixed, 
        CASE
        WHEN extras = 'NaN' THEN null
        WHEN extras = '' THEN null
        WHEN extras = 'null' THEN null
        ELSE extras
        END AS extras_fixed
        FROM pizza_runner.customer_orders) AS customer_orders_fixed 
    WHERE exclusions_fixed IS null and extras_fixed IS null 

-- At least 1 change
   SELECT COUNT(order_id)
     FROM
       (SELECT order_id,
        CASE
        WHEN exclusions = 'NaN' THEN null
        WHEN exclusions = '' THEN null
        WHEN exclusions = 'null' THEN null
        ELSE exclusions
        END AS exclusions_fixed, 
        CASE
        WHEN extras = 'NaN' THEN null
        WHEN extras = '' THEN null
        WHEN extras = 'null' THEN null
        ELSE extras
        END AS extras_fixed
        FROM pizza_runner.customer_orders) AS customer_orders_fixed 
    WHERE exclusions_fixed IS NOT null OR extras_fixed IS NOT null 
   
   -- 8. How many pizzas were delivered that had both exclusions and extras?
    SELECT COUNT(order_id)
     FROM
       (SELECT order_id,
        CASE
        WHEN exclusions = 'NaN' THEN null
        WHEN exclusions = '' THEN null
        WHEN exclusions = 'null' THEN null
        ELSE exclusions
        END AS exclusions_fixed, 
        CASE
        WHEN extras = 'NaN' THEN null
        WHEN extras = '' THEN null
        WHEN extras = 'null' THEN null
        ELSE extras
        END AS extras_fixed
        FROM pizza_runner.customer_orders) AS customer_orders_fixed 
    WHERE exclusions_fixed IS NOT null AND extras_fixed IS NOT null 
    
    
 -- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS hour_of_the_day, COUNT(order_id)  
FROM pizza_runner.customer_orders
GROUP BY EXTRACT(HOUR FROM order_time)

-- 10. What was the volume of orders for each day of the week?
SELECT EXTRACT(DAY FROM order_time) AS day_of_the_week, COUNT(order_id)  
FROM pizza_runner.customer_orders
GROUP BY EXTRACT(DAY FROM order_time)
