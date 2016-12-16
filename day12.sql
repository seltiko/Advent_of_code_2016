drop table if exists santa;
create temp table santa as
select
'cpy 1 a
cpy 1 b
cpy 26 d
jnz c 2
jnz 1 5
cpy 7 c
inc d
dec c
jnz c -2
cpy a c
inc a
dec b
jnz b -2
cpy c b
dec d
jnz d -6
cpy 18 c
cpy 11 d
inc a
dec d
jnz d -2
dec c
jnz c -5'::text inputs
;


drop table if exists santa_parse;
create temp table santa_parse as
select row_number() over() as id
	,inst
	,0 as a
	,0 as b
	,1 as c
	,0 as d
	,0 as pos
-- 	,substring(inst,'-?\d+$')
	,inst ~ '^cpy \w c'
from(
select regexp_split_to_table(inputs,'\n') as inst
from santa
)t
;

with recursive santa_values (id,inst,a,b,c,d,pos) as (
select id
	,inst
	,case 
		when inst ~ '^cpy \d+ a' then substring(inst,'\d+')::int + a
		when inst ~ '^inc a' then a + 1
		when inst ~ '^dec a' then a - 1
		else a end as a
	,case 
		when inst ~ '^cpy \d+ b' then substring(inst,'\d+')::int + b
		when inst ~ '^inc b' then b + 1
		when inst ~ '^dec b' then b - 1
		else b end as b
	,case 
		when inst ~ '^cpy \d+ c' then substring(inst,'\d+')::int + c
		when inst ~ '^inc c' then c + 1
		when inst ~ '^dec c' then c - 1
		else c end as c
	,case 
		when inst ~ '^cpy \d+ d' then substring(inst,'\d+')::int + d
		when inst ~ '^inc d' then d + 1
		when inst ~ '^dec d' then d - 1
		else d end as d
	,case when inst ~ 'jnz a' and a <>0 then substring(inst,'-?\d+')::int + pos
		when inst ~ 'jnz b' and b <>0 then substring(inst,'-?\d+')::int + pos
		when inst ~ 'jnz c' and c <>0 then substring(inst,'-?\d+')::int + pos
		when inst ~ 'jnz d' and d <>0 then substring(inst,'-?\d+')::int + pos
		when inst ~ 'jnz \d' then substring(inst,'-?\d+$')::int + pos
		else pos + 1 end as pos
from santa_parse
where pos + 1 = id
union all
select sp.id
	,sp.inst
	,case 
		when sp.inst ~ '^cpy \d+ a' then substring(sp.inst,'\d+')::int
		when sp.inst ~ '^cpy [b-d] a' and substring(sp.inst, '^cpy ([b-d]) a') = 'b' then sv.b
		when sp.inst ~ '^cpy [b-d] a' and substring(sp.inst, '^cpy ([b-d]) a') = 'c' then sv.c
		when sp.inst ~ '^cpy [b-d] a' and substring(sp.inst, '^cpy ([b-d]) a') = 'd' then sv.d
		when sp.inst ~ '^inc a' then sv.a + 1
		when sp.inst ~ '^dec a' then sv.a - 1
		else sv.a end as a
	,case 
		when sp.inst ~ '^cpy \d+ b' then substring(sp.inst,'\d+')::int
		when sp.inst ~ '^cpy [a-d] b' and substring(sp.inst, '^cpy ([a-d]) b') = 'a' then sv.a
		when sp.inst ~ '^cpy [a-d] b' and substring(sp.inst, '^cpy ([a-d]) b') = 'c' then sv.c
		when sp.inst ~ '^cpy [a-d] b' and substring(sp.inst, '^cpy ([a-d]) b') = 'd' then sv.d
		when sp.inst ~ '^inc b' then sv.b + 1
		when sp.inst ~ '^dec b' then sv.b - 1
		else sv.b end as b
	,case 
		when sp.inst ~ '^cpy \d+ c' then substring(sp.inst,'\d+')::int
		when sp.inst ~ '^cpy [a-d] c' and substring(sp.inst, '^cpy ([a-d]) c') = 'a' then sv.a
		when sp.inst ~ '^cpy [a-d] c' and substring(sp.inst, '^cpy ([a-d]) c') = 'b' then sv.b
		when sp.inst ~ '^cpy [a-d] c' and substring(sp.inst, '^cpy ([a-d]) c') = 'd' then sv.d
		when sp.inst ~ '^inc c' then sv.c + 1
		when sp.inst ~ '^dec c' then sv.c - 1
		else sv.c end as c
	,case 
		when sp.inst ~ '^cpy \d+ d' then substring(sp.inst,'\d+')::int
		when sp.inst ~ '^cpy [a-d] d' and substring(sp.inst, '^cpy ([a-d]) d') = 'a' then sv.a
		when sp.inst ~ '^cpy [a-d] d' and substring(sp.inst, '^cpy ([a-d]) d') = 'b' then sv.b
		when sp.inst ~ '^cpy [a-d] d' and substring(sp.inst, '^cpy ([a-d]) d') = 'c' then sv.c
		when sp.inst ~ '^inc d' then sv.d + 1
		when sp.inst ~ '^dec d' then sv.d - 1
		else sv.d end as d
	,case when sp.inst ~ 'jnz a' and sv.a <>0 then substring(sp.inst,'-?\d+')::int + sv.pos
		when sp.inst ~ 'jnz b' and sv.b <>0 then substring(sp.inst,'-?\d+')::int + sv.pos
		when sp.inst ~ 'jnz c' and sv.c <>0 then substring(sp.inst,'-?\d+')::int + sv.pos
		when sp.inst ~ 'jnz d' and sv.d <>0 then substring(sp.inst,'-?\d+')::int + sv.pos
		when sp.inst ~ 'jnz \d' then substring(sp.inst,'-?\d+$')::int + sv.pos
		else sv.pos + 1 end as pos
from santa_values sv
inner join santa_parse sp
	on sp.id = sv.pos + 1
-- where sv.pos < 23
)
select * from santa_values
;