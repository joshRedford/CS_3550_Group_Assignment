USE [GenericCompany]
GO

CREATE OR ALTER VIEW LostComputers
-- View of all stolen/lost computers
-- Also checks to make sure it gets the last known history of 
-- a computer (in the event a computer is lost/stolen more than once).
AS

	SELECT
		E.LastName,
		E.FirstName,
		C.PurchaseDate,
		CONVERT(DATE, Y.MostRecentHistoryDate) [LossDate],
		C.PurchaseCost [OriginalCost],
		(C.PurchaseCost / 36) * (DATEDIFF(MONTH, C.PurchaseDate, GETDATE())) [AmountDepreciated],
		C.PurchaseCost - (C.PurchaseCost / 36) * (DATEDIFF(MONTH, C.PurchaseDate, GETDATE())) [ComputerWorth],
		DATEDIFF(MONTH, GETDATE(), DATEADD(MONTH, 36, C.PurchaseDate)) [MonthsRemaining]
	FROM
		(
			--Get computer key and history from derived table, then join with history table to get employee
			SELECT
				X.ComputerKey,
				CSH.EmployeeKey,
				X.MostRecentHistoryDate
			FROM
			(
				--Get the computer key and the most recent history for that computer
				SELECT
					CSH.ComputerKey,
					MAX(CSH.HistoryDate) [MostRecentHistoryDate]
				FROM
					ComputerStatusHistory CSH
				WHERE 
					CSH.ChangedComputerStatusKey = 3 --key of 3 means lost or stolen
				GROUP BY
					CSH.ComputerKey
			) X
			INNER JOIN ComputerStatusHistory CSH
				ON X.MostRecentHistoryDate = CSH.HistoryDate
			GROUP BY
				X.ComputerKey,
				CSH.EmployeeKey,
				X.MostRecentHistoryDate
		) Y
		INNER JOIN Computers C
			ON Y.ComputerKey = C.ComputerKey
		INNER JOIN Employees E
			ON Y.EmployeeKey = E.EmployeeKey	
GO
