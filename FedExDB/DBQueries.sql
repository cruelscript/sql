create index index_retail_center on ShippedItem(retail_id);
create index index_destination on ShippedItem(destination);
drop index index_retail_center, index_destination;

explain (analyze, buffers, timing, format json)
select * from ShippedItem
    where retail_id > 14000 and
          destination like 'The Cottage In The Wall, Dawley Road, Hayes';


create index index_item on ShippedItem using hash(id_item);
create index index_event on TransportationEvent using hash(id_event);
create index index_type on TransportationEvent(type);
create index index_insurance_amt on ShippedItem (insurance_amt);
drop index index_item, index_event, index_type, index_insurance_amt;

explain (analyze, buffers, timing, format json)
select * from ItemTransportation
    join ShippedItem SI on ItemTransportation.item_id = SI.id_item
    join TransportationEvent TE on ItemTransportation.event_id = TE.id_event
        where TE.type like 'Accepted' and SI.insurance_amt > 100;


create extension btree_gin;
create extension btree_gist;

create index index_delivery on TransportationEvent using gist(to_tsvector('english', "delivery_route"));
drop index index_delivery;

explain (analyze, buffers, timing, format json)
select * from TransportationEvent
    where to_tsvector('english', "delivery_route") @@ plainto_tsquery('London - Birmingham')
        limit 10;


create index index_delivery on TransportationEvent
    using gin(to_tsvector('english', "delivery_route"));
drop index index_delivery;

explain (analyze, buffers, timing, format json)
select * from TransportationEvent
    where to_tsvector('english', "delivery_route") @@ plainto_tsquery('London - Birmingham')
        limit 10;


explain (analyze, buffers, timing, format json)
select * from ShippedItem
    where retail_id < 14000;

explain (analyze, buffers, timing, format json)
select * from ShippedItemPartition
    where retail_id < 14000;