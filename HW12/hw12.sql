use FitnessClub;

--Создание индексов

CREATE INDEX idx_Clients_name
ON Clients (Name)
GO 

CREATE INDEX idx_Trainers_name
ON Trainers (Surname_and_name)
GO 

CREATE INDEX ix_Subscription_valid_until_expired
ON Subscription (valid_until)
WHERE valid_until IS NOT NULL
GO  

 