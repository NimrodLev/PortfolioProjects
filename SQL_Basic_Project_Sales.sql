GO

USE master

GO 

CREATE DATABASE Sales

GO

USE Sales

GO

CREATE SCHEMA Person

GO

CREATE TABLE Person.[Address]
(
	AddressID INT PRIMARY KEY NOT NULL,
	AddressLine1 NVARCHAR(60) NOT NULL,
	AddressLine2 NVARCHAR(60),
	City NVARCHAR(30) NOT NULL,
	StateProvinceID INT NOT NULL,
	PostalCode NVARCHAR(15) NOT NULL,
	SpatialLocation GEOGRAPHY,
	rowguid UNIQUEIDENTIFIER,
	ModifiedDate DATETIME,

)

GO

CREATE SCHEMA Sales

GO 

CREATE TABLE Sales.SalesOrderHeader --A
(SalesOrderID INT NOT NULL
,CONSTRAINT SalesOrderID_PK PRIMARY KEY(SalesOrderID)
,RevisionNumber TINYINT NOT NULL
,OrderDate DATETIME NOT NULL
,DueDate DATETIME NOT NULL
,CONSTRAINT CK_SalesOrderHeader_DueDate CHECK(DueDate >= OrderDate)
,ShipDate DATETIME
,CONSTRAINT CK_SalesOrderHeader_ShipDate CHECK(ShipDate >= OrderDate)
,Status TINYINT NOT NULL
,CONSTRAINT CK_SalesOrderHeader_Status CHECK(Status BETWEEN 0 AND 8)
,OnlineOrderFlag BIT NOT NULL
,SalesOrderNumber NVARCHAR(255) NOT NULL
,PurchaseOrderNumber NVARCHAR(255)
,AccountNumber NVARCHAR(255)
,CustomerID INT NOT NULL
,SalesPersonID INT
,TerritoryID INT
,BillToAddressID INT NOT NULL
,ShipToAddressID INT NOT NULL
,ShipMethodID INT NOT NULL
,CreditCardID INT
,CreditCardApprovalCode VARCHAR(15)
,CurrencyRateID INT
,SubTotal MONEY NOT NULL
,CONSTRAINT CK_SalesOrderHeader_SubTotal CHECK(SubTotal>=0)
,TaxAmt MONEY NOT NULL
,CONSTRAINT CK_SalesOrderHeader_TaxAmt CHECK(TaxAmt>=0)
,Freight MONEY NOT NULL
,CONSTRAINT CK_SalesOrderHeader_Freight CHECK(Freight>=0)
,TotalDue MONEY NOT NULL
,Comment NVARCHAR(128)
,rowguid UNIQUEIDENTIFIER NOT NULL
,ModifiedDate DATETIME NOT NULL)

GO

---------------
CREATE TABLE Sales.SpecialOfferProduct --B
(
    SpecialOfferID INT NOT NULL,
    ProductID INT NOT NULL,
    CONSTRAINT PK_SpecialOfferID_ProductID PRIMARY KEY (SpecialOfferID, ProductID),
    rowguid UNIQUEIDENTIFIER NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    CONSTRAINT UQ_SpecialOfferProduct_SpecialOfferID_ProductID UNIQUE (SpecialOfferID, ProductID)
)
--------------

CREATE TABLE Sales.SalesOrderDetail --C
(
SalesOrderID INT NOT NULL
,CONSTRAINT PK_SalesOrderID_SalesOrderDetailID PRIMARY KEY (SalesOrderID, SalesOrderDetailID)
,CONSTRAINT SalesOrderID_FK FOREIGN KEY(SalesOrderID) REFERENCES Sales.SalesOrderHeader(SalesOrderID)
,SalesOrderDetailID INT NOT NULL
,CarrierTrackingNumber NVARCHAR(25)
,OrderQty SMALLINT NOT NULL
,CONSTRAINT CK_SalesOrderDetail_OrderQty CHECK(OrderQty>=0)
,ProductID INT NOT NULL
,SpecialOfferID INT NOT NULL
,UnitPrice MONEY NOT NULL
,CONSTRAINT CK_SalesOrderDetail_UnitPrice CHECK(UnitPrice>=0)
,UnitPriceDiscount MONEY NOT NULL
,CONSTRAINT CK_SalesOrderDetail_UnitPriceDiscount CHECK(UnitPriceDiscount>=0)
,LineTotal NUMERIC NOT NULL
,rowguid UNIQUEIDENTIFIER NOT NULL
,ModifiedDate DATETIME NOT NULL
,CONSTRAINT FK_SpecialOfferID FOREIGN KEY (SpecialOfferID, ProductID) REFERENCES Sales.SpecialOfferProduct(SpecialOfferID, ProductID)
)


--------------

CREATE TABLE Sales.CurrencyRate --D
(
	CurrencyRateID INT NOT NULL,
	CONSTRAINT PK_CurrencyRateID PRIMARY KEY(CurrencyRateID),
	CurrencyRateDate DATETIME NOT NULL,
	FromCurrencyCode nchar(3) NOT NULL,
	ToCurrencyCode nchar(3) NOT NULL,
	AverageRate MONEY NOT NULL,
	EndOfDayRate MONEY NOT NULL,
	ModifiedDate DATETIME NOT NULL
)

ALTER TABLE Sales.SalesOrderHeader
ADD CONSTRAINT FK_CurrencyRateID FOREIGN KEY(CurrencyRateID) REFERENCES Sales.CurrencyRate(CurrencyRateID)
GO
-----------
CREATE TABLE Sales.CreditCard --E
(
	CreditCardID INT NOT NULL,
	CONSTRAINT PK_CreditCardID PRIMARY KEY(CreditCardID),
	CardType NVARCHAR (50) NOT NULL,
	CardNumber NVARCHAR (25) NOT NULL,
	ExpMonth TINYINT NOT NULL,
	ExpYear SMALLINT NOT NULL,
	ModifiedDate DATETIME NOT NULL,
)
ALTER TABLE Sales.SalesOrderHeader
ADD CONSTRAINT FK_CreditCardID FOREIGN KEY(CreditCardID) REFERENCES Sales.CreditCard(CreditCardID)
GO
-----------

CREATE SCHEMA Purchasing --F
GO

CREATE TABLE Purchasing.ShipMethod
(
	ShipMethodID INT PRIMARY KEY NOT NULL,
	Name NVARCHAR(50) NOT NULL,
	ShipBase MONEY NOT NULL,
	CONSTRAINT CK_ShipMethod_ShipBase CHECK(ShipBase>0.00),
	ShipRate MONEY NOT NULL,
	CONSTRAINT CK_ShipMethod_ShipRate CHECK(ShipRate>0.00),
	rowguid UNIQUEIDENTIFIER NOT NULL,
	ModifiedDate DATETIME NOT NULL
)
-----------
ALTER TABLE Sales.SalesOrderHeader
ADD CONSTRAINT FK_ShipMethodID FOREIGN KEY(ShipMethodID) REFERENCES Purchasing.ShipMethod(ShipMethodID)
GO
----------

CREATE TABLE Sales.SalesPerson --G
(
	BusinessEntityID INT PRIMARY KEY NOT NULL,
	TerritoryID INT,
	SalesQuota MONEY,
	CONSTRAINT CK_SalesPerson_SalesQuota CHECK(SalesQuota>0),
	Bonus MONEY NOT NULL,
	CONSTRAINT CK_SalesPerson_Bonus CHECK(Bonus>=0.00),
	CommissionPct SMALLMONEY NOT NULL,
	CONSTRAINT CK_SalesPerson_CommissionPct CHECK(CommissionPct>=0.00),
	SalesYTD MONEY NOT NULL,
	CONSTRAINT CK_SalesPerson_SalesYTD CHECK(SalesYTD>=0.00),
	SalesLastYear MONEY NOT NULL,
	CONSTRAINT CK_SalesPerson_SalesLastYear CHECK(SalesLastYear>=0.00),
	rowguid UNIQUEIDENTIFIER NOT NULL,
	ModifiedDate DATETIME NOT NULL
)
GO

ALTER TABLE Sales.SalesOrderHeader
ADD CONSTRAINT FK_SalesOrderHeader_SalesPerson_SalesPersonID FOREIGN KEY(SalesPersonID) REFERENCES Sales.SalesPerson(BusinessEntityID)

GO

CREATE TABLE Sales.SalesTerritory --H
(
	TerritoryID INT PRIMARY KEY NOT NULL,
	Name NVARCHAR(50) NOT NULL,
	CountryRegionCode NVARCHAR(3) NOT NULL,
	[Group] NVARCHAR(50) NOT NULL,
	SalesYTD MONEY NOT NULL,
	CONSTRAINT CK_SalesTerritory_SalesYTD CHECK(SalesYTD>=0.00),
	SalesLastYear MONEY NOT NULL,
	CONSTRAINT CK_SalesTerritory_SalesLastYear CHECK(SalesLastYear>=0.00),
	CostYTD MONEY NOT NULL,
	CONSTRAINT CK_SalesTerritory_CostYTD CHECK(CostYTD>=0.00),
	CostLastYear MONEY NOT NULL, 
	CONSTRAINT CK_SalesTerritory_CostLastYear CHECK(CostLastYear>=0.00),
	rowguid UNIQUEIDENTIFIER NOT NULL,
	ModifiedDate DATETIME NOT NULL
)

GO

ALTER TABLE Sales.SalesOrderHeader
ADD CONSTRAINT FK_SalesOrderHeader_SalesTerritory_TerritoryID FOREIGN KEY(TerritoryID) REFERENCES Sales.SalesTerritory(TerritoryID)

GO

ALTER TABLE Sales.SalesPerson
ADD CONSTRAINT FK_SalesPerson_SalesTerritory_TerritoryID FOREIGN KEY(TerritoryID) REFERENCES Sales.SalesTerritory(TerritoryID)

GO

CREATE TABLE Sales.Customer	 --I
(
	CustomerID INT PRIMARY KEY NOT NULL,
	PersonID INT,
	StoreID INT,
	TerritoryID INT,
	CONSTRAINT FK_Customer_SalesTerritory_TerritoryID FOREIGN KEY(TerritoryID) REFERENCES Sales.SalesTerritory(TerritoryID),
	AccountNumber VARCHAR(10) NOT NULL,
	rowguid UNIQUEIDENTIFIER NOT NULL,
	ModifiedDate DATETIME NOT NULL
)

ALTER TABLE Sales.SalesOrderHeader
ADD CONSTRAINT FK_SalesOrderHeader_Customer_CustomerID FOREIGN KEY(CustomerID) REFERENCES Sales.Customer(CustomerID)

GO


-----------------------------

INSERT INTO Sales.Person.[Address]
SELECT *
FROM AdventureWorks2019.Person.[Address]

INSERT INTO Sales.Sales.CurrencyRate
SELECT *
FROM AdventureWorks2019.Sales.CurrencyRate

INSERT INTO Sales.Sales.CreditCard
SELECT *
FROM AdventureWorks2019.Sales.CreditCard

INSERT INTO Sales.Purchasing.ShipMethod
SELECT *
FROM AdventureWorks2019.Purchasing.ShipMethod

INSERT INTO Sales.Sales.SalesTerritory
SELECT *
FROM AdventureWorks2019.Sales.SalesTerritory

INSERT INTO Sales.Sales.Customer
SELECT *
FROM AdventureWorks2019.Sales.Customer

INSERT INTO Sales.Sales.SalesPerson
SELECT *
FROM AdventureWorks2019.Sales.SalesPerson

INSERT INTO Sales.Sales.SalesOrderHeader
SELECT *
FROM AdventureWorks2019.Sales.SalesOrderHeader

INSERT INTO Sales.Sales.SpecialOfferProduct
SELECT *
FROM AdventureWorks2019.Sales.SpecialOfferProduct

INSERT INTO Sales.Sales.SalesOrderDetail
SELECT *
FROM AdventureWorks2019.Sales.SalesOrderDetail





---FOR DEBUGGING
/*
DROP TABLE Sales.Person.[Address]
DROP TABLE Sales.Purchasing.ShipMethod
DROP TABLE Sales.Sales.CreditCard
DROP TABLE Sales.Sales.CurrencyRate
DROP TABLE Sales.Sales.Customer
DROP TABLE Sales.Sales.SalesOrderDetail
DROP TABLE Sales.Sales.SalesOrderHeader
DROP TABLE Sales.Sales.SalesPerson
DROP TABLE Sales.Sales.SalesTerritory
DROP TABLE Sales.Sales.SpecialOfferProduct
*/








