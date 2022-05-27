create table if not exists RetailCenter (
    id_retail serial primary key,
    type varchar(255) not null,
    address varchar(255) not null
);

create table if not exists ShippedItem (
    id_item serial primary key,
    retail_id int not null references RetailCenter(id_retail),
    weight numeric(19, 0) not null,
    dimension numeric(19, 0) not null,
    insurance_amt numeric(19, 0) not null,
    destination varchar(255) not null,
    delivery_date timestamp not null
);

create table if not exists TransportationEvent (
    id_event serial primary key,
    type varchar (255) not null,
    delivery_route varchar(255) not null
);

create table if not exists ItemTransportation (
    event_id int not null references TransportationEvent(id_event),
    item_id int not null references ShippedItem(id_item)
);

create extension if not exists plpython3u;

create or replace function fill_retail(id integer, file_path varchar(255))
    returns boolean
as $fill_retail$
    if (id <= 0) or (len(file_path) == 0):
        return False

    sql = "insert into RetailCenter(type, address) values "

    file_lines = 0
    with open(file_path, "r") as file:
        for line in file:
            line = line.rstrip('\n')
            sql += f"({line}),"
            file_lines += 1
    sql = sql[:-1]
    sql += ";"

    plan = plpy.prepare(sql)
    insert_id = 1
    if id > file_lines:
        insert_id = id // file_lines
    for _ in range(insert_id):
        plpy.execute(plan)
    return True

$fill_retail$ language plpython3u;


create or replace function fill_item(id integer, file_path varchar(255))
    returns boolean
as $fill_item$

    import random
    from datetime import datetime, timedelta

    if id <= 0 or len(file_path) == 0:
        return False

    num_str = 10000

    retail_select = f"select id_retail from RetailCenter order by random() limit $1;"
    sql = "insert into ShippedItem(retail_id, weight, dimension, insurance_amt, destination, delivery_date) values "

    retail_plan = plpy.prepare(retail_select, ["int"])
    raw_id = plpy.execute(retail_plan, [num_str])

    def generate_data():
        retail_id = raw_id[random.randint(0, len(raw_id) - 1)]["id_retail"]
        weight = random.uniform(0, num_str)
        dimension = random.uniform(0, num_str)
        insurance_amt = random.uniform(0, num_str)
        destination = destination_dict[
            random.randint(0, len(destination_dict) - 1)
        ]
        delta = datetime.strptime(
            "1/1/2035 0:00",
            "%m/%d/%Y %H:%M") - datetime.now()
        delta_sec = (delta.days * 24 * 60 * 60) + delta.seconds
        rand_sec = random.randrange(delta_sec)
        delivery_date = datetime.strptime("1/1/2022 0:00", "%m/%d/%Y %H:%M") + timedelta(seconds = rand_sec)

        return str(
            f"('{retail_id}', '{weight}', '{dimension}', '{insurance_amt}', '{destination}', '{delivery_date}')"
        )

    file_lines = 0
    destination_dict = []
    with open(file_path, "r") as file:
        for line in file:
            line = line.rstrip('\n')
            destination_dict.append(line)
            file_lines += 1

    insert_id = 1
    if id > num_str:
        insert_id = id // num_str
    else:
        num_str = id

    for _ in range(insert_id):
        temp_sql = sql
        raw_id = plpy.execute(retail_plan, [num_str])
        for _ in range(num_str):
            temp_sql += generate_data() + ","
        temp_sql = temp_sql[:-1]
        temp_sql += ";"
        plan = plpy.prepare(temp_sql)
        plpy.execute(plan)
    return True

$fill_item$ language plpython3u;


create or replace function fill_event(id integer)
    returns boolean
as $fill_event$

    import random

    if id <= 0:
        return False

    sql = "insert into TransportationEvent(type, delivery_route) values "
    types = [
        "Received information about package", "Customs declaration",
        "Cancelled", "Accepted", "In transit", "Arrived at the sorting station",
        "Departed from the sorting station", "Arrived at destination point"
    ]
    cities = [
        "London", "Birmingham", "Manchester", "Leeds", "Newcastle", "Birstall",
        "Glasgow", "Liverpool", "Portsmouth", "Southampton", "Nottingham",
        "Bristol", "Sheffield", "Kingston upon Hull", "Leicester", "Edinburgh",
        "Caerdydd", "Stoke-on-Trent", "Coventry", "Reading", "Belfast", "Derby",
        "Plymouth", "Wolverhampton", "Abertawe", "Milton Keynes", "Aberdeen",
        "Norwich", "Luton", "Islington", "Swindon", "Croydon", "Basildon",
        "Bournemouth", "Worthing", "Ipswich", "Middlesbrough", "Sunderland"
    ]

    def generate_data():
        type = types[random.randint(0, len(types) - 1)]
        delivery_route = cities[random.randint(
            0,
            len(cities) - 1)] + " - " + cities[random.randint(
                0,
                len(cities) - 1)]
        return str(f"('{type}', '{delivery_route}')")

    insert_id = 1
    num_str = 1000
    if id > num_str:
        insert_id = id // num_str
    else:
        num_str = id

    for _ in range(insert_id):
        temp_sql = sql
        for _ in range(num_str):
            temp_sql += generate_data() + ","
        temp_sql = temp_sql[:-1]
        temp_sql += ";"

        plan = plpy.prepare(temp_sql)
        plpy.execute(plan)

    return True

$fill_event$ language plpython3u;


create or replace function fill_transportation(id integer)
    returns boolean
as $fill_transportation$

    if id <= 0:
        return False

    item = "select id_item from ShippedItem order by random() limit $1;"
    event = "select id_event from TransportationEvent order by random() limit $1;"
    sql = "insert into ItemTransportation(event_id, item_id) values "

    event_plan = plpy.prepare(event, ["int"])
    item_plan = plpy.prepare(item, ["int"])

    def generate_data(num_str: int):
        raw_event_ids = plpy.execute(event_plan, [num_str])
        event_ids = [x["id_event"] for x in raw_event_ids]

        raw_item_ids = plpy.execute(item_plan, [num_str])
        item_ids = [x["id_item"] for x in raw_item_ids]

        return (event_ids, item_ids)

    insert_id = 1
    num_str = 1000
    if id > num_str:
        insert_id = id // num_str
    else:
        num_str = id

    for _ in range(insert_id):
        temp_sql = sql
        for event_id, item_id in zip(*generate_data(num_str)):
            temp_sql += f"('{event_id}', '{item_id}'),"
        temp_sql = temp_sql[:-1]
        temp_sql += ";"

        plan = plpy.prepare(temp_sql)
        plpy.execute(plan)

    return True

$fill_transportation$ language plpython3u;


do $$
begin
    perform fill_retail(1000000, 'D:\\ed\\bd\\sql\\FedExDB\\RetailCenterDataset.txt');
    select count(*) from RetailCenter;

    perform fill_event(1000000);
    select count(*) from TransportationEvent;

    perform fill_item(10000000, 'D:\\ed\\bd\\sql\\FedExDB\\ShippingItemDataset.txt');
    select count(*) from ShippedItem;

    perform fill_transportation(1000000);
    select count(*) from ItemTransportation;
end $$;


create table if not exists ShippedItemPartition (
    like ShippedItem including all
) partition by range(id_item);

create table it_1m partition of ShippedItemPartition
    for values from (0) to (1000000);

create table it_2m partition of ShippedItemPartition
    for values from (1000000) to (2000000);

create table it_3m partition of ShippedItemPartition
    for values from (2000000) to (3000000);

create table it_4m partition of ShippedItemPartition
    for values from (3000000) to (4000000);

create table it_5m partition of ShippedItemPartition
    for values from (4000000) to (5000000);

create table it_6m partition of ShippedItemPartition
    for values from (5000000) to (6000000);

create table it_7m partition of ShippedItemPartition
    for values from (6000000) to (7000000);

create table it_8m partition of ShippedItemPartition
    for values from (7000000) to (8000000);

create table it_9m partition of ShippedItemPartition
    for values from (8000000) to (9000000);

create table it_10m partition of ShippedItemPartition
    for values from (9000000) to (10000001);

insert into ShippedItemPartition
    select * from ShippedItem;

