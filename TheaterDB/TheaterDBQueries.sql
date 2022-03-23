-- Выбрать всех актрис
select Actor.name from Actor
    join Sex S
        on Actor.sexID = S.idSex
            where sexName = 'female';

-- Найти все постановки и их даты, где режиссер - Кирилл Серебренников
select distinct playDate, Play.name, Play.author, Staging.directorName from Staging
    join Role on Staging.roleID = Role.idRole
    join PLay on Role.playID = Play.idPlay
        where directorName = 'Кирилл Серебренников';

-- выбрать все роли мужского пола, которые являются главными героями
select Role.name from Role
    join Sex on Role.sexID = Sex.idSex
        where sexName = 'male'
except
select Role.name from Role
    join Amplua A on Role.ampluaID = A.idAmplua
        where A.name != 'Главный герой';

-- обновить дату постановки
update Staging set playDate = '2022-03-03'
    where idStaging = 1;

-- обновить амплуа актера
update Actor set ampluaID = (select idAmplua from Amplua where name = 'Антагонист')
    where name = 'Никита Волков';

-- обновить дату снятия с роли конкретной актрисы с постановки
update Staging set removalDate = '2022-03-09'
    where actorID = (select idActor from Actor where name = 'Инга Нагорная')
        and playDate = '2022-03-18';

-- удалить постановку, которая попала под санкции
delete from Staging where idStaging = 14;

-- Разделяет по полу и берет предыдущего актера
select name, sexName, playDate,
       lag(name) over (partition by sexId
            order by playDate) as previous
    from Staging
        join Actor on Staging.actorId = Actor.idActor
        join Sex on Actor.sexId = Sex.idsex
            order by sexId, playdate;
