USE master
GO

CREATE DATABASE test_copy ON (
    Name=test_copy, 
    FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\test_copy.mdf',
    Maxsize=100
) 
LOG ON (
    Name=test_copy_log, 
    FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\test_copy_log.ldf',
    Maxsize=100
)
GO

EXEC SP_HELPDB test_copy
GO
ALTER DATABASE SessionDB SET AUTO_SHRINK ON 
GO

EXEC SP_HELPDB test_copy
GO