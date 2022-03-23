create user JaneDoe with password 'fake';

grant select on Amplua, Sex to JaneDoe;
grant select, insert, update on Actor to JaneDoe;
grant select(idStaging, actorId, roleId, directorName, appointmentDate, removalDate)
    on Staging to JaneDoe;
grant update(removalDate) on Staging to JaneDoe;
grant usage, select on all sequences in schema public to JaneDoe;

create or replace view full_staging as
    select Actor.name as Actor, Role.name as Role, playDate, directorName, appointmentDate, removalDate
        from Staging join Actor on Staging.actorId = Actor.idActor
            join Role on Staging.roleId = Role.idRole

create or replace view full_role as
    select Role.name as Role, Amplua.name as Amplua, Play.name as PLay, sexname as Sex from Role
        join Amplua on Role.ampluaId = Amplua.idAmplua
        join Play on Role.playId = Play.idPlay
        join Sex on Role.sexId = Sex.idsex

create or replace view full_play as
    select * from Play;

grant select on full_staging, full_play to JaneDoe;

create role on_update;
grant update (appointmentDate) on full_staging to on_update;
grant update (name) on full_play to on_update;
grant on_update to JaneDoe;


-- Test privileges for JaneDoe

select * from Actor; -- OK
insert into Actor values (default, 'Никита Волков2', 4, 28, 1); -- OK
update Actor set name = 'Никита Волков3' where name = 'Никита Волков2'; -- OK
delete from Actor where name = 'Никита Волков3'; -- NO

select idStaging, actorId, roleId, directorName, appointmentDate, removalDate from Staging; -- OK
select playDate from Staging; -- NO
update Staging set removalDate = '2022-03-10' where idStaging = 8; -- OK
update Staging set directorName = 'Never be updated' where idStaging = 8; -- NO

select * from Amplua; -- OK
insert into Amplua values (default, 'New Amplua'); -- NO
update Amplua set name = 'Old Amplua' where name = 'New Amplua'; -- NO
delete from Amplua where name = 'New Amplua'; -- NO

select * from Role; -- NO
select * from Play; -- NO

select playDate from full_staging; -- OK

select * from full_play; -- OK
insert into full_play(name, author) values ('Never', 'Added'); -- NO
update full_play set name = 'Отелло2' where name = 'Отелло'; -- OK
delete from full_play where name = 'Ревизор'; -- NO
