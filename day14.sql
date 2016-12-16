-- part 1
with md5_data as (
select md5('ihaygndm'||generate_series) as hash, generate_series as code
from generate_series(0,100000)
)


select a.code
from
(
select substring(hash, '([a-z0-9])\1\1') as repeated_3, code
from md5_data
)a
inner join md5_data md on md.code between a.code+1 and a.code+1001
    and md.hash ilike '%'||repeat(repeated_3, 5)||'%'
left join md5_data md2 on md2.code between a.code+1 and a.code+1001
    and md2.hash ilike '%'||repeat(repeated_3, 5)||'%'
    and md2.code < md.code

where a.repeated_3 is not null
and md2.code is null
order by 1 
limit 64;



--part 2
with recursive md5_data(code, hash, md5s) as(
select 0
    , md5('abc0')
    , 1
union all
select case when md5s = 2017 then code+1 else code end as code
    ,case when md5s != 2017 then md5(hash) else md5('abc'||(code+1)) end as hash
    ,case when md5s = 2017 then 1 else md5s+1 end as md5s
from md5_data
where code < 25000
)



select a.code
from
(
select substring(hash, '([a-z0-9])\1\1') as repeated_3, code
from md5_data
where md5s = 2017
)a
inner join md5_data md on md.code between a.code+1 and a.code+1001
    and md.hash ilike '%'||repeat(repeated_3, 5)||'%'
    and md.md5s = 2017
where a.repeated_3 is not null
order by 1 
limit 64;
