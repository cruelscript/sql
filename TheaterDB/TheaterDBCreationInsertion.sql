create domain ID_T as int check (value > 0) not null;
create domain NAME_T as varchar(500) not null;
create domain AMPLUA_T as varchar(100) not null;
create domain AGE_T as int not null check (value > 0);
create domain SEX_T as varchar(6) not null;
create domain PLAY_T as varchar(500) not null;

-- create or replace function sex(arg varchar(6)) returns bool as $$
--         begin
--             if arg = 'male' then
--                 return true;
--             end if;
--             if arg = 'female' then
--                 return false;
--             else raise exception 'Invalid sex name: %.', $1;
--             end if;
--         end;
--     $$ language plpgsql immutable parallel safe;

create table Sex (
    idSex   serial primary key,
    sexName SEX_T
);

create table Amplua (
    idAmplua serial primary key,
    name     AMPLUA_T
);

create table Play (
    idPlay serial primary key,
    name   PLAY_T,
    author NAME_T
);

create table Actor (
    idActor  serial primary key,
    name     NAME_T,
    ampluaID ID_T,
    age      AGE_T,
    sexID    ID_T,

    constraint actor_amplua_fk foreign key (ampluaID)
        references Amplua (idAmplua),
    constraint actor_sex_fk foreign key (sexID)
        references Sex (idSex)
);

create table Role (
    idRole   serial primary key,
    name     NAME_T,
    ampluaID ID_T,
    playID   ID_T,
    sexID    ID_T,

    constraint role_amplua_fk foreign key (ampluaID)
        references Amplua (idAmplua),
    constraint role_play_fk foreign key (playID)
        references Play (idPlay),
    constraint role_sex_fk foreign key (sexID)
        references Sex (idSex)
);

create table Staging (
    idStaging       serial primary key,
    actorID         ID_T,
    roleID          ID_T,
    playDate        date not null,
    directorName    NAME_T,
    appointmentDate date not null,
    removalDate     date,

    constraint staging_actor_fk foreign key (actorID)
        references Actor (idActor),
    constraint staging_role_fk foreign key (roleID)
        references Role (idRole)
);

insert into Sex(sexName) values
    ('male'),
    ('female');

insert into Amplua(name) values
    ('Герой'),
    ('Гранд-кокет'),
    ('Главный герой'),
    ('Антагонист'),
    ('Резонер'),
    ('Трагик'),
    ('Злодей'),
    ('Герой-любовник');

insert into Play(name, author) values
    ('Ревизор', 'Н.В.Гоголь'),
    ('Горе от ума', 'А.С.Грибоедов'),
    ('Вишневый сад', 'А.П.Чехов'),
    ('Бесприданница', 'А.Н.Островский'),
    ('Ромео и Джульетта', 'У.Шекспир'),
    ('Гамлет', 'У.Шекспир'),
    ('Отелло', 'У.Шекспир');

insert into Actor values
    (default, 'Чулпан Хаматова', 1, 46, 2),
    (default, 'Рената Литвинова', 2, 55, 2),
    (default, 'Александр Ширвиндт', 3, 87, 1),
    (default, 'Никита Волков', 4, 28, 1),
    (default, 'Владимир Кошевой', 3, 45, 1),
    (default, 'Инга Нагорная', 5, 24, 2),
    (default, 'Анна Ковальчук', 6, 44, 2),
    (default, 'Никита Чевычелов', 7, 20, 1),
    (default, 'Кирилл Головин', 5, 22, 1),
    (default, 'Федор Гырлов', 8, 20, 1);

insert into Role values
    (default, 'Иван Хлестаков', 3, 1, 1),
    (default, 'Александр Чацкий', 3, 2, 1),
    (default, 'Алексей Молчалин', 4, 2, 1),
    (default, 'Любовь Раневская', 3, 3, 2),
    (default, 'Аня', 1, 3, 2),
    (default, 'Лариса Дмитриевна', 3, 4, 2),
    (default, 'Ромео', 3, 5, 1),
    (default, 'Джульетта', 3, 5, 2),
    (default, 'Гамлет', 3, 6, 1),
    (default, 'Отелло', 8, 7, 1);

insert into Staging values
    (default, 3, 1, '2022-03-02', 'Кирилл Серебренников', '2022-01-10', NULL),
    (default, 5, 2, '2022-04-22', 'Дмитрий Крымов', '2022-02-22', NULL),
    (default, 4, 3, '2022-04-22', 'Дмитрий Крымов', '2022-02-24', '2022-03-01'),
    (default, 2, 4, '2021-03-03', 'Рената Литвинова', '2021-12-13', NULL),
    (default, 1, 5, '2022-03-28', 'Рената Литвинова', '2022-02-02', NULL),
    (default, 7, 6, '2022-05-12', 'Евгений Каменькович', '2022-02-28', NULL),
    (default, 9, 7, '2022-04-04', 'Константин Богомолов', '2022-02-15', NULL),
    (default, 6, 8, '2022-03-18', 'Константин Богомолов', '2022-02-14', NULL),
    (default, 4, 9, '2022-04-22', 'Филипп Григорьян', '2022-03-02', NULL),
    (default, 8, 3, '2022-04-22', 'Дмитрий Крымов', '2022-03-01', NULL),
    (default, 10, 10, '2022-05-01', 'Кама Гинкас', '2022-02-25', NULL),
    (default, 1, 8, '2022-03-18', 'Константин Богомолов', '2022-02-01', '2022-02-14'),
    (default, 8, 7, '2022-04-04', 'Константин Богомолов', '2022-01-10', '2022-02-09'),
    (default, 5, 1, '2022-03-02', 'Кирилл Серебренников', '2022-01-05', '2022-01-10'),
    (default, 3, 2, '2022-04-22', 'Дмитрий Крымов', '2022-02-02', '2022-02-20');
