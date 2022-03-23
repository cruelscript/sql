create or replace function staging_trigger() returns trigger as $staging_trigger$
begin
    if not exists(select * from Actor where idActor = new.actorId) then
        raise exception 'Error: Actor with id % does not exist', new.actorId;
    end if;
    if not exists(select * from Role where idRole = new.roleId) then
        raise exception 'Error: Role with id % does not exist', new.roleId;
    end if;
    if (new.directorName = '') then
        raise exception 'Name of the play director cannot be empty';
    end if;
    if (new.playDate is null) then
        raise exception 'Play date cannot be empty';
    end if;
    if (new.appointmentDate is null) then
        raise exception 'Appointment date cannot be empty';
    end if;
    if (new.playDate < (select now()::date)) then
            raise exception 'You cannot add a past date for a new play';
    end if;
    return new;
end;
$staging_trigger$ language plpgsql;


create trigger staging_trigger before insert or update on Staging
    for each row execute function staging_trigger();

drop trigger staging_trigger on Staging;

insert into Staging(actorId, roleId, playDate, directorName, appointmentDate, removalDate)
    values (1, 1, '2022-03-03', 'Слава Белорусских', '2022-03-28', null);

insert into Staging(actorId, roleId, playDate, directorName, appointmentDate, removalDate)
    values (689, 1, '2022-04-04', 'Слава Белорусских', '2022-03-28', null);

insert into Staging(actorId, roleId, playDate, directorName, appointmentDate, removalDate)
    values (1, 589, '2022-04-04', 'Слава Белорусских', '2022-03-28', null);