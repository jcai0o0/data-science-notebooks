
# first and last name, email address for customer from store 2
SELECT first_name, last_name, email, store_id
FROM customer
WHERE store_id = 2

# which rating do we have the most filems in?
# films by rating
SELECT rating, count(film_id)
FROM film
GROUP BY rating
ORDER BY 2 DESC;

# which rating is most prevalent in each price
# films by rating & rental price
SELECT rental_rate, rating, count(film_id)
FROM film
GROUP BY rental_rate, rating
ORDER BY 1, 3 DESC;

# customer id, name(first nad last), mailing address
SELECT
	customer.customer_id, customer.first_name, customer.last_name, address.address
FROM
	customer, address
WHERE
	customer.address_id = address.address_id
;

# list by film name, category and language
SELECT
	title, category.name as category_name, language.name as language_name
FROM
	film, film_category, language, category
WHERE
	film.film_id = film_category.film_id
	and
	film.language_id = language.language_id
	and
	film_category.category_id = category.category_id
;

# how many times has each movie been reneted out
SELECT
	film.name, count(rental_id)
FROM
	film, inventory, rental
WHERE
	film.film_id = inventory.film_id
	and
	rental.inventory_id = inventory.inventory_id
GROUP BY
	film.film_id
;

# revenue per video/film title
SELECT
	film.title as "Film Title", 
	count(rental_id),
	rental_rate,
	count(rental_id) * rental_rate as Revenue
FROM
	film, inventory, rental
WHERE
	film.film_id = inventory.film_id
	and
	rental.inventory_id = inventory.inventory_id
GROUP BY
	film.film_id
ORDER BY 
    revenue DESC
;

# what customer has paid us the most money
SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
	sum(amount) as cost
FROM
	payment p, customer c
WHERE
	p.customer_id = c.customer_id
GROUP BY
	p.customer_id
ORDER BY 
	4 DESC
;

# what store has historically brought the most revenue
SELECT
	staff.store_id, sum(amount)
FROM
	payment, staff

WHERE
	payment.staff_id = staff.staff_id

GROUP BY
	staff.store_id
ORDER BY
	2 DESC
;
#  how many rentals we had each month
SELECT
    left(rental_date, 7),
    count(rental_id)
FROM
    rental
GROUP BY
    1
;

# for each movie, when is it first time rented and when is it last time rented
SELECT
	f.title,
	min(rental_date) as "Firt Rental",
	max(rental_date) as "Last Rental"
FROM
	film f, inventory i, rental r
WHERE
	f.film_id = i.film_id
	and
	i.inventory_id = r.inventory_id
GROUP BY
	f.film_id
;

# every customer's last rental date
SELECT
	concat(c.first_name, " ", c.last_name),
	c.email,
	max(r.rental_date) as "Last Rental Date"
FROM
	rental r, customer c
WHERE
	r.customer_id = c.customer_id
GROUP BY
	r.customer_id
;

# revenue by each month
SELECT
	left(payment_date, 7) as Month,
	SUM(amount) as "Monthly Revenue"
FROM
	payment
GROUP BY 1
;

# how many distinct renters per month
SELECT
	left(rental_date, 7),
	COUNT(rental_id) as total_rentals,
	COUNT(DISTINCT customer_id) as unique_renters,
	COUNT(rental_id)/COUNT(DISTINCT customer_id) as avg_num_rentals_per_renter
FROM
	rental
GROUP BY
	1
;

# number of distinct movies rented per month
SELECT
	left(rental_date, 7),
	COUNT(DISTINCT i.film_id)
FROM
	rental r, inventory i
WHERE
	r.inventory_id = i.inventory_id
GROUP BY 1
;

# users who have rented at least 3 times
SELECT
	c.customer_id, concat(c.first_name, " ", c.last_name),
	COUNT(DISTINCT rental_id) as total_rentals
FROM
	rental r, customer c
WHERE
	r.customer_id = c.customer_id
GROUP BY
	c.customer_id
HAVING
	total_rentals > 2
;

# how much revenue has one single store made over PG-13 and R-rated films
SELECT
    i.store_id as store,
    f.rating as movie_rating,
    sum(p.amount) as store_revenue
FROM
	inventory i, film f, rental r, payment p
WHERE
	i.inventory_id = r.inventory_id
	AND r.rental_id = p.rental_id
	AND i.film_id = f.film_id
	AND i.store_id = 1
	AND f.rating IN ("R", "PG-13")
GROUP BY 1, 2
ORDER BY 3 DESC;

SELECT
    i.store_id as store,
    f.rating as movie_rating,
    sum(p.amount) as store_revenue
FROM
	inventory i, film f, rental r, payment p
WHERE
	i.inventory_id = r.inventory_id
	AND r.rental_id = p.rental_id
	AND i.film_id = f.film_id
	AND i.store_id = 1
	AND f.rating IN ("R", "PG-13")
	AND r.rental_date between "2005-06-08" AND '2005-07-19'
GROUP BY 1, 2
ORDER BY 3 DESC;

-- rentals per customer
SELECT
	customer_id,
	COUNT(DISTINCT rental_id) as num_rental
FROM 
	rental r
GROUP BY customer_id

-- revenue from super users (users who have rented more than 20 times)
SELECT
  sum(p.amount)
FROM
  (
    SELECT
      customer_id,
      COUNT(DISTINCT rental_id) as num_rentals
    FROM
      rental r
    GROUP BY
      customer_id
  ) as rpc,
  payment p
WHERE
  rpc.customer_id = p.customer_id
  AND rpc.num_rentals > 20;

 
 --
SELECT
  rpc.num_rentals,
  COUNT(DISTINCT rpc.customer_id) as num_customers,
  sum(p.amount) as total_revenue
FROM
  (
    SELECT
      customer_id,
      COUNT(DISTINCT rental_id) as num_rentals
    FROM
      rental r
    GROUP BY
      customer_id
  ) as rpc,
  payment p
WHERE
  rpc.customer_id = p.customer_id
  AND rpc.num_rentals > 20
GROUP BY
  1;

-- use temp table
create temporary table rpc as
SELECT
	customer_id,
	COUNT(DISTINCT rental_id) as num_rentals
FROM 
	rental r
GROUP BY 
	customer_id
;

SELECT
	sum(p.amount) as total_revenue
FROM
	rpc, 
	payment p
WHERE
	rpc.customer_id = p.customer_id
	AND rpc.num_rentals > 20
;

# all info from active customers (active=1) and their phone number
create temporary table active_Users as
SELECT
	c.*, 
	a.phone
FROM
	customer c
		LEFT JOIN address a ON c.address_id = a.address_id
WHERE
	c.active = 1
;
/* 
customers who had at least 30 rentals - reward customer
customer_id, num of rentals, last rental date
just using rental table
*/
SELECT
	r.customer_id,
	COUNT(DISTINCT rental_id) as num_rentals,
	max(rental_date)
FROM
	rental r
		JOIN active_Users au ON au.customer_id = r.customer_id
GROUP BY r.customer_id
HAVING num_rentals >= 30
;

-- no temp table
SELECT
	r.customer_id,
	COUNT(DISTINCT rental_id) as num_rentals,
	max(rental_date)
FROM
	rental r
		JOIN (
			SELECT
				c.*, 
				a.phone
			FROM
				customer c
					LEFT JOIN address a ON c.address_id = a.address_id
			WHERE
				c.active = 1
			) active_Users ON active_Users.customer_id = r.customer_id
GROUP BY r.customer_id
HAVING num_rentals >= 30
;

/* reward users who are also active users
columns : customer_id, email, first_name

all reward users
columns : customer_id, email, phone (for those who are also active users)
*/

# find all reward customers (num of rentals >= 30) who is also active
SELECT
	r.customer_id,
	au.email,
	COUNT(DISTINCT rental_id) as num_rentals
FROM
	rental r
		JOIN (
			SELECT 
				customer_id, email
			FROM
				customer
			WHERE
				active = 1
			) au
		ON r.customer_id = au.customer_id
GROUP BY 1
HAVING num_rentals >= 30;

-- temp table solution:
drop temporary table if exists activeUsers
create temporary table activeUsers
SELECT
	c.*,
	a.phone
FROM
	customer c
		JOIN address a ON c.customer_id = a.customer_id
WHERE
	c.active = 1
GROUP BY 1 
;

drop temporary table if exists rewardUsers
create temporary table rewardUsers
SELECT
	customer_id,
	COUNT(DISTINCT rental_id) as num_rentals,
	max(rental_date)
FROM
	rental
GROUP BY 1
HAVING num_rentals >= 30
;

SELECT
	au.customer_id,
	au.email,
	au.first_name
FROM
	activeUsers au
		JOIN rewardUsers ru ON au.customer_id = ru.customer_id
GROUP BY 1
;

# all reward customers (num of rental >= 30), if active, provide phone number as well
SELECT
	r.customer_id,
	COUNT(DISTINCT rental_id) as num_rentals,
	c.email,
	CASE
		WHEN c.active = 1 THEN a.phone
		ELSE Null
	END

FROM
	rental r
		JOIN customer c ON c.customer_id = r.customer_id
		JOIN address a ON c.address_id = a.address_id
GROUP BY 1
HAVING num_rentals >= 30
;


/* cohort analysis
*/

-- customer's first rental date
DROP TEMPORARY TABLE IF EXISTS first_rental;
CREATE TEMPORARY TABLE first_rental
SELECT
	customer_id,
	min(rental_date) as first_time
FROM
	rental
GROUP BY 1
;

-- size of each cohort
DROP TEMPORARY TABLE IF EXISTS cohort_size;
CREATE TEMPORARY TABLE cohort_size
SELECT
	left(first_time, 7) as month,
	count(customer_id) as num
FROM
	first_rental
GROUP BY 1
;

# Revenue Per User for each cohort and month
DROP TEMPORARY TABLE IF EXISTS cohort
CREATE TEMPORARY TABLE cohort
SELECT
	date_format(fr.first_time, '%Y%m') as cohort_formatted,
	date_format(r.rental_date, '%Y%m') as rental_date_formatted,
	cs.num as cohort_size,
	sum(p.amount) as month_revenue,
	sum(p.amount)/cs.num as rev_per_user
FROM
	rental r
	JOIN first_rental fr ON r.customer_id = fr.customer_id
	JOIN cohort_size cs ON cs.month = left(fr.first_time, 7)
	JOIN payment ON p.rental_id = r.rental_id
GROUP BY
	1, 2
;

-- no temp table solution

SELECT
    date_format(first_rental.r2_first_time, '%Y%m') as cohort_formatted,
    date_format(rental.rental_date, '%Y%m') as rental_date_formatted,
    cohort_size.grouped_month_customer,
    sum(payment.amount) as month_revenue,
    sum(payment.amount)/cohort_size.grouped_month_customer as rev_per_customer
FROM
    (
    SELECT
        left(a.first_time, 7) as grouped_month,
        count(a.fr_cid) as grouped_month_customer
    FROM
        (
        SELECT
            customer_id as fr_cid,
            min(rental_date) as first_time
        FROM
            rental r1
        GROUP BY 1
        ) a
    GROUP BY 1
    ) cohort_size
    JOIN
    (
    SELECT
        r2.customer_id as r2_cid,
        min(r2.rental_date) as r2_first_time
    FROM
        rental r2
    GROUP BY 1
    ) first_rental
    ON cohort_size.grouped_month = left(first_rental.r2_first_time, 7)
    JOIN rental ON rental.customer_id = first_rental.r2_cid
    JOIN payment ON payment.rental_id = rental.rental_id
GROUP BY
    1, 2
;

# get the duration 
SELECT
	left(STR_TO_DATE(cohort_formatted, '%Y%m'), 7) as 'First Rental Month'
	period_diff(rental_date_formatted, cohort_formatted) as 'Months After Join'
	cohort_size,
	rev_per_user
FROM
	cohort
GROUP BY
	1, 2
;

-- no temp table solution

SELECT
    cohort_formatted,
    period_diff(rental_date_formatted, cohort_formatted) as "Months After Join",
    grouped_monthly_customer,
    month_revenue,
    rev_per_customer
FROM
(
SELECT
    date_format(first_rental.r2_first_time, '%Y%m') as cohort_formatted,
    date_format(rental.rental_date, '%Y%m') as rental_date_formatted,
    cohort_size.grouped_monthly_customer,
    sum(payment.amount) as month_revenue,
    sum(payment.amount)/cohort_size.grouped_monthly_customer as rev_per_customer
FROM
    (
    SELECT
        left(a.first_time, 7) as grouped_month,
        count(a.fr_cid) as grouped_monthly_customer
    FROM
        (
        SELECT
            customer_id as fr_cid,
            min(rental_date) as first_time
        FROM
            rental r1
        GROUP BY 1
        ) a
    GROUP BY 1
    ) cohort_size
    JOIN
    (
    SELECT
        r2.customer_id as r2_cid,
        min(r2.rental_date) as r2_first_time
    FROM
        rental r2
    GROUP BY 1
    ) first_rental
    ON cohort_size.grouped_month = left(first_rental.r2_first_time, 7)
    JOIN rental ON rental.customer_id = first_rental.r2_cid
    JOIN payment ON payment.rental_id = rental.rental_id
GROUP BY
    1, 2
) temp
GROUP BY 1, 2
;









