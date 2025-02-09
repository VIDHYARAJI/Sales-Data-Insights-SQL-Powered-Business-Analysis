CREATE DATABASE Sales

-- 1) Retrieve all transactions

	SELECT * 
	FROM Transactions;

-- 2) Get unique product categories

	SELECT DISTINCT ProductCategory 
	FROM Products;

-- 3) Count the number of customers

	SELECT COUNT(*) AS TotalCustomers 
	FROM Customers;

-- 4) Total sales amount

	SELECT 
	SUM(SalesAmount) AS TotalSales 
	FROM Transactions;

-- 5) Find transactions for a specific date

	SELECT * FROM Transactions 
	WHERE TransactionDate = '2024-01-01';

-- 6)  Get total sales by market

	SELECT m.MarketName, SUM(t.SalesAmount) AS TotalSales
	FROM Transactions t
	JOIN Markets m ON t.MarketID = m.MarketID
	GROUP BY m.MarketName;

-- 7)  Find the top 5 highest-selling products

	SELECT p.ProductName, SUM(t.SalesAmount) AS TotalRevenue
	FROM Transactions t
	JOIN Products p ON t.ProductID = p.ProductID
	GROUP BY p.ProductName
	ORDER BY TotalRevenue DESC
    LIMIT 5;

-- 8)  Monthly sales trend

	SELECT DATE_FORMAT(TransactionDate, '%Y-%m') AS Month, SUM(SalesAmount) AS TotalSales
	FROM Transactions
	GROUP BY Month
	ORDER BY Month;

-- 9)  Customers with more than 5 transactions

	SELECT c.CustomerName, COUNT(t.TransactionID) AS TotalTransactions
	FROM Transactions t
	JOIN Customers c ON t.CustomerID = c.CustomerID
	GROUP BY c.CustomerName
	HAVING TotalTransactions > 5;

-- 10) Find the most popular product category

	SELECT p.ProductCategory, COUNT(t.TransactionID) AS TransactionCount
	FROM Transactions t
	JOIN Products p ON t.ProductID = p.ProductID
	GROUP BY p.ProductCategory
	ORDER BY TransactionCount DESC
	LIMIT 1;

-- 11) Find the top-selling product in each market

	SELECT MarketName, ProductName, TotalSales
	FROM (
		SELECT m.MarketName, p.ProductName, SUM(t.SalesAmount) AS TotalSales,
			   RANK() OVER (PARTITION BY m.MarketName ORDER BY SUM(t.SalesAmount) DESC) AS rnk
		FROM Transactions t
		JOIN Products p ON t.ProductID = p.ProductID
		JOIN Markets m ON t.MarketID = m.MarketID
		GROUP BY m.MarketName, p.ProductName
	) ranked_sales
	WHERE rnk = 1;

-- 12) The monthly growth rate in sales

	WITH MonthlySales AS (
		SELECT DATE_FORMAT(TransactionDate, '%Y-%m') AS Month,
			   SUM(SalesAmount) AS TotalSales
		FROM Transactions
		GROUP BY Month
	)
	SELECT Month, TotalSales, 
		   (TotalSales - LAG(TotalSales) OVER (ORDER BY Month)) / LAG(TotalSales) OVER (ORDER BY Month) * 100 AS GrowthRate
	FROM MonthlySales;

-- 13) Find customers who made their first purchase in the last 3 months

	SELECT c.CustomerID, c.CustomerName, MIN(t.TransactionDate) AS FirstPurchaseDate
	FROM Transactions t
	JOIN Customers c ON t.CustomerID = c.CustomerID
	GROUP BY c.CustomerID, c.CustomerName
	HAVING FirstPurchaseDate >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);

-- 14) Products with the highest average order value

	SELECT p.ProductName, AVG(t.SalesAmount) AS AvgOrderValue
	FROM Transactions t
	JOIN Products p ON t.ProductID = p.ProductID
	GROUP BY p.ProductName
	ORDER BY AvgOrderValue DESC
	LIMIT 10;

-- 15) Find the top customer by total spending

	SELECT c.CustomerName, SUM(t.SalesAmount) AS TotalSpending
	FROM Transactions t
	JOIN Customers c ON t.CustomerID = c.CustomerID
	GROUP BY c.CustomerName
	ORDER BY TotalSpending DESC
	LIMIT 1;

-- 16) Compare this year's sales vs. last year’s sales

	SELECT 
		YEAR(TransactionDate) AS Year,
		SUM(SalesAmount) AS TotalSales
	FROM Transactions
	WHERE YEAR(TransactionDate) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1)
	GROUP BY Year;

-- 17) Find customers who have not made any purchases in the previous 6 months

	SELECT c.CustomerID, c.CustomerName
	FROM Customers c
	LEFT JOIN Transactions t ON c.CustomerID = t.CustomerID 
		AND t.TransactionDate >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
	WHERE t.TransactionID IS NULL;

-- 18) Find product sales percentage contribution

	SELECT p.ProductName,
		   SUM(t.SalesAmount) AS ProductSales,
		   (SUM(t.SalesAmount) / (SELECT SUM(SalesAmount) FROM Transactions) * 100) AS SalesPercentage
	FROM Transactions t
	JOIN Products p ON t.ProductID = p.ProductID
	GROUP BY p.ProductName
	ORDER BY SalesPercentage DESC;

-- 19) Customer segmentation based on total spending (High, Medium, Low)

	SELECT CustomerID, CustomerName, TotalSpending,
		   CASE 
			   WHEN TotalSpending >= 10000 THEN 'High Value'
			   WHEN TotalSpending BETWEEN 5000 AND 9999 THEN 'Medium Value'
			   ELSE 'Low Value'
		   END AS CustomerSegment
	FROM (
		SELECT c.CustomerID, c.CustomerName, SUM(t.SalesAmount) AS TotalSpending
		FROM Transactions t
		JOIN Customers c ON t.CustomerID = c.CustomerID
		GROUP BY c.CustomerID, c.CustomerName
	) customer_spending;

-- 20) Detect seasonal trends in product sales

	SELECT 
		p.ProductCategory, 
		MONTH(t.TransactionDate) AS Month, 
		SUM(t.SalesAmount) AS MonthlySales,
		RANK() OVER (PARTITION BY p.ProductCategory ORDER BY SUM(t.SalesAmount) DESC) AS SeasonRank
	FROM Transactions t
	JOIN Products p ON t.ProductID = p.ProductID
	GROUP BY p.ProductCategory, MONTH(t.TransactionDate)
	ORDER BY p.ProductCategory, SeasonRank;

-- 21) Find the most loyal customers (Customers who make purchases every month)

	WITH CustomerMonthlyPurchases AS (
		SELECT CustomerID, DATE_FORMAT(TransactionDate, '%Y-%m') AS PurchaseMonth
		FROM Transactions
		GROUP BY CustomerID, PurchaseMonth
	)
	SELECT c.CustomerID, c.CustomerName, COUNT(DISTINCT cmp.PurchaseMonth) AS ActiveMonths
	FROM Customers c
	JOIN CustomerMonthlyPurchases cmp ON c.CustomerID = cmp.CustomerID
	GROUP BY c.CustomerID, c.CustomerName
	HAVING ActiveMonths = (SELECT COUNT(DISTINCT DATE_FORMAT(TransactionDate, '%Y-%m')) FROM Transactions);

-- 22) Find price sensitivity: How discounts impact sales volume

	SELECT p.ProductName, 
		   SUM(t.SalesAmount) AS TotalRevenue, 
		   SUM(t.QuantitySold) AS TotalUnitsSold, 
		   SUM(t.Discount) AS TotalDiscountGiven,
		   (SUM(t.SalesAmount) / SUM(t.QuantitySold)) AS AvgSellingPrice,
		   (SUM(t.Discount) / SUM(t.QuantitySold)) AS AvgDiscountPerUnit
	FROM Transactions t
	JOIN Products p ON t.ProductID = p.ProductID
	GROUP BY p.ProductName
	ORDER BY AvgDiscountPerUnit DESC;






