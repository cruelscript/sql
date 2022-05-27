--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 14.1

-- Started on 2022-05-27 15:51:12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 33093)
-- Name: plpython3u; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpython3u WITH SCHEMA pg_catalog;


--
-- TOC entry 3111 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION plpython3u; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpython3u IS 'PL/Python3U untrusted procedural language';


--
-- TOC entry 658 (class 1247 OID 24590)
-- Name: age_t; Type: DOMAIN; Schema: public; Owner: root
--

CREATE DOMAIN public.age_t AS integer NOT NULL
	CONSTRAINT age_t_check CHECK ((VALUE > 0));


ALTER DOMAIN public.age_t OWNER TO root;

--
-- TOC entry 652 (class 1247 OID 24586)
-- Name: amplua_t; Type: DOMAIN; Schema: public; Owner: root
--

CREATE DOMAIN public.amplua_t AS character varying(100) NOT NULL;


ALTER DOMAIN public.amplua_t OWNER TO root;

--
-- TOC entry 655 (class 1247 OID 24588)
-- Name: date_t; Type: DOMAIN; Schema: public; Owner: root
--

CREATE DOMAIN public.date_t AS date NOT NULL;


ALTER DOMAIN public.date_t OWNER TO root;

--
-- TOC entry 645 (class 1247 OID 24579)
-- Name: id_t; Type: DOMAIN; Schema: public; Owner: root
--

CREATE DOMAIN public.id_t AS integer NOT NULL
	CONSTRAINT id_t_check CHECK ((VALUE > 0));


ALTER DOMAIN public.id_t OWNER TO root;

--
-- TOC entry 649 (class 1247 OID 24584)
-- Name: name_t; Type: DOMAIN; Schema: public; Owner: root
--

CREATE DOMAIN public.name_t AS character varying(500) NOT NULL;


ALTER DOMAIN public.name_t OWNER TO root;

--
-- TOC entry 665 (class 1247 OID 24764)
-- Name: play_t; Type: DOMAIN; Schema: public; Owner: root
--

CREATE DOMAIN public.play_t AS character varying(500) NOT NULL;


ALTER DOMAIN public.play_t OWNER TO root;

--
-- TOC entry 662 (class 1247 OID 24762)
-- Name: sex_t; Type: DOMAIN; Schema: public; Owner: root
--

CREATE DOMAIN public.sex_t AS character varying(6) NOT NULL;


ALTER DOMAIN public.sex_t OWNER TO root;

--
-- TOC entry 232 (class 1255 OID 24910)
-- Name: getactorplays(character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.getactorplays(actorname character varying) RETURNS TABLE(play public.play_t, author public.name_t, role public.name_t, directorname public.name_t, playdate date)
    LANGUAGE plpgsql
    AS $$
    begin
        return query
            select Play.name, Play.author, Role.name, Staging.directorName, Staging.playDate from Staging
                join Role on Staging.roleId = Role.idrole
                join Play on Role.playId = Play.idPlay
                    where actorId = (select idActor from Actor where Actor.name = actorName);
    end;
$$;


ALTER FUNCTION public.getactorplays(actorname character varying) OWNER TO root;

--
-- TOC entry 231 (class 1255 OID 24905)
-- Name: insertstaging(integer, integer, date, character varying, date, date); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.insertstaging(actorid integer, roleid integer, playdate date, directorname character varying, appointmentdate date, removaldate date DEFAULT NULL::date) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.insertstaging(actorid integer, roleid integer, playdate date, directorname character varying, appointmentdate date, removaldate date) OWNER TO root;

--
-- TOC entry 218 (class 1255 OID 33098)
-- Name: pymax(integer, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.pymax(a integer, b integer) RETURNS integer
    LANGUAGE plpython3u
    AS $$
  if a > b:
    return a
  return b
$$;


ALTER FUNCTION public.pymax(a integer, b integer) OWNER TO root;

--
-- TOC entry 217 (class 1255 OID 24600)
-- Name: sex(character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.sex(arg character varying) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
        begin
            if arg = 'male' then
                return true;
            end if;
            if arg = 'female' then
                return false;
            else raise exception 'Invalid sex name: %.', $1;
            end if;
        end;
    $_$;


ALTER FUNCTION public.sex(arg character varying) OWNER TO root;

--
-- TOC entry 233 (class 1255 OID 24912)
-- Name: showperformancesafter(date); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.showperformancesafter(neededdate date) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.showperformancesafter(neededdate date) OWNER TO root;

--
-- TOC entry 230 (class 1255 OID 24879)
-- Name: staging_trigger(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.staging_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.staging_trigger() OWNER TO root;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 208 (class 1259 OID 24800)
-- Name: actor; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.actor (
    idactor integer NOT NULL,
    name public.name_t,
    ampluaid public.id_t,
    age public.age_t,
    sexid public.id_t
);


ALTER TABLE public.actor OWNER TO root;

--
-- TOC entry 207 (class 1259 OID 24798)
-- Name: actor_idactor_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.actor_idactor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.actor_idactor_seq OWNER TO root;

--
-- TOC entry 3113 (class 0 OID 0)
-- Dependencies: 207
-- Name: actor_idactor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.actor_idactor_seq OWNED BY public.actor.idactor;


--
-- TOC entry 204 (class 1259 OID 24778)
-- Name: amplua; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.amplua (
    idamplua integer NOT NULL,
    name public.amplua_t
);


ALTER TABLE public.amplua OWNER TO root;

--
-- TOC entry 203 (class 1259 OID 24776)
-- Name: amplua_idamplua_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.amplua_idamplua_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.amplua_idamplua_seq OWNER TO root;

--
-- TOC entry 3116 (class 0 OID 0)
-- Dependencies: 203
-- Name: amplua_idamplua_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.amplua_idamplua_seq OWNED BY public.amplua.idamplua;


--
-- TOC entry 206 (class 1259 OID 24789)
-- Name: play; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.play (
    idplay integer NOT NULL,
    name public.play_t,
    author public.name_t
);


ALTER TABLE public.play OWNER TO root;

--
-- TOC entry 215 (class 1259 OID 24894)
-- Name: full_play; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.full_play AS
 SELECT play.idplay,
    play.name,
    play.author
   FROM public.play;


ALTER TABLE public.full_play OWNER TO root;

--
-- TOC entry 210 (class 1259 OID 24821)
-- Name: role; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.role (
    idrole integer NOT NULL,
    name public.name_t,
    ampluaid public.id_t,
    playid public.id_t,
    sexid public.id_t
);


ALTER TABLE public.role OWNER TO root;

--
-- TOC entry 202 (class 1259 OID 24767)
-- Name: sex; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.sex (
    idsex integer NOT NULL,
    sexname public.sex_t
);


ALTER TABLE public.sex OWNER TO root;

--
-- TOC entry 214 (class 1259 OID 24889)
-- Name: full_role; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.full_role AS
 SELECT role.name AS role,
    amplua.name AS amplua,
    play.name AS play,
    sex.sexname AS sex
   FROM (((public.role
     JOIN public.amplua ON (((role.ampluaid)::integer = amplua.idamplua)))
     JOIN public.play ON (((role.playid)::integer = play.idplay)))
     JOIN public.sex ON (((role.sexid)::integer = sex.idsex)));


ALTER TABLE public.full_role OWNER TO root;

--
-- TOC entry 212 (class 1259 OID 24847)
-- Name: staging; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.staging (
    idstaging integer NOT NULL,
    actorid public.id_t,
    roleid public.id_t,
    playdate date NOT NULL,
    directorname public.name_t,
    appointmentdate date NOT NULL,
    removaldate date
);


ALTER TABLE public.staging OWNER TO root;

--
-- TOC entry 213 (class 1259 OID 24885)
-- Name: full_staging; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.full_staging AS
 SELECT actor.name AS actor,
    role.name AS role,
    staging.playdate,
    staging.directorname,
    staging.appointmentdate,
    staging.removaldate
   FROM ((public.staging
     JOIN public.actor ON (((staging.actorid)::integer = actor.idactor)))
     JOIN public.role ON (((staging.roleid)::integer = role.idrole)));


ALTER TABLE public.full_staging OWNER TO root;

--
-- TOC entry 205 (class 1259 OID 24787)
-- Name: play_idplay_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.play_idplay_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.play_idplay_seq OWNER TO root;

--
-- TOC entry 3129 (class 0 OID 0)
-- Dependencies: 205
-- Name: play_idplay_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.play_idplay_seq OWNED BY public.play.idplay;


--
-- TOC entry 209 (class 1259 OID 24819)
-- Name: role_idrole_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.role_idrole_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_idrole_seq OWNER TO root;

--
-- TOC entry 3131 (class 0 OID 0)
-- Dependencies: 209
-- Name: role_idrole_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.role_idrole_seq OWNED BY public.role.idrole;


--
-- TOC entry 201 (class 1259 OID 24765)
-- Name: sex_idsex_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.sex_idsex_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sex_idsex_seq OWNER TO root;

--
-- TOC entry 3133 (class 0 OID 0)
-- Dependencies: 201
-- Name: sex_idsex_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.sex_idsex_seq OWNED BY public.sex.idsex;


--
-- TOC entry 211 (class 1259 OID 24845)
-- Name: staging_idstaging_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.staging_idstaging_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.staging_idstaging_seq OWNER TO root;

--
-- TOC entry 3135 (class 0 OID 0)
-- Dependencies: 211
-- Name: staging_idstaging_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.staging_idstaging_seq OWNED BY public.staging.idstaging;


--
-- TOC entry 216 (class 1259 OID 24898)
-- Name: tr; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tr (
    a character varying,
    b character varying
);


ALTER TABLE public.tr OWNER TO root;

--
-- TOC entry 2937 (class 2604 OID 24803)
-- Name: actor idactor; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.actor ALTER COLUMN idactor SET DEFAULT nextval('public.actor_idactor_seq'::regclass);


--
-- TOC entry 2935 (class 2604 OID 24781)
-- Name: amplua idamplua; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.amplua ALTER COLUMN idamplua SET DEFAULT nextval('public.amplua_idamplua_seq'::regclass);


--
-- TOC entry 2936 (class 2604 OID 24792)
-- Name: play idplay; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.play ALTER COLUMN idplay SET DEFAULT nextval('public.play_idplay_seq'::regclass);


--
-- TOC entry 2938 (class 2604 OID 24824)
-- Name: role idrole; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.role ALTER COLUMN idrole SET DEFAULT nextval('public.role_idrole_seq'::regclass);


--
-- TOC entry 2934 (class 2604 OID 24770)
-- Name: sex idsex; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.sex ALTER COLUMN idsex SET DEFAULT nextval('public.sex_idsex_seq'::regclass);


--
-- TOC entry 2939 (class 2604 OID 24850)
-- Name: staging idstaging; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.staging ALTER COLUMN idstaging SET DEFAULT nextval('public.staging_idstaging_seq'::regclass);


--
-- TOC entry 3100 (class 0 OID 24800)
-- Dependencies: 208
-- Data for Name: actor; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.actor (idactor, name, ampluaid, age, sexid) FROM stdin;
1	Чулпан Хаматова	1	46	2
2	Рената Литвинова	2	55	2
3	Александр Ширвиндт	3	87	1
5	Владимир Кошевой	3	45	1
6	Инга Нагорная	5	24	2
7	Анна Ковальчук	6	44	2
8	Никита Чевычелов	7	20	1
9	Кирилл Головин	5	22	1
10	Федор Гырлов	8	20	1
4	Никита Волков	4	28	1
11	Никита Волков3	4	28	1
12	Никита Волков3	4	28	1
\.


--
-- TOC entry 3096 (class 0 OID 24778)
-- Dependencies: 204
-- Data for Name: amplua; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.amplua (idamplua, name) FROM stdin;
1	Герой
2	Гранд-кокет
3	Главный герой
4	Антагонист
5	Резонер
6	Трагик
7	Злодей
8	Герой-любовник
\.


--
-- TOC entry 3098 (class 0 OID 24789)
-- Dependencies: 206
-- Data for Name: play; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.play (idplay, name, author) FROM stdin;
1	Ревизор	Н.В.Гоголь
2	Горе от ума	А.С.Грибоедов
3	Вишневый сад	А.П.Чехов
4	Бесприданница	А.Н.Островский
5	Ромео и Джульетта	У.Шекспир
6	Гамлет	У.Шекспир
7	Отелло2	У.Шекспир
\.


--
-- TOC entry 3102 (class 0 OID 24821)
-- Dependencies: 210
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.role (idrole, name, ampluaid, playid, sexid) FROM stdin;
1	Иван Хлестаков	3	1	1
2	Александр Чацкий	3	2	1
4	Любовь Раневская	3	3	2
5	Аня	1	3	2
6	Лариса Дмитриевна	3	4	2
8	Джульетта	3	5	2
9	Гамлет	3	6	1
10	Отелло	8	7	1
3	Алексей Молчалин	4	2	1
7	Ромео2	3	5	1
\.


--
-- TOC entry 3094 (class 0 OID 24767)
-- Dependencies: 202
-- Data for Name: sex; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.sex (idsex, sexname) FROM stdin;
1	male
2	female
\.


--
-- TOC entry 3104 (class 0 OID 24847)
-- Dependencies: 212
-- Data for Name: staging; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.staging (idstaging, actorid, roleid, playdate, directorname, appointmentdate, removaldate) FROM stdin;
2	5	2	2022-04-22	Дмитрий Крымов	2022-02-22	\N
3	4	3	2022-04-22	Дмитрий Крымов	2022-02-24	2022-03-01
4	2	4	2021-03-03	Рената Литвинова	2021-12-13	\N
5	1	5	2022-03-28	Рената Литвинова	2022-02-02	\N
6	7	6	2022-05-12	Евгений Каменькович	2022-02-28	\N
7	9	7	2022-04-04	Константин Богомолов	2022-02-15	\N
9	4	9	2022-04-22	Филипп Григорьян	2022-03-02	\N
10	8	3	2022-04-22	Дмитрий Крымов	2022-03-01	\N
11	10	10	2022-05-01	Кама Гинкас	2022-02-25	\N
12	1	8	2022-03-18	Константин Богомолов	2022-02-01	2022-02-14
13	8	7	2022-04-04	Константин Богомолов	2022-01-10	2022-02-09
14	5	1	2022-03-02	Кирилл Серебренников	2022-01-05	2022-01-10
15	3	2	2022-04-22	Дмитрий Крымов	2022-02-02	2022-02-20
1	3	1	2022-03-03	Кирилл Серебренников	2022-01-10	\N
8	6	8	2022-03-18	Константин Богомолов	2022-02-14	2022-03-09
\.


--
-- TOC entry 3105 (class 0 OID 24898)
-- Dependencies: 216
-- Data for Name: tr; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tr (a, b) FROM stdin;
testA	testB
testA	\N
\.


--
-- TOC entry 3137 (class 0 OID 0)
-- Dependencies: 207
-- Name: actor_idactor_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.actor_idactor_seq', 12, true);


--
-- TOC entry 3138 (class 0 OID 0)
-- Dependencies: 203
-- Name: amplua_idamplua_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.amplua_idamplua_seq', 8, true);


--
-- TOC entry 3139 (class 0 OID 0)
-- Dependencies: 205
-- Name: play_idplay_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.play_idplay_seq', 7, true);


--
-- TOC entry 3140 (class 0 OID 0)
-- Dependencies: 209
-- Name: role_idrole_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.role_idrole_seq', 10, true);


--
-- TOC entry 3141 (class 0 OID 0)
-- Dependencies: 201
-- Name: sex_idsex_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.sex_idsex_seq', 2, true);


--
-- TOC entry 3142 (class 0 OID 0)
-- Dependencies: 211
-- Name: staging_idstaging_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.staging_idstaging_seq', 24, true);


--
-- TOC entry 2947 (class 2606 OID 24808)
-- Name: actor actor_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.actor
    ADD CONSTRAINT actor_pkey PRIMARY KEY (idactor);


--
-- TOC entry 2943 (class 2606 OID 24786)
-- Name: amplua amplua_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.amplua
    ADD CONSTRAINT amplua_pkey PRIMARY KEY (idamplua);


--
-- TOC entry 2945 (class 2606 OID 24797)
-- Name: play play_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.play
    ADD CONSTRAINT play_pkey PRIMARY KEY (idplay);


--
-- TOC entry 2949 (class 2606 OID 24829)
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (idrole);


--
-- TOC entry 2941 (class 2606 OID 24775)
-- Name: sex sex_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.sex
    ADD CONSTRAINT sex_pkey PRIMARY KEY (idsex);


--
-- TOC entry 2951 (class 2606 OID 24855)
-- Name: staging staging_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.staging
    ADD CONSTRAINT staging_pkey PRIMARY KEY (idstaging);


--
-- TOC entry 2959 (class 2620 OID 24883)
-- Name: staging staging_trigger; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER staging_trigger BEFORE INSERT OR UPDATE ON public.staging FOR EACH ROW EXECUTE FUNCTION public.staging_trigger();


--
-- TOC entry 2952 (class 2606 OID 24809)
-- Name: actor actor_amplua_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.actor
    ADD CONSTRAINT actor_amplua_fk FOREIGN KEY (ampluaid) REFERENCES public.amplua(idamplua);


--
-- TOC entry 2953 (class 2606 OID 24814)
-- Name: actor actor_sex_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.actor
    ADD CONSTRAINT actor_sex_fk FOREIGN KEY (sexid) REFERENCES public.sex(idsex);


--
-- TOC entry 2954 (class 2606 OID 24830)
-- Name: role role_amplua_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_amplua_fk FOREIGN KEY (ampluaid) REFERENCES public.amplua(idamplua);


--
-- TOC entry 2955 (class 2606 OID 24835)
-- Name: role role_play_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_play_fk FOREIGN KEY (playid) REFERENCES public.play(idplay);


--
-- TOC entry 2956 (class 2606 OID 24840)
-- Name: role role_sex_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_sex_fk FOREIGN KEY (sexid) REFERENCES public.sex(idsex);


--
-- TOC entry 2957 (class 2606 OID 24856)
-- Name: staging staging_actor_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.staging
    ADD CONSTRAINT staging_actor_fk FOREIGN KEY (actorid) REFERENCES public.actor(idactor);


--
-- TOC entry 2958 (class 2606 OID 24861)
-- Name: staging staging_role_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.staging
    ADD CONSTRAINT staging_role_fk FOREIGN KEY (roleid) REFERENCES public.role(idrole);


--
-- TOC entry 3112 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE actor; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.actor TO janedoe;


--
-- TOC entry 3114 (class 0 OID 0)
-- Dependencies: 207
-- Name: SEQUENCE actor_idactor_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.actor_idactor_seq TO janedoe;


--
-- TOC entry 3115 (class 0 OID 0)
-- Dependencies: 204
-- Name: TABLE amplua; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT ON TABLE public.amplua TO janedoe;


--
-- TOC entry 3117 (class 0 OID 0)
-- Dependencies: 203
-- Name: SEQUENCE amplua_idamplua_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.amplua_idamplua_seq TO janedoe;


--
-- TOC entry 3118 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE full_play; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT ON TABLE public.full_play TO janedoe;


--
-- TOC entry 3119 (class 0 OID 0)
-- Dependencies: 215 3118
-- Name: COLUMN full_play.name; Type: ACL; Schema: public; Owner: root
--

GRANT UPDATE(name) ON TABLE public.full_play TO on_update;


--
-- TOC entry 3120 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE sex; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT ON TABLE public.sex TO janedoe;


--
-- TOC entry 3121 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN staging.idstaging; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT(idstaging) ON TABLE public.staging TO janedoe;


--
-- TOC entry 3122 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN staging.actorid; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT(actorid) ON TABLE public.staging TO janedoe;


--
-- TOC entry 3123 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN staging.roleid; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT(roleid) ON TABLE public.staging TO janedoe;


--
-- TOC entry 3124 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN staging.directorname; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT(directorname) ON TABLE public.staging TO janedoe;


--
-- TOC entry 3125 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN staging.appointmentdate; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT(appointmentdate) ON TABLE public.staging TO janedoe;


--
-- TOC entry 3126 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN staging.removaldate; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT(removaldate),UPDATE(removaldate) ON TABLE public.staging TO janedoe;


--
-- TOC entry 3127 (class 0 OID 0)
-- Dependencies: 213
-- Name: TABLE full_staging; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT ON TABLE public.full_staging TO janedoe;


--
-- TOC entry 3128 (class 0 OID 0)
-- Dependencies: 213 3127
-- Name: COLUMN full_staging.appointmentdate; Type: ACL; Schema: public; Owner: root
--

GRANT UPDATE(appointmentdate) ON TABLE public.full_staging TO on_update;


--
-- TOC entry 3130 (class 0 OID 0)
-- Dependencies: 205
-- Name: SEQUENCE play_idplay_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.play_idplay_seq TO janedoe;


--
-- TOC entry 3132 (class 0 OID 0)
-- Dependencies: 209
-- Name: SEQUENCE role_idrole_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.role_idrole_seq TO janedoe;


--
-- TOC entry 3134 (class 0 OID 0)
-- Dependencies: 201
-- Name: SEQUENCE sex_idsex_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.sex_idsex_seq TO janedoe;


--
-- TOC entry 3136 (class 0 OID 0)
-- Dependencies: 211
-- Name: SEQUENCE staging_idstaging_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.staging_idstaging_seq TO janedoe;


-- Completed on 2022-05-27 15:51:13

--
-- PostgreSQL database dump complete
--

