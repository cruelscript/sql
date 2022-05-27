create or replace function insertStaging(actorId int,
    roleId int, playDate date, directorName varchar,
    appointmentDate date, removalDate date = null) returns void as $$
    begin
        if not exists(select * from Actor where idActor = actorId) then
            raise exception 'Error: Actor with id % does not exist', actorId;
        end if;
        if not exists(select * from Role where idRole = roleId) then
            raise exception 'Error: Role with id % does not exist', roleId;
        end if;
        if (directorName = '') then
            raise exception 'Name of the play director cannot be empty';
        end if;
        if (playDate is null) then
            raise exception 'Play date cannot be empty';
        end if;
        if (appointmentDate is null) then
            raise exception 'Appointment date cannot be empty';
        end if;
        if (playDate < (select now()::date)) then
            raise exception 'You cannot add a past date for a new play';
        end if;

        insert into Staging (actorid, roleid, playdate, directorname, appointmentdate, removaldate) values
            (actorId, roleId, playDate, directorName, appointmentDate, removalDate);
    end;
$$ language plpgsql;

do $$
    begin
        select insertStaging(155, 1, '2022-04-01', 'Руслан Кучугуров', '2022-04-05');
        exception
            when others then
                raise notice 'Illegal operation in TheaterDB -> Staging: %', SQLERRM;
    end;
$$ language plpgsql;

create or replace function getActorPlays(actorName varchar) returns
    table (play play_t, author name_t, role name_t,directorName name_t, playDate date) as $$
    begin
        return query
            select Play.name, Play.author, Role.name, Staging.directorName, Staging.playDate from Staging
                join Role on Staging.roleId = Role.idrole
                join Play on Role.playId = Play.idPlay
                    where actorId = (select idActor from Actor where Actor.name = actorName);
    end;
$$ language plpgsql;

select * from getActorPlays('Чулпан Хаматова');

create or replace function showPerformancesAfter(neededDate date) returns void as $$
    begin
        declare selectPerfomances cursor for
            select Play.name, Play.author, directorName, Staging.playDate from Staging
                join Role on Staging.roleId = Role.idRole
                join Play on Role.playId = Play.idPlay
                    where Staging.playDate > neededDate;
        begin
            for i in selectPerfomances loop
                raise info 'Постановка "%", написанная % и поставленная % будет сыграна позднее %, %',
                    i.name, i.author, i.directorName, neededDate, i.playDate;
            end loop;
        end;
    end;
$$ language plpgsql;

drop function showPerformancesAfter(neededDate date);

select showPerformancesAfter('2022-03-10');
