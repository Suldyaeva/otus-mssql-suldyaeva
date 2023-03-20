use FitnessClub;

--Создание таблиц 

CREATE TABLE Trainers(
	ID_Trainers			int not null identity(1, 1)  primary key,
	Surname_and_name	nvarchar(50),
	Date_of_birth		date not null,
	Date_of_admission	date not null,
	Address				nvarchar(50),
	Telephone			nvarchar(50),
	N_Pasport_Trainers	nvarchar(50),
	Category			nvarchar(50),
	Specialisation		nvarchar(50),
	Salary				numeric(19,4)
)
GO


insert into Trainers values	
('Иванов Петр', '1987-09-01','2022-06-15','1877 Mittal Road','(308) 555-0100','8899776655','Высшая','Инструктор тренажерного зала',30000), 
('Петрова Мария', '1994-05-11','2021-07-18','483 Raut Lane','(212) 555-0100','8810776005','Высшая','Инструктор аэробного зала',50000), 
('Сидоров Андрей', '1989-12-28','2022-12-20','25 Kasesalu Street','(423) 555-0100','8812345657','Средняя','Инструктор тренажерного зала',20000)

CREATE TABLE Sign_up_for_a_training(
	ID_Sign				int not null identity(1, 1)  primary key,
	Date_training		date not null
)
GO

insert into Sign_up_for_a_training values	
('2022-12-15'), 
('2022-12-16'), 
('2022-12-17')

CREATE TABLE Sports_Hall(
	ID_Hall				int not null identity(1, 1)  primary key,
	Name				nvarchar(50)
)
GO

insert into Sports_Hall values	
('Тренажерный зал'), 
('Бассейн'), 
('Зал групповых занятий №1')

CREATE TABLE Training(
	ID_Training			int not null identity(1, 1)  primary key,
	Name				nvarchar(50)
)
GO

insert into Training values	
('Йога'), 
('Аквааэробика'), 
('Аэробика')

CREATE TABLE Attendance(
	ID_Attendance		int not null identity(1, 1)  primary key,
	Date				date not null
)
GO

insert into Attendance values	
('2022-12-15'), 
('2022-12-16'), 
('2022-12-17')

CREATE TABLE Clients(
	ID_Clients			int not null identity(1, 1)  primary key,
	Name				nvarchar(50),
	Date_of_birth		date not null,
	Telephone			nvarchar(50),
	N_Pasport_Trainers	nvarchar(50)
)
GO

insert into Clients values	
('Смирнов Григорий', '1999-03-01','(308) 555-0100','8899776655'), 
('Кереева Александра', '1996-05-28','(212) 555-0100','8815974569'),
('Клименчук Виктор', '1987-05-22','(423) 555-0100','8813454678')

CREATE TABLE Entrance(
	ID_Attendance		INT,
	ID_Clients			INT,
	Entry_time			[datetime2] (7) NOT NULL DEFAULT GETDATE(), 
	Exit_time			[datetime2] (7) NOT NULL DEFAULT GETDATE(),
	CONSTRAINT FK_Entrance_1 FOREIGN KEY (ID_Attendance) REFERENCES Attendance (ID_Attendance),
	CONSTRAINT FK_Entrance_2 FOREIGN KEY (ID_Clients) REFERENCES Clients (ID_Clients)
)
GO

insert into Entrance values	
(2,1,'2022-12-15 14:23:17.1230409','2022-12-14 23:59:59.9999999'), 
(1,3,'2022-12-16 17:27:15.1530409','2022-12-15 23:59:59.9999999'), 
(3,2,'2022-12-17 18:28:18.1280808','2022-12-16 23:59:59.9999999') 

CREATE TABLE Sale_of_subscription(
	ID_Sale				int not null identity(1, 1)  primary key,
	ID_Clients			INT,
	Date_of_birth		date not null,
	CONSTRAINT FK_Sale_of_subscription FOREIGN KEY (ID_Clients) REFERENCES Clients (ID_Clients)
)
GO

insert into Sale_of_subscription values	
(1,'2022-11-19'), 
(2,'2020-06-11'), 
(3,'2022-12-03')


create TABLE Tariff(
	ID_Tariff			int not null identity(1, 1)  primary key,
	ID_Hall				INT,
	Name				nvarchar(50),
	Description			nvarchar(50),
	Cost				numeric(19,4),
	CONSTRAINT FK_Tariff FOREIGN KEY (ID_Hall) REFERENCES Sports_Hall (ID_Hall)
)
GO

insert into Tariff values	
(3,'Стандартная карта', '12 мес с возможностью неограниченного посещения',50000), 
(2,'Детская карта', 'Дети до 13 лет год безлимитного посещения до 21:00',40000), 
(2,'Фитнес Утро', '12 мес неограниченного посещения до 12:00',45000)

select * from Tariff

CREATE TABLE Subscription(
	ID_Sale				INT,
	ID_Tariff			INT,
	Valid_from			[datetime2] (7) DEFAULT GETDATE() NOT NULL, 
	Valid_until			[datetime2] (7) DEFAULT GETDATE() NOT NULL,
	Cost				numeric(19,4),
	CONSTRAINT FK_Subscription1 FOREIGN KEY (ID_Sale) REFERENCES Sale_of_subscription (ID_Sale),
	CONSTRAINT FK_Subscription2 FOREIGN KEY (ID_Tariff) REFERENCES Tariff (ID_Tariff)
)
GO

insert into Subscription values	
(1,14,'2021-12-15 14:23:17.1230409','2022-12-14 23:59:59.9999999',29000), 
(2,15,'2021-12-16 17:27:15.1530409','2022-12-15 23:59:59.9999999',24000), 
(3,16,'2021-12-17 18:28:18.1280808','2022-12-16 23:59:59.9999999',37000) 

CREATE TABLE Schedule_of_training(
	ID_Training			int not null,
	ID_Sign				int not null,
	ID_Trainers			int not null,
	ID_Hall				int not null,
	Date				date not null,
	Start_time			[datetime2] (7) DEFAULT GETDATE() NOT NULL, 
	End_time			[datetime2] (7) DEFAULT GETDATE() NOT NULL,
	CONSTRAINT FK_Schedule_of_training_1 FOREIGN KEY (ID_Training) REFERENCES Training (ID_Training),
	CONSTRAINT FK_Schedule_of_training_2 FOREIGN KEY (ID_Sign)	   REFERENCES Sign_up_for_a_training (ID_Sign),
	CONSTRAINT FK_Schedule_of_training_3 FOREIGN KEY (ID_Trainers) REFERENCES Trainers (ID_Trainers),
	CONSTRAINT FK_Schedule_of_training_4 FOREIGN KEY (ID_Hall)     REFERENCES Sports_Hall (ID_Hall)
)
GO

insert into Schedule_of_training values	
(1,2,3,1,'2022-12-15','2022-12-15 14:23:17.1230409','2022-12-14 23:59:59.9999999'), 
(2,3,1,2,'2022-12-16','2022-12-16 17:27:15.1530409','2022-12-15 23:59:59.9999999'), 
(3,2,3,1,'2022-12-17','2022-12-17 18:28:18.1280808','2022-12-16 23:59:59.9999999') 

--Создание индексов

CREATE INDEX idx_Clients_name
ON Clients (Name)
GO 

CREATE INDEX ix_Subscription_valid_until_expired
ON Subscription (valid_until)
WHERE valid_until IS NOT NULL
GO  

 