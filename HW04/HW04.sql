/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT 
	[PersonID], 
	[FullName]
FROM Application.People
WHERE IsSalesperson=1 AND (SELECT  COUNT (*) FROM Sales.Invoices WHERE Invoices.SalespersonPersonID=People.PersonID AND InvoiceDate = '2015-07-04') < 1

;WITH InvoicesCTE AS
(	SELECT DISTINCT SalespersonPersonID
	FROM Sales.Invoices
	WHERE InvoiceDate = '2015-07-04'
)
SELECT [PersonID], 
	   [FullName]
FROM Application.People AS P
	LEFT JOIN InvoicesCTE AS I
		ON P.PersonID=I.SalespersonPersonID
WHERE IsSalesperson=1 AND I.SalespersonPersonID IS NULL

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT [StockItemID],
	   [StockItemName], 
	   [UnitPrice]
FROM Warehouse.StockItems
WHERE UnitPrice IN (SELECT MIN(UnitPrice) FROM Warehouse.StockItems)

SELECT * FROM 
(
	SELECT [StockItemID],
		   [StockItemName], 
		   [UnitPrice]
	FROM Warehouse.StockItems
) T 
WHERE UnitPrice IN (SELECT MIN(UnitPrice) FROM Warehouse.StockItems)

;WITH PriceCTE AS
(	SELECT MIN(UnitPrice) AS MinPrice
	FROM Warehouse.StockItems 
)
SELECT [StockItemID],
	   [StockItemName], 
	   WS.[UnitPrice]
FROM Warehouse.StockItems AS WS
	JOIN PriceCTE AS P  
		ON WS.UnitPrice=P.MinPrice

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT C.CustomerID, CustomerName, CT.TransactionAmount 
FROM Sales.Customers AS C
	JOIN 
		(SELECT TOP 5 TransactionAmount, CustomerID
		FROM Sales.CustomerTransactions
		WHERE IsFinalized=1
		ORDER BY TransactionAmount DESC) AS CT
			ON C.CustomerID=CT.CustomerID

;WITH CT_CTE AS
(SELECT TOP 5 TransactionAmount, CustomerID
FROM Sales.CustomerTransactions
WHERE IsFinalized=1
ORDER BY TransactionAmount DESC)

SELECT C.CustomerID, CustomerName, CT.TransactionAmount 
FROM Sales.Customers  AS C
	JOIN CT_CTE CT 
		ON C.CustomerID=CT.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

;WITH PriceCTE AS 
(
	SELECT TOP 3 UnitPrice AS UnitPrice, 
		   StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC
),
	  InvoicesCTE AS
(
	SELECT FULLNAME,  
		   PackedByPersonID, 
		   CustomerID,
		   InvoiceID
	FROM Sales.Invoices
		JOIN Application.People 
			ON PersonID=PackedByPersonID
	GROUP BY PackedByPersonID, FullName, CustomerID, InvoiceID
)

SELECT DISTINCT CityID, 
				CityName, 
				IC.FullName
FROM Application.Cities AS C
	JOIN Sales.Customers AS SC 
		ON CityID=PostalCityID
	JOIN InvoicesCTE AS IC
		ON SC.CustomerID=IC.CustomerID
	JOIN Sales.InvoiceLines AS SI
		ON SI.InvoiceID=IC.InvoiceID
	JOIN PriceCTE AS P
		ON P.StockItemID=SI.StockItemID


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос


SELECT ---
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

/*Запрос находит id, дату, ФИО продажника, сумму выставленного счета, оплаченный счет.
Улучшила читабельность, ускорила выполнение запроса с помощью JOIN.
Во вложении скрины производительности 1-го запроса и 2-го.*/


;WITH TotalSummForPickedItemsCTE AS
(	SELECT SOL.OrderID, 
		   SUM(PickedQuantity*UnitPrice) AS TotalSummForPickedItems
	FROM Sales.OrderLines AS SOL
	JOIN Sales.Orders AS SO
		ON SO.OrderID=SOL.OrderID
	WHERE SOL.PickingCompletedWhen IS NOT NULL
	GROUP BY SOL.OrderID
)

SELECT SI.InvoiceID, SI.InvoiceDate, P.FullName, SUM(SIL.Quantity*SIL.UnitPrice) AS TotalSummByInvoice, TotalSummForPickedItems
FROM Sales.Invoices AS SI
JOIN Application.People AS P 
	ON P.PersonID=SI.SalespersonPersonID
JOIN TotalSummForPickedItemsCTE AS T
	ON T.OrderID=SI.OrderID
JOIN Sales.InvoiceLines AS SIL
	ON SIL.InvoiceID=SI.InvoiceID
WHERE IsSalesperson=1
GROUP BY SI.InvoiceID,SI.InvoiceDate, P.FullName, TotalSummForPickedItems
HAVING SUM(SIL.Quantity*SIL.UnitPrice) > 27000
ORDER BY TotalSummByInvoice DESC