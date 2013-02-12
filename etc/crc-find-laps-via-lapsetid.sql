select concat(u.firstname, ' ', u.lastname) FULLNAME, t2.chipid, ((l3.finishms -l1.finishms)/1000)/60 elapsed, l3.lapms /1000 / 60 laptime, l3.lapnumber, g.groupsetid, g.members, t1.starttime
from racetest.lapsets t1                                                    # t1 lapsets will be used to find the initial groupset
join racetest.laps l1 on l1.lapsetid = t1.lapsetid and l1.lapnumber = 0     # l1 laps will be used to find the initial groupset
join racetest.groupsets g on l1.groupsetid = g.groupsetid                   # g groupset is the inital groupset, 
join racetest.laps l2 on l2.groupsetid = g.groupsetid                       # l2 laps is all of the laps that point at the groupset g 
join racetest.lapsets t2 on l2.lapsetid = t2.lapsetid                       # t2 lapsets will link laps back to users 
join racetest.laps l3 on l3.lapsetid = t2.lapsetid                          # l3 laps will be all laps that point back to the t2 lapsets
join racetest.chips c on t2.chipid = c.chipid
join racetest.chiphistory h on c.chipid = h.chipid and h.finishtime = '00-00-00 00:00:00'  
join racetest.users u on u.userid = h.userid 
where t1.lapsetid = 469
order by l3.finishms asc