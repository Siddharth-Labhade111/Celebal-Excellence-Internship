-- Create a Database 
create database superstore_db;
use superstore_db;

show tables;

SELECT *
FROM superstore_raw
LIMIT 10;

-- Create customers  Table
CREATE TABLE customers (
    Customer_ID VARCHAR(20) PRIMARY KEY,
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50)
);

SHOW COLUMNS FROM superstore_raw;

-- Insert the data into the customers table
INSERT INTO customers
(
    Customer_ID,
    Customer_Name,
    Segment,
    Country,
    City,
    State,
    Postal_Code,
    Region
)
SELECT
    `Customer ID`,
    MAX(`Customer Name`),
    MAX(`Segment`),
    MAX(`Country`),
    MAX(`City`),
    MAX(`State`),
    MAX(`Postal Code`),
    MAX(`Region`)
FROM superstore_raw
GROUP BY `Customer ID`;

-- Verify the Table
SELECT COUNT(*) AS Total_Customers
FROM customers;

SELECT `Customer ID`
FROM superstore_raw;

-- Create the orders table
CREATE TABLE orders (
    Order_ID VARCHAR(20) PRIMARY KEY,
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(20),

    CONSTRAINT fk_customer
        FOREIGN KEY (Customer_ID)
        REFERENCES customers(Customer_ID)
);

-- Insert data into orders table
INSERT INTO orders
(
    Order_ID,
    Order_Date,
    Ship_Date,
    Ship_Mode,
    Customer_ID
)

SELECT DISTINCT
    `Order ID`,
    STR_TO_DATE(`Order Date`, '%m/%d/%Y'),
    STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),
    `Ship Mode`,
    `Customer ID`
FROM superstore_raw;

-- Verify The Table
SELECT *
FROM orders
LIMIT 10;

-- Create the products Table
CREATE TABLE products (
    Product_ID VARCHAR(30) PRIMARY KEY,
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255)
);

-- Insert tha data into products table
INSERT INTO products
(
    Product_ID,
    Category,
    Sub_Category,
    Product_Name
)
SELECT
    `Product ID`,
    MAX(`Category`),
    MAX(`Sub-Category`),
    MAX(`Product Name`)
FROM superstore_raw
GROUP BY `Product ID`;

-- Verify the table
SELECT *
FROM products
LIMIT 10;

-- Step 2: Perform Required Queries 
-- 1.	Find all orders where sales are greater than the average sales. (Subquery)  
SELECT
    o.Order_ID,
    o.Customer_ID,
    sr.`Sales`
FROM orders o
JOIN superstore_raw sr
    ON o.Order_ID = sr.`Order ID`
WHERE sr.`Sales` >
(
    SELECT AVG(`Sales`)
    FROM superstore_raw
);
 
 
-- 2. Find the highest sales order for each customer. (Subquery)  
SELECT
    c.Customer_Name,
    o.Order_ID,
    sr.Sales
FROM customers c
JOIN orders o
    ON c.Customer_ID = o.Customer_ID
JOIN superstore_raw sr
    ON o.Order_ID = sr.`Order ID`
WHERE (sr.`Customer ID`, sr.Sales) IN
(
    SELECT
        `Customer ID`,
        MAX(Sales)
    FROM superstore_raw
    GROUP BY `Customer ID`
);

-- 3.	Calculate total sales for each customer. (CTE)  
WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
)

SELECT *
FROM CustomerSales
ORDER BY Total_Sales DESC;

-- 4. Find customers whose total sales are above average. (CTE + Subquery)  
WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
)

SELECT
    Customer_ID,
    Customer_Name,
    Total_Sales
FROM CustomerSales
WHERE Total_Sales >
(
    SELECT AVG(Total_Sales)
    FROM CustomerSales
)
ORDER BY Total_Sales DESC;

-- 5. Rank all customers based on total sales. (Window Function)  
WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
)

SELECT
    Customer_ID,
    Customer_Name,
    Total_Sales,
    RANK() OVER (ORDER BY Total_Sales DESC) AS Customer_Rank
FROM CustomerSales
ORDER BY Customer_Rank;

-- 6. Assign row numbers to each order within a customer. (Window Function + PARTITION BY)  
SELECT
    Customer_ID,
    Order_ID,
    Order_Date,
    ROW_NUMBER() OVER (
        PARTITION BY Customer_ID
        ORDER BY Order_Date
    ) AS Order_Number
FROM orders
ORDER BY Customer_ID, Order_Date;

-- 7. Display top 3 customers based on total sales. (Window Function)   
WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
),

RankedCustomers AS
(
    SELECT
        Customer_ID,
        Customer_Name,
        Total_Sales,
        RANK() OVER (ORDER BY Total_Sales DESC) AS Customer_Rank
    FROM CustomerSales
)

SELECT
    Customer_ID,
    Customer_Name,
    Total_Sales,
    Customer_Rank
FROM RankedCustomers
WHERE Customer_Rank <= 3
ORDER BY Customer_Rank;


-- Step 3: Final Combined Query 
-- Write one final query that shows: 
-- Customer Name  
-- Total Sales  
-- Rank  
-- (Use JOIN + CTE + Window Function together) 

WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
)

SELECT
    Customer_Name,
    Total_Sales,
    RANK() OVER (ORDER BY Total_Sales DESC) AS Customer_Rank
FROM CustomerSales
ORDER BY Customer_Rank;


-- Mini Project: Customer Sales Insights 

-- Answer the following using SQL: 

-- Who are the top 5 customers?  
WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
)

SELECT
    Customer_ID,
    Customer_Name,
    Total_Sales
FROM CustomerSales
ORDER BY Total_Sales DESC
LIMIT 5;

-- Who are the bottom 5 customers?  
WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
)

SELECT
    Customer_ID,
    Customer_Name,
    Total_Sales
FROM CustomerSales
ORDER BY Total_Sales ASC
LIMIT 5;

-- Which customers made only one order?  
SELECT
    c.Customer_ID,
    c.Customer_Name,
    COUNT(o.Order_ID) AS Total_Orders
FROM customers c
JOIN orders o
    ON c.Customer_ID = o.Customer_ID
GROUP BY
    c.Customer_ID,
    c.Customer_Name
HAVING COUNT(o.Order_ID) = 1;

-- Which customers have above-average sales?  
WITH CustomerSales AS
(
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        SUM(sr.Sales) AS Total_Sales
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN superstore_raw sr
        ON o.Order_ID = sr.`Order ID`
    GROUP BY
        c.Customer_ID,
        c.Customer_Name
)

SELECT
    Customer_ID,
    Customer_Name,
    Total_Sales
FROM CustomerSales
WHERE Total_Sales >
(
    SELECT AVG(Total_Sales)
    FROM CustomerSales
)
ORDER BY Total_Sales DESC;

-- What is the highest order value per customer? 
SELECT
    c.Customer_ID,
    c.Customer_Name,
    MAX(sr.Sales) AS Highest_Order_Value
FROM customers c
JOIN orders o
    ON c.Customer_ID = o.Customer_ID
JOIN superstore_raw sr
    ON o.Order_ID = sr.`Order ID`
GROUP BY
    c.Customer_ID,
    c.Customer_Name
ORDER BY Highest_Order_Value DESC;