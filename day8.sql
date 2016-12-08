drop table if exists temp_input;
create temp table temp_input as
select 
'rect 1x1
rotate row y=0 by 5
rect 1x1
rotate row y=0 by 6
rect 1x1
rotate row y=0 by 5
rect 1x1
rotate row y=0 by 2
rect 1x1
rotate row y=0 by 5
rect 2x1
rotate row y=0 by 2
rect 1x1
rotate row y=0 by 4
rect 1x1
rotate row y=0 by 3
rect 2x1
rotate row y=0 by 7
rect 3x1
rotate row y=0 by 3
rect 1x1
rotate row y=0 by 3
rect 1x2
rotate row y=1 by 13
rotate column x=0 by 1
rect 2x1
rotate row y=0 by 5
rotate column x=0 by 1
rect 3x1
rotate row y=0 by 18
rotate column x=13 by 1
rotate column x=7 by 2
rotate column x=2 by 3
rotate column x=0 by 1
rect 17x1
rotate row y=3 by 13
rotate row y=1 by 37
rotate row y=0 by 11
rotate column x=7 by 1
rotate column x=6 by 1
rotate column x=4 by 1
rotate column x=0 by 1
rect 10x1
rotate row y=2 by 37
rotate column x=19 by 2
rotate column x=9 by 2
rotate row y=3 by 5
rotate row y=2 by 1
rotate row y=1 by 4
rotate row y=0 by 4
rect 1x4
rotate column x=25 by 3
rotate row y=3 by 5
rotate row y=2 by 2
rotate row y=1 by 1
rotate row y=0 by 1
rect 1x5
rotate row y=2 by 10
rotate column x=39 by 1
rotate column x=35 by 1
rotate column x=29 by 1
rotate column x=19 by 1
rotate column x=7 by 2
rotate row y=4 by 22
rotate row y=3 by 5
rotate row y=1 by 21
rotate row y=0 by 10
rotate column x=2 by 2
rotate column x=0 by 2
rect 4x2
rotate column x=46 by 2
rotate column x=44 by 2
rotate column x=42 by 1
rotate column x=41 by 1
rotate column x=40 by 2
rotate column x=38 by 2
rotate column x=37 by 3
rotate column x=35 by 1
rotate column x=33 by 2
rotate column x=32 by 1
rotate column x=31 by 2
rotate column x=30 by 1
rotate column x=28 by 1
rotate column x=27 by 3
rotate column x=26 by 1
rotate column x=23 by 2
rotate column x=22 by 1
rotate column x=21 by 1
rotate column x=20 by 1
rotate column x=19 by 1
rotate column x=18 by 2
rotate column x=16 by 2
rotate column x=15 by 1
rotate column x=13 by 1
rotate column x=12 by 1
rotate column x=11 by 1
rotate column x=10 by 1
rotate column x=7 by 1
rotate column x=6 by 1
rotate column x=5 by 1
rotate column x=3 by 2
rotate column x=2 by 1
rotate column x=1 by 1
rotate column x=0 by 1
rect 49x1
rotate row y=2 by 34
rotate column x=44 by 1
rotate column x=40 by 2
rotate column x=39 by 1
rotate column x=35 by 4
rotate column x=34 by 1
rotate column x=30 by 4
rotate column x=29 by 1
rotate column x=24 by 1
rotate column x=15 by 4
rotate column x=14 by 1
rotate column x=13 by 3
rotate column x=10 by 4
rotate column x=9 by 1
rotate column x=5 by 4
rotate column x=4 by 3
rotate row y=5 by 20
rotate row y=4 by 20
rotate row y=3 by 48
rotate row y=2 by 20
rotate row y=1 by 41
rotate column x=47 by 5
rotate column x=46 by 5
rotate column x=45 by 4
rotate column x=43 by 5
rotate column x=41 by 5
rotate column x=33 by 1
rotate column x=32 by 3
rotate column x=23 by 5
rotate column x=22 by 1
rotate column x=21 by 2
rotate column x=18 by 2
rotate column x=17 by 3
rotate column x=16 by 2
rotate column x=13 by 5
rotate column x=12 by 5
rotate column x=11 by 5
rotate column x=3 by 5
rotate column x=2 by 5
rotate column x=1 by 5'::text as inputs
;




drop table if exists screen_alt;
create temp table screen_alt as
select id
	,row_number() over(partition by (id-1)/50) - 1 as col
	,(id-1)/50 as roe
	,light
from(
select generate_series(1,50*6,1) as id
	,0 as light
)t
;
select * from screen_alt
;







create or replace function jfoster1.rect(int, int) returns void  as $$
	update screen_alt set light = 1
		where  col+1 <= $1
			and roe + 1 <= $2
	;
	$$
	language sql;

create or replace function jfoster1.rotrow(int, int) returns void  as $$
	update screen_alt set light = new_light
		from
		(select s.col as col_update
			,s2.light as new_light
		from screen_alt s
		left join screen_alt s2
			on (s2.col + $2)%50 = s.col
			and s2.roe = $1
		where s.roe = $1
-- 			and s.roe = screen_alt.roe
		)t
		where screen_alt.roe = $1
			and screen_alt.col = t.col_update
	;
	$$
	language sql;

create or replace function jfoster1.rotcol(int, int) returns void  as $$
	update screen_alt set light = new_light
		from
		(select s.roe as roe_update
			,s2.light as new_light
		from screen_alt s
		left join screen_alt s2
			on (s2.roe + $2)%6 = s.roe
			and s2.col = $1
		where s.col = $1
-- 			and s.roe = screen_alt.roe
		)t
		where screen_alt.col = $1
			and screen_alt.roe = t.roe_update
	;
	$$
	language sql;


-- select jfoster1.rect(3,5);
-- select jfoster1.rotrow(1,5);
-- select jfoster1.rotrow(0,1);
-- select * from screen_alt where col = 0 order by id;







drop table if exists parsed;
create temp table parsed as
select 
	row_number() over() as id
	,case 
		when inst ~* '^rect'
		then 'rect'
		when inst ~* '^rotate row'
		then 'rotate_row'
		when inst ~* '^rotate column'
		then 'rotate_col'
		end as inst_type
	,substring(inst from '\d+')::int as num1
	,reverse(substring(reverse(inst) from '\d+'))::int as num2
	,inst
from(
select regexp_split_to_table(inputs,'\n') as inst
from temp_input
-- limit 100
)t
-- limit 142
;

with recursive act(id,inst_type,num1,num2,inst,counter) as(
select id,inst_type,num1,num2,inst,1 as counter
	,case when inst_type = 'rect'
		then jfoster1.rect(num1,num2)
		when inst_type = 'rotate_row'
		then jfoster1.rotrow(num1,num2)
		when inst_type = 'rotate_col'
		then jfoster1.rotcol(num1,num2)
		end
	,(select sum(light) from screen_alt) as cur_sum
from parsed
where id = 1

union all

select id,inst_type,num1,num2,inst, counter + 1 as counter
	,case when inst_type = 'rect'
		then jfoster1.rect(num1,num2)
		when inst_type = 'rotate_row'
		then jfoster1.rotrow(num1,num2)
		when inst_type = 'rotate_col'
		then jfoster1.rotcol(num1,num2)
		end
	,(select sum(light) from screen_alt) as cur_sum
from(
select p.*,a.counter
from act a
inner join parsed p
	on p.id = a.id + 1
)t
where id = 1 + counter
)

select * from act
;


-- create temp table temp_screen_holder as
select * from screen_alt order by 1;
select * from temp_screen_holder where col = 3 order by 1;

select sum(light) from screen_alt;






select thing as col
	,(
		select case when s9.light = 1 then '|||||' end
		from screen_alt s9
		where s9.col = thing
			and s9.roe = 0
		) as roe1
	,(
		select case when s9.light = 1 then '|||||' end
		from screen_alt s9
		where s9.col = thing
			and s9.roe = 1
		) as roe2
	,(
		select case when s9.light = 1 then '|||||' end
		from screen_alt s9
		where s9.col = thing
			and s9.roe = 2
		) as roe3
	,(
		select case when s9.light = 1 then '|||||' end
		from screen_alt s9
		where s9.col = thing
			and s9.roe = 3
		) as roe4
	,(
		select case when s9.light = 1 then '|||||' end
		from screen_alt s9
		where s9.col = thing
			and s9.roe = 4
		) as roe5
	,(
		select case when s9.light = 1 then '|||||' end
		from screen_alt s9
		where s9.col = thing
			and s9.roe = 5
		) as roe6
	,0 as counter
from (select generate_series(49,0,-1) as thing) t
;

	