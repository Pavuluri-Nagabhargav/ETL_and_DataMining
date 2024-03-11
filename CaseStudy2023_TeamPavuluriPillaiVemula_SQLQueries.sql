use SP23_ksbvemula
go

DROP View IF EXISTS FactAndDIMENSIONTables
DROP VIEW IF EXISTS Top3LocationsForProfitbyYear
DROP VIEW IF EXISTS Top3LocationsForProfitbyMonth
DROP VIEW IF EXISTS Top3LocationsForProfitbyWeek
DROP VIEW IF EXISTS Top3LocationsForProfitbyDay
DROP VIEW IF EXISTS CustomersServedPerYear
DROP VIEW IF EXISTS CustomersServedPerMonth
DROP VIEW IF EXISTS CustomersServedPerWeek
DROP VIEW IF EXISTS CustomersServedPerDay
DROP VIEW if exists Top10ProductsByLocationAnnually
DROP VIEW if exists Top10ProductsByLocationMonthly
DROP VIEW if exists Top10ProductsByLocationWeekly
DROP VIEW if exists Top10ProductsByLocationDaily
DROP VIEW if exists ProductsWithNoOrFewSales
DROP VIEW if exists DriveThruImpactOnSales
go

--- Create a view to show all the records in fact table once joined with dimension tables
CREATE VIEW FactAndDimensionTables as 
(
SELECT f.factID,f.dimProductID,f.dimStoreID,f.dimTransactionID,f.date_key,f.ProductGrossAmt,f.ProductNetAmt,f.ProductTaxAmt,f.Quantity
FROM factHealthOptionsInc f
INNER JOIN dimProduct p
ON p.dimProductID=f.dimProductID
INNER JOIN dimStore s
ON s.dimStoreID=f.dimStoreID
INNER JOIN dimDate d
ON d.date_key=f.date_key
INNER JOIN dimTransaction t
ON t.dimTransactionID=f.dimTransactionID
);
go

--- Displays all the records in fact table after joining with all dimension tables
SELECT * FROM FactAndDimensionTables;
go

--*********************************************************************************************************************************************************
--- 1. What are the top 3 locations with respect to profit annually, monthly, weekly and daily?

--- Top 3 Locations w.r.t Profit by Year

CREATE VIEW Top3LocationsForProfitByYear 
AS
(
SELECT SubQuery.StoreNbr,SubQuery.StoreAddress,SubQuery.StoreCity,SubQuery.StoreState,SubQuery.StoreZipcode,SubQuery.Year,SubQuery.PROFIT
FROM 
(
SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode,d.year_nbr as Year,SUM(f.ProductNetAmt) as PROFIT,
RANK() OVER(PARTITION BY d.year_nbr ORDER BY SUM(f.ProductNetAmt) desc) as rank 
FROM factHealthOptionsInc as f
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
INNER JOIN dimProduct as p
ON f.dimProductID=p.dimProductID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
GROUP BY d.year_nbr,s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode) SubQuery
WHERE SubQuery.rank<4
);
go


--- Displays Top 3 Locations with Highest Profit for the year 2022
SELECT * FROM Top3LocationsForProfitByYear WHERE Year=2022 ORDER BY PROFIT desc;
go


--- Top 3 Locations w.r.t Profit by Month

CREATE VIEW Top3LocationsForProfitByMonth
AS
(
SELECT SubQuery.StoreNbr,SubQuery.StoreAddress,SubQuery.StoreCity,SubQuery.StoreState,SubQuery.StoreZipcode,SubQuery.Year,SubQuery.Month,SubQuery.PROFIT
FROM 
(
SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode,d.year_nbr as Year,d.month_name as Month,SUM(f.ProductNetAmt) as PROFIT,
RANK() OVER(PARTITION BY d.year_nbr,d.month_name ORDER BY SUM(f.ProductNetAmt) desc) as rank 
FROM factHealthOptionsInc as f
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
INNER JOIN dimProduct as p
ON f.dimProductID=p.dimProductID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
GROUP BY d.year_nbr,d.month_name,s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode) SubQuery
WHERE SubQuery.rank<4
);
go

--- Displays Top 3 Locations with total Highest Profit for January,2022
SELECT * FROM Top3LocationsForProfitByMonth WHERE Year=2022 and Month='January' ORDER BY PROFIT DESC;
go


--- Top 3 Locations w.r.t Profit by Week

CREATE VIEW Top3LocationsForProfitByWeek
AS
(
SELECT SubQuery.StoreNbr,SubQuery.StoreAddress,SubQuery.StoreCity,SubQuery.StoreState,SubQuery.StoreZipcode,SubQuery.Year,SubQuery.Week,SubQuery.PROFIT
FROM 
(
SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode,d.year_nbr as Year,DATEPART(WEEK,d.fulldate) as Week,SUM(f.ProductNetAmt) as PROFIT,
RANK() OVER(PARTITION BY d.year_nbr,DATEPART(WEEK,d.fulldate) ORDER BY SUM(f.ProductNetAmt) desc) as rank 
FROM factHealthOptionsInc as f
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
INNER JOIN dimProduct as p
ON f.dimProductID=p.dimProductID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
GROUP BY d.year_nbr,DATEPART(WEEK,d.fulldate),s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode) SubQuery
WHERE SubQuery.rank<4
);
go

--- Displays Top 3 Locations with total Highest Profit in the second week of the year 2022
SELECT * FROM Top3LocationsForProfitByWeek WHERE Year=2022 and Week=2
go


--- Top 3 Locations w.r.t Profit Daily

CREATE VIEW Top3LocationsForProfitByDay
AS
(
SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode,
CAST(d.fulldate as date) as Day,
SUM(f.ProductNetAmt) as PROFIT
FROM factHealthOptionsInc as f
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
INNER JOIN dimProduct as p
ON f.dimProductID=p.dimProductID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
GROUP BY CAST(d.fulldate as date),s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,s.StoreZipcode
);
go

--- Displays Top 3 Locations with Highest Profit on January 1,2022
SELECT TOP 3 * FROM Top3LocationsForProfitByDay WHERE Day='01-01-2022' ORDER BY PROFIT desc
go

---*******************************************************************************************************************************************************

--- 2.	How many customers does each location serve annually, monthly, weekly and daily?

--- Customers served in each location annually

CREATE VIEW CustomersServedPerYear
AS
(
SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,d.year_nbr as Year,COUNT(distinct t.ReceiptNbr) as customers_served
FROM factHealthOptionsInc as f
INNER JOIN dimTransaction as t
ON t.dimTransactionID=f.dimTransactionID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
GROUP BY d.year_nbr,s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState
);
go

---Displays data of number of customers served by each location for the year of 2022
SELECT * FROM CustomersServedPerYear WHERE Year=2022 ORDER BY customers_served desc;
go


--- Customers served in each location monthly

CREATE VIEW CustomersServedPerMonth
AS
(
SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,d.year_nbr as Year,d.month_name as Month,COUNT(distinct t.ReceiptNbr) as customers_served
FROM factHealthOptionsInc as f
INNER JOIN dimTransaction as t
ON t.dimTransactionID=f.dimTransactionID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
GROUP BY d.year_nbr,d.month_name,s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState
);
go

--- Displays number of customers served by each location in each month for the year 2022
SELECT * FROM CustomersServedPerMonth WHERE Year=2022 and Month='December' ORDER BY StoreNbr,customers_served desc;
go


--- Customers served in each location weekly

CREATE VIEW CustomersServedPerWeek
AS
(
SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,d.year_nbr as Year,DATEPART(Week,d.fulldate) as Week,COUNT(distinct t.ReceiptNbr) as customers_served
FROM factHealthOptionsInc as f
INNER JOIN dimTransaction as t
ON t.dimTransactionID=f.dimTransactionID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
GROUP BY d.year_nbr,DATEPART(Week,d.fulldate),s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState
);
go

--- Displays number of customers served by each location for the last week of 2022
SELECT * FROM CustomersServedPerWeek WHERE Week=53 and Year=2022 ORDER BY StoreNbr,customers_served desc;
go


--- Customers served in each location daily

CREATE VIEW CustomersServedPerDay
AS
(
SELECT  s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,CAST(d.fulldate as date) as Day,COUNT(distinct t.ReceiptNbr) as customers_served
FROM factHealthOptionsInc as f
INNER JOIN dimTransaction as t
ON t.dimTransactionID=f.dimTransactionID
INNER JOIN dimDate as d
ON f.date_key=d.date_key
INNER JOIN dimStore as s
ON s.dimStoreID=f.dimStoreID
GROUP BY CAST(d.fulldate as date),s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState
);
go

--- Displays number of customers served by each location on 20 June,2022
SELECT * FROM CustomersServedPerDay WHERE Day='06-20-2022' ORDER BY StoreNbr,customers_served desc;
go

---***********************************************************************************************************************************************************

--- 3.	What are the top 10 most popular products sold by location annually, monthly, weekly and daily?

--- Top 10 Products by Location Annually

CREATE VIEW Top10ProductsByLocationAnnually
AS
(
SELECT SubQuery.StoreNbr,SubQuery.StoreAddress,SubQuery.StoreCity,SubQuery.StoreState,SubQuery.ProductNbr,SubQuery.ProductDesc,SubQuery.Year,SubQuery.QuantitySold
FROM
(SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,p.ProductNbr,p.ProductDesc,d.year_nbr as Year,SUM(f.Quantity) as QuantitySold,
DENSE_RANK() OVER(PARTITION BY s.StoreNbr,d.year_nbr ORDER BY SUM(f.Quantity) desc) as rank
FROM factHealthOptionsInc f
INNER JOIN dimProduct p
ON f.dimProductID=p.dimProductID
INNER JOIN dimStore s
ON f.dimStoreID=s.dimStoreID
INNER JOIN dimDate d
ON f.date_key=d.date_key
GROUP BY s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,d.year_nbr,p.ProductNbr,p.ProductDesc
) SubQuery
WHERE SubQuery.rank <11
);
go

--- Displays Top 10 Products sold in each location in the year 2022
SELECT * FROM Top10ProductsByLocationAnnually WHERE Year=2022 ORDER BY StoreNbr,QuantitySold desc;
go


--- Top 10 Products by Location Monthly

CREATE VIEW Top10ProductsByLocationMonthly
AS
(
SELECT SubQuery.StoreNbr,SubQuery.StoreAddress,SubQuery.StoreCity,SubQuery.StoreState,SubQuery.ProductNbr,SubQuery.ProductDesc,SubQuery.Year,SubQuery.Month,SubQuery.QuantitySold
FROM
(SELECT p.ProductNbr,p.ProductDesc,s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,d.year_nbr as Year,d.month_name as Month,SUM(f.Quantity) as QuantitySold,
DENSE_RANK() OVER(PARTITION BY s.StoreNbr,d.month_name ORDER BY SUM(f.Quantity) desc) as rank
FROM factHealthOptionsInc f
INNER JOIN dimProduct p
ON f.dimProductID=p.dimProductID
INNER JOIN dimStore s
ON f.dimStoreID=s.dimStoreID
INNER JOIN dimDate d
ON f.date_key=d.date_key
GROUP BY s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,d.year_nbr,d.month_name,p.ProductNbr,p.ProductDesc
) SubQuery
WHERE SubQuery.rank <11
);
go

--- Displays Top 10 Products sold in each location in December,2022
SELECT * FROM Top10ProductsByLocationMonthly WHERE Year=2022 and Month='December' ORDER BY StoreNbr,QuantitySold desc;
go


--- Top 10 Products by Location Weekly

CREATE VIEW Top10ProductsByLocationWeekly
AS
(
SELECT SubQuery.StoreNbr,SubQuery.StoreAddress,SubQuery.StoreCity,SubQuery.StoreState,SubQuery.ProductNbr,SubQuery.ProductDesc,SubQuery.Year,SubQuery.Week,SubQuery.QuantitySold
FROM
(SELECT s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,p.ProductNbr,p.ProductDesc,d.year_nbr as Year,DATEPART(WEEK,d.fulldate) as Week,SUM(f.Quantity) as QuantitySold,
DENSE_RANK() OVER(PARTITION BY s.StoreNbr,DATEPART(WEEK,d.fulldate) ORDER BY SUM(f.Quantity) desc) as rank
FROM factHealthOptionsInc f
INNER JOIN dimProduct p
ON f.dimProductID=p.dimProductID
INNER JOIN dimStore s
ON f.dimStoreID=s.dimStoreID
INNER JOIN dimDate d
ON f.date_key=d.date_key
GROUP BY s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,d.year_nbr,DATEPART(WEEK,d.fulldate),p.ProductNbr,p.ProductDesc
) SubQuery
WHERE SubQuery.rank <11
);
go

--- Displays Top 10 Products sold in each location in the last week of 2022
SELECT * FROM Top10ProductsByLocationWeekly WHERE Year=2022 and Week=53 ORDER BY StoreNbr,QuantitySold desc;
go


--- Top 10 Products by Location Daily

CREATE VIEW Top10ProductsByLocationDaily
AS
(
SELECT SubQuery.StoreNbr,SubQuery.StoreAddress,SubQuery.StoreCity,SubQuery.StoreState,SubQuery.ProductNbr,SubQuery.ProductDesc,SubQuery.Day,SubQuery.QuantitySold
FROM
(SELECT p.ProductNbr,p.ProductDesc,s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,CAST(d.fulldate as date) as Day,SUM(f.Quantity) as QuantitySold,
DENSE_RANK() OVER(PARTITION BY s.StoreNbr,CAST(d.fulldate as date) ORDER BY SUM(f.Quantity) desc) as rank
FROM factHealthOptionsInc f
INNER JOIN dimProduct p
ON f.dimProductID=p.dimProductID
INNER JOIN dimStore s
ON f.dimStoreID=s.dimStoreID
INNER JOIN dimDate d
ON f.date_key=d.date_key
GROUP BY s.StoreNbr,s.StoreAddress,s.StoreCity,s.StoreState,p.ProductNbr,p.ProductDesc,CAST(d.fulldate as date)
) SubQuery
WHERE SubQuery.rank <11
);
go

--- Displays Top 10 Products sold in each location on June 20,2022
SELECT * FROM Top10ProductsByLocationDaily WHERE Day='06-20-2022' ORDER BY StoreNbr,QuantitySold desc;
go

---**********************************************************************************************************************************************************

--- 4.	Which products have no sales or few sales?

CREATE VIEW ProductsWithNoOrFewSales
AS
(
	SELECT p.ProductNbr,p.ProductDesc,p.MenuName,p.MenuType,p.MenuCategory,p.MenuSubCategory,SUM(f.Quantity) AS QuantitySold
	FROM  factHealthOptionsInc f
	INNER JOIN dimProduct p
	ON p.dimProductID=f.dimProductID
	GROUP BY p.ProductNbr,p.ProductDesc,p.MenuName,p.MenuType,p.MenuCategory,p.MenuSubCategory
	HAVING SUM(f.Quantity) < 500
);
go

---Displays all the products whose units sold are less than 500 (This value has been chosen
---looking at the sudden drop in the total units sold when comparing the total quantity sold for different product varieties) - Results in 7 products
SELECT * FROM ProductsWithNoOrFewSales ORDER BY QuantitySold desc
go

---*************************************************************************************************************************************************************

--- 5.	How is the number of drive-thru lanes impacting sales?

CREATE VIEW DriveThruImpactOnSales
AS
(
SELECT s.NbrDriveThruLanes AS Number_Of_DriveThru_Lanes,SUM(f.ProductGrossAmt) as TotalSales
FROM factHealthOptionsInc f
INNER JOIN dimStore s
ON s.dimStoreID=f.dimStoreID
GROUP BY s.NbrDriveThruLanes
);
go

---Displays the number of drive thru lanes and the total amount of sales for each of them
--- THERE IS NO EVIDENCE FROM THE RESULTS OF THE NUMBER OF DRIVE THRU LINES IMPACTING THE SALES
SELECT * FROM DriveThruImpactOnSales ORDER BY Number_Of_DriveThru_Lanes desc
go

