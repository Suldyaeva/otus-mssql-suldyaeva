/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
SET STATISTICS TIME  ON
SET STATISTICS io  ON

SELECT SI.InvoiceID, 
	   SC.CustomerName, 
	   SI.InvoiceDate, 
       (SELECT sum(SIL.UnitPrice*SIL.Quantity)
        FROM Sales.InvoiceLines AS SIL
             JOIN Sales.Invoices AS SI2 
				ON SI2.InvoiceID = SIL.InvoiceID
             WHERE format(SI2.InvoiceDate, 'yyyyMM') <= format(SI.InvoiceDate, 'yyyyMM') AND SI2.InvoiceDate >= '20150101'
             ) AS total
FROM Sales.Invoices AS SI
	JOIN Sales.Customers AS SC 
		ON SC.CustomerID = SI.CustomerID
WHERE SI.InvoiceDate >= '20150101'
ORDER BY SI.InvoiceDate

Выполнялось 3 мин 52 сек.

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
SET STATISTICS TIME  ON
SET STATISTICS io  ON

SELECT SI.InvoiceID,
	   SI.CustomerID,
	   InvoiceDate,
	   SUM(UnitPrice*Quantity) OVER (PARTITION BY  MONTH(InvoiceDate), YEAR(InvoiceDate)) AS ResultTotal

FROM Sales.Invoices AS SI
JOIN Sales.Customers AS SC ON SI.CustomerID=SC.CustomerID
JOIN Sales.InvoiceLines AS SIL ON SI.InvoiceID=SIL.InvoiceID
WHERE YEAR(InvoiceDate) >= 2015
ORDER BY InvoiceDate

 Время работы SQL Server:
   Время ЦП = 94 мс, затраченное время = 1249 мс.

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

SELECT * 
FROM (
SELECT 
		MONTH(InvoiceDate) AS [Month],
		[Description],
		SUM (Quantity) AS SumQuantity,
		ROW_NUMBER () OVER (PARTITION BY MONTH(InvoiceDate) ORDER BY(SUM (Quantity)) DESC) AS RowPopular

FROM Sales.Invoices AS SI
JOIN Sales.InvoiceLines AS SIL ON
	SI.InvoiceID=SIL.InvoiceID
WHERE YEAR(InvoiceDate)=2016
GROUP BY [Description], MONTH(InvoiceDate)) AS T
WHERE T.RowPopular <=2
ORDER BY [Month]


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT StockItemID,
	   StockItemName,
	   Brand,
	   UnitPrice,
	   RANK () OVER (PARTITION BY LEFT(StockItemName,1) ORDER BY StockItemName) AS RNK,
	   COUNT (StockItemID) OVER () AS QuantityTotal,
	   COUNT (StockItemID) OVER (PARTITION BY LEFT(StockItemName,1)) AS QuantityTotal,
	   LEAD (StockItemID) OVER (ORDER BY StockItemName) AS NextId,
	   LAG (StockItemID) OVER (PARTITION BY LEFT(StockItemName,1) ORDER BY StockItemName) AS PredId,
	   LAG (StockItemName,2,'No items') OVER (ORDER BY StockItemName) AS PredId,
	   NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) AS [30Gr]
	   
FROM Warehouse.StockItems
/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT *
FROM (
SELECT PersonID, 
	   FullName,
	   SI.CustomerID,
	   CustomerName,
	   InvoiceDate,
	   TransactionAmount,
	   ROW_NUMBER () OVER (PARTITION BY PersonID ORDER BY(InvoiceDate) DESC ) AS LastCustomer

FROM Sales.Invoices AS SI
	JOIN Sales.Customers AS SC
		ON SI.CustomerID=SC.CustomerID
	JOIN Application.People AS AP
		ON AP.PersonID=SI.SalespersonPersonID
	JOIN Sales.CustomerTransactions AS SCT
		ON SI.InvoiceID=SCT.InvoiceID) AS T

WHERE InvoiceDate = (SELECT MAX(InvoiceDate) FROM Sales.Invoices) AND LastCustomer=1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT *
FROM (
SELECT 
	   SI.CustomerID,
	   CustomerName,
	   [Description],
	   InvoiceDate,
	   WS.UnitPrice,
	   ROW_NUMBER () OVER (PARTITION BY SI.CustomerID ORDER BY(WS.UnitPrice) DESC ) AS LastSale

FROM Sales.Invoices AS SI
	JOIN Sales.Customers AS SC
		ON SI.CustomerID=SC.CustomerID
	JOIN Sales.InvoiceLines AS SIL
		ON SIL.InvoiceID=SI.InvoiceID
	JOIN Warehouse.StockItems AS WS
		ON SIL.StockItemID=WS.StockItemID
	JOIN Sales.CustomerTransactions AS SCT
		ON SI.InvoiceID=SCT.InvoiceID) AS T

WHERE LastSale<=2

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 