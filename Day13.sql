drop table if exists santa;
select *
    , length(regexp_replace(((x*x + 3*x + 2*x*y + y + y*y+1362)::bit(32))::varchar, '0', '', 'g')) % 2 as pos_value
into temp santa
from
generate_series(0,60) x
,generate_series(0,60) y;





drop table if exists travel_links;
select s.x as x_from
    ,s.y as y_from
    ,s2.x as x_to
    ,s2.y as y_to
into temp travel_links
from santa s
inner join santa s2 on abs(s.x-s2.x)+abs(s.y-s2.y) = 1
where s.pos_value != 1 and s2.pos_value != 1;




with recursive path_taken(start_block, end_block, visited, steps) as(
select array[1,1] as start_block
    , array[1,1] as end_block
    , array[]::text[] as visited
    ,0 as steps
union all
select pt.end_block as start_block
    , array[tl.x_to,tl.y_to] as end_block
    , array_append(pt.visited, '|'||tl.x_from||','||tl.y_from||'|') as visited
    ,steps+1 as steps
from path_taken pt
inner join travel_links tl on tl.x_from = pt.end_block[1] and tl.y_from = pt.end_block[2]
    and not  '|'||tl.x_to||','||tl.y_to||'|' = any(pt.visited)
where pt.steps < 100)


select * from path_taken 
where end_block = array[31, 39]
order by steps;


select distinct end_block
from path_taken
where steps <= 50
