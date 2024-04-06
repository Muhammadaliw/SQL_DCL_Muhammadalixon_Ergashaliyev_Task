-- Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

-- Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
CREATE ROLE rentaluser_select;
GRANT SELECT ON TABLE customer TO rentaluser_select;
SET ROLE rentaluser_select;
SELECT * FROM customer;
RESET ROLE;

-- Create a new user group called "rental" and add "rentaluser" to the group. 
RESET ROLE;
CREATE ROLE rental;
GRANT rental to rentaluser;

/*
Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
Insert a new row and update one existing row in the "rental" table under that role. 
*/

GRANT INSERT ON TABLE rental TO rental;
GRANT UPDATE ON TABLE rental TO rental;
SET ROLE rental;

WITH inserted_row AS (
    INSERT INTO rental
        (rental_date, inventory_id, customer_id, return_date, staff_id)
        VALUES ('2029-05-25 00:54:33.000 +0500', 389, 12, '2029-05-28 21:40:33.000 +0500', 1)
        RETURNING rental_id
)
UPDATE rental
SET rental_date = '2023-11-25 00:00:00.000 +0500'
FROM inserted_row
WHERE rental.rental_id = inserted_row.rental_id;

/*
Revoke the "rental" group's INSERT permission for the "rental" table. 
Try to insert new rows into the "rental" table make sure this action is denied.
*/

CREATE ROLE restricted_rental;
GRANT ALL ON TABLE rental TO restricted_rental;
REVOKE INSERT ON TABLE rental FROM rental;
SET ROLE restricted_rental;
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES ('2029-05-25 00:54:33.000 +0500', 389, 12, '2029-05-28 21:40:33.000 +0500', 1);

RESET ROLE;

/*
Create a personalized role for any customer already existing in the dvd_rental database. 
The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
The customer's payment and rental history must not be empty. 
Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
Write a query to make sure this user sees only their own data.
*/

CREATE ROLE client_CASSANDRA_WALTERS;
GRANT USAGE ON SCHEMA public TO client_CASSANDRA_WALTERS;
GRANT SELECT ON rental TO client_CASSANDRA_WALTERS;
GRANT SELECT ON payment TO client_CASSANDRA_WALTERS;
GRANT SELECT ON customer TO client_CASSANDRA_WALTERS;

------------------------------------------------------

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

------------------------------------------------------

CREATE OR REPLACE FUNCTION get_customer_id(first_name TEXT, last_name TEXT) RETURNS INTEGER AS $$
DECLARE
    customer_id INTEGER;
BEGIN
    SELECT customer_id INTO customer_id
    FROM customer
    WHERE first_name = get_customer_id.first_name
    AND last_name = get_customer_id.last_name
    LIMIT 1;
    
    RETURN customer_id;
END;
$$ LANGUAGE plpgsql;


CREATE POLICY rental_policy
    ON rental
    USING (customer_id = get_customer_id('Max', 'Johnson'));


CREATE POLICY payment_policy
    ON payment
    USING (customer_id = get_customer_id('Max', 'Johnson'));

--------------------------------------------------------------

ALTER TABLE rental FORCE ROW LEVEL SECURITY;
ALTER TABLE payment FORCE ROW LEVEL SECURITY;