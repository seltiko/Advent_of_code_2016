drop table if exists temp_input;
create temp table temp_input as 
select '10001001100000001'::text as inputs;

select inputs
	,inputs||'0'||reverse(
		regexp_replace(
			regexp_replace(
				regexp_replace(
					regexp_replace(inputs,'1','zero','g')
					,'0','one','g')
				,'zero','0','g')
			,'one','1','g')
		) as dragon
from temp_input
;

select string_agg(case when same then '1'::text else '0'::text end,'') as checksum 
	,char_length(string_agg(case when same then '1'::text else '0'::text end,'')) as len
from(
select (regexp_matches(inputs,'..','g'))[1] ~ '(\d)\1' as same
	,iter
from(
select '0010000100010100100010000110010100'::text as inputs, 0 as iter
)t
)t2
;

-- drop table if exists santa_dragon;
-- create temp table santa_dragon as
with recursive dragon_santa (dragon) as (
select inputs||'0'||reverse(
		regexp_replace(
			regexp_replace(
				regexp_replace(
					regexp_replace(inputs,'1','zero','g')
					,'0','one','g')
				,'zero','0','g')
			,'one','1','g')
		) as dragon
from temp_input
union all
select dragon||'0'||reverse(
		regexp_replace(
			regexp_replace(
				regexp_replace(
					regexp_replace(dragon,'1','zero','g')
					,'0','one','g')
				,'zero','0','g')
			,'one','1','g')
		) as dragon
from dragon_santa
where char_length(dragon) <= 35651584
)

-- select left(dragon,35651584) as checksum,char_length(left(dragon,35651584)) as len
-- -- into temp santa_dragon
-- from dragon_santa
-- where char_length(left(dragon,35651584)) = 35651584
-- -- 
-- ;


-- with recursive dragon_sum (checksum, len, iter) as (
,dragon_sum (checksum, len, iter) as (
-- select *,0 as iter
-- from santa_dragon
select left(dragon,35651584) as checksum,char_length(left(dragon,35651584)) as len, 0 as iter
from dragon_santa
where char_length(left(dragon,35651584)) = 35651584
union all
select string_agg(case when same then '1'::text else '0'::text end,'') as checksum
	,char_length(string_agg(case when same then '1'::text else '0'::text end,'')) as len
	,iter + 1 as iter
	
from(
select (regexp_matches(checksum,'..','g'))[1] ~ '(\d)\1' as same
	,iter
from(
select checksum, iter
from dragon_sum
where len%2 = 0 
)t
)t2
-- where iter + 1 < 9
group by iter + 1 
)

select * from dragon_sum
where len%2 = 1
;