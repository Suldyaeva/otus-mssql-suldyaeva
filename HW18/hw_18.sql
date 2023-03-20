SET STATISTICS TIME ON;
SET STATISTICS IO ON;
--исходный код:
Select ord.CustomerID, 
	   det.StockItemID, 
	   SUM(det.UnitPrice), 
	   SUM(det.Quantity), 
	   COUNT(ord.OrderID)
FROM Sales.Orders AS ord
	JOIN Sales.OrderLines AS det
		ON det.OrderID = ord.OrderID
	JOIN Sales.Invoices AS Inv
		ON Inv.OrderID = ord.OrderID
	JOIN Sales.CustomerTransactions AS Trans
		ON Trans.InvoiceID = Inv.InvoiceID
	JOIN Warehouse.StockItemTransactions AS ItemTrans
		ON ItemTrans.StockItemID = det.StockItemID
		WHERE Inv.BillToCustomerID != ord.CustomerID
		AND (Select SupplierId
			 FROM Warehouse.StockItems AS It
			 Where It.StockItemID = det.StockItemID) = 12
			 AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
				  FROM Sales.OrderLines AS Total
					Join Sales.Orders AS ordTotal
						On ordTotal.OrderID = Total.OrderID
						WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
						AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;

--оптимизация^
--1) рассмотрела join на предмет необходимости использования тех или иных таблиц: удалила join с таблицами Sales.CustomerTransactions и Warehouse.StockItemTransactions, так как данных из них нам неинтересны;
--2) берем все данные из Sales.Invoices;
--3) делаем join с таблицей Warehouse.StockItems, чтобы избавиться от подзапроса;
--4) делаем CTE с выборкой из покупателей
WITH SelectionFromCustomer AS (
	SELECT o.CustomerID FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
	GROUP BY o.CustomerID
	HAVING SUM(ol.UnitPrice * ol.Quantity) > 250000
)
SELECT ord.CustomerID, 
	   det.StockItemID, 
	   SUM(det.UnitPrice) AS [TotalUnitPrice], 
	   SUM(det.Quantity) AS [TotalQuantity], 
	   COUNT(ord.OrderID) AS [TotalOrdersCount]
FROM Sales.Invoices AS SI
	INNER JOIN Sales.Orders AS ord
		ON SI.OrderID = ord.OrderID
	INNER JOIN Sales.OrderLines AS det
		ON det.OrderID = ord.OrderID
	INNER JOIN Warehouse.StockItems AS WS
		ON det.StockItemID = WS.StockItemID
	INNER JOIN SelectionFromCustomer SFC 
		ON ord.CustomerID = SFC.CustomerID
WHERE SI.BillToCustomerID <> ord.CustomerID
	 AND WS.SupplierID = 12
	 AND SI.InvoiceDate = ord.OrderDate	
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--Результаты

/* Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.

(3619 rows affected)
Таблица "StockItemTransactions". Число просмотров 1, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 66, lob физических чтений 1, lob упреждающих чтений 130.
Таблица "StockItemTransactions". Считано сегментов 1, пропущено 0.
Таблица "OrderLines". Число просмотров 4, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 518, lob физических чтений 5, lob упреждающих чтений 795.
Таблица "OrderLines". Считано сегментов 2, пропущено 0.
Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "CustomerTransactions". Число просмотров 5, логических чтений 261, физических чтений 1, упреждающих чтений 78, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "Orders". Число просмотров 2, логических чтений 883, физических чтений 1, упреждающих чтений 598, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "Invoices". Число просмотров 1, логических чтений 68377, физических чтений 1, упреждающих чтений 10856, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "StockItems". Число просмотров 1, логических чтений 2, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

(1 row affected)

 Время работы SQL Server:
   Время ЦП = 390 мс, затраченное время = 622 мс.

(3619 rows affected)
Таблица "OrderLines". Число просмотров 4, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 331, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "OrderLines". Считано сегментов 2, пропущено 0.
Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 52, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "Invoices". Число просмотров 11767, логических чтений 61156, физических чтений 0, упреждающих чтений 61, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "Orders". Число просмотров 2, логических чтений 883, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "StockItems". Число просмотров 1, логических чтений 2, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

(1 row affected)

 Время работы SQL Server:
   Время ЦП = 141 мс, затраченное время = 431 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.

Completion time: 2023-03-18T20:14:25.6132139+03:00
