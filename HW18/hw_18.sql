SET STATISTICS TIME ON;
SET STATISTICS IO ON;
--�������� ���:
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

--�����������^
--1) ����������� join �� ������� ������������� ������������� ��� ��� ���� ������: ������� join � ��������� Sales.CustomerTransactions � Warehouse.StockItemTransactions, ��� ��� ������ �� ��� ��� �����������;
--2) ����� ��� ������ �� Sales.Invoices;
--3) ������ join � �������� Warehouse.StockItems, ����� ���������� �� ����������;
--4) ������ CTE � �������� �� �����������
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

--����������

/* ����� ������ SQL Server:
   ����� �� = 0 ��, ����������� ����� = 0 ��.

(3619 rows affected)
������� "StockItemTransactions". ����� ���������� 1, ���������� ������ 0, ���������� ������ 0, ����������� ������ 0, lob ���������� ������ 66, lob ���������� ������ 1, lob ����������� ������ 130.
������� "StockItemTransactions". ������� ��������� 1, ��������� 0.
������� "OrderLines". ����� ���������� 4, ���������� ������ 0, ���������� ������ 0, ����������� ������ 0, lob ���������� ������ 518, lob ���������� ������ 5, lob ����������� ������ 795.
������� "OrderLines". ������� ��������� 2, ��������� 0.
������� "Worktable". ����� ���������� 0, ���������� ������ 0, ���������� ������ 0, ����������� ������ 0, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.
������� "CustomerTransactions". ����� ���������� 5, ���������� ������ 261, ���������� ������ 1, ����������� ������ 78, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.
������� "Orders". ����� ���������� 2, ���������� ������ 883, ���������� ������ 1, ����������� ������ 598, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.
������� "Invoices". ����� ���������� 1, ���������� ������ 68377, ���������� ������ 1, ����������� ������ 10856, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.
������� "StockItems". ����� ���������� 1, ���������� ������ 2, ���������� ������ 0, ����������� ������ 0, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.

(1 row affected)

 ����� ������ SQL Server:
   ����� �� = 390 ��, ����������� ����� = 622 ��.

(3619 rows affected)
������� "OrderLines". ����� ���������� 4, ���������� ������ 0, ���������� ������ 0, ����������� ������ 0, lob ���������� ������ 331, lob ���������� ������ 0, lob ����������� ������ 0.
������� "OrderLines". ������� ��������� 2, ��������� 0.
������� "Worktable". ����� ���������� 0, ���������� ������ 0, ���������� ������ 0, ����������� ������ 52, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.
������� "Invoices". ����� ���������� 11767, ���������� ������ 61156, ���������� ������ 0, ����������� ������ 61, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.
������� "Orders". ����� ���������� 2, ���������� ������ 883, ���������� ������ 0, ����������� ������ 0, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.
������� "StockItems". ����� ���������� 1, ���������� ������ 2, ���������� ������ 0, ����������� ������ 0, lob ���������� ������ 0, lob ���������� ������ 0, lob ����������� ������ 0.

(1 row affected)

 ����� ������ SQL Server:
   ����� �� = 141 ��, ����������� ����� = 431 ��.
����� ��������������� ������� � ���������� SQL Server: 
 ����� �� = 0 ��, �������� ����� = 0 ��.

 ����� ������ SQL Server:
   ����� �� = 0 ��, ����������� ����� = 0 ��.

Completion time: 2023-03-18T20:14:25.6132139+03:00
