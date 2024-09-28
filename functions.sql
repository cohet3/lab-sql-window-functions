USE sakila;

-- Challenge 1

-- 1. Rank films by length:
SELECT title, length, RANK() OVER (ORDER BY length DESC) AS ranki
FROM film
WHERE length IS NOT NULL AND length > 0;

-- 2. Rank films by length within rating category:
SELECT title, length, rating, RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS ranki
FROM film
WHERE length IS NOT NULL AND length > 0;

-- 3. List actors/actresses with the most films:
WITH ActorFilmCounts AS (
    SELECT actor_id, COUNT(*) AS film_count
    FROM film_actor
    GROUP BY actor_id
),
ActorInfo AS (
    SELECT a.actor_id, a.first_name, a.last_name, afc.film_count
    FROM actor a
    JOIN ActorFilmCounts afc ON a.actor_id = afc.actor_id
)
SELECT *
FROM ActorInfo
ORDER BY film_count DESC;

-- Challenge 2

-- Step 1. Retrieve the number of monthly active customers:
SELECT MONTH(rental_date) AS month, COUNT(DISTINCT customer_id) AS active_customers
FROM rental
GROUP BY MONTH(rental_date);

-- Step 2. Retrieve the number of active users in the previous month:
WITH MonthlyActiveCustomers AS (
    SELECT MONTH(rental_date) AS month, COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY MONTH(rental_date)
)
SELECT
    mac.month,
    mac.active_customers,
    LAG(mac.active_customers) OVER (ORDER BY mac.month) AS prev_month_active_customers
FROM
    MonthlyActiveCustomers mac;
    
-- Step 3. Calculate the percentage change in the number of active customers:
WITH MonthlyActiveCustomers AS (
    SELECT MONTH(rental_date) AS month, COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY MONTH(rental_date)
),
ActiveCustomersWithPrevious AS (
    SELECT
        mac.month,
        mac.active_customers,
        LAG(mac.active_customers) OVER (ORDER BY mac.month) AS prev_month_active_customers
    FROM
        MonthlyActiveCustomers mac
)
SELECT
    month,
    active_customers,
    prev_month_active_customers,
    ((active_customers - prev_month_active_customers) / prev_month_active_customers) * 100 AS pct_change
FROM
    ActiveCustomersWithPrevious;
    
-- Step 4. Calculate the number of retained customers:
WITH MonthlyActiveCustomers AS (
    SELECT 
        MONTH(rental_date) AS month, 
        COUNT(DISTINCT customer_id) AS active_customers
    FROM 
        rental
    GROUP BY 
        MONTH(rental_date)
),
ActiveCustomersWithPrevious AS (
    SELECT
        mac.month,
        mac.active_customers,
        LAG(mac.active_customers) OVER (ORDER BY mac.month) AS prev_month_active_customers
    FROM
        MonthlyActiveCustomers mac
),
MonthlyCustomerRetention AS (
    SELECT
        MONTH(rental_date) AS month,
        customer_id,
        LAG(MONTH(rental_date)) OVER (PARTITION BY customer_id ORDER BY rental_date) AS prev_month
    FROM 
        rental
),
RetainedCustomers AS (
    SELECT 
        month,
        COUNT(DISTINCT customer_id) AS retained_customers
    FROM 
        MonthlyCustomerRetention
    WHERE 
        prev_month IS NOT NULL
    GROUP BY 
        month
)
SELECT
    acwp.month,
    acwp.active_customers,
    acwp.prev_month_active_customers,
    rc.retained_customers
FROM
    ActiveCustomersWithPrevious acwp
LEFT JOIN
    RetainedCustomers rc ON acwp.month = rc.month
ORDER BY
    acwp.month;

