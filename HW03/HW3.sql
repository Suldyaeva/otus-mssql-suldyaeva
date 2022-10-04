/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
		YEAR(I.INVOICEDATE) AS [YEAR OF SALE],
		MONTH(I.INVOICEDATE) AS [MONTH OF SALE],
		AVG(L.UnitPrice) AS [AVG PRICE],
		SUM(L.UnitPrice*L.Quantity) AS [SUM OF SALE]
FROM Sales.Invoices I
JOIN Sales.InvoiceLines L ON I.INVOICEID=L.INVOICEID
GROUP BY YEAR(I.INVOICEDATE),MONTH(I.INVOICEDATE)
ORDER BY YEAR(I.INVOICEDATE),MONTH(I.INVOICEDATE)

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
		YEAR(I.INVOICEDATE) AS [YEAR OF SALE],
		MONTH(I.INVOICEDATE) AS [MONTH OF SALE],
		SUM(L.UnitPrice*L.Quantity) AS [SUM OF SALE]
FROM Sales.Invoices I
JOIN Sales.InvoiceLines L ON I.INVOICEID=L.INVOICEID
GROUP BY YEAR(I.INVOICEDATE),MONTH(I.INVOICEDATE)
HAVING SUM(L.UnitPrice*L.Quantity)>4600000
ORDER BY YEAR(I.INVOICEDATE),MONTH(I.INVOICEDATE)

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
		YEAR(I.INVOICEDATE) AS [YEAR OF SALE],
		MONTH(I.INVOICEDATE) AS [MONTH OF SALE],
		L.[Description] AS [NAME],
		SUM(L.UnitPrice*L.Quantity) AS [SUM OF SALE],
		MIN(I.INVOICEDATE) AS [FIRST DATE OF SALE],
		SUM(L.Quantity) AS [QUANTITY OF SALE]
FROM Sales.Invoices I
JOIN Sales.InvoiceLines L ON I.INVOICEID=L.INVOICEID
GROUP BY YEAR(I.INVOICEDATE),MONTH(I.INVOICEDATE), L.[Description]
HAVING SUM(L.Quantity)<50
ORDER BY YEAR(I.INVOICEDATE), MONTH(I.INVOICEDATE)

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
SELECT 
	y.[YEAR OF SALE], 
	m.[MONTH OF SALE], 
	CASE 
		WHEN d.[SUM OF SALE] IS NULL THEN '0.0'
		ELSE d.[SUM OF SALE]
		END AS [SUM OF SALE] FROM
(
       SELECT DISTINCT YEAR(InvoiceDate) AS [YEAR OF SALE] FROM Sales.Invoices
) y CROSS JOIN (
       SELECT 1 AS [MONTH OF SALE]
       UNION
       SELECT 2
       UNION
       SELECT 3
       UNION
       SELECT 4
       UNION
       SELECT 5
       UNION
       SELECT 6
       UNION
       SELECT 7
       UNION
       SELECT 8
       UNION
       SELECT 9
       UNION
       SELECT 10
       UNION
       SELECT 11
       UNION
       SELECT 12
) m LEFT JOIN (
SELECT 
		YEAR(I.INVOICEDATE) AS [YEAR OF SALE],
		MONTH(I.INVOICEDATE) AS [MONTH OF SALE],
		SUM(L.UnitPrice*L.Quantity) AS [SUM OF SALE]
FROM Sales.Invoices I
JOIN Sales.InvoiceLines L ON I.INVOICEID=L.INVOICEID
GROUP BY YEAR(I.INVOICEDATE), MONTH(I.INVOICEDATE)
HAVING SUM(L.UnitPrice*L.Quantity)>4600000
) d ON (d.[YEAR OF SALE] = y.[YEAR OF SALE] AND d.[MONTH OF SALE] = m.[MONTH OF SALE])
ORDER BY y.[YEAR OF SALE], m.[MONTH OF SALE]

