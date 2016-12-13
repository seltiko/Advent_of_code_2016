drop table if exists temp_input;
create temp table temp_input as
select
'The first floor contains a strontium generator, a strontium-compatible microchip, a plutonium generator, and a plutonium-compatible microchip.
The second floor contains a thulium generator, a ruthenium generator, a ruthenium-compatible microchip, a curium generator, and a curium-compatible microchip.
The third floor contains a thulium-compatible microchip.
The fourth floor contains nothing relevant.'::text as inputs
;


drop table if exists state_holder;
create temp table state_holder as
select row_number() over() as id
	,*
from(
select null::int as floor
	,t.elem[1]
    ,c.chip_flg
from(
select regexp_matches(inputs,'a (.{0,10}) generator','g') as elem
from temp_input
union select array['elevator']
order by 1
)t
-- inner join (select generate_series(1,4,1) floor_id) f
-- 	on true
inner join (select generate_series(0,1,1) chip_flg) c
	on not(chip_flg = 1 and t.elem[1] = 'elevator')
order by floor
	,chip_flg
	,t.elem[1]
)t
;



drop table if exists stat;
create temp table stat as
select
	s.id
    ,coalesce(t2.floor,t3.floor,s.floor) as floor
    ,s.elem
    ,s.chip_flg
    ,''::text as blockchain
    ,0::int as rides
    ,0 as next_stepped
    ,0 as blocknumber
--    ,t2.*
from state_holder s
left join(
    select floor
        ,floors
        ,regexp_matches(floors,'a (.{0,10}) generator','g') as elem_gen
    from(
    select row_number() over () as floor
        ,*
    from(
    select
        regexp_split_to_table(inputs,'\n') as floors
    from temp_input t
    )t
    )t
    )t2
	on ((t2.elem_gen[1] = s.elem and s.chip_flg = 0))
--     and t2.floor_id = s.floor_id
left join(
    select floor
        ,floors
        ,regexp_matches(floors,'a (.{0,10})-compatible','g') as elem_chip
    from(
    select row_number() over () as floor
        ,*
    from(
    select
        regexp_split_to_table(inputs,'\n') as floors
    from temp_input t
    )t
    )t
    )t3
	on ((t3.elem_chip[1] = s.elem and s.chip_flg = 1))
--     and t3.floor_id = s.floor_id
order by id
;

update stat set floor = 1
where elem = 'elevator'
;

select * 
from stat;



drop table if exists all_stats;
create temp table all_stats as
select * from stat
;


drop table if exists search_stats;
create temp table search_stats as
select * from stat
;

-- insert into all_stats 
-- select id
-- 	,floor
-- 	,elem
-- 	,chip_flg
-- 	,'test' as blockchain
-- 	,1 as rides
-- from stat;

--Remove duplicates, mostly...
delete from all_stats
where blockchain = 
(select bad
from(
select a.blockchain as bad,a2.blockchain,count(1)
from all_stats a
inner join all_stats a2
	on a2.id = a.id
	and a.floor = a2.floor
	and a.blockchain <> a2.blockchain
	and a.rides > a2.rides
group by 1,2
having count(1) = 11
)t
)
;

create temp sequence blocknumber start 1;



create or replace function pg_temp.mover(dir int, el1 text, obj1 int, el2 text, obj2 int)
returns void as $$
-- insert into all_stat
with next_stat as
(
select id
	,case when elem = 'elevator' then floor + dir
		when elem = el1 and chip_flg = obj1 then floor + dir
		when elem = el2 and chip_flg = obj2 then floor + dir
		else floor end as floor
	,elem
	,chip_flg
	,blockchain||coalesce(dir::text,'')||coalesce(el1,'')||coalesce(obj1::text,'')||coalesce(el2,'')||(case when coalesce(el2,'') = '' then '' else obj2::text end) as blockchain
	,rides + 1 as rides
	,0 as next_stepped
    ,b.blocknumber
from stat
inner join (select nextval('blocknumber') as blocknumber)b
    on true
)
insert into all_stats
select *
from next_stat
where not exists(
	select 1
	from next_stat
	where floor > 4 or floor < 1
	)
	and not exists(
		select 1
		from next_stat n
		inner join next_stat n2
			on n2.floor = n.floor
			and n2.chip_flg = 0
			and n2.elem <> 'elevator'
			and n2.elem <> n.elem
		where n.chip_flg = 1
			and not exists(
				select 1
				from next_stat n3
				where n3.elem = n.elem
					and n3.chip_flg = 0
					and n3.floor = n.floor
				)
		)
;
$$
language sql
;


-- select pg_temp.mover(1,'strontium'::text,0,'strontium'::text,1)
-- ;
select * from all_stats;

create or replace function pg_temp.do_everything()
returns void as $$

truncate stat;
insert into stat (
select *
from all_stats
where blocknumber = (select blocknumber
		from(
		select distinct blocknumber
			,rides
		from all_stats
		where next_stepped = 0
		order by rides asc
			,blocknumber asc
		limit 1
		)t)
)
;

update  all_stats set next_stepped = 1
where blocknumber = (select blocknumber
		from(
		select distinct blocknumber
			,rides
		from all_stats
		where next_stepped = 0
		order by rides asc
			,blocknumber asc
		limit 1
		)t)
;

with steps as
(
select distinct 
    s.elem as elem1
	,s.chip_flg as chip_flg1
	,s2.elem as elem2
	,s2.chip_flg as chip_flg2
	,d.direction 
from stat s
left join (
		select *
		from stat
		where floor = (
			select floor 
			from stat
			where elem = 'elevator'
			)
			and elem <> 'elevator'
		union
		select null, null, null, null, null, null, null, null
		)s2
	on not(s2.elem = s.elem and s2.chip_flg = s.chip_flg)
    and case when s2.elem = s.elem then s2.chip_flg < s.chip_flg else s2.elem < s.elem end
	or s2.id is null
left join (select generate_series(-1,1,2) direction)d
	on s2.id is null
	or (s2.id is not null and d.direction = 1)
where s.floor = (
	select floor 
	from stat
	where elem = 'elevator'
	)
	and s.elem <> 'elevator'
)
select pg_temp.mover(direction,elem1,chip_flg1,elem2,chip_flg2)
from steps t
;




-- --Remove duplicates, mostly...
with dedup as(
select a.floor as chip_floor
    ,a2.floor as gen_floor
    ,a.blocknumber
    ,count(1) as num
from all_stats a
left join all_stats a2
    on a2.blocknumber = a.blocknumber
    and a2.elem = a.elem
    and (a2.chip_flg = 0)
where a.chip_flg = 1
group by 1,2,3
)
delete from all_stats
where blocknumber in 
(select block1
 from(
    select block1
	,block2
	,sum(num)
from(
select d.blocknumber as block1
	,d2.blocknumber as block2
	,d.num
from dedup d
left join dedup d2
	on d2.chip_floor = d.chip_floor
    and d2.gen_floor = d.gen_floor
    and d2.num = d.num
    and d2.blocknumber <> d.blocknumber
    and d2.blocknumber < d.blocknumber
where (
    	select floor
    	from all_stats
    	where elem = 'elevator'
    		and blocknumber = d.blocknumber) = 
    (
    	select floor
    	from all_stats
    	where elem = 'elevator'
    		and blocknumber = d2.blocknumber)
)t
group by 1,2
having sum(num) = 5
)t
)
;

$$
language sql
;



select pg_temp.do_everything();

select * from all_stats;
--truncate search_stats;
--insert into search_stats
select * from search_stats;

with recursive doit(blah,iter) as (
select pg_temp.do_everything() as blah
	,0 as iter
union all
select pg_temp.do_everything() as blah
	,iter + 1 as iter
from doit
where iter < 100
)
select * from doit
;


select blockchain,sum(floor),max(rides)
from all_stats
where next_stepped = 0
--	and rides = 4
group by 1
--having sum(floor) < 25
order by 2 desc
having sum(floor) = 44

-- select * from all_stats where blockchain is null;
--drop table if exists unpruned1;
create temp table unpruned1 as
select *
from all_stats;

--delete from all_stats
update all_stats set next_stepped = 1
where blockchain in (
    select blockchain
    from(
    select blockchain,sum(floor),max(rides)
    from all_stats
--    where next_stepped = 0
    group by 1
    order by 2 desc
        )t
    where t.sum < 27
--    	and t.max = 5
   )