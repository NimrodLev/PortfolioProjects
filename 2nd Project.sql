USE AdventureWorks2019
GO

---1st Question

SELECT PP.Productid,name,Color,ListPrice,Size
FROM Production.Product PP LEFT JOIN Sales.SalesOrderDetail SOD
ON PP.ProductID = SOD.ProductID
WHERE SOD.ProductID IS NULL
ORDER BY PP.ProductID

GO
---2nd Question
SELECT SC.CustomerID, ISNULL(PP.LastName,'Unknown') AS [Last Name], ISNULL(PP.FirstName,'Unknown') AS [First Name]
FROM Sales.Customer SC LEFT JOIN Person.Person PP
ON SC.CustomerID = PP.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader SOH
ON SC.CustomerID = SOH.CustomerID
WHERE SOH.SalesOrderID IS NULL
ORDER BY CustomerID ASC

GO
---3rd Question
SELECT TOP (10) SC.CustomerID, PP.FirstName, PP.LastName, COUNT(SOH.CustomerID) AS CountOfOrders
FROM Sales.Customer SC JOIN Person.Person PP
ON SC.PersonID = PP.BusinessEntityID
JOIN Sales.SalesOrderHeader SOH
ON SC.CustomerID = SOH.CustomerID
GROUP BY SC.CustomerID, PP.FirstName, PP.LastName
ORDER BY CountOfOrders DESC

GO
---4th Question // i = The new count of title table
SELECT PP.FirstName,PP.LastName,EMP.JobTitle, EMP.HireDate,i.CountOfTitle
FROM HumanResources.Employee EMP
JOIN Person.Person PP
ON EMP.BusinessEntityID = PP.BusinessEntityID
JOIN (SELECT JobTitle, COUNT(BusinessEntityID) AS CountOfTitle
	  FROM HumanResources.Employee
	  GROUP BY JobTitle) i
ON EMP.JobTitle = i.JobTitle

GO
--4th Question --- Another way to solve with cte***EXTRA
WITH cte
AS
(
SELECT EMP.BusinessEntityID,PP.FirstName,PP.LastName,EMP.JobTitle, EMP.HireDate
FROM HumanResources.Employee EMP
JOIN Person.Person PP
ON EMP.BusinessEntityID = PP.BusinessEntityID)
SELECT FirstName, LastName, cte.Jobtitle, HireDate, CountOfTitle
FROM cte
JOIN (SELECT JobTitle, COUNT(BusinessEntityID) AS CountOfTitle
	  FROM HumanResources.Employee
	  GROUP BY JobTitle) emp ON emp.JobTitle = cte.JobTitle

GO
---5th Question
WITH cte AS
(
SELECT SOH.SalesOrderID, SOH.CustomerID, PP.LastName, PP.FirstName, SOH.OrderDate AS LastOrder,
LAG(SOH.OrderDate) OVER (PARTITION BY SOH.CustomerID ORDER BY SOH.OrderDate) AS PreviousOrder,
DENSE_RANK() OVER (PARTITION BY SOH.CustomerID ORDER BY SOH.OrderDate DESC) AS RNK
FROM Sales.SalesOrderHeader SOH
JOIN Sales.Customer SC
ON SOH.CustomerID = SC.CustomerID
JOIN Person.Person PP
ON PP.BusinessEntityID = SC.PersonID
)
SELECT DISTINCT SalesOrderID, CustomerID, LastName, FirstName, LastOrder,
ISNULL(PreviousOrder, LastOrder) AS PreviousOrder
FROM cte
WHERE RNK = 1;

GO
---6th Question

WITH cte
AS
(
SELECT YEAR(SOH.OrderDate) AS YY, SOD.SalesOrderID, SUM(UnitPrice*(1-UnitPriceDiscount)*OrderQty) AS Total,
ROW_NUMBER() OVER (PARTITION BY YEAR(SOH.OrderDate) ORDER BY SUM(UnitPrice * (1 - UnitPriceDiscount) * OrderQty) DESC) AS RN, SOH.CustomerID
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH
ON SOD.SalesOrderID = SOH.SalesOrderID
GROUP BY SOD.SalesOrderID,SOH.OrderDate,SOH.CustomerID
), tbl
AS
(
SELECT cte.*,PP.LastName, PP.FirstName
FROM cte
JOIN Sales.Customer C
ON cte.CustomerID = C.CustomerID
JOIN Person.Person PP
ON C.PersonID = PP.BusinessEntityID
)
SELECT YY, SalesOrderID, LastName, FirstName, Total
FROM tbl
WHERE RN = 1
ORDER BY YY ASC

GO
---7th Question

SELECT MM,[2011],[2012],[2013],[2014]
FROM (SELECT SalesOrderID , YEAR(OrderDate) AS YY, MONTH(OrderDate) AS MM
		FROM Sales.SalesOrderHeader) AS tbl
PIVOT (COUNT(SalesOrderID) FOR YY IN ([2011],[2012],[2013],[2014])) PVT
ORDER BY MM;

GO
---8th Question
WITH cte
AS
(
SELECT CAST(YEAR(SOH.OrderDate) AS VARCHAR) AS OrderYear, CAST(MONTH(SOH.OrderDate) AS VARCHAR) AS OrderMonth,
CAST(ROUND(SUM(UnitPrice*(1-UnitPriceDiscount)),2,1) AS VARCHAR) AS Sum_Price,
CAST(SUM(SUM(UnitPrice*(1-UnitPriceDiscount))) OVER(PARTITION BY YEAR(SOH.OrderDate) ORDER BY MONTH(SOH.OrderDate)) AS VARCHAR) AS CumSum
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD 
ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY YEAR(OrderDate),MONTH(OrderDate)
),tbl
AS
(
SELECT YEAR(SOH.OrderDate) AS OrderYear,MONTH(SOH.OrderDate) AS OrderMonth,SUM(SUM(UnitPrice*(1-UnitPriceDiscount))) OVER(PARTITION BY YEAR(SOH.OrderDate) ORDER BY MONTH(SOH.OrderDate)) AS CumSum
,ROUND(SUM(UnitPrice*(1-UnitPriceDiscount)),2,1) AS Sum_Price,ROW_NUMBER()OVER(ORDER BY YEAR(SOH.OrderDate)) AS RN
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD 
ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY YEAR(OrderDate),MONTH(OrderDate)
),grand_total
AS
(
SELECT CAST(OrderYear AS VARCHAR) AS OrderYear,'grand total' AS OrderMonth,NULL AS Sum_Price,CAST(MAX(CumSum) AS VARCHAR) AS CumSum
FROM tbl
WHERE OrderMonth = 12 OR OrderYear = '2014' AND OrderMonth = 6
GROUP BY OrderYear,OrderMonth,Sum_Price
)
SELECT OrderYear, OrderMonth, Sum_Price, CumSum
FROM (  SELECT OrderYear,OrderMonth,Sum_Price,CumSum
		FROM grand_total

		UNION ALL

		SELECT OrderYear, OrderMonth, Sum_Price, CumSum
        FROM cte
     ) AS FinalCalculatedTable
ORDER BY OrderYear, CASE WHEN OrderMonth = 'grand total' THEN 13 ELSE CAST(OrderMonth AS INT) END

GO
---9th Question
WITH cte
AS
(
SELECT dep.Name AS DepartmentName, emp.BusinessEntityID AS [Employee's ID], CONCAT_WS(' ',PP.FirstName,PP.LastName) AS [Employee'sFullName], emp.HireDate
,DATEDIFF(MONTH,emp.HireDate,GETDATE()) AS Seniority,
LAG(CONCAT_WS(' ', PP.FirstName, PP.LastName)) OVER (PARTITION BY emp_hist.DepartmentID ORDER BY emp_hist.StartDate) AS PreviousEmployeeFullName
,LAG(emp.HireDate) OVER (PARTITION BY emp_hist.DepartmentID ORDER BY emp_hist.StartDate) AS PreviousEMPHDate
FROM HumanResources.Employee emp
JOIN HumanResources.EmployeeDepartmentHistory emp_hist
ON emp.BusinessEntityID = emp_hist.BusinessEntityID
JOIN HumanResources.Department dep
ON emp_hist.DepartmentID = dep.DepartmentID
JOIN Person.Person PP
ON PP.BusinessEntityID = EMP.BusinessEntityID
)
SELECT *,DATEDIFF(DAY,PreviousEMPHDate,HireDate)
FROM cte
ORDER BY DepartmentName, HireDate DESC

GO
---10th Question --- WITH FOR XML PATH
WITH cte
AS 
(
SELECT emp.BusinessEntityID, PP.LastName, PP.FirstName, emp_hist.DepartmentID, emp.HireDate,
ROW_NUMBER() OVER (PARTITION BY emp.BusinessEntityID ORDER BY emp.HireDate) AS RN
FROM HumanResources.Employee emp
JOIN Person.Person PP 
ON emp.BusinessEntityID = PP.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory emp_hist 
ON emp_hist.BusinessEntityID = emp.BusinessEntityID
),
tbl AS
(
SELECT DISTINCT emp2.HireDate, emp_hist2.DepartmentID,
STUFF((SELECT ','+CONCAT_WS(' ', cte.BusinessEntityID, cte.LastName, cte.FirstName)
FROM cte
WHERE cte.HireDate = emp2.HireDate AND cte.DepartmentID = emp_hist2.DepartmentID and cte.RN = 1 
FOR XML PATH('')),1,1,'') AS TeamEmployees
FROM cte emp2 JOIN HumanResources.EmployeeDepartmentHistory emp_hist2
ON emp2.BusinessEntityID = emp_hist2.BusinessEntityID
)
SELECT *
FROM tbl
WHERE TeamEmployees IS NOT NULL
ORDER BY HireDate DESC

GO
---10th Question --- WITH STRING_AGG() FUNCTION***EXTRA

WITH cte
AS 
(
SELECT emp.BusinessEntityID, PP.LastName, PP.FirstName, emp_hist.DepartmentID, emp.HireDate,
ROW_NUMBER() OVER (PARTITION BY emp.BusinessEntityID ORDER BY emp.HireDate) AS RN
FROM HumanResources.Employee emp
JOIN Person.Person PP 
ON emp.BusinessEntityID = PP.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory emp_hist 
ON emp_hist.BusinessEntityID = emp.BusinessEntityID
),
tbl AS
(
SELECT cte.HireDate, cte.DepartmentID,
STRING_AGG(CONCAT_WS(' ', cte.BusinessEntityID, cte.LastName, cte.FirstName),',') AS TeamEmployees
FROM cte
WHERE cte.RN = 1
GROUP BY cte.HireDate,cte.DepartmentID
)
SELECT DISTINCT *
FROM tbl
ORDER BY HireDate DESC

GO
/* DUPLICATES REMOVED WITH RN ARE: 250 Word Sheela (3) DEPARTMENTS.
16 Bradley David (2) DEPARTMENTS. 
4 Walters Rob (2) DEPARTMENTS.
234 Norman Laura (2) DEPARTMENTS.
224 Vong Wiliam (2) DEPARTMENTS.--- TOTAL OF 6 TO BE REMOVED. ALL ARE EMPLOYEES THAT GOT ACCEPTED TO SEVERAL DEPARTMENTS ON THE SAME HIREDATE.*/
















