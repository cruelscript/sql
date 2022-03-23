USE SessionDB
GO

-- Examples

-- выбрать все названия дисциплин, по которым студентами были получены оценки 
SELECT DISTINCT DisciplinesName FROM Disciplines 
	JOIN Uplans ON Disciplines.NumDisc=Uplans.NumDisc 
		JOIN Balls ON Uplans.IdDisc=Balls.IdDisc

-- выбрать всех студентов с указанием оценок, если они есть
SELECT FIO, Ball FROM Students 
	LEFT JOIN Balls ON Students.NumSt=Balls.NumSt
		WHERE Ball IS NOT NULL

-- выбрать номера студентов, у которых нет оценок
SELECT NumSt FROM Students 
	EXCEPT 
		Select NumSt FROM Balls 

-- выбрать номера студентов, которые сдали хотя бы один экзамен
SELECT NumSt FROM Students 
	INTERSECT 
		SELECT NumSt FROM Balls 

-- выбрать студентов, которые получили пятерки и которые вообще ничего не сдали
SELECT NumSt FROM Students	
	EXCEPT 
		SELECT NumSt FROM Balls
	UNION
		SELECT NumSt FROM Balls 
			WHERE Ball=5

-- вывести студентов, которые сдали все экзамены первого семестра
SELECT NumSt, NumDir, COUNT(Ball) AS BallCount
	FROM Balls JOIN Uplans ON Balls.IdDisc=Uplans.IdDisc 
			WHERE Semestr=1
		GROUP BY NumSt, NumDir
			HAVING COUNT(Ball)=(SELECT COUNT(*) FROM Uplans u
									WHERE Uplans.NumDir=u.NumDir AND Semestr=1)

-- 3.1 Выберите направления, в которых есть студенты, которые сдали экзамены
SELECT DISTINCT Title FROM Directions 
	JOIN Groups 
		ON Directions.NumDir = Groups.NumDir
	JOIN Students 
		ON Groups.NumGr=Students.NumGr
	JOIN Balls 
		ON Students.NumSt=Balls.NumSt

-- 3.2. Выберите наименования дисциплин первого семестра
SELECT DISTINCT DisciplinesName 
	FROM Disciplines JOIN Uplans
		ON Disciplines.NumDisc=Uplans.NumDisc
		WHERE Uplans.Semestr = 1

-- 3.3. Выберите номера групп, в которых есть студенты, сдавшие хотя бы один экзамен
SELECT DISTINCT Students.NumGr 
	FROM Balls JOIN Students 
		ON Balls.NumSt=Students.NumSt

-- 3.4. Выведите наименование дисциплин с указанием идентификатора студента, если он сдал экзамен
SELECT Disciplines.DisciplinesName, Balls.NumSt
	FROM Balls 
		JOIN Uplans
			ON Balls.IdDisc = Uplans.IdDisc
		JOIN Disciplines
			ON Uplans.NumDisc = Disciplines.NumDisc

-- 3.5. Выберите номера групп, в которых есть свободные места
SELECT Groups.NumGr
	FROM Groups JOIN Students 
		ON Groups.NumGr = Students.NumGr
		GROUP BY Groups.NumGr, Groups.Quantity
			HAVING COUNT(Students.NumSt) < Groups.Quantity

-- 3.6. Выберите номера групп, в которых есть студенты, сдавшие больше одного экзамена, добавив к ним номера групп, в которых есть студенты, которые ничего не сдали.
SELECT Students.NumGr 
	FROM Balls JOIN Students
		ON Students.NumSt = Balls.NumSt
		GROUP BY Students.NumGr, Students.NumSt 
			HAVING COUNT(Balls.NumSt) > 1
UNION
SELECT Students.NumGr 
	FROM Students JOIN (SELECT Students.NumSt FROM Students  
						EXCEPT 
						SELECT DISTINCT Balls.NumSt FROM Balls) T 
		ON Students.NumSt = T.NumSt

-- больше одного + вообще ничего = все - ровно один

SELECT DISTINCT Students.NumGr 
	FROM Students JOIN (SELECT NumSt FROM Students 
						EXCEPT 
						SELECT DISTINCT Balls.NumSt FROM Balls
							GROUP BY NumSt
								HAVING COUNT(Balls.NumSt) = 1) T 
		ON Students.NumSt = T.NumSt

-- 3.7. Выберите дисциплины, которые есть и в первом и во втором семестре
SELECT DisciplinesName 
	FROM Disciplines JOIN (SELECT DISTINCT NumDisc FROM Uplans
						       WHERE Uplans.Semestr = 1
						   INTERSECT
						   SELECT DISTINCT NumDisc FROM Uplans
						       WHERE Uplans.Semestr = 2 ) T
		ON Disciplines.NumDisc = T.NumDisc

-- 3.8. Придумайте запрос, который использует операцию соединения по неравенству
-- Выбрать группы
SELECT DISTINCT NumGr
	FROM Students JOIN Balls 
		ON Balls.NumSt <= Students.NumSt

-- 3.9. Придумайте запрос, который использует операцию внешнего соединения справа, предварительно подготовив тестовые данные
-- Выбрать фамилии негодяев, которые ничего не сдали
SELECT FIO
	FROM Balls RIGHT JOIN Students 
		ON Balls.NumSt = Students.NumSt
		WHERE Ball IS NULL

-- 3.10. Придумайте запрос с группировкой и соединением нескольких таблиц.
-- Вывести всех людей, которые сдавали такое количество предметов, которое больше по номиналу уникальной оценки, которую они получили за эти предметы
-- Подойдут ученики, которые сдали больше трех предметов на оценку три, больше четырех предметов на оценку 4, больше 5 предметов на оценку 5
SELECT Balls.NumSt, Students.FIO
	FROM Students JOIN Balls 
		ON Balls.NumSt = Students.NumSt
		GROUP BY Balls.NumSt, Students.FIO, Balls.Ball
			HAVING COUNT(Students.NumSt) > Balls.Ball

-- 4.1 Выберите студентов, которые сдали только одну дисциплину
SELECT NumSt FROM Students AS s
	WHERE NOT EXISTS (
		SELECT NumST FROM Balls AS b
			WHERE b.NumSt = s.NumSt
				GROUP BY NumSt
					HAVING COUNT(NumSt) > 1
	)

-- 4.2. Выбрать студентов, которые не сдали ни одного экзамена
SELECT NumSt, FIO FROM Students 
	WHERE NOT EXISTS (
		SELECT * FROM Balls
			WHERE Students.NumSt = Balls.NumSt
	)

-- 4.3. Выберите группы, в которых есть студенты, сдавшие все экзамены 1 семестра
SELECT NumGr FROM Groups AS g
	WHERE EXISTS (
		SELECT * From Students AS s
			WHERE s.NumGr = g.NumGr 
				AND NOT EXISTS (
					SELECT * FROM Uplans AS u
						WHERE g.NumDir = u.NumDir
							AND u.Semestr = 1
							AND NOT EXISTS (
								SELECT * FROM Balls AS b
									WHERE b.IdDisc = u.IdDisc
										AND s.NumSt = b.NumSt
							)
				)
	)

-- 4.4. Выберите группы, в которых есть студенты, которые не сдали ни одной дисциплины
SELECT g.NumGr FROM Groups AS g
	WHERE EXISTS (
		SELECT * FROM Students AS s
			WHERE s.NumGr = g.NumGr 
				AND NOT EXISTS (
					SELECT * FROM Disciplines AS d 
						WHERE EXISTS (
							SELECT * FROM Uplans AS u
								WHERE u.NumDir = g.NumDir
									AND U.NumDisc = d.NumDisc
							)
							AND NOT EXISTS (
								SELECT * FROM Uplans AS u
									WHERE u.NumDir = g.NumDir
										AND u.NumDisc = d.NumDisc
										AND NOT EXISTS (
											SELECT * FROM Balls AS b
												WHERE b.NumSt = s.NumSt 
													AND u.IdDisc = b.IdDisc
										)
							)
				)
	)

-- 4.5. Выбрать дисциплины, которые не попали в учебный план направления 231000
SELECT DisciplinesName FROM Disciplines AS d
	WHERE NOT EXISTS (
		SELECT * FROM Uplans AS u
			WHERE u.NumDisc = d.NumDisc 
				AND u.NumDir = '231000'
	)

-- 4.6. Выбрать дисциплины, которые не сдали все студенты направления 231000
SELECT DisciplinesName FROM Disciplines AS d
	WHERE NOT EXISTS (
		SELECT * 
			FROM Balls AS b JOIN Uplans AS u 
				ON b.IdDisc = u.IdDisc
				WHERE u.NumDisc = d.NumDisc 
					AND u.NumDir = '231000'
	)

-- 4.7. Выбрать группы, в которых все студенты сдали физику
SELECT g.NumGr FROM Groups AS g
	WHERE EXISTS (
		SELECT * FROM Uplans AS u JOIN Disciplines AS d
			ON u.NumDisc = d.NumDisc
			WHERE u.NumDir = g.NumDir 
				AND d.DisciplinesName = 'Физика'
	)
		AND NOT EXISTS (
			SELECT * FROM Students AS s
				WHERE s.NumGr = g.NumGr
					AND EXISTS (
						SELECT * FROM Uplans AS u JOIN Disciplines AS d
							ON u.NumDisc = d.NumDisc
							WHERE u.NumDir = g.NumDir
								AND d.DisciplinesName = 'Физика'
								AND NOT EXISTS (
									SELECT * FROM Balls AS b
										WHERE b.IdDisc = u.IdDisc
											AND b.NumSt = s.NumSt
								)
					)
		)

SELECT g.NumGr FROM Groups AS g
EXCEPT
SELECT s.NumGr FROM Students AS s 
	JOIN Groups AS g
		ON s.NumGr = g.NumGr
	JOIN Uplans AS u
		ON g.NumDir = u.NumDir
	JOIN Disciplines AS d
		ON u.NumDisc = d.NumDisc
	LEFT JOIN Balls AS b
		ON u.IdDisc = b.IdDisc 
			AND s.NumSt = b.NumSt
	WHERE d.DisciplinesName = 'Физика' 
		AND b.IdBall IS NULL

-- 4.8. Выбрать группы, в которых все студенты сдали все дисциплины 1 семестра
SELECT g.NumGr FROM Groups AS g
	WHERE NOT EXISTS (
		SELECT * FROM Students AS s
			WHERE s.NumGr = g.NumGr
				AND EXISTS (
					SELECT * FROM Uplans AS u
						WHERE u.Semestr = 1
							AND u.NumDir = g.NumDir
							AND NOT EXISTS (
								SELECT * FROM Balls AS b
									WHERE b.NumSt = s.NumSt
										AND b.IdDisc = u.IdDisc
							)
				)
	)

SELECT Groups.NumGr FROM Groups
EXCEPT
SELECT s.NumGr FROM Students AS s
	JOIN Groups AS g
		ON s.NumGr = g.NumGr
	JOIN Uplans AS u
		ON g.NumDir = u.NumDir
	LEFT JOIN Balls AS b
		ON u.IdDisc = b.IdDisc 
			AND s.NumSt = b.NumSt
	WHERE u.Semestr = 1 
		AND b.IdBall IS NULL

-- 4.9. Выбрать студентов, которые сдали все (о которых есть запись) экзамены на хорошо и отлично.
SELECT NumST FROM Students AS s
	WHERE EXISTS (
		SELECT DISTINCT NumST FROM Balls AS b JOIN Uplans AS u
			ON b.IdDisc = u.IdDisc
			WHERE b.NumSt = s.NumSt
				AND b.Ball > 3
				AND NOT EXISTS (
					SELECT * FROM Balls AS b JOIN Uplans AS u
						ON b.IdDisc = u.IdDisc
							WHERE b.NumSt = s.NumSt
								AND b.Ball <= 3
				)
	)

-- 4.9. Выбрать студентов, которые сдали все (которые должны были сдать по учебной программе) экзамены на хорошо и отлично.
SELECT s.NumSt FROM Students AS s JOIN Groups AS g
	ON s.NumGr = g.NumGr
	WHERE NOT EXISTS (
		SELECT * FROM Uplans AS u
			WHERE u.NumDir = g.NumDir
				AND NOT EXISTS ( 
					SELECT * FROM Balls AS b 
						WHERE b.NumSt = s.NumSt 
							AND b.IdDisc = u.IdDisc
							AND b.Ball > 3
				)
	)	
	
-- 4.10. Выбрать студентов, которые сдали наибольшее количество экзаменов
SELECT NumSt FROM Balls
	GROUP BY NumST
		HAVING COUNT(Ball) = (
			SELECT MAX(T.m) FROM (
				SELECT COUNT(Ball) AS m FROM Balls
					GROUP BY NumSt
				) T
		)

SELECT Students.FIO, Students.NumSt, Directions.Title 
	FROM Students JOIN Groups 
		ON Students.NumGr = Groups.NumGr
			AND Groups.NumGr = '13504/1' 
			AND Students.NumSt BETWEEN 1 AND 10 
		JOIN Directions 
			ON Directions.NumDir = Groups.NumDir 
UNION
SELECT Students.FIO, Students.NumSt, Directions.Title 
	FROM Students JOIN Groups 
		ON Students.NumGr = Groups.NumGr
			AND Groups.NumGr = '13504/1' 
			AND Students.NumSt BETWEEN 10 AND 20 
		JOIN Directions 
			ON Directions.NumDir = Groups.NumDir 

SELECT g.NumGr, d.Title FROM Groups AS g JOIN Directions AS d 
	ON g.NumDir = d.NumDir 
