/* A Customer Nodes Exploration */
/* Question 1 */
SELECT COUNT(DISTINCT(region_id))
FROM data_bank.customer_nodes

/* Question 2 */
SELECT region_id, COUNT(DISTINCT node_id)
FROM data_bank.customer_nodes
GROUP BY region_id

/* Question 3 */
SELECT region_id, COUNT(DISTINCT customer_id)
FROM data_bank.customer_nodes
GROUP BY region_id

/* Question 4 How many days on average are customers reallocated to a different node? */
-- First calculate the num of days between start_date and end_date
-- Then calculate the avg of the num_of_days for the avg duration a customer spent at a node
SELECT ROUND(AVG(end_date - start_date),0) AS avg_days
FROM data_bank.customer_nodes
WHERE end_date!='9999-12-31';

/* Question 5: Median, 80th, 90th*/
SELECT region_id, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (end_date - start_date)) AS median
FROM data_bank.customer_nodes
WHERE end_date!='9999-12-31'
GROUP BY region_id;

/* B. Customer Transactions */
/* 1. What is the unique count and total amount for each transaction type? */
SELECT txn_type, SUM(txn_amount), COUNT(*)
FROM data_bank.customer_transactions
GROUP BY txn_type

/* 2. What is the average total historical deposit counts and amounts for all customers? */
SELECT txn_type, ROUND(AVG(txn_amount),2), COUNT(txn_type)
FROM data_bank.customer_transactions
WHERE txn_type = 'deposit'
GROUP BY txn_type

/* 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month? */
SELECT EXTRACT(Month FROM txn_date) AS Month, customer_id, txn_type, COUNT(*) AS count
FROM data_bank.customer_transactions
GROUP BY EXTRACT(Month FROM txn_date), customer_id, txn_type
HAVING (txn_type = 'deposit' and COUNT(*) > 1)
OR (txn_type = 'purchase' and COUNT(*) >= 1)
OR (txn_type = 'withdrawal' and COUNT(*) >= 1)
ORDER BY EXTRACT(Month FROM txn_date), customer_id ASC

WITH cust_txn_type_cte AS (
  SELECT customer_id, EXTRACT(Month FROM txn_date) AS Month, 
  SUM(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
  SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count,
  SUM(CASE WHEN txn_type = 'purchases' THEN 1 END) AS purchases_count
  FROM data_bank.customer_transactions
  GROUP BY customer_id, EXTRACT(Month FROM txn_date)
  ORDER BY customer_id, EXTRACT(Month FROM txn_date)ASC)
  
/* When defining a CTE in SQL Server, is that in its definition, you must always include a SELECT, DELETE, INSERT or UPDATE statement, that references one or more columns returned by the CTE */
SELECT Month, COUNT(customer_id)
FROM cust_txn_type_cte 
WHERE deposit_count > 1 AND (withdrawal_count >= 1 OR purchases_count >= 1)
GROUP BY Month
ORDER BY Month ASC

SELECT region_id, PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY (end_date - start_date)) AS percentile_80th
FROM data_bank.customer_nodes
WHERE end_date!='9999-12-31'
GROUP BY region_id;

SELECT region_id, PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY (end_date - start_date)) AS percentile_90th
FROM data_bank.customer_nodes
WHERE end_date!='9999-12-31'
GROUP BY region_id;

/* Question 4: What is the closing balance for each customer at their end of the month? */
WITH cust_txn_amt_sum_cte AS (
  SELECT customer_id, EXTRACT(Month FROM txn_date) AS month, 
  SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount END) AS deposit_sum,
  SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount END) AS withdrawal_sum
  FROM data_bank.customer_transactions
  GROUP BY customer_id, EXTRACT(Month FROM txn_date)
  ORDER BY EXTRACT(Month FROM txn_date), customer_id ASC
)

SELECT customer_id, month, (deposit_total-withdrawal_total) AS closing_balance
FROM
  (SELECT customer_id, month, 
    CASE WHEN cust_txn_amt_sum_cte.deposit_sum IS NULL THEN 0 ELSE cust_txn_amt_sum_cte.deposit_sum END AS deposit_total,
    CASE WHEN cust_txn_amt_sum_cte.withdrawal_sum IS NULL THEN 0 ELSE cust_txn_amt_sum_cte.withdrawal_sum END AS withdrawal_total
  FROM cust_txn_amt_sum_cte) AS cust_total
ORDER BY customer_id, month ASC
