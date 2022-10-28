/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT *
FROM (
	SELECT DISTINCT 
		SUBSTRING(CustomerName, CHARINDEX('(', CustomerName)+1,CHARINDEX(')', CustomerName)-CHARINDEX('(', CustomerName)-1) AS NameShort,
		convert(varchar,DATEADD(dd,-(day(InvoiceDate)-1),InvoiceDate), 104) as InvoiceMonth,
		OrderID
	FROM Sales.Customers as SC
		JOIN Sales.Invoices AS SI 
			ON SC.CustomerID=SI.CustomerID
		JOIN Sales.InvoiceLines AS SIL
			ON SI.InvoiceID=SIL.InvoiceID
	WHERE CustomerName like 'Tailspin Toys%' AND SC.CustomerID BETWEEN 2 AND 6
	) AS Cust

PIVOT (COUNT(OrderID) FOR NameShort in ("Peeples Valley, AZ", "Medicine Lodge, KS", "Gasport, NY", "Sylvanite, MT", "Jessie, ND")) AS PVT
ORDER BY year(InvoiceMonth), month(InvoiceMonth)

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT CustomerName,
		AddressLine
	   
FROM (
	SELECT CustomerName,
		   DeliveryAddressLine1,
		   DeliveryAddressLine2,
		   PostalAddressLine1,
		   PostalAddressLine2
	FROM Sales.Customers
	WHERE CustomerName LIKE '%Tailspin Toys%'
) AS AddressLine

UNPIVOT (AddressLine FOR CustomerID IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) AS UPVT

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select CountryID,
	   CountryName,
	   Code
from (
	SELECT CountryID,
		   CountryName,
		   CAST(IsoAlpha3Code AS varchar) AS IsoAlpha3Code,
		   CAST(IsoNumericCode AS varchar) AS IsoNumericCode
	FROM Application.Countries
) AS Code

UNPIVOT (Code FOR C IN (IsoAlpha3Code,IsoNumericCode)) AS UPVT

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;WITH A AS (
SELECT 
	   SI.CustomerID,
	   CustomerName,
	   SIL.StockItemID,
	   UnitPrice,
	   InvoiceDate
		FROM Sales.Invoices AS SI
		JOIN Sales.Customers AS SC 
			ON SC.CustomerID=SI.CustomerID
		JOIN Sales.InvoiceLines AS SIL
			ON SI.InvoiceID=SIL.InvoiceID
)
SELECT B.CustomerID,
	   S.CustomerName,
	   B.StockItemID,
	   UnitPrice,
	   B.InvoiceDate
FROM Sales.Customers as S
CROSS APPLY (SELECT TOP 2 *
			 FROM A
			 WHERE A.CustomerID=S.CustomerID
			 ORDER BY UnitPrice DESC
) as B


