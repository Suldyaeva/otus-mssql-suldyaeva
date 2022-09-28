/*  
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT A.SupplierID, A.SupplierName
FROM Purchasing.Suppliers A
LEFT JOIN Purchasing.PurchaseOrders B ON
	 a.SupplierID=b.SupplierID
WHERE  B.SupplierID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.
Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).
Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
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
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT C.DeliveryMethodName, B.ExpectedDeliveryDate, A.SupplierName, D.FullName
FROM Purchasing.Suppliers A
JOIN Purchasing.PurchaseOrders B ON A.SupplierID=B.SupplierID
JOIN Application.DeliveryMethods C ON A.DeliveryMethodID=C.DeliveryMethodID
JOIN Application.People D ON B.ContactPersonID=D.PersonID
WHERE MONTH(B.ExpectedDeliveryDate)=1 AND YEAR(B.ExpectedDeliveryDate)=2013 AND (C.DeliveryMethodName LIKE '%Air Freight%' OR C.DeliveryMethodName LIKE '%Refrigerated Air Freight%') AND B.IsOrderFinalized=1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 B.CustomerName, C.FullName
FROM Sales.Orders A
JOIN Sales.Customers B ON A.CustomerID=B.CustomerID
JOIN Application.People C ON A.SalespersonPersonID = C.PersonID
WHERE C.IsSalesperson=1
ORDER BY A.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT A.CustomerID, CustomerName, PhoneNumber
FROM Sales.Customers A
	JOIN Sales.Orders B ON A.CustomerID=B.CustomerID
	JOIN Sales.OrderLines C ON B.OrderID=C.OrderID
	JOIN Warehouse.StockItems D ON C.StockItemID=D.StockItemID
WHERE D.StockItemName LIKE '%Chocolate frogs 250g%'