/* Using PostgreSQL v15 */
/* Question 1 */

SELECT COUNT(DISTINCT(customer_id)) FROM foodie_fi.subscriptions;

/* Question 2 */

SELECT DATE_TRUNC('month', start_date), COUNT(*) AS monthly_distribution
FROM foodie_fi.subscriptions
GROUP BY DATE_TRUNC('month', start_date)

/* Question 3 */

SELECT plan_name, count_of_events
FROM foodie_fi.plans f1
INNER JOIN
    (SELECT plan_id, DATE_TRUNC('year', start_date),  COUNT(*) AS count_of_events
    FROM foodie_fi.subscriptions
    GROUP BY plan_id, DATE_TRUNC('year', start_date)
    HAVING DATE_TRUNC('year', start_date) > '2020-01-01T00:00:00.000Z') AS f2
ON f1.plan_id = f2.plan_id

/* Question 4 */

SELECT
    COUNT(*) AS cust_churn,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions),1) AS perc_churn
FROM foodie_fi.subscriptions
WHERE plan_id = 4;

/* Question 5 - Meaning to say the people that plan_id is 0 followed by a 4 immediately */

SELECT COUNT(DISTINCT(customer_id)) AS cust_churn_straight, 
ROUND(COUNT(DISTINCT(customer_id))*100/(SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions), 1)
FROM
    (SELECT customer_id, plan_id, 
    LEAD(plan_id, 1) OVER (
      PARTITION BY customer_id) AS plan_id_next
    FROM foodie_fi.subscriptions) AS lead_table
WHERE plan_id = 0 
AND plan_id_next = 4

/* Question 6 */

SELECT plan_id_next, 
COUNT(DISTINCT(customer_id)) AS cust_plan, 
ROUND(COUNT(DISTINCT(customer_id))*100/(SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions), 1)
FROM
    (SELECT customer_id, plan_id, 
    LEAD(plan_id, 1) OVER (
      PARTITION BY customer_id) AS plan_id_next
    FROM foodie_fi.subscriptions) AS lead_table
WHERE plan_id = 0 
AND plan_id_next IN (1,2,3)
GROUP BY plan_id_next

/* Question 7 */

CREATE TEMP TABLE cust_latest_plan AS
	(
    SELECT *
    FROM foodie_fi.subscriptions
    WHERE (customer_id, plan_id) IN
        (SELECT customer_id, MAX(plan_id) AS latest_plan  /* Using the MAX and groupby gives the last row of each group) */
        FROM foodie_fi.subscriptions
        GROUP BY customer_id))
;

SELECT plan_id, COUNT(DISTINCT(customer_id)) as cust_count,
ROUND(COUNT(DISTINCT(customer_id))*100/(SELECT COUNT(DISTINCT(customer_id)) FROM foodie_fi.subscriptions), 1)
FROM
    (SELECT *
    FROM cust_latest_plan
    WHERE start_date <= '2020-12-31') AS cust_plan_before
GROUP BY plan_id;

/* Question 8 */
SELECT plan_id, COUNT(*)
FROM foodie_fi.subscriptions
WHERE (customer_id, plan_id) in
    (SELECT customer_id, MAX(plan_id) AS latest_plan  /* Using the MAX and groupby gives the last row of each group) */
    FROM foodie_fi.subscriptions
    WHERE DATE_TRUNC('year', start_date) = '2020-01-01T00:00:00.000Z'
    GROUP BY customer_id)
GROUP BY plan_id
HAVING plan_id = 3

/* Question 9 */
/* First select all customers with plan_id 0 and plan_id = 3 */
CREATE TEMP TABLE cust_upgrade AS
    SELECT *
     FROM foodie_fi.subscriptions
     WHERE plan_id IN (0,3);

CREATE TEMP TABLE cust_upgrade_2 AS
    SELECT customer_id, plan_id, LEAD(plan_id, 1) OVER (
      PARTITION BY customer_id) AS plan_id_next, start_date, 
      LEAD(start_date, 1) OVER (
      PARTITION BY customer_id) AS start_date_next
    FROM cust_upgrade;

CREATE TEMP TABLE cust_day_diff AS
    SELECT customer_id, (start_date_next - start_date) AS day_diff
    FROM
        (SELECT customer_id, plan_id, plan_id_next, start_date, start_date_next,
        CASE WHEN plan_id = 0 and plan_id_next = 3 THEN 'cust_converted_annual'
        ELSE NULL
        END AS cust_annual
        FROM cust_upgrade_2) AS t1
    WHERE cust_annual = 'cust_converted_annual';
     
SELECT AVG(day_diff)
FROM cust_day_diff
