USE SessionDB
GO 

-- 3.1. Выберите все направления подготовки, по которым обучаются студенты
SELECT * FROM DIRECTIONS

-- 3.2. Выберите все номера групп по всем направлениям подготовки
SELECT NumDir, NumGr FROM Groups

-- 3.3. Выберите ФИО всех студентов
SELECT FIO FROM Students

-- 3.4. Выберите идентификаторы всех студентов, которые получили оценки
SELECT NumSt FROM Balls

-- 3.5. Выберите номера направлений подготовки специалистов, которые включены в учебный план. Напишите два варианта запроса: без DISTINCT и с использованием DISTINCT
SELECT NumDir FROM Uplans
SELECT DISTINCT NumDir FROM Uplans

-- 3.6. Выберите номера семестров из таблицы Uplans, удалив дубликаты строк.
SELECT DISTINCT Semestr FROM Uplans

-- 3.7. Выберите всех студентов группы 13504/1
SELECT * FROM Students 
	WHERE NumGr = '13504/1' 

-- 3.8. Выберите дисциплины первого семестра для направления 230100
SELECT DISTINCT NumDisc FROM Uplans 
	WHERE NumDir = '230100' AND Semestr = 1

-- 3.9. Выведите номера групп с указанием количества студентов в каждой группе
SELECT DISTINCT NumGr, Quantity FROM Groups

-- 3.10. Выведите для каждой группы количество студентов, сдававших хотя бы один экзамен
SELECT Students.NumGr, COUNT(Balls.NumSt) FROM Balls, Students 
	WHERE Students.NumSt = Balls.NumSt
		GROUP BY Students.NumGr

-- 3.11. Выведите для каждой группы количество студентов, сдавших более одного экзамена
SELECT Students.NumGr, COUNT(DISTINCT Students.NumSt) FROM Balls, Students
	WHERE Students.NumSt = Balls.NumSt
		GROUP BY Students.NumGr, Students.NumSt 
			HAVING COUNT(Balls.NumSt) > 1

-- 4.1. Выберите ФИО студентов, которые сдали экзамены
SELECT DISTINCT FIO FROM Balls, Students
	WHERE Students.NumSt = Balls.NumSt

-- 4.2. Выберите названия дисциплин, по которым студенты сдавали экзамены
SELECT DISTINCT DisciplinesName FROM Balls, Disciplines, Uplans
	WHERE Balls.IdDisc = Uplans.IdDisc 
		AND Uplans.NumDisc = Disciplines.NumDisc

-- 4.3. Выведите названия дисциплин по направлению 230100
SELECT DISTINCT DisciplinesName FROM Disciplines, Uplans
	WHERE Uplans.NumDisc = Disciplines.NumDisc 
		AND Uplans.NumDir = '230100'

-- 4.4. Выведите ФИО студентов, которые сдали более одного экзамена
SELECT DISTINCT FIO FROM Students, Balls
	WHERE Students.NumSt = Balls.NumSt
		GROUP BY FIO
			HAVING COUNT(Balls.NumSt) > 1

-- 4.5. Выведите ФИО студентов, получивших минимальный балл
SELECT Students.NumSt, FIO, Min(Ball) FROM Students, Balls
    WHERE Students.NumSt = Balls.NumSt
    GROUP BY FIO, Ball, Students.NumSt
		HAVING Ball = (SELECT Min(Ball) FROM Balls)

-- 4.6. Выведите ФИО студентов, получивших максимальный балл
SELECT Students.NumSt, FIO, Max(Ball) AS MaxBall FROM Students, Balls
    WHERE Students.NumSt = Balls.NumSt and Ball IN (SELECT Max(Ball) FROM Balls)
    GROUP BY FIO, Ball, Students.NumSt

-- 4.7. Выведите номера групп, в которые есть более одного студента, сдавшего экзамен по Физике в 1 семестре
SELECT DISTINCT Groups.NumGr FROM Students, Balls, Groups, Uplans, Disciplines
	WHERE Students.NumSt = Balls.NumSt 
		AND Students.NumGr = Groups.NumGr 
		AND Balls.IdDisc = Uplans.IdDisc 
		AND Uplans.Semestr = 1 
		AND Uplans.NumDisc = Disciplines.NumDisc 
		AND Disciplines.DisciplinesName = 'Физика'
		GROUP BY Groups.NumGr
			HAVING COUNT(Balls.NumSt) > 1

-- 4.8. Выведите ФИО студентов, получивших за время обучения общее количество баллов по всем предметам более 9.
SELECT DISTINCT Students.FIO, SUM(Balls.Ball) AS SumBalls FROM Students, Balls
	WHERE Students.NumSt = Balls.NumSt
		GROUP BY Students.FIO
			HAVING SUM(Balls.Ball) > 9

-- 4.9. Выведите семестры, по которым количество сдавших студентов более одного
SELECT DISTINCT Uplans.Semestr FROM Uplans, Balls
	WHERE Balls.IdDisc = Uplans.IdDisc
		GROUP BY Uplans.Semestr
			HAVING COUNT(Balls.NumSt) > 1

-- 4.10. Выведите студентов, сдавших более одного предмета.
SELECT DISTINCT FIO FROM Students, Balls, Uplans
	WHERE Students.NumSt = Balls.NumSt 
		AND Balls.IdDisc = Uplans.IdDisc
		GROUP BY FIO
			HAVING COUNT(Uplans.NumDisc) > 1

SELECT Distinct FIO, Ball FROM Students, Balls, Groups, Uplans, Disciplines
    WHERE Students.NumSt = Balls.NumSt 
        AND Students.NumGr = Groups.NumGr 
        AND Balls.IdDisc = Uplans.IdDisc  
        AND Uplans.NumDisc = Disciplines.NumDisc 
        AND Disciplines.DisciplinesName = 'Физика'
        AND Balls.Ball >= 4
