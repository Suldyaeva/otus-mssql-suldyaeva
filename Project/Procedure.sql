--Расписание работы тренеров в залах
CREATE PROCEDURE Work_Trainers 
@NameTrainer Nvarchar (50),
@Date DATETIME

AS
    SET NOCOUNT ON
	SELECT 
	   FORMAT(DATE, 'dd/MM/yyyy') AS DATE,
	   SURNAME_AND_NAME,
	   SH.NAME AS HALL_NAME,
	   TR.NAME AS TRAINING_NAME,
	   Start_time,
	   End_time

	FROM Schedule_of_training SOT
	JOIN Trainers T ON sot.ID_Trainers=t.ID_Trainers
	JOIN Sports_Hall SH ON SOT.ID_Hall=SH.ID_Hall
	JOIN Training TR ON TR.ID_Training=SOT.ID_Training
	WHERE @NameTrainer = SURNAME_AND_NAME AND @Date=DATE
	ORDER BY DATE
GO

exec Work_Trainers @NameTrainer = 'Сидоров Андрей', @Date = '15.12.2022'

--Расписание определенного вида тренировки
CREATE PROCEDURE TrainingSchedule 
@NameTraining Nvarchar (50),
@Date DATETIME

AS
    SET NOCOUNT ON
	SELECT 
	   FORMAT(DATE, 'dd/MM/yyyy') AS DATE,
	   SURNAME_AND_NAME,
	   SH.NAME AS HALL_NAME,
	   TR.NAME AS TRAINING_NAME,
	   Start_time,
	   End_time

	FROM Schedule_of_training SOT
	JOIN Trainers T ON sot.ID_Trainers=t.ID_Trainers
	JOIN Sports_Hall SH ON SOT.ID_Hall=SH.ID_Hall
	JOIN Training TR ON TR.ID_Training=SOT.ID_Training
	WHERE @NameTraining = TR.NAME AND @Date=DATE
	ORDER BY DATE
GO

exec TrainingSchedule @NameTraining = 'Йога', @Date = '15.12.2022'

--Последний день визита клиента в фитнес-клуб
CREATE PROCEDURE LastDayClient
@NameClient Nvarchar (50)
AS
    SET NOCOUNT ON
    SELECT C.Name,MAX(FORMAT(E.Exit_Time, 'dd/MM/yyyy')) as LastDay
    FROM Entrance as E
    LEFT JOIN Clients C on E.ID_Clients = C.ID_Clients
    WHERE @NameClient = C.Name
	GROUP BY C.Name
    ORDER BY C.Name
GO

exec LastDayClient @NameClient = 'Смирнов Григорий'

--Проверка на срок действия абонемента
CREATE PROCEDURE ValidityCheck
@NameClient Nvarchar (50)
AS
    SET NOCOUNT ON
	DECLARE @END_DATE DATETIME = (SELECT S.Valid_until
								  FROM Subscription as S
								  LEFT JOIN Sale_of_subscription SOS on S.ID_Sale = SOS.ID_Sale
								  LEFT JOIN Clients C on SOS.ID_Clients = C.ID_Clients
								  WHERE @NameClient = C.Name
								  )
		IF @END_DATE < GETDATE() 
			BEGIN
				SELECT @NameClient,FORMAT(@END_DATE, 'dd/MM/yyyy') as EndDate, 'Срок действия закончился'
			END
		ELSE 
			BEGIN
				SELECT @NameClient,FORMAT(@END_DATE, 'dd/MM/yyyy') as EndDate, 'Срок действия не закончился'
			END
GO

exec ValidityCheck @NameClient = 'Смирнов Григорий'
