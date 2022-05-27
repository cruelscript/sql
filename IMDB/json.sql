create table if not exists persons
(
    id serial primary key,
    data jsonb not null
);

create extension if not exists plpython3u;

create or replace procedure insertJSON()
as $json$

    import json
    import csv
    plan = plpy.prepare("insert into persons(data) values ($1)", ["jsonb"])

    titles = {}
    with open('D:\\ed\\bd\\sql\\IMDB\\titles.csv') as t:
        reader = csv.reader(t, delimiter='|')
        next(reader)
        for row in reader:
            titles[row[0]] = [row[2], row[5]]

    nconst = ""
    primaryName = ""
    roles = []
    birthDate = ""
    deathDate = ""
    with open('D:\\ed\\bd\\sql\\IMDB\\actors_extended.csv') as a:
        reader = csv.reader(a, delimiter='|')
        next(reader)
        index = 0
        for row in reader:
            if index > 300000:
                break
            newIndex = row[0]
            if newIndex != nconst:
                if nconst != "":
                    jsonRow = {"nconst": index, "primaryName": primaryName, "roles": roles, "birthDate": birthDate, "deathDate": deathDate }
                    plpy.info(jsonRow)
                    plpy.execute(plan, [json.dumps(jsonRow)])
                    index += 1
                nconst = newIndex
                roles = []
            try:
                title = titles[row[5]]
            except:
                title = ["Null", "Null"]
            role = {"title": title[0], "year": title[1]}
            roles.append(role)
            primaryName = row[1]
            birthDate = row[2]
            deathDate = row[3]

$json$ language plpython3u;

call insertJSON();

select * from "persons";

select data ->> 'nconst' from persons;
select name, amount
    from (select *
          from (select data ->> 'primaryName' as name,
                       json_array_length(data::json -> 'roles') as amount
                    from persons) as query) as "q*";

select data ->> 'primaryName' as name,
       json_array_length(data::json -> 'roles') as amount
            from persons
                where json_array_length(data::json -> 'roles') = 3;

select data ->> 'primaryName' as name from persons
    where data @@ '$.roles[*].title == "Star Wars"';

select * from persons where data @> '{"primaryName" : "Mark Hamill"}';

select name, birthYear, deathYear, amount
    from (select * from (select data ->> 'primaryName'                   as name,
                                data ->> 'birthDate'                     as birthYear,
                                data ->> 'deathDate'                     as deathYear,
                                json_array_length(data::json -> 'roles') as amount
                            from persons) as q1) as q2
        where birthYear = '1960';

explain analyse select data->>'primaryName' from persons where data->>'nconst' = '259';

select
    data ->> 'primaryName' as name,
    data ->> 'deathDate' as deathYear,
    data #>> '{roles, 1, title}' as title
from persons;


select pg_size_pretty(pg_total_relation_size('persons')) as size;
select pg_total_relation_size('persons');
select pg_current_wal_lsn(), pg_current_wal_insert_lsn();

explain analyse select data from persons where data @> '{"primaryName": "Brigitte Bardot"}';


update persons
    set data = data - 'roles' || '{"roles":  [{"year": "1944", "title": "Woman Without a Soul"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}, {"year": "1945", "title": "Una mujer que no miente"}]}'
        where data->>'primaryName' = 'Brigitte Bardot';

select pg_total_relation_size('persons');
explain analyse
update persons
    set data = data - 'primaryName' || '{"primaryName": "Brigitte Bardot3"}'
        where data->>'primaryName' = 'Bridgitte Bardot2';

explain analyse
update persons
    set data = data - 'primaryName' || '{"primaryName": "Mark Hamill"}'
        where data->>'primaryName' = 'Mark Hamilll';

create or replace procedure selectFromPersons()
as
$$
import re

f = open("D:\\ed\\bd\\sql\\IMDB\\result.txt", "a")
for id in range(1, 100000):
    cursor = plpy.cursor(f'explain analyze select "persons"."data"->\'primaryName\' from \"persons\" where "data"->>\'nconst\'= \'{id}\'')
    f.write(str(re.findall(r"\d+\.\d+", str(list(cursor)[-1]["QUERY PLAN"]))[0]) + "\n")
    cursor = plpy.cursor(f'select length("persons"."data"::text) from "persons" where "data"->>\'nconst\' = \'{id}\'')
    f.write(str(list(cursor)[0]["length"]) + "\n")
f.close()
$$ language plpython3u;

call selectFromPersons();
