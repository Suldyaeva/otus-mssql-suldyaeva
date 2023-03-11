/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE FUNCTION CustomersMaxPay (@CustomerID int)
RETURNS TABLE
AS 
RETURN 
( 
	SELECT CustomerName, UnitPrice*Quantity AS 'Стоимость покупки'
	FROM Sales.InvoiceLines AS SIL
	JOIN Sales.Invoices AS SI ON SIL.InvoiceID=SI.InvoiceID
	JOIN Sales.Customers AS SC ON SI.CustomerID=SC.CustomerID
	WHERE UnitPrice*Quantity = (SELECT TOP 1 MAX(UnitPrice*Quantity) FROM Sales.InvoiceLines) and SC.CustomerID = @customerid  
)

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/
CREATE PROCEDURE SumPay 
@CustomerID int,
@ComparePrice money OUTPUT
AS  
    SET NOCOUNT ON; 

	SELECT CustomerName, UnitPrice*Quantity AS 'Стоимость покупки'
	FROM Sales.InvoiceLines AS SIL
	JOIN Sales.Invoices AS SI ON SIL.InvoiceID=SI.InvoiceID
	JOIN Sales.Customers AS SC ON SI.CustomerID=SC.CustomerID
	WHERE  SC.CustomerID = @customerid and @ComparePrice = (select SUM(UnitPrice*Quantity) from Sales.InvoiceLines)

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
Выберите товары с минимальной ценой
*/
CREATE FUNCTION MinUnitPrice (@StockItemID int, @UnitPrice int)
RETURNS TABLE
AS 
RETURN 
( 
	SELECT [StockItemID],
	   [StockItemName], 
	   [UnitPrice]
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems where @StockItemID=StockItemID) and @StockItemID=StockItemID
)

CREATE PROCEDURE MinUnitPrice1 
@StockItemID int,
@UnitPrice int
AS  
    SET NOCOUNT ON; 

	SELECT [StockItemID],
		   [StockItemName], 
	       [UnitPrice]
FROM Warehouse.StockItems
WHERE @UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems where @StockItemID=StockItemID) and @StockItemID=StockItemID

SET STATISTICS IO, TIME ON

SELECT * FROM MinUnitPrice (10, 32)

exec MinUnitPrice1
	@StockItemID = 10,
	@UnitPrice = 32

	Производительность получилась 50/50
/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

CREATE PROCEDURE UnitPriceAll
AS
BEGIN 
    SELECT
		   [StockItemID],
		   [StockItemName], 
	       [UnitPrice]
	From Warehouse.StockItems
END

EXEC UnitPriceAll 

WITH RESULT SETS(
  (  [SupplierID] int
	,[StockItemName] nvarchar (100)
    ,[UnitPackageID] int
  )
)
/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
