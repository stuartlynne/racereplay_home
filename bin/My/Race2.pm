
package Race;

use strict;
use Exporter;
use Data::Dumper;


use My::FKey qw(init find finish);
use My::Misc qw(kph);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(do_analysis);

my  @PointsRaceDB = (5, 3, 2, 1);

sub dump_flags {
    my ($cgi, $racetype, $racelaps, $lastlap, $lapinfo_ref) = @_;
    my @lapinfo = @{$lapinfo_ref};

    my @Content;

    printf STDERR "dump_flags: racelaps: %d\n", $lastlap;
    push (@Content, "", "", "");
    push (@Content, @lapinfo);
    push (@Content, "-", "-");
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, $cgi->th(\@Content),);
}

sub dump_th {
    my ($cgi, $racetype, $racelaps, $lastlap, $togo_ref) = @_;
    my @togo = @{$togo_ref};

    my @Content;

    printf STDERR "dump_th: racelaps: %d\n", $lastlap;
    push (@Content, "", "Rider", "Chip");
    push (@Content, @togo);
    push (@Content, "-", "-");
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, $cgi->th(\@Content),);
}

sub dump_perlap {
    my ($cgi, $racetype, $lastlap, $raceinfo_ref) = @_;
    my @raceinfo = @{$raceinfo_ref};
    my @Content;
    #push (@Content, "", "Time per lap", "MM:SS or SS.S");

    my $lasttime = 0;
    for (my $i = 0; $i <= $lastlap; $i++) {
        my $row = $raceinfo[$i];
        my $lntime = $row->{'ELAPSED'};
        push(@Content, Misc::mmss(($lntime - $lasttime)/1000)); 
        $lasttime = $lntime;
    }
    #push(@Content, "","");
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, 
            $cgi->th({-colspan => 3}, "Time per lap"),
            $cgi->th(\@Content),
            $cgi->th({-colspan => 2}, "(MM:SS or SS.S"),
            );
}

sub dump_kph {
    my ($cgi, $racetype, $lastlap, $distance, $raceinfo_ref) = @_;
    my @raceinfo = @{$raceinfo_ref};
    my @Content;

    #push (@Content, "", "Average speed per lap", "kph");

    my $lasttime = 0;
    for (my $i = 0; $i <= $lastlap; $i++) {
        my $row = $raceinfo[$i];
        my $lntime = $row->{'ELAPSED'};
        push(@Content, Misc::kph($distance, ($lntime - $lasttime))); 
        $lasttime = $lntime;
    }
    #push(@Content, "","");
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, 
            $cgi->th({-colspan => 3}, "Average speed per lap"),
            $cgi->th(\@Content),
            $cgi->th({-colspan => 2}, "(kph)"),
            );
}

sub dump_time {
    my ($cgi, $racetype, $lastlap, $raceinfo_ref) = @_;
    my @raceinfo = @{$raceinfo_ref};
    my @Content;
    #push (@Content, "", "Elapsed Time", "MM:SS");

    for (my $i = 0; $i <= $lastlap; $i++) {
        my $row = $raceinfo[$i];
        push(@Content, Misc::mmss($row->{'ELAPSED'}/1000)); 
    }

    #push (@Content, "","");
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, 
            $cgi->th({-colspan => 3}, "Elapsed time"),
            $cgi->th(\@Content),
            $cgi->th({-colspan => 2}, "(MM:SS or SS.S)"),
            );
}
    
sub do_start_table {
    my ($cgi, $datestamp, $distance, $racetype, $StartMS, $racelaps, $lastlap, $raceinfo_ref, $lapinfo_ref, $togo_ref) = @_;

    my @raceinfo = @{$raceinfo_ref};
    my @lapinfo = @{$lapinfo_ref};
    my @togo = @{$togo_ref};

    printf STDERR " do_start_table: distance: %d racelaps: %d lastlap: %d\n", $distance, $racelaps, $lastlap;
    #printf STDERR "dump_table: start: %d end: %d\n", $start, $end;

    #printf STDERR "datestamp: %s racetype: %s Members: %s\n", $datestamp, $racetype, $members;

    printf STDERR "---------------------------\n";
    printf STDERR "\@raceinfo\n";

    my $start = 1;
    my $end = $lastlap;
    my @Content;
    push(@Content, 
            $cgi->start_table({ -class => 'table', -cellpadding => 3 }),
            $cgi->caption({-class => "small_left_caption"}, sprintf("%s [%d:%d] %s - %s km", 
                    $datestamp, 
                    $start, $end,
                    $racetype, 
                    $distance
                    )),
            dump_kph($cgi, $racetype, $lastlap, $distance, \@raceinfo),
            dump_perlap($cgi, $racetype, $lastlap, \@raceinfo),
            dump_time($cgi, $racetype, $lastlap, \@raceinfo),
            dump_flags($cgi, $racetype, $racelaps, $lastlap, \@lapinfo),
            dump_th($cgi, $racetype, $racelaps, $lastlap, $togo_ref),
            );

    return @Content;
}

sub dump_last {
    my ($cgi, $racetype, $racelaps, $lastlap, @raceinfo) = @_;
    my @Content;

    push (@Content, "", "", "");

    for (my $i = 0; $i < $lastlap; $i++) {
        push(@Content, sprintf("%5d", $i)); 
    }
    push(@Content, "", "");
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, $cgi->th(\@Content),);
}


sub do_end_table {
    my ($cgi, $datestamp, $distance, $racetype, $StartMS, $racelaps, $lastlap, @raceinfo) = @_;
    my @Content;
    push(@Content, 
            dump_last($cgi, $racetype, $racelaps, $lastlap, @raceinfo),
            $cgi->end_table(), $cgi->br(),
            #$cgi->hidden('maxlaps', $maxlaps),
            );

    return @Content;
}


# do_analysis
#
sub Race::do_analysis {

    my ($dbh, $cgi, $reference_groupsetid, $distance, $correction, $maxlaps, $datestamp, $racetype, $sprint) = @_;

    my $FirstTimeFlag = 0;
    unless(defined($correction)) {
        printf STDERR "=============================\n";
        printf STDERR "FIRST TIME\n";
        printf STDERR "=============================\n";
        $FirstTimeFlag = 1;
    }

    my $lapcorrection = 0;
    my $Sprint = 10;
   
    my $sth;

    # Get the per lap race information
    $sth = $dbh->prepare('
                SELECT 
                        RI.raceinfoid, 
                        RI.lapnumber, 
                        R.startms, 
                        RI.finishms, 
                        (RI.finishms - R.startms) ELAPSED, 
                        RI.racelap, 
                        RI.startflag,
                        RI.neutralflag,
                        RI.bellflag,
                        RI.premeflag,
                        RI.sprintflag,
                        RI.finishflag,
                        R.lastlap,
                        G.datestamp,
                        R.racelaps
                FROM raceinfo RI
                JOIN races R ON R.raceid = RI.raceid
                JOIN groupsets G ON G.groupsetid = R.groupsetid
                WHERE G.groupsetid = ?
                ORDER by RI.lapnumber
            ');
    $sth->execute($reference_groupsetid) || Misc::diemsg(__LINE__, "finish order", $sth);

    my $LastLap = 0;
    my $RaceLaps = 0;
    my $DateStamp;
    my $StartMS;
    my $NeutralLaps = 0;
    
    my (@RaceInfo, @LapTimes, @ToGo, @LapInfo);

    while ( my $row = $sth->fetchrow_hashref()) {

        # push row onto RaceInfo array and timems onto LapTimes array
        #
        push(@RaceInfo, $row);
        push(@LapTimes, $row->{'ELAPSED'}); 



        # First lap - save LastLap, DateStamp and StartMS
        #
        unless ($LastLap) {
            $LastLap = $row->{'lastlap'};
            $RaceLaps = $row->{'racelaps'};
            $DateStamp = $row->{'datestamp'};
            $StartMS = $row->{'startms'};
            #printf STDERR Dumper($row);
            printf STDERR "first: DateStamp: %s RaceLaps: %d LastLap: %d StartMS: %d\n", $DateStamp, $RaceLaps, $LastLap, $StartMS;
        }

        if ($row->{'startflag'}) { $NeutralLaps++; next; }
        if ($row->{'neutralflag'}) { $NeutralLaps++; next; }

    }
    $sth->finish();
    printf STDERR "\@LapTimes: %d\n", $#LapTimes;
    printf STDERR Dumper(\@LapTimes);

    if ($FirstTimeFlag) {
        printf STDERR "FIRST TIME\n";
        my $lasttime = 0;
        my @perlaptimes;
        for (my $i = 1; $i <= $#LapTimes; $i++) {
            my $lntime = $LapTimes[$i];
            push(@perlaptimes, ($lntime - $lasttime)/1000); 
            $lasttime = $lntime;
        }
        for (my $i = 0; $i < 4; $i++) {
            my $last = $#perlaptimes;
            printf STDERR "[%d] %d %d CHECK\n", $last, $perlaptimes[$last], $perlaptimes[$last-1];
            if ($perlaptimes[$last] > $perlaptimes[$last-1]) {
                printf STDERR "TRIMMING!\n";
                pop(@perlaptimes);
                $correction--;
            }
        }
        $maxlaps = $#perlaptimes;

        printf STDERR "Correction: %d SUGGESTED\n", $correction;
    }

    # User has specified lower Maximum Laps, override if necessary
    #

    $maxlaps = $LastLap unless(defined($maxlaps));

    printf STDERR "NeutralLaps: %d Correction: %d LastLap: %d -> %d RaceLaps: %d -> %d\n", $NeutralLaps, $correction,
           $LastLap, $LastLap + $correction,
           $RaceLaps, $RaceLaps + $correction - $NeutralLaps;

    $LastLap += $correction;
    #$RaceLaps += $correction - $NeutralLaps;
    $RaceLaps += $correction;

    my $togo = 0;
    for (my $i = $LastLap; $i >= 0; $i--) {

        my $row = $RaceInfo[$i];

        if ($togo) {
            unshift(@ToGo, sprintf("%d", $togo));
        }
        else {
            unshift(@ToGo, "-");
        }

        if ($row->{'startflag'}) {
            unshift(@LapInfo, "start");
            next;
        }

        if ($row->{'neutralflag'}) {
            unshift(@LapInfo, "neutral");
            next;
        }

        $togo++;

        if ($i == $LastLap) {
            unshift(@LapInfo, "finish");
            next;
        }

        if ($row->{'bellflag'}) {
            unshift(@LapInfo, "bell");
            next;
        }
        if ($row->{'sprintflag'}) {
            unshift(@LapInfo, "sprint");
            next;
        }
        if ($row->{'premeflag'}) {
            unshift(@LapInfo, "preme");
            next;
        }
        unshift(@LapInfo, "");
    }

    printf STDERR Dumper(\@LapInfo);
    printf STDERR Dumper(\@ToGo);

    #if (defined($correction)) { $maxlaps += $correction; }
    #$LastLap = $maxlaps if ($maxlaps < $LastLap);

    # start table with headers
    #
    my @Content;

    push(@Content, 
            do_start_table($cgi, $datestamp, $distance, $racetype, $StartMS, $RaceLaps, $LastLap, \@RaceInfo, \@LapInfo, \@ToGo));

    # Iterate across tags in finish order.
    # First Get the rider finish order, this can any one of chipid or chip or workoutid
    #
    my @FinishOrderByChipID;
    $sth = $dbh->prepare('
            select distinct chipid  from (select ln.datestamp, ln.finishms,  ri.lapnumber, c.chipid
                from races r
                join raceinfo ri on ri.raceid = r.raceid                   # ri - raceinfo 
                join racelaps rl on rl.raceinfoid = ri.raceinfoid          # rl - link to laps
                join laps ln on ln.lapid = rl.lapid                        # ln - lap information
                join workouts w on w.workoutid = ln.workoutid              # w - workout
                join chips c on c.chipid = w.chipid                        # c - chips
                where r.groupsetid = ? and ri.lapnumber <= ?
                order by ri.lapnumber desc, ln.finishms ) Sub
            ');

    $sth->execute($reference_groupsetid, $LastLap) || Misc::diemsg(__LINE__, "finish order", $sth);

    while ( my $row = $sth->fetchrow_hashref()) {
        push(@FinishOrderByChipID, $row->{'chipid'}) if (defined($row->{'chipid'}));
    }
    $sth->finish();
    printf STDERR "\@FinishOrderByChipID\n";
    printf STDERR Dumper(@FinishOrderByChipID);

    # The lap data per rider
    #
    my @RaceInfo;
    $sth = $dbh->prepare('
                SELECT 
                        RI.raceinfoid, 
                        RI.startflag, 
                        USER.datestamp, 
                        (RI.finishms - R.startms) LAPTIME0,
                        (USER.finishms - R.startms)  LAPTIMEN,  
                        RI.lapnumber, 
                        USER.finishorder, 
                        USER.chip, 
                        RI.lapnumber, 
                        RI.racelap, 
                        RI.neutralflag, 
                        RI.startflag, 
                        RI.bellflag, 
                        RI.sprintflag
                FROM races R
                JOIN raceinfo RI ON RI.raceid = R.raceid 
                LEFT JOIN (
                    SELECT 
                            C.chipid, 
                            C.chip, 
                            LN.finishms, 
                            LN.datestamp, 
                            RL.finishorder, 
                            RL.raceinfoid
                    FROM racelaps RL 
                    JOIN laps LN ON LN.lapid = RL.lapid
                    JOIN workouts W ON W.workoutid = LN.workoutid
                    JOIN chips C ON C.chipid = W.chipid
                ) USER ON USER.raceinfoid = RI.raceinfoid  AND USER.chipid = ?
                WHERE R.groupsetid = ? AND RI.lapnumber <= ?
                ORDER by RI.lapnumber asc, USER.finishms 
            ');

    # Iterate across finish list
    #
    for (my $i = 0; $i <= $#FinishOrderByChipID; $i++) {

        my $chipid = $FinishOrderByChipID[$i];
        my ($userid, $name, $shortname, $chip) = Misc::get_user_name_extended($dbh, "", $chipid, $DateStamp);
        my $LapsDown = 0;
        my $MyLastLap = 0;
        my $LastFinishMS = 0;

        my @Entries;

        push (@Entries, $cgi->td($i+1));
        if (defined($name)) {
            push (@Entries, $cgi->td($name));
        }
        elsif (defined($shortname)) {
            push (@Entries, $cgi->td($shortname));
        }
        else {
            push (@Entries, $cgi->td("-"));
        }
        push (@Entries, $cgi->td($chip), $cgi->td(""));

        my $tr_class = ($i % 2)  ? 'tr_odd' : 'tr_even';

        $sth->execute($chipid, $reference_groupsetid, $LastLap) || Misc::diemsg(__LINE__, "finish order lookup", $sth);

        # build data points
        #
        while(my $row = $sth->fetchrow_hashref()) {
            #printf STDERR "=========================\n";
            #printf STDERR "chipid: %s LastLap: %d\n", $chipid, $LastLap;
            #printf STDERR Dumper($row);

            my $laptime0 = $row->{'LAPTIME0'};
            my $laptimen = $row->{'LAPTIMEN'};
            my $lapnumber = $row->{'lapnumber'};
            my $startms = $row->{'startms'};
            my $finishorder = $row->{'finishorder'};

            next unless ($lapnumber);

            if (defined($laptimen)) {
                my $lapms = $laptimen - $laptime0;
                #printf STDERR "lapnumber: %d %d LAPTIME0: %s LAPTIMEN: %s lapms: %d\n", $lapnumber, $LapTimes[$lapnumber], $laptime0, $laptimen, $lapms;

                if ($finishorder == 1) {
                    push(@Entries, $cgi->td({-bgcolor => 'yellow'},Misc::mmss($lapms/1000))); 
                }
                else {
                    push(@Entries, $cgi->td(Misc::mmss($lapms/1000))); 
                }
                $LastFinishMS = $laptimen;

                $MyLastLap = $lapnumber;
            }
            else {
                push(@Entries, $cgi->td("-")); 
                $LapsDown++;
            }
        }

        #printf STDERR "LastLap: %d MyLastLap: %d LapsDown: %d LastFinishMS: %d\n", $LastLap, $MyLastLap, $LapsDown, $LastFinishMS;

        if ($LapsDown) {
            if ($MyLastLap == $LastLap) {
                push(@Entries, 
                        $cgi->td($LapsDown),
                        $cgi->td( Misc::kph(($LastLap - $LapsDown) * $distance, $LastFinishMS))); 
            }
            else {
                push(@Entries, 
                        $cgi->td("DNF"), 
                        $cgi->td("")); 
            }
        }
        else {
                push(@Entries, 
                        $cgi->td(""),
                        $cgi->td(Misc::kph($LastLap * $distance, $LastFinishMS))); 
        }

        push (@Content, 
                $cgi->Tr( { -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" }, @Entries));

    }
    $sth->finish();

    # finish table
    #
    push(@Content, 
            do_end_table($cgi, $datestamp, $distance, $racetype, $StartMS, $RaceLaps, $LastLap, @RaceInfo));
    
    return @Content;
}

1;

