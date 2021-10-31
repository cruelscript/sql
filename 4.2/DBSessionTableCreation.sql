USE SessionDB; 

CREATE TABLE Directions(
   NumDir varchar(128) PRIMARY KEY,
   Title varchar(128),
   Quantity int CHECK(Quantity > 0)
)
GO

CREATE TABLE Groups(
   NumGr varchar(128) PRIMARY KEY,
   NumDir varchar(128),
   NumSt int,
   Quantity int CHECK(Quantity > 0)
   FOREIGN KEY (NumDir)  REFERENCES Directions (NumDir)
      ON DELETE CASCADE
      ON UPDATE CASCADE
)
GO

CREATE TABLE Students(
   NumSt int IDENTITY (1,1) PRIMARY KEY,
   FIO varchar(128),
   NumGr varchar(128),
   FOREIGN KEY (NumGr)  REFERENCES Groups (NumGr)
       ON DELETE CASCADE
       ON UPDATE CASCADE
)
GO

CREATE TABLE Disciplines(
    NumDisc int IDENTITY (1,1) PRIMARY KEY,
    DisciplinesName varchar(128)
)
GO

CREATE TABLE Uplans(
    IdDisc int IDENTITY (1,1) PRIMARY KEY,
    NumDir varchar(128),
    NumDisc int,
	Semestr int,
	FOREIGN KEY (NumDir)  REFERENCES Directions (NumDir)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (NumDisc)  REFERENCES Disciplines (NumDisc)
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO

CREATE TABLE Balls(
	IdBall int IDENTITY (1,1) PRIMARY KEY,
    IdDisc int,
    NumSt int,
	Ball int,
	DateEx date
	FOREIGN KEY (IdDisc)  REFERENCES Uplans (IdDisc)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (NumSt)  REFERENCES Students (NumSt)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
)
GO
