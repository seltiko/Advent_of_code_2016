with santa as (
select substring(instruction, '^Disc #(\d+).+$')::int as disc_number
    ,substring(instruction, '^Disc #\d+ has (\d+) .+$')::int as positions 
    , substring(instruction, '^.+ (\d+)\.\s?$')::int as starting_position
from(   
select regexp_split_to_table('Disc #1 has 7 positions; at time=0, it is at position 0.
Disc #2 has 13 positions; at time=0, it is at position 0.
Disc #3 has 3 positions; at time=0, it is at position 2.
Disc #4 has 5 positions; at time=0, it is at position 2.
Disc #5 has 17 positions; at time=0, it is at position 0.
Disc #6 has 19 positions; at time=0, it is at position 7.', E'\n') as instruction
)a
union all (select 7, 11, 0)
)
select button_press_time
    , bool_and((disc_number + starting_position + button_press_time)%positions = 0) as pass
from santa, generate_series(1,10000000) as button_press_time
group by 1
order by 2 desc , 1
limit 1
