select g.groupsetid, g.members, l.datestamp, l.lapsetid, l.lapnumber, c.chipid, h.chipid, h.userid, h.starttime, h.finishtime, u.lastname
from racetest.groupsets g
join racetest.events e on e.venueid = g.venueid 
join racetest.laps l on l.groupsetid = g.groupsetid
join racetest.lapsets s on l.lapsetid = s.lapsetid
left join racetest.chips c on s.chipid = c.chipid
left join racetest.chiphistory h 
    on c.chipid = h.chipid and ((s.starttime between h.starttime and h.finishtime) or (s.starttime >= h.starttime and h.finishtime = '00-00-00 00:00:00' ))
left join racetest.users u on h.userid = u.userid
where g.datestamp between e.starttime and e.finishtime and e.eventid = 21 and l.lapnumber = 0 and g.members > 5
order by lapsetid 