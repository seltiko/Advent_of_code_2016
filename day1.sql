
drop table if exists temp_input;
create temp table temp_input as
select 
'R1, L4, L5, L5, R2, R2, L1, L1, R2, L3, R4, R3, R2, L4, L2, R5, L1, R5, L5, L2, L3, L1, R1, R4, R5, L3, R2, L4, L5, R1, R2, L3, R3, L3, L1, L2, R5, R4, R5, L5, R1, L190, L3, L3, R3, R4, R47, L3, R5, R79, R5, R3, R1, L4, L3, L2, R194, L2, R1, L2, L2, R4, L5, L5, R1, R1, L1, L3, L2, R5, L3, L3, R4, R1, R5, L4, R3, R1, L1, L2, R4, R1, L2, R4, R4, L5, R3, L5, L3, R1, R1, L3, L1, L1, L3, L4, L1, L2, R1, L5, L3, R2, L5, L3, R5, R3, L4, L2, R2, R4, R4, L4, R5, L1, L3, R3, R4, R4, L5, R4, R2, L3, R4, R2, R1, R2, L4, L2, R2, L5, L5, L3, R5, L5, L1, R4, L1, R1, L1, R4, L5, L3, R4, R1, L3, R4, R1, L3, L1, R1, R2, L4, L2, R1, L5, L4, L5'::text as inputs
;

drop table if exists temp_parsed;
create temp table temp_parsed (
	id integer primary key,
	directions text
	)
;

insert into temp_parsed (id,directions)
select 
generate_series(1,157,1),
unnest(string_to_array(inputs,', ')) directions
from temp_input

;

drop table if exists full_parse;
create temp table full_parse as
select id
	,directions
	,regexp_replace(directions,'[RL]','')::int as distance
	--comment out for final stop
	,generate_series(1,regexp_replace(directions,'[RL]','')::int,1) as steps
	,1 as step_size
	,(sum(direction_change) over (order by id))%4 as orientation
from (
select *
	,case when directions ~ 'R' then 1 else -1 end as direction_change
-- 	,lag(directions, 1) over()
from temp_parsed
)t
;

/*
north:0
east:1,-3
south:2,-2
west:3,-1
*/


drop table if exists steps;
create temp table steps as
select id,directions,orientation,distance
	,sum(case when orientation = 0 then 1
		when orientation in (2,-2) then -1* 1 else 0 end) over(order by id,steps) as north_south
	,sum(case when orientation in (1,-3) then 1
		when orientation in (3,-1) then -1 * 1 else 0 end) over(order by id,steps) as east_west
	,abs(sum(case when orientation = 0 then 1
		when orientation in (2,-2) then -1* 1 else 0 end) over(order by id,steps))+
	abs(sum(case when orientation in (1,-3) then 1
		when orientation in (3,-1) then -1 * 1 else 0 end) over(order by id,steps)) as total_grid
from full_parse
;


select s.*
	,s2.id
from steps s
inner join steps s2
	on s2.id > s.id
	and s2.north_south = s.north_south
	and s2.east_west = s.east_west
order by s2.id
;


