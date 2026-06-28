use sales_db;
-- Section A — SQL Basics (SELECT, Constraints, Primary Keys) 
-- Q1. Write a query to display all columns and rows from the customer's table. 
select * from customers;

-- Q2. Retrieve only the first_name, last_name, and city of all customers.  
SELECT 
    first_name,
    last_name,
    city
FROM customers;





-- Q3. List all unique categories available in the products table.  
select distinct category from products;


-- Q4. Identify the Primary Key of each table in the schema. Explain why a Primary Key must be unique and NOT NULL. 
desc customers;

desc order_items;

desc orders;

desc products;

-- Q5. What constraints are applied to the email column in the customers table? What would happen if you tried to insert a duplicate email? 
 
select * from customers;
INSERT INTO customers
VALUES
(109,
'Rahul',
'Patil',
'aarav.s@email.com',
'Pune',
'Maharashtra',
'2024-09-01',
TRUE);
 
--  Q6. Try inserting a product with unit_price = -50. What happens and which constraint prevents it? Write both the INSERT statement and explain the error. 
 
INSERT INTO products
VALUES
(
209,
'Gaming Mouse',
'Electronics',
'Logitech',
-50,
100
);


-- Section B — Filtering & Optimization (WHERE, Indexes) 

-- Q7. Retrieve all orders with status = 'Delivered'. 
SELECT *
FROM orders
WHERE status = 'Delivered';

-- Q8. Find all products in the 'Electronics' category with a unit_price greater than ₹2000. 

SELECT *
FROM products
WHERE category = 'Electronics'
AND unit_price > 2000;

-- Q9. List all customers who joined in the year 2024 and belong to the state 'Maharashtra'. 

SELECT *
FROM customers
WHERE state = 'Maharashtra'
AND YEAR(join_date) = 2024;

-- Q10. Find all orders placed between '2024-08-10' and '2024-08-25' (inclusive) that are NOT cancelled. 

SELECT *
FROM orders
WHERE order_date BETWEEN '2024-08-10'
AND '2024-08-25'
AND status <> 'Cancelled';

-- Q11. Explain what the index idx_orders_date does. How would it improve the performance of a query that filters orders by order_date? Write a sample query that would benefit from this index. 

CREATE INDEX idx_orders_date
ON orders(order_date);

-- Q12. If you run: SELECT * FROM customers WHERE YEAR(join_date) = 2024; — would the index on join_date be used? Explain why or why not, and rewrite the query to be index-friendly (SARGable). 

SELECT *
FROM customers
WHERE YEAR(join_date) = 2024;


-- Section C — Aggregation (GROUP BY, SUM, COUNT, AVG, MIN, MAX) 
-- Q13. Count the total number of orders in the orders table. 

SELECT COUNT(*) AS total_orders
FROM orders;

-- Q14. Find the total revenue (SUM of total_amount) from all 'Delivered' orders. 

SELECT 
    SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'Delivered';

-- Q15. Calculate the average unit_price of products in each category. 

SELECT
    category,
    AVG(unit_price) AS average_price
FROM products
GROUP BY category;

-- Q16. For each order status, find the count of orders and the total revenue. Sort the result by total revenue in descending order. 

SELECT
    status,
    COUNT(order_id) AS order_count,
    SUM(total_amount) AS total_revenue
FROM orders
GROUP BY status
ORDER BY total_revenue DESC;

-- Q17. Find the most expensive (MAX) and cheapest (MIN) product in each category. 

SELECT
    category,
    MAX(unit_price) AS highest_price,
    MIN(unit_price) AS lowest_price
FROM products
GROUP BY category;

-- Q18. List all product categories where the average unit_price is greater than ₹2000. (Hint: Use HAVING clause) 

SELECT
    category,
    AVG(unit_price) AS average_price
FROM products
GROUP BY category
HAVING AVG(unit_price) > 2000;

-- Section D — Joins & Relationships 

-- Q19. Write an INNER JOIN query to display each order along with the customer's first_name and last_name. Show: order_id, order_date, first_name, last_name, total_amount. 
SELECT
    orders.order_id,
    orders.order_date,
    customers.first_name,
    customers.last_name,
    orders.total_amount
FROM orders
INNER JOIN customers
ON orders.customer_id = customers.customer_id;

-- Q20. Using a LEFT JOIN, list ALL customers and their orders (if any). Customers with no orders should still appear with NULL values for order columns. 

SELECT
    customers.customer_id,
    customers.first_name,
    customers.last_name,
    orders.order_id,
    orders.order_date,
    orders.total_amount
FROM customers
LEFT JOIN orders
ON customers.customer_id = orders.customer_id;

-- Q21. Write a query using JOINs across three tables (orders → order_items → products) to show: order_id, product_name, quantity, unit_price, and discount_pct for each order item. 

SELECT
    orders.order_id,
    products.product_name,
    order_items.quantity,
    order_items.unit_price,
    order_items.discount_pct
FROM orders
INNER JOIN order_items
ON orders.order_id = order_items.order_id
INNER JOIN products
ON order_items.product_id = products.product_id;

-- Q22. Explain the difference between LEFT JOIN and RIGHT JOIN with an example from this schema. When would you use a FULL OUTER JOIN? 

SELECT *
FROM customers
LEFT JOIN orders
ON customers.customer_id = orders.customer_id;

-- Q23. Identify all Foreign Key relationships in the schema. Explain what would happen if you tried to insert an order with customer_id = 999 (which doesn't exist in customers).

INSERT INTO orders
VALUES
(
1011,
999,
'2024-09-01',
'Pending',
1598
);

-- Section E — Advanced Concepts (CASE, ACID, Transactions) 

-- Q24. Write a query using CASE to classify products into price tiers: 
--   • 'Budget'    → unit_price < 1000 
--   • 'Mid-Range' → unit_price BETWEEN 1000 AND 3000 
--   • 'Premium'   → unit_price > 3000 
-- Display: product_name, unit_price, price_tier. 

SELECT
    product_name,
    unit_price,
    CASE
        WHEN unit_price < 1000 THEN 'Budget'
        WHEN unit_price BETWEEN 1000 AND 3000 THEN 'Mid-Range'
        WHEN unit_price > 3000 THEN 'Premium'
    END AS price_tier
FROM products;

-- Q25. Using a CASE statement inside an aggregate function, count how many orders are 'Delivered' vs 'Not Delivered' (all other statuses). Display the result in a single row. 

SELECT
    COUNT(
        CASE
            WHEN status = 'Delivered'
            THEN 1
        END
    ) AS delivered_orders,
    COUNT(
        CASE
            WHEN status <> 'Delivered'
            THEN 1
        END
    ) AS not_delivered_orders
FROM orders;

-- Q26. Explain each letter of ACID: 
--   • A – Atomicity 
--   • C – Consistency 
--   • I – Isolation 
--   • D – Durability 
-- Give a real-world example (e.g., bank transfer) showing why each property is important.


-- Q27. Write a SQL transaction that does the following atomically: 
--   1. Insert a new order (order_id=1011, customer_id=102, today's date, 'Pending', 1598.00) 
--   2. Insert two order items for that order 
--   3. Update the stock_qty of the purchased products 
--   4. If any step fails, ROLLBACK the entire transaction. Otherwise, COMMIT. 
-- Write the complete BEGIN...COMMIT/ROLLBACK block. 

START TRANSACTION;


-- Step 1: Insert new order

INSERT INTO orders
(
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
)
VALUES
(
    1011,
    102,
    CURRENT_DATE,
    'Pending',
    1598.00
);



-- Step 2: Insert order items

INSERT INTO order_items
(
    item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_pct
)
VALUES
(
   5016,
   1011,
   206,
   1,
   1299.00,
   0
);



INSERT INTO order_items
(
    item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_pct
)
VALUES
(
5017,
1011,
208,
1,
599.00,
0
);



-- Step 3: Update stock quantity

UPDATE products
SET stock_qty = stock_qty - 1
WHERE product_id = 206;


UPDATE products
SET stock_qty = stock_qty - 1
WHERE product_id = 208;



-- Step 4: Commit changes

COMMIT;
 
