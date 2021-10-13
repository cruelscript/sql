USE master
GO

CREATE DATABASE CinemaStudio ON (
	Name=CinemaStudio,
	FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\CinemaStudio.mdf',
	Maxsize=100MB
)

LOG ON (
	Name=CinemaStudio_log,
	FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\CinemaStudio.ldf',
	Maxsize=100MB
)
GO

EXEC SP_HELPDB CinemaStudio
GO

ALTER DATABASE CinemaStudio SET
AUTO_SHRINK ON
GO

ALTER DATABASE CinemaStudio
MODIFY FILE (name=CinemaStudio, maxsize=115MB)
GO

EXEC SP_HELPDB CinemaStudio
GO
	