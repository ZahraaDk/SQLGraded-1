-- Part 1:
-- Using a CTE, find out the total number of films rented for each rating (like 'PG', 'G', etc.)
-- in the year 2005. List the ratings that had more than 50 rentals.

WITH CTE_TOTAL_RENTED AS (
	SELECT 
		se_film.rating, 
		COUNT(se_rental.rental_id) as total_rentals
	FROM film as se_film
	INNER JOIN inventory as se_inventory
		ON se_inventory.film_id = se_film.film_id
	INNER JOIN rental as se_rental 
		ON se_rental.inventory_id = se_inventory.inventory_id
	WHERE EXTRACT(YEAR FROM rental_date) = 2005
	GROUP BY 
		se_film.rating
)
SELECT 
	CTE_TOTAL_RENTED.rating, 
	CTE_TOTAL_RENTED.total_rentals
FROM CTE_TOTAL_RENTED
WHERE total_rentals > 50 

-- Part 2:
-- Identify the categories of films that have an average rental duration greater than 5 days. 
-- Only consider films rated 'PG' or 'G'.

SELECT 
	se_category.category_id, 
	se_category.name,
	ROUND(AVG(rental_duration), 2) as avg_rental_duration
FROM category as se_category
INNER JOIN film_category as se_film_category
	ON se_film_category.category_id = se_category.category_id
INNER JOIN film as se_film
	ON se_film.film_id = se_film_category.film_id
WHERE rating = 'PG' or rating = 'G'
GROUP BY 
	se_category.category_id,
	se_category.name
HAVING ROUND(AVG(rental_duration), 2) > 5
	

-- Part 3: 
-- Determine the total rental amount collected from each customer. 
-- List only those customers who have spent more than $100 in total.
SELECT DISTINCT
	se_payment.customer_id, 
	SUM(se_payment.amount) AS total_amount
FROM payment as se_payment
GROUP BY 
	se_payment.customer_id
HAVING SUM(se_payment.amount) > 100


-- If the total rental amount is # than the total payment amount:
SELECT 
	se_rental.customer_id, 
	SUM(se_film.rental_rate * se_film.rental_duration) AS total_rental_amount
FROM rental as se_rental
INNER JOIN inventory as se_inventory
	ON se_inventory.inventory_id = se_rental.inventory_id
INNER JOIN film as se_film
	ON se_film.film_id = se_inventory.film_id
GROUP BY 
	se_rental.customer_id
HAVING SUM(se_film.rental_rate * se_film.rental_duration) > 100

-- Part 4 :
-- Create a temporary table containing the names and email addresses of customers 
-- who have rented more than 10 films.
DROP TABLE IF EXISTS TEMP_NAMES_EMAILS;
CREATE TEMPORARY TABLE TEMP_NAMES_EMAILS AS (
	SELECT 
		se_customer.first_name, 
		se_customer.last_name, 
		se_customer.email, 
		COUNT(rental_id) as total_rental
	FROM customer as se_customer
	INNER JOIN rental as se_rental
		ON se_rental.customer_id = se_customer.customer_id
	GROUP BY 
		se_customer.first_name, 
		se_customer.last_name, 
		se_customer.email
	HAVING COUNT(rental_id) > 10
);
-- CREATE INDEX TEMP_NAMES_EMAILS ON TEMP_NAMES_EMAILS(se_customer.first_name);

-- Part 5: From the temporary table, identify customers who have a Gmail email address
SELECT 
	TEMP_NAMES_EMAILS.first_name, 
	TEMP_NAMES_EMAILS.last_name, 
	TEMP_NAMES_EMAILS.emails
FROM TEMP_NAMES_EMAILS
WHERE TEMP_NAMES_EMAILS.email ILIKE ('%@gmail.com')

-- Part 6:
-- Start by creating a CTE that finds the total number of films rented for each category.
-- Create a temporary table from this CTE.
-- Using the temporary table, list the top 5 categories with the highest number of rentals.
-- Ensure the results are in descending order.
DROP TABLE IF EXISTS top_5categories;
CREATE TEMPORARY TABLE top_5categories AS(
	WITH CTE_TOTAL_RENTEDFILMS AS (
		SELECT 
			se_category.category_id,
			se_category.name as category_name, 
			COUNT(se_rental.rental_id) as total_films
		FROM category as se_category
		INNER JOIN film_category as se_fc
		ON se_fc.category_id = se_category.category_id
		INNER JOIN film as se_film
		ON se_film.film_id = se_fc.film_id
		INNER JOIN inventory as se_inventory
		ON se_inventory.film_id = se_film.film_id
		INNER JOIN rental as se_rental
		ON se_rental.inventory_id = se_inventory.inventory_id
		GROUP BY 
			se_category.category_id, 
			se_category.name
	)
SELECT 
	CTE_TOTAL_RENTEDFILMS.category_id, 
	CTE_TOTAL_RENTEDFILMS.category_name, 
	CTE_TOTAL_RENTEDFILMS.total_films
FROM CTE_TOTAL_RENTEDFILMS
ORDER BY CTE_TOTAL_RENTEDFILMS.total_films DESC
LIMIT 5 
);

SELECT 
* FROM top_5categories

-- Part 7:
-- Identify films that have never been rented out. 
-- Use a combination of CTE and LEFT JOIN for this task.

WITH FULL_FILMS AS (
    SELECT
        se_film.film_id,
        se_film.title
    FROM public.film AS se_film
)
SELECT  
    FULL_FILMS.film_id,
    FULL_FILMS.title
FROM FULL_FILMS
LEFT JOIN public.inventory as se_inventory
ON se_inventory.film_id = FULL_FILMS.film_id
LEFT JOIN rental AS se_rental 
ON se_inventory.inventory_id = se_rental.inventory_id
WHERE se_rental.rental_id IS NULL;

-- Part 8:
-- (INNER JOIN): Find the names of customers who rented films 
-- with a replacement cost greater than $20 
-- and which belong to the 'Action' or 'Comedy' categories.
SELECT DISTINCT
	CONCAT(se_customer.first_name, ' ', se_customer.last_name) as Name
FROM public.customer as se_customer
INNER JOIN rental as se_rental 
	ON se_rental.customer_id = se_customer.customer_id
INNER JOIN public.inventory as se_inventory
	ON se_inventory.inventory_id = se_rental.inventory_id
INNER JOIN public.film AS se_film
	ON se_film.film_id = se_inventory.film_id
INNER JOIN public.film_category as se_film_category
	ON se_film_category.film_id = se_film.film_id
INNER JOIN public.category AS se_category
	ON se_category.category_id = se_film_category.category_id
WHERE se_film.replacement_cost > 20 
AND se_category.name IN ('Action', 'Comedy') 

-- Part 9:
-- (LEFT JOIN): List all actors who haven't appeared in a film with a rating of 'R'.
WITH ACTOR_RATING_R AS (
	SELECT 
		actor_id 
	FROM public.film_actor as se_film_actor
	LEFT JOIN public.film as se_film
		ON se_film.film_id = se_film_actor.film_id
	WHERE se_film.rating = 'R'
)
SELECT 
	se_actor.actor_id, 
	CONCAT(se_actor.first_name, ' ', se_actor.last_name) as Actor_Name
FROM public.actor as se_actor
LEFT JOIN ACTOR_RATING_R 
	ON ACTOR_RATING_R.actor_id = se_actor.actor_id
WHERE ACTOR_RATING_R.actor_id is NULL

-- Part 10:
-- Identify customers who have never rented a film from the 'Horror' category.
-- using a combination of inner and left join
-- identify customers who rented a film with horror, and then select null 
WITH CUSTOMERS_RENTED_HORROR AS (
	SELECT 
		se_rental.customer_id, 
		se_category.name
	FROM public.rental as se_rental
	INNER JOIN public.inventory as se_inventory
	ON se_inventory.inventory_id = se_rental.inventory_id
	INNER JOIN public.film_category as se_film_category
	ON se_film_category.film_id = se_inventory.film_id
	INNER JOIN public.category as se_category
	ON se_category.category_id = se_film_category.category_id
	WHERE se_category.name = 'Horror'
)

SELECT 
	se_customer.customer_id,
	se_customer.first_name, 
	se_customer.last_name
FROM public.customer as se_customer
LEFT JOIN CUSTOMERS_RENTED_HORROR 
	ON CUSTOMERS_RENTED_HORROR.customer_id = se_customer.customer_id
WHERE CUSTOMERS_RENTED_HORROR.customer_id is NULL

-- Part 11:
SELECT DISTINCT
	CONCAT(se_customer.first_name, ' ', se_customer.last_name) as Customer_name,
	se_customer.email,
FROM public.customer as se_customer
INNER JOIN rental as se_rental
	ON se_rental.customer_id = se_customer.customer_id
INNER JOIN inventory as se_inventory 
	ON se_inventory.inventory_id = se_rental.inventory_id
INNER JOIN public.film_actor as se_film_actor 
	ON se_film_actor.film_id  = se_inventory.film_id
INNER JOIN public.actor as se_actor
	ON se_actor.actor_id = se_film_actor.actor_id
WHERE se_actor.first_name = 'Nick'
AND se_actor.last_name = 'Wahlberg'
