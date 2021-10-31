USE master
GO

CREATE DATABASE SessionDB ON (
    Name= SessionDB, 
    FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\ SessionDB.mdf',
    Maxsize=100
) 
LOG ON (
    Name= SessionDB_log, 
    FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\ SessionDB_log.ldf',
    Maxsize=100
)
GO

EXEC SP_HELPDB SessionDB
GO
ALTER DATABASE SessionDB SET AUTO_SHRINK ON 
GO

ALTER DATABASE SessionDB
	MODIFY FILE (name=SessionDB, maxsize = 115MB)
GO
EXEC SP_HELPDB SessionDB
GO