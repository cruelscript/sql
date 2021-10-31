USE CinemaStudio
GO

CREATE TABLE Actor (
	IdActor int IDENTITY(1,1) PRIMARY KEY, 
	ActorName varchar(255),
	BirthDate date,
	Salary money CHECK (Salary > 0)
)
GO

CREATE TABLE Film (
	IdFilm int IDENTITY(1,1) PRIMARY KEY,
	FilmName varchar(255),
	FilmDuration time CHECK (FilmDuration > '00:00:00:000')
)
GO

CREATE TABLE ActorFilm (
	IdActorFilm int,
	ActorId int,
	FilmId int,

	FOREIGN KEY(ActorId) REFERENCES Actor(IdActor) 
		ON DELETE SET NULL
		ON UPDATE CASCADE,

	FOREIGN KEY(FilmId) REFERENCES Film(IdFilm)
		ON DELETE SET NULL
		ON UPDATE CASCADE
)
GO
		