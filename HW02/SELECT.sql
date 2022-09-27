/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".
������� ����������� � �������������� ���� ������ WideWorldImporters.
����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak
�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

SELECT A.SupplierID, A.SupplierName
FROM Purchasing.Suppliers A
LEFT JOIN Purchasing.PurchaseOrders B ON
	 a.SupplierID=b.SupplierID
WHERE  B.SupplierID IS NULL

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.
���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).
�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT A.OrderID, CONVERT(nvarchar(10), B.OrderDate, 104) as OrderDate,  DATENAME(MM, B.OrderDate) AS OrderMounth, DATEPART(QUARTER, B.OrderDate) AS OrderQuarter, C.CustomerName,
CASE WHEN MONTH(B.OrderDate)IN (1,2,3,4) THEN 1 WHEN MONTH(B.OrderDate) IN (5,6,7,8) THEN 2 ELSE 3 END AS THIRD
FROM Sales.OrderLines A
JOIN Sales.Orders B ON A.OrderID=B.OrderID
JOIN Sales.Customers C ON B.CustomerID=C.CustomerID
WHERE (A.UnitPrice >100 OR A.Quantity > 20) AND A.PickingCompletedWhen IS NOT NULL
ORDER BY OrderQuarter,THIRD, OrderDate

SELECT A.OrderID, CONVERT(nvarchar(10), B.OrderDate, 104) as OrderDate,  DATENAME(MM, B.OrderDate) AS OrderMounth, DATEPART(QUARTER, B.OrderDate) AS OrderQuarter, C.CustomerName,
CASE WHEN MONTH(B.OrderDate)IN (1,2,3,4) THEN 1 WHEN MONTH(B.OrderDate) IN (5,6,7,8) THEN 2 ELSE 3 END AS THIRD
FROM Sales.OrderLines A
JOIN Sales.Orders B ON A.OrderID=B.OrderID
JOIN Sales.Customers C ON B.CustomerID=C.CustomerID
WHERE (A.UnitPrice >100 OR A.Quantity > 20) AND A.PickingCompletedWhen IS NOT NULL
ORDER BY OrderQuarter,THIRD, OrderDate OFFSET 1000 rows fetch first 100 rows only

/*
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT C.DeliveryMethodName, B.ExpectedDeliveryDate, A.SupplierName, D.FullName
FROM Purchasing.Suppliers A
JOIN Purchasing.PurchaseOrders B ON A.SupplierID=B.SupplierID
JOIN Application.DeliveryMethods C ON A.DeliveryMethodID=C.DeliveryMethodID
JOIN Application.People D ON B.ContactPersonID=D.PersonID
WHERE MONTH(B.ExpectedDeliveryDate)=1 AND YEAR(B.ExpectedDeliveryDate)=2013 AND (C.DeliveryMethodName LIKE '%Air Freight%' OR C.DeliveryMethodName LIKE '%Refrigerated Air Freight%') AND B.IsOrderFinalized=1

/*
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/

SELECT TOP 10 B.CustomerName, C.FullName
FROM Sales.Orders A
JOIN Sales.Customers B ON A.CustomerID=B.CustomerID
JOIN Application.People C ON A.SalespersonPersonID = C.PersonID
WHERE C.IsSalesperson=1
ORDER BY A.OrderDate DESC

/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

SELECT DISTINCT A.CustomerID, CustomerName, PhoneNumber
FROM Sales.Customers A
	JOIN Sales.Orders B ON A.CustomerID=B.CustomerID
	JOIN Sales.OrderLines C ON B.OrderID=C.OrderID
	JOIN Warehouse.StockItems D ON C.StockItemID=D.StockItemID
WHERE D.StockItemName LIKE '%Chocolate frogs 250g%'