select substring(a, '(\d+)-\d+')::bigint as lower_bound
	, substring(a, '\d+-(\d+)')::bigint as upper_bound
into temp santa
from(
select regexp_split_to_table('420604416-480421096
172102328-195230700
613677102-639635955
1689844284-1724152701
3358865073-3365629764', E'\n')a)a
order by 1;



drop table if exists santa2;
select *
into temp santa2
 from santa
 limit 3;


select s1.upper_bound+1
from santa s1
left join santa s2 on s2.lower_bound <= s1.upper_bound
	and s2.upper_bound >= s1.upper_bound
	and s1.lower_bound != s2.lower_bound
where s2.lower_bound is null
order by 1;
