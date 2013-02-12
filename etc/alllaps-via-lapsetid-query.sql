SELECT L0.groupsetid, S.starttime,
                CONCAT(U.firstname, ' ', U.lastname) FULLNAME,                 # user name
                (L.finishms) LFINISHMS,
                (LN.finishms) LNFINISHMS,
                ((L.finishms - LN.finishms)) ELAPSEDMS,
                ((L.finishms - LN.finishms) /1000) ELAPSED,       # compute elapsed time in decimal seconds
                L.lapnumber,                                                   # lapnumber
                L0.groupms,
                S.chipid                                                  # chipid                                                    
            FROM racetest.laps L0
            JOIN racetest.laps LN on L0.groupsetid = LN.groupsetid
            JOIN racetest.lapsets S ON LN.lapsetid = S.lapsetid
            JOIN racetest.laps L ON S.lapsetid = L.lapsetid AND L.finishms > LN.finishms
            LEFT JOIN racetest.chips C ON S.chipid = C.chipid
            LEFT JOIN racetest.chiphistory H
                ON C.chipid = H.chipid AND (
                    (S.starttime BETWEEN H.starttime AND H.finishtime) OR
                    (S.starttime >= H.starttime and H.finishtime = '00-00-00 00:00:00'))
            LEFT JOIN racetest.users U ON H.userid = U.userid
            WHERE L0.groupsetid = '666'  and L0.lapnumber = 1
            ORDER by ELAPSEDMS ASC
