create table Tr (
    A varchar,
    B varchar
);

insert into Tr values
    ('testA', null),
    (null, 'testB');

-- READ UNCOMMITTED

-- потерянные изменения --

--trA
begin;
    set transaction isolation level read uncommitted;
    select current_setting('transaction_isolation');
    update Tr set A = 'testA1' where A is null;
    select * from Tr; --
end;

--trB
begin;
    set transaction isolation level read uncommitted;
    select current_setting('transaction_isolation');
    update Tr set B = 'never' where A is null;
    select * from Tr;
end;

-- грязное чтение --

--trA
begin;
    set transaction isolation level read uncommitted;
    select current_setting('transaction_isolation');
    savepoint before_update;
    update Tr set A = 'testA2' where B is null;
    select * from Tr;
    rollback to before_update;
end;

--trB
begin;
    set transaction isolation level read uncommitted;
    select current_setting('transaction_isolation');
    select * from Tr;
end;


-- READ COMMITTED

-- грязное чтение --

--trA
begin;
    set transaction isolation level read committed;
    select current_setting('transaction_isolation');
    savepoint before_update;
    update Tr set A = 'testA3' where B is null;
    select * from Tr;
    rollback to before_update;
end;

--trB
begin;
    set transaction isolation level read committed;
    select current_setting('transaction_isolation');
    select * from Tr;
end;

-- неповторяющиеся чтения ++

--trA
begin;
    set transaction isolation level read committed ;
    select current_setting('transaction_isolation');
    update Tr set A = 'testA4' where B is null;
end;

--trB
begin;
    set transaction isolation level read committed ;
    select current_setting('transaction_isolation');
    select * from Tr;
    select * from Tr;
end;

-- REPEATABLE READ

-- неповторяющиеся чтения --

--trA
begin;
    set transaction isolation level repeatable read ;
    select current_setting('transaction_isolation');
    update Tr set A = 'testA5' where B is null;
end;

--trB
begin;
    set transaction isolation level repeatable read ;
    select current_setting('transaction_isolation');
    select * from Tr;
    select * from Tr;
end;

-- чтение «фантомов» --

--trA
begin;
    set transaction isolation level repeatable read ;
    select current_setting('transaction_isolation');
    insert into Tr values ('testA6', null);
end;

--trB
begin;
    set transaction isolation level repeatable read ;
    select current_setting('transaction_isolation');
    select A from Tr;
    select A from Tr;
end;

-- SERIALIZABLE

-- чтение «фантомов» --

--trA
begin;
    set transaction isolation level serializable ;
    select current_setting('transaction_isolation');
    insert into Tr values ('testA7', null);
end;

--trB
begin;
    set transaction isolation level serializable ;
    select current_setting('transaction_isolation');
    select A from Tr;
    select A from Tr;
end;
