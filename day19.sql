-- 3005290

--Part I
select 1 +
	2 * 
	(3005290 - (2^((floor(log(2,3005290)))::int))::int) as math
;





--Part II
select case when 3005290 - 3^floor(log(3,3005290))::int + 
	case when 3005290 - 2 * 3^floor(log(3,3005290))::int >= 0 
		then 3005290 - 2 * 3^floor(log(3,3005290))::int
		else 0 end
		= 0 then 3005290 else
	3005290 - 3^floor(log(3,3005290))::int + 
	case when 3005290 - 2 * 3^floor(log(3,3005290))::int >= 0 
		then 3005290 - 2 * 3^floor(log(3,3005290))::int
		else 0 end end as math
