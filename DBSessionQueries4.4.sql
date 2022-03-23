USE SessionDB
GO

-- Examples

-- 1.1 Создание и использование представления для выборки  названий дисциплин, по которым хотя бы одним студентом была получена оценка 
CREATE VIEW DisciplinesWithBalls AS
	SELECT DISTINCT DisciplinesName 
		FROM Disciplines 
			JOIN Uplans 
				ON Disciplines.NumDisc = Uplans.NumDisc 
			JOIN Balls
				ON Uplans.IdDisc = Balls.IdDisc;
GO

SELECT * FROM DisciplinesWithBalls
GO

-- 1.2 Создание и использование представления c использованием реляционных операций для выборки студентов, которые получили пятерки и которые вообще ничего не сдали
CREATE VIEW StudentsTopAndLast2 (FIO, Complete) AS
	(SELECT A.Stud, 'NO' 
		FROM (SELECT FIO AS Stud FROM Students 
			EXCEPT
			SELECT DISTINCT FIO AS Stud FROM Balls 
				JOIN Students 
					ON Students.NumSt = Balls.NumSt
			) AS A
	)
	UNION
	(SELECT FIO, 'Five' FROM Balls JOIN Students 
		ON Students.NumSt = Balls.NumSt
		WHERE Ball = 5
	)
GO

SELECT * FROM StudentsTopAndLast2
GO

CREATE VIEW StudentsDiscipline AS
	SELECT DISTINCT Students.FIO, Disciplines.DisciplinesName FROM Students
		JOIN Groups
			ON Students.NumGr = Groups.NumGr
		JOIN Uplans
			ON Groups.NumDir = Uplans.NumDir
		JOIN Disciplines
			ON Uplans.NumDisc = Disciplines.NumDisc
GO

SELECT * FROM StudentsDiscipline
GO

ALTER PROCEDURE ListStudent (@Disc AS VARCHAR(30))
	AS SELECT DISTINCT Students.FIO, Students.NumGr, Ball FROM Groups 
		JOIN Students
			ON Groups.NumGr = Students.NumGr 
		JOIN Balls 
			ON Students.NumSt = Balls.NumSt 
		JOIN Uplans 
			ON Uplans.IdDisc = Balls.IdDisc 

			WHERE NumDisc = (SELECT NumDisc FROM Disciplines
							      WHERE DisciplinesName = @Disc)
GO

EXEC ListStudent  'Физика'
GO


-- 1.3 Создание и использование представления с использованием агрегатных функций, группировки и подзапросов для вывода студентов, которые сдали все экзамены первого семестра

CREATE VIEW StudentsComplete (FIO, Direction, NumberOfBalls) AS
	SELECT NumSt, NumDir, COUNT(Ball) 
		FROM Balls JOIN Uplans
			ON Balls.IdDisc = Uplans.IdDisc
			WHERE Semestr = 1 
				GROUP BY NumSt, NumDir
					HAVING COUNT(Ball) = (
						SELECT COUNT(*) FROM Uplans AS u
							WHERE Uplans.NumDir = u.NumDir 
								AND Semestr = 1
						);
GO

SELECT * FROM StudentsComplete;
GO

-- 1.4 Создание и использование представления с использованием  предиката NOT EXISTS для вывода номеров студентов, которые сдали все экзамены своего курса 
CREATE VIEW StudentsComplete2 AS
	SELECT Students.NumSt FROM Students JOIN Groups
		ON Groups.NumGr = Students.NumGr 
		WHERE NOT EXISTS (
			SELECT * FROM Uplans
				WHERE (Semestr = CONVERT(int, LEFT(Students.NumGr, 1)) * 2 - 1 
					OR Semestr = CONVERT(int, LEFT(Students.NumGr, 1)) * 2) 
					AND Groups.NumDir = Uplans.NumDir 
					AND NOT EXISTS (
						SELECT * FROM Balls
							WHERE Balls.IdDisc = Uplans.IdDisc 
								AND Students.NumSt = Balls.NumSt
					)
		)

GO

SELECT * FROM StudentsComplete2
GO

-- Procedures

-- 1 Создание процедуры без параметров. Создаем процедуру для подсчета общего количества студентов
CREATE PROCEDURE CountStudents AS
	SELECT COUNT(*) FROM Students

EXEC CountStudents
GO

-- 2 Создание процедуры c входным параметром. Создаем процедуру для подсчета студентов, сдавших хотя бы один экзамен в заданном семестре
CREATE PROCEDURE CountStudentsSem @CountSem AS INT AS
	SELECT COUNT(DISTINCT NumSt) FROM Balls JOIN Uplans 
		ON Uplans.IdDisc = Balls.IdDisc 
			WHERE Semestr >= @CountSem;
GO

EXEC CountStudentsSem 1
GO

DECLARE @kol INT
SET @kol = 1
EXEC CountStudentsSem @kol
GO

-- 3. Создание процедуры c несколькими  входными параметрами. 
-- 3.1. Создаем процедуру для получения списка студентов указанного направления, сдавших экзамен по  указанной дисциплине
CREATE PROCEDURE ListStudentsDir (@Dir AS INT, @Disc AS VARCHAR(30))
	AS SELECT DISTINCT Students.FIO FROM Groups 
		JOIN Students
			ON Groups.NumGr = Students.NumGr 
		JOIN Balls 
			ON Students.NumSt = Balls.NumSt 
		JOIN Uplans 
			ON Uplans.IdDisc = Balls.IdDisc 
			WHERE Groups.NumDir = @Dir 
				AND NumDisc = (SELECT NumDisc FROM Disciplines
							      WHERE DisciplinesName = @Disc)
GO

EXEC ListStudentsDir 230100, 'Физика'
GO

-- 3.2 Создаем процедуру для ввода информации о новом студенте
CREATE PROCEDURE EnterStudents (@FIO AS VARCHAR(30), @Group AS VARCHAR(10))
	AS INSERT INTO Students (FIO, NumGr) VALUES (@FIO, @Group)
GO

INSERT INTO Directions VALUES 
	('232000', 'Фундаментальная прокрастинация и информационные тракторы', 10)

INSERT INTO Groups VALUES
	('53504/3', '232000', 5, 5),
	('63504/3', '232000', 5, 5)
GO

DECLARE @Stud1 VARCHAR(30), 
		@Group1 VARCHAR(10), 
		@Stud2 VARCHAR(30),
		@Group2 VARCHAR(10);
SET @Stud1 = 'Новая Наталья'
SET @Stud2 = 'Светлова Вероника'
SET @Group1 = '53504/3'
SET @Group2 = '53504/3';

EXEC EnterStudents @Stud1, @Group1
EXEC EnterStudents @Stud2, @Group2
GO

-- 4. Создание процедуры с входными параметрами и значениями по умолчанию. Создать процедуру для перевода студентов указанной группы на следующий курс
INSERT INTO Groups VALUES 
	('23504/3', '230100', 5, 5),
	('23504/1', '231000', 5, 5)
GO

CREATE PROCEDURE NextCourse (@Group AS VARCHAR(10) = '13504/1')
	AS UPDATE Students SET NumGr = CONVERT(
		char(1), CONVERT(INT, LEFT(NumGr, 1)) + 1) 
		+ SUBSTRING(NumGr, 2, LEN(NumGr) - 1)
		WHERE NumGr = @Group
GO

DECLARE @Group VARCHAR(10)
SET @Group = '13504/3'
EXEC NextCourse @Group
GO

CREATE PROCEDURE PrevCourse (@Group AS VARCHAR(10) = '23504/1')
	AS UPDATE Students SET NumGr = CONVERT(
		char(1), CONVERT(INT, LEFT(NumGr, 1)) - 1) 
		+ SUBSTRING(NumGr, 2, LEN(NumGr) - 1)
		WHERE NumGr = @Group
GO

DECLARE @Group VARCHAR(10)
SET @Group = '23504/3'
EXEC PrevCourse @Group
GO

-- 5. Создание процедуры с входными и выходными параметрами. Создать процедуру для определения количества групп по указанному направлению.
CREATE PROCEDURE NumberGroups (@Dir AS INT, @Number AS INT OUTPUT)
	AS SELECT @Number = COUNT(NumGr) FROM Groups
		WHERE NumDir = @Dir
GO

DECLARE @Group INT 
EXEC NumberGroups 230100, @Group OUTPUT
SELECT @Group AS GroupCount
GO

-- 6. Создание процедуры, использующей вложенные хранимые процедуры. Создать улучшенную процедуру для перевода студентов указанной группы на следующий курс.
INSERT INTO Students VALUES
	('Уходящий Павел', '63504/3')
INSERT INTO Balls VALUES
	(3, 22, 5, '10.01.2008')
GO

ALTER TABLE Balls 
ADD CONSTRAINT FK__Balls__NumSt
FOREIGN KEY (NumSt) REFERENCES Students (NumSt)
	ON DELETE CASCADE
	ON UPDATE CASCADE
GO 

CREATE TABLE ArchiveStudents (
	Id INT IDENTITY (1,1) PRIMARY KEY,
	Year int,
	NumSt int, 
	FIO VARCHAR(30),
	NumGr VARCHAR(10)
)
GO

CREATE PROCEDURE DeleteStudentsComplete
	AS INSERT INTO ArchiveStudents
		SELECT YEAR(GETDATE()), NumSt, FIO, NumGr FROM Students 
			WHERE LEFT(NumGr, 1) = 6
		DELETE FROM Students 
			WHERE LEFT(NumGr, 1) = 6
GO

CREATE PROCEDURE NextCourse2 
	AS EXEC DeleteStudentsComplete
	UPDATE Students SET NumGr = CONVERT(
		char(1), CONVERT(INT, LEFT(NumGr, 1)) + 1) + 
			SUBSTRING(NumGr, 2, LEN(NumGr) - 1)
		WHERE NumSt IN (SELECT NumSt FROM StudentsComplete2)
GO

EXEC NextCourse2
GO

CREATE PROCEDURE ReturnStudents
	AS INSERT INTO Students 
		SELECT FIO, NumGr FROM ArchiveStudents
	DELETE FROM ArchiveStudents
GO

EXEC ReturnStudents
GO

							