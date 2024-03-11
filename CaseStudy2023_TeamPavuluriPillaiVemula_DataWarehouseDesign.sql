use SP23_ksbvemula
go

--*********************************************************************
-- Already loaded data into a table called "FinalCaseStudyTable"

--Use CaseStudy2023
--go

--SELECT *
--INTO SP23_ksbvemula.dbo.FinalCaseStudyTable
--FROM CaseStudy2023AllRecs_new
--go
--***********************************************************************

--- Code to show original data loaded into a table in our database - Results in 96,577 rows
--- SELECT * FROM FinalCaseStudyTable

--- Code to know the non-duplicate records - Results in 74,111 rows (Actual duplicate removal has been done in SSIS)
--- SELECT count(ReceiptNbr) FROM FinalCaseStudyTable	
--- GROUP BY ReceiptNbr,TransDate,TransTime,ProductNbr,Quantity

--- Dropping fact and dimension tables
DROP TABLE if exists factHealthOptionsInc
DROP TABLE if exists dimProduct
DROP TABLE if exists dimStore
DROP TABLE if exists dimTransaction
DROP TABLE if exists dimDate
DROP PROCEDURE if exists dimDateProcedure
go

--- Creating the Product dimension table
CREATE TABLE dimProduct (
dimProductID int Identity(1,1) CONSTRAINT pkdimProductID Primary Key,
ProductNbr int not null,
MenuName varchar(50) not null,
MenuType varchar(100) not null,
MenuCategory varchar(50) not null,
MenuSubCategory varchar(50) not null,
ProductDesc varchar(300) not null,
DefaultProductPrice decimal(10,6) not null
)
go

--- Creating the Store dimension table
CREATE TABLE dimStore (
dimStoreID int Identity(1,1) CONSTRAINT pkdimStoreID Primary Key,
StoreNbr int not null,
StoreCapacity int not null,
DateStoreOpened datetime,
StoreStatus varchar(10) not null,
StoreAddress varchar(200) not null,
StoreCity varchar(50) not null,
StoreState varchar(50) not null,
StoreZipCode int not null,
BuildingType varchar(20) not null,
NbrDriveThruLanes int not null,
NbrParkingSpaces int not null
)
go

--- Creating the Transaction dimension table
CREATE TABLE dimTransaction (
dimTransactionID int Identity(1,1) CONSTRAINT pkdimTransactionID Primary Key,
TransactionDate datetime not null,
TransactionTime time not null,
ReceiptNbr int not null,
File1ID int not null
)
go

--- Creating the date dimension table
CREATE TABLE dimDate (
   date_key int PRIMARY KEY,
   fulldate datetime,
   year_nbr int,
   month_nbr int,
   day_nbr int,
   qtr int,
   day_of_week int,
   day_of_year int,
   day_name char(15),
   month_name char(15)
)
go

--- Creating a stored procedure to populate date dimension table with data
CREATE PROCEDURE dimDateProcedure
as

BEGIN

	DECLARE @date date = '2021-01-01'
	DECLARE @date_key int = 1

	WHILE (@date <= '2023-12-31')
	BEGIN
	   INSERT INTO dimDate(date_key, fulldate, year_nbr, month_nbr, day_nbr, qtr, day_of_week, day_of_year, day_name, month_name)
	   VALUES (@date_key, @date, YEAR(@date), MONTH(@date), DAY(@date), DATEPART(quarter, @date), DATEPART(dw, @date), DATEPART(dy, @date), DATENAME(weekday, @date), DATENAME(month, @date))

	   SET @date = DATEADD(day, 1, @date)
	   SET @date_key = @date_key + 1
	END
END
go

--- Executing the stored  procedure to ensure the date dimension table is populated
EXEC dimDateProcedure
go

SELECT * FROM dimDate

--- Creating the fact table for the data warehouse of "Health Options, Inc."
CREATE TABLE factHealthOptionsInc (
factID int Identity(1,1) constraint pkfactID primary key,
ProductNetAmt decimal(18,6) not null,
ProductTaxAmt decimal(18,6) not null,
ProductGrossAmt decimal(18,6) not null,
Quantity int not null,
dimProductID int  not null constraint fkdimProductID Foreign Key references dimProduct(dimProductID),
dimStoreID int not null constraint fkdimStoreID Foreign Key references dimStore(dimStoreID),
dimTransactionID int  not null constraint fkdimTransactionID Foreign Key references dimTransaction(dimTransactionID),
date_key int  not null constraint fkdimdate_key Foreign Key references dimDate(date_key)
)
go

--- Displaying data in the dummy table using which dimension tables are populated through SSIS
--- SELECT * FROM dummyTable  ----> Displays the cleaned data and has 74,111 rows

--- SQL queries to be executed to see populated data in the dimension tables once package is executed in SSIS
SELECT * FROM dimProduct
SELECT * FROM dimTransaction
SELECT * FROM dimStore

--- SQL query to be executed to see populated data in the fact table once package is executed in SSIS
SELECT * from factHealthOptionsInc






