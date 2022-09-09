/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1. What is the total amount each customer spent at the restaurant?
SELECT t1.customer_id, SUM(t2.price) AS Total_Price
FROM dannys_diner.sales t1
INNER JOIN dannys_diner.menu t2
USING (product_id)
GROUP BY t1.customer_id
ORDER BY t1.customer_id ASC;

-- 2. How many days has each customer visited the restaurant?
SELECT t1.customer_id, COUNT(DISTINCT(t1.order_date)) AS Num_Of_Days
FROM dannys_diner.sales t1
GROUP BY t1.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT t2.customer_id, t3.first_order_date, t2.product_id
FROM dannys_diner.sales t2
INNER JOIN
  (SELECT t1.customer_id, MIN(t1.order_date) AS first_order_date
  FROM dannys_diner.sales t1
  GROUP BY t1.customer_id) AS t3
ON t2.order_date = t3.first_order_date AND t2.customer_id = t3.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT t2.product_name, COUNT(*)
FROM dannys_diner.sales t1
INNER JOIN dannys_diner.menu t2
USING (product_id)
GROUP BY t2.product_name;

-- 5. Which item was the most popular for each customer?
SELECT t1.customer_id, t2.product_name, COUNT(t2.product_name) AS count_of_item
FROM dannys_diner.sales t1 
INNER JOIN dannys_diner.menu t2
USING (product_id)
GROUP BY t1.customer_id, t2.product_name
ORDER BY t1.customer_id ASC, count_of_item DESC;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT t3.customer_id, t4.product_id
FROM
  (SELECT t1.customer_id, MIN(t1.order_date) as min_date
  FROM dannys_diner.sales t1 
  INNER JOIN dannys_diner.members t2
  USING (customer_id)
  WHERE t2.join_date <= t1.order_date
  GROUP BY t1.customer_id) AS t3
INNER JOIN dannys_diner.sales t4
ON t3.customer_id = t4.customer_id AND t3.min_date = t4.order_date
  
  
  -- 7. Which item was purchased just before the customer became a member?
SELECT t3.customer_id, t4.product_id
FROM
  (SELECT t1.customer_id, MAX(t1.order_date) as min_date
  FROM dannys_diner.sales t1 
  INNER JOIN dannys_diner.members t2
  USING (customer_id)
  WHERE t2.join_date > t1.order_date
  GROUP BY t1.customer_id) AS t3
INNER JOIN dannys_diner.sales t4
ON t3.customer_id = t4.customer_id AND t3.min_date = t4.order_date

-- -- 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id, COUNT(*), SUM(price)
FROM
  (SELECT t1.customer_id, t1.order_date, t1.product_id, t3.price
  FROM dannys_diner.sales t1
  INNER JOIN dannys_diner.members t2
  USING (customer_id)
  INNER JOIN dannys_diner.menu t3
  USING (product_id)
  WHERE t1.order_date < t2.join_date) AS t4
GROUP BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points)
FROM
  (SELECT t1.customer_id, t2.product_name, t2.price, 
  CASE 
  WHEN t1.product_id = 1 THEN 200
  WHEN t1.product_id = 2 THEN 150
  WHEN t1.product_id = 3 THEN 120
  END AS points
  FROM dannys_diner.sales t1
  INNER JOIN dannys_diner.menu t2
  USING (product_id)) t3
GROUP BY customer_id
ORDER BY customer_id ASC;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id, SUM(points) AS total_points
FROM
  (SELECT t1.customer_id, t1.order_date, t3.join_date, t1.product_id, t2.price, 
  CASE 
  WHEN t1.order_date - t3.join_date < 7 AND t1.order_date - t3.join_date >= 0 AND t1.product_id = 1 THEN 200
  WHEN t1.order_date - t3.join_date < 7 AND t1.order_date - t3.join_date >= 0 AND t1.product_id = 2 THEN 300
  WHEN t1.order_date - t3.join_date < 7 AND t1.order_date - t3.join_date >= 0 AND t1.product_id = 3 THEN 240
  WHEN t1.order_date - t3.join_date >= 7 AND t1.product_id = 1 THEN 200
  WHEN t1.order_date - t3.join_date >= 7 AND t1.product_id = 2 THEN 150
  WHEN t1.order_date - t3.join_date >= 7 AND t1.product_id = 3 THEN 120
  END as points
  FROM dannys_diner.sales t1
  LEFT JOIN dannys_diner.menu t2
  USING (product_id)
  INNER JOIN dannys_diner.members t3
  USING (customer_id)
  WHERE t1.order_date <= '2021-01-31'::DATE
  ORDER BY customer_id ASC, order_date ASC) t4
GROUP BY customer_id

-- BONUS QN 1
SELECT t1.customer_id, t1.order_date, t2.product_name, t2.price, 
CASE
WHEN t3.join_date <= t1.order_date THEN 'Y'
ELSE 'N'
END AS member
FROM dannys_diner.sales t1
LEFT JOIN dannys_diner.menu t2
USING (product_id)
LEFT JOIN dannys_diner.members t3
USING (customer_id)
ORDER BY t1.customer_id ASC, t1.order_date ASC

-- BONUS QN 2
SELECT *, 
CASE 
WHEN member = 'Y' THEN DENSE_RANK() OVER (
  PARTITION BY t4.customer_id
  ORDER BY CASE WHEN member = 'Y' THEN order_date END)
ELSE NULL
END ranking
FROM 
  (SELECT t1.customer_id, t1.order_date, t2.product_name, t2.price, 
  CASE
  WHEN t3.join_date <= t1.order_date THEN 'Y' ELSE 'N'
  END AS member
  FROM dannys_diner.sales t1
  LEFT JOIN dannys_diner.menu t2
  USING (product_id)
  LEFT JOIN dannys_diner.members t3
  USING (customer_id)
  ORDER BY t1.customer_id ASC, t1.order_date ASC) t4
ORDER BY customer_id ASC, order_date ASC
