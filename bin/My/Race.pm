

package Race;

use strict;
use Exporter;
use Data::Dumper;


use My::FKey qw(init find finish);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(do_analysis);

my  @PointsRaceDB = (5, 3, 2, 1);


sub dump_th {
    my ($cgi, $racetype, $start, $end) = @_;
    printf STDERR "dump_th: start: %d end: %d\n", $start, $end;
    my @Content;
    push (@Content, "", "Rider");
    for (my $i = $start; $i <= $end; $i++) { push(@Content, sprintf("%5d", $i + 1)); }

    if ($racetype eq "Points Race") {
        push(@Content, "Points");
    }
    else {
        push(@Content, "Laps Down");
    }
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, $cgi->th(\@Content));
}

sub dump_time {
    my ($cgi, $racetype, $start, $end, @lapstarts) = @_;
    printf STDERR "dump_time: start: %d end: %d\n", $start, $end;
    my @Content;
    push (@Content, "", "");
    for (my $i = $start; $i <= $end; $i++) { push(@Content, mmss($lapstarts[$i])); }
    push (@Content, "");
    return $cgi->Tr( { -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" }, $cgi->th(\@Content));
}
    
sub do_start_table {
    my ($cgi, $datestamp, $racetype, $members, $lapcurrent, $start, $end, $groupsetid, @lapstarts) = @_;
    printf STDERR "dump_table: start: %d end: %d\n", $start, $end;

    printf STDERR "datestamp: %s racetype: %s Members: %s\n", $datestamp, $racetype, $members;

    my @Content;
    push(@Content, 
            $cgi->start_table({ -class => 'table', -cellpadding => 3 }),
            $cgi->caption({-class => "small_left_caption"}, sprintf("%s [%d:%d] %s", 
                    $datestamp, 
                    $start + 1, $end + 1,
                    $racetype, 
                    )),
            dump_th($cgi, $racetype, $start, $end),
            dump_time($cgi, $racetype, $start, $end, @lapstarts));
    return @Content;
}

sub do_end_table {

}


sub mmss {
    my ($totalseconds) = @_;

    my $minutes = $totalseconds / 60;
    my $seconds = $totalseconds % 60;
    my $tenths = ($totalseconds * 10) %10;

    my $mmss;
    if ($minutes >= 1) {
        $mmss = sprintf("%d:%02d", $minutes, $seconds);
    }
    else {
        $mmss = sprintf("%d.%d", $seconds, $tenths);
    }
    #printf STDERR "[%6.2f] %s minutes: %d seconds: %d tenths: %d\n", $totalseconds, $mmss, $minutes, $seconds, $tenths;
    return $mmss;
}

sub dump_tr {
    my ($cgi, $racetype, $count, $lapcurrent, $maxlapsdown, $fullname, $mylapsdown, $start, $end, $points, $lapped, @laptimes) = @_;
    printf STDERR "dump_tr: start: %d end: %d\n", $start, $end;

    my @Content;

    push (@Content, $cgi->td($count+1));
    push (@Content, $cgi->td($fullname));

    my $lapsdown = 0;
    #for (my $i = 1; $i <= $lapcurrent; $i++) 
    
    for (my $i = $start; $i <= $end; $i++) {

        my $time = "-";
        if (defined($laptimes[$i])) {
            $time = $laptimes[$i];

            if ($time) {
                push(@Content, $cgi->td(mmss($time)));
            }
            else {
                push(@Content, $cgi->td({-bgcolor => 'yellow'}, mmss($time)));
            }
        }
        else {
            $lapsdown++;
            push(@Content, $cgi->td(sprintf("-")));
        }
    }

    if ($racetype eq "Points Race") {
        if (defined($points)) {
            if ($lapped) {
                push (@Content, $cgi->td(sprintf("DNF", $points)));
            }
            else {
                push (@Content, $cgi->td(sprintf("%d", $points)));
            }
        }
        else {
            push (@Content, $cgi->td("-"));
        }
    }
    else {
        if ($mylapsdown) {
            if ($lapped) {
                push (@Content, $cgi->td(sprintf("DNF", $points)));
            }
            else {
                push (@Content, $cgi->td(sprintf("%d", $mylapsdown)));
            }
        }
        else {
            push (@Content, $cgi->td("-"));
        }
    }


    #if ($lapsdown) {
        #    if ($lapsdown > $maxlapsdown) {
            #        push (@Content, $cgi->td("DNF"));
            #    }
    #    else {
    #        push (@Content, $cgi->td(sprintf("%d", -$lapsdown)));
    #    }
    #}
    #else {
    #    push (@Content, $cgi->td(""));
    #}
    return @Content;

    #return $cgi->td(\@Content);

    #my $tr_class = ($count % 2)  ? 'tr_odd' : 'tr_even';
    #return $cgi->Tr( { -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" }, $cgi->td(\@Content));

}

my $firsttime = 0;

my $LapCurrent = -1;        # current lap for leading rider
my @LapStart;               # time leading rider started each lap
my %LapCount;               # lap counts for all riders by workoutid
my %LapArrayBehind;         # array ref per rider for time behind for each lap
my $LapCorrection = 0;

my %Started;
my %LastLap;
my %Points;
my %DownLaps;
my %Riders;

my @LapArrays;
$LapArrays[0] =  [];

#my @LastLapOrder = @{$LapArrays[0]};

my $StartTime;
my $First = 0;

# do_table
#
sub do_table {
    my ($cgi, $datestamp, $racetype, $sprint, $last, $final) = @_;

    my @Content;
    my %lapped;


    printf STDERR "------------------------------------------\n";
    printf STDERR "do_table\n";

    my @lastlaporder = @{$LapArrays[$last]};

    for (my $i = 0 ; ($i < 5) && ($i < $#lastlaporder); $i++ ) {
        $Points{$lastlaporder[$i]} += $PointsRaceDB[$i];
        printf STDERR "Points[%d] %s %d\n", $i, $lastlaporder[$i], $Points{$lastlaporder[$i]};
    }
    foreach my $key (keys %DownLaps) {
        next unless($DownLaps{$key} > 0);
        $Points{$key} -= 20 * $DownLaps{$key};
        printf STDERR "Lapped %s %d\n", $key, $Points{$key};
    }

    my %laporder;
    my $i = 0;
    for ($i = 0; $i < $#lastlaporder; $i++) {
        $laporder{$lastlaporder[$i]} = $i;
        $lapped{$lastlaporder[$i]} = 0;
    }
    foreach my $key (sort keys %Riders) {
        next if (defined($laporder{$key}));
        $laporder{$key} = $i + $DownLaps{$key};
        $lapped{$key} = 1;
    }

    $i = 0;
    foreach my $key (sort { $laporder{$a} <=> $laporder{$b}} keys %laporder)  {
        printf STDERR "[%2d] %s %d\n", $i++, $key, $DownLaps{$key};
    }


    push(@Content, 
            do_start_table($cgi, $datestamp, $racetype, $#lastlaporder, $last, $First, $last, 0, @LapStart));

    if ($racetype eq "Points Race") {

        #
        #
        my $count = 0;
        my @results;
        foreach my $key (sort { $Points{$b} <=> $Points{$a}} keys %Points)  {

            my $finish = (defined($laporder{$key})) ? $laporder{$key} : 0;

            $results[$count] = ( {'key' => $key, 'points' => $Points{$key}, 'finish' => $finish });
            $count++;
        }
        printf STDERR Dumper(@results);

        my $count = 0;
        for (my $m = 0; $m < 2; $m++ ) {
            foreach ( sort {$$b{'points'} <=> $$a{'points'} || $$a{'finish'} <=> $$b{'finish'}} @results) {
                my $key = $$_{'key'};
                printf STDERR "[%2d] %s %d\n", $count, $key, $Points{$key};
                my $tr_class = ($count % 2)  ? 'tr_odd' : 'tr_even';
                my $behind_ref = $LapArrayBehind{$key};
                next if (($m == 0) && $lapped{$key} && $final);
                next if (($m == 1) && !($lapped{$key} && $final));
                push(@Content, 
                        $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" }, 
                            dump_tr($cgi, $racetype, $count, $LapCurrent, 0, $key, 0, $First, $last, $Points{$key}, $lapped{$key} && $final, @{$behind_ref})));

                $count++;
            }
        }
    }
    else {
        #
        #
        my $count = 0;
        my @results;
        foreach my $key (sort { $Points{$b} <=> $Points{$a}} keys %Points)  {

            my $finish = (defined($laporder{$key})) ? $laporder{$key} : 0;

            $results[$count] = ( {'key' => $key, 'downlaps' => $DownLaps{$key}, 'finish' => $finish });
            $count++;
        }
        printf STDERR Dumper(@results);

        my $count = 0;
        for (my $m = 0; $m < 2; $m++ ) {
            foreach ( sort {$$a{'downlaps'} <=> $$b{'downlaps'} || $$a{'finish'} <=> $$b{'finish'}} @results) {
                my $key = $$_{'key'};
                my $downlaps = $$_{'downlaps'};
                printf STDERR "[%2d] %s %d\n", $count, $key, $downlaps;
                my $tr_class = ($count % 2)  ? 'tr_odd' : 'tr_even';
                my $behind_ref = $LapArrayBehind{$key};
                next if (($m == 0) && $lapped{$key} && $final);
                next if (($m == 1) && !($lapped{$key} && $final));
                push(@Content, 
                        $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" }, 
                            dump_tr($cgi, $racetype, $count, $LapCurrent, 0, $key, $downlaps, $First, $last, 0, $lapped{$key} && $final, @{$behind_ref})));
                $count++;
            }
        }
    }


    push(@Content, $cgi->end_table(), $cgi->br());

    $First = $last + 1;

    printf STDERR "------------------------------------------\n";
    return @Content;
}



# do_one
#
sub do_one {
    my ($cgi, $maxlaps, $datestamp, $racetype, $sprint, $row) = @_;

    my @Content;

    if ($firsttime) {
        $firsttime--;
        printf STDERR Dumper($row);
    }

    $StartTime = $row->{'starttime'} unless (defined($StartTime));
    my $fullname = $row->{'FULLNAME'};
    my $chipid = $row->{'chipid'};
    my $elapsed = $row->{'ELAPSED'};
    my $lapms = $row->{'lapms'};
    my $lapnumber = $row->{'lapnumber'};


    # get array refs this user, setup if necessary
    #
    unless(defined($LapCount{$fullname})) {
        $LapCount{$fullname} = 0; 
        $LapArrayBehind{$fullname} = [];
        $LapCount{$fullname} = 0;
        $Started{$fullname} = 0;
        $Riders{$fullname} = 0;
        $Points{$fullname} = 0;
    }

    #printf STDERR "lapnumber: %d maxlaps: %d LapCorrection: %d\n", $lapnumber, $maxlaps, $LapCorrection;
    next if ($maxlaps && $lapnumber > ($maxlaps + $LapCorrection));

    # get this users lap, check if he is lead rider, set appropriate entries if he is
    #
    my $lap = $LapCount{$fullname};
    if ($lap > $LapCurrent) {

        printf STDERR "----------------------------------------------------------------------------\n";
        printf STDERR "NEW LAP[%2d]: %s %s\n", $lap, $LapArrays[$lap], $LapArrays[$lap+1];

        my $array_ref = $LapArrays[$LapCurrent];
        my $last = $#{$array_ref};
        my %finished;

        for (my $i = 0; $i <= $last; $i++) {
            $finished{${$array_ref}[$i]} = $i;
        }
        if ($lap > 0) {
            foreach my $key (keys %Started) {
                next if (defined($finished{$key}));
                #$Points{$key} -= 20;
                $DownLaps{$key}++;
                printf STDERR "LAPPED %s points: %d down:%d\n", $key, $Points{$key}, $DownLaps{$key};
            }

            printf STDERR "lap: %d sprint: %d mod: %d\n", $lap, $sprint, $lap % $sprint;

            if ($lap && !($lap % $sprint)) {
                push(@Content, do_table($cgi, $datestamp, $racetype, $sprint, $LapCurrent, 0));
            }
        }

        $LapStart[$lap] = $elapsed;
        $LapCurrent = $lap;
        $LapArrays[$lap+1] =  [];

        printf STDERR "NEW LAP[%2d]: %s %s\n", $lap, $LapArrays[$lap], $LapArrays[$lap+1];

        %LastLap = ();

        printf STDERR "----------------------------------------------------------------------------\n";
        #printf STDERR "[%2d] %s %5.1f\n", $LapCurrent, $fullname, $elapsed;

    }

    # save current lap completed for user
    $LastLap{$fullname} = $lap;
    
    # save finish order in the race lap
    my $array_ref = $LapArrays[$LapCurrent];
    my $position = $#{$array_ref} + 1;
    ${$array_ref}[$position] = $fullname;


    # save the finish time in the race lap
    my $behind_ref = $LapArrayBehind{$fullname};
    my $behind =  $elapsed - $LapStart[$LapCurrent];
    ${$behind_ref}[$LapCurrent] = $behind;
    $LapCount{$fullname}++; 

    #unless (($LapCurrent + 1) % $sprint) {
    #    #printf STDERR "[%2d:%2d:%2d] %s %5.1f ***************\n", $LapCurrent, $position, $Points{$fullname}, $fullname, $elapsed;
    #    if ($position < 3) {
    #        $Points{$fullname} += $PointsRaceDB[$position];
    #    }
    #}

    printf STDERR "[%2d:%2d:%4d:%3d] %3d %s %5.1f\n", $LapCurrent, $position, $Points{$fullname}, $DownLaps{$fullname}, $chipid, $fullname, $elapsed;


    return @Content;
}


# do_analysis
#
sub Race::do_analysis {

    my ($dbh, $cgi, $reference_groupsetid, $maxlaps, $datestamp, $racetype, $sprint) = @_;

    my $lapcorrection = 0;
    my $Sprint = 10;

    my @Content;
    printf STDERR "reference_groupsetid: %s maxlaps: %d \n", $reference_groupsetid, $maxlaps;

    my $sth = $dbh->prepare("
            SELECT 
            L0.finishms L0FINISHMS,
            L.finishms LFINISHMS,
            CONCAT(U.firstname, ' ', U.lastname) FULLNAME,                 # user name
            ((L.finishms - L0.finishms) /1000) ELAPSED,       # compute elapsed time in decimal seconds
            ((L.finishms - L0.finishms)) ELAPSEDMS,         # compute elapsed time in decimal seconds
            L.lapnumber,                                                   # lapnumber
            L.finishms l_finishms,
            S.chipid,                                                      # chipid
            S.starttime                                                    # start time
            FROM laps L0                                                          # L0 - first lap from starting group
            JOIN laps LN ON L0.groupsetid = LN.groupsetid                         # LN - all laps from starting group
            JOIN workouts S ON LN.workoutid = S.workoutid                            # S - all workouts for LN laps
            JOIN laps L ON S.workoutid = L.workoutid AND L.finishms > LN.finishms   # L - all laps for S workouts
            LEFT JOIN chips C ON S.chipid = C.chipid
            LEFT JOIN chiphistory H
            ON C.chipid = H.chipid AND (
                (S.starttime BETWEEN H.starttime AND H.finishtime) OR 
                (S.starttime >= H.starttime and H.finishtime = '00-00-00 00:00:00'))
            LEFT JOIN users U ON H.userid = U.userid
            WHERE L0.groupsetid = ? AND L0.groupnumber = 1
            ORDER by ELAPSEDMS ASC
            ");
    
    $sth->execute($reference_groupsetid) || die sprintf("Execute failed: %s\n", $sth->errstr);

    # Analysis
    # Iterate across all laps:
    #   1. Determine the lead rider for each lap
    #   2. Record start time for each lap (when lead rider started lap)
    #   3. Record lap times for all laps for all riders.
    #
    # For each rider we compute and record the time he is behind the lead rider for each
    # lap. If the rider is lapped he will not have a recorded time for that lap and the report
    # will indicate laps down.
    #

    my $lapcurrent = -1;        # current lap for leading rider
    my @lapstart;               # time leading rider started each lap
    my %lapcount;               # lap counts for all riders by workoutid
    my %laparraybehind;         # array ref per rider for time behind for each lap

    my %started;
    my %lastlap;

    my @laparrays;
    $laparrays[0] =  [];
    
    my $StartTime;

    while ( my $row = $sth->fetchrow_hashref()) {

        push(@Content, do_one($cgi, $maxlaps, $datestamp, $racetype, $sprint, $row));

        # sanity check and grab interesting info
        #
        $StartTime = $row->{'starttime'} unless (defined($StartTime));
        my $fullname = $row->{'FULLNAME'};
        my $chipid = $row->{'workoutid'};
        my $elapsed = $row->{'ELAPSED'};
        my $lapms = $row->{'lapms'};
        my $lapnumber = $row->{'lapnumber'};


        # get array refs this user, setup if necessary
        #
        unless(defined($lapcount{$fullname})) {
            $lapcount{$fullname} = 0; 
            $laparraybehind{$fullname} = [];
            $lapcount{$fullname} = 0;
            $started{$fullname} = 0;
        }

        #printf STDERR "lapnumber: %d maxlaps: %d lapcorrection: %d\n", $lapnumber, $maxlaps, $lapcorrection;
        next if ($maxlaps && $lapnumber > ($maxlaps + $lapcorrection));

        # get this users lap, check if he is lead rider, set appropriate entries if he is
        #
        my $lap = $lapcount{$fullname};
        if ($lap > $lapcurrent) {

            $lapstart[$lap] = $elapsed;
            $lapcurrent = $lap;
            $laparrays[$lap+1] =  [];

            #printf STDERR "NEW LAP[%2d]: %s %s\n", $lap, $laparrays[$lap],, $laparrays[$lap+1];

            %lastlap = ();
            
            #printf STDERR "----------------------------------------------------------------------------\n";
            #printf STDERR "[%2d] %s %5.1f\n", $lapcurrent, $fullname, $elapsed;
        }

        $lastlap{$fullname} = $lap;
        my $array_ref = $laparrays[$lapcurrent];
        ${$array_ref}[$#{$array_ref} + 1] = $fullname;

        #printf STDERR "[%2d:%2d] %s %5.1f\n", $lapcurrent, $#{$array_ref}, $fullname, $elapsed;

        my $behind_ref = $laparraybehind{$fullname};
        my $behind =  $elapsed - $lapstart[$lapcurrent];
        ${$behind_ref}[$lapcurrent] = $behind;
        $lapcount{$fullname}++; 
    }
    $sth->finish();
    push(@Content, do_table($cgi, $datestamp, $racetype, $sprint, $LapCurrent, 1));
    return @Content;

    my $MaxLapsDown = 0;

    my %LapsDown = ();

    my $array_ref = $laparrays[$lapcurrent];
    my @LastLapOrder = @{$array_ref};

    #printf STDERR "-----------------------------------------------------\n";
    #printf STDERR "-----------------------------------------------------\n";
    #printf STDERR "Finished: %d\n", $#LastLapOrder + 1;


    my %Finished;
    my %DNF;
    my %points;

    for (my $i = 0; $i <= $#LastLapOrder; $i++) {
        $Finished{$i} = $i;
    }
    foreach my $key (keys %started) {
        next if (defined($Finished{$key}));
        $DNF{$key} = 0;
    }

    printf STDERR "------------------\n";
    printf STDERR "------------------\n";
    printf STDERR "Determine laps down.\n";
    my %Riders;
    my $count;
    for (my $count = 0; $count <= $#LastLapOrder; $count++) {
        my $key = $LastLapOrder[$count];
        $Riders{$key} = $count;
        #delete $lapcount{$key};
        my $lastlap = $lastlap{$key};
        my $lapsdown = $lapcurrent - $lastlap;
        $LapsDown{$key} = $lapsdown;
        $MaxLapsDown = $lapsdown if ($lapsdown > $MaxLapsDown);

        printf STDERR "[%2d] %s FINISHED laps: %d down: %d MaxLapsDown: %d\n", $count, $key, $lastlap, $lapcurrent - $lastlap, $MaxLapsDown;
    }

    printf STDERR "----------------------------------------------\n";
    printf STDERR "MaxLapsDown: %d datestamp: %s racetype: %s #LastLapOrder: %s lapcurrent: %d\n", $MaxLapsDown, $datestamp, $racetype, $#LastLapOrder, $lapcurrent;

    foreach my $key (sort { $lapcount{$a} <=> $lapcount{$b}} keys %lapcount)  {

        #next if (defined($Finished{$key}));
        next if (defined($LapsDown{$key}));

        $Riders{$key} = $count++;
        push (@LastLapOrder, $key);
        $LapsDown{$key} = $MaxLapsDown+1;
        printf STDERR "[--] %s DID NOT FINISH\n", $key;
    }

    #for (my $i = 0; $i <= $#LastLapOrder; $i++) {
    #    printf STDERR "[%2d] %s\n", $i, $LastLapOrder[$i];
    #}




    my @SprintStarts;
    $SprintStarts[0] = 0;

    my $first = 0;

    #my $width = $lapcurrent;
    
    my $width = 100;
    if ($racetype eq "Points Race") {
        $width = $sprint;
    }

    #if ($Sprint > 24) {
    #    while ($width > 20) {
    #        $width = int($width / 2);
    #    }
    #}
    #elsif ($Sprint < 12) {
    #    while (($width + $Sprint) < $22) {
    #        $width += $Sprint;
    #    }
    #}

#   if (0) {
#       printf STDERR "------------------\n";
#       for (my $i = 0; $i <= $#laparrays; $i++) {
#           my $array_ref = $laparrays[$i];
#           my @lastlaporder = @{$array_ref};
#           printf STDERR "[%2d] arrary_ref: %s lastlaparray %s", $i, $array_ref, @lastlaporder;
#           for (my $j = 0; $j <= $finished; $j++) {
#               #printf STDERR "%s ", $lastlaporder[$j];
#               printf STDERR "%s,", ${$array_ref}[$j];
#
#           }
#           printf STDERR "\n";
#       }
#       printf STDERR "------------------\n";
#   }

    for (my $table = 0; ; $table++) {

        my $entries = $Sprint;
        my $last = $first + $width - 1;
        #printf STDERR "LOOP: first: %d last: %d lapstart Count: %d\n", $first, $last, $#lapstart;

        last if ($first > $#lapstart);

        $last = $#lapstart if ($last > $#lapstart);


        push(@Content, 
                do_start_table($cgi, $datestamp, $racetype, $#LastLapOrder, $lapcurrent, $first, $last, $reference_groupsetid, @lapstart));

        my $count = 0;
        for (my $m = 0; $m <= $MaxLapsDown + 1; $m++) {

            printf STDERR "#############################################################\n";
            printf STDERR "m: %d\n", $m;

            #$laparrays[$lap] = \@LastLapOrder;

            my @lastlaporder = @{$laparrays[$last]};

            if ($m == 0) {
                for (my $i = 0 ; ($i < 5) && ($i < $#lastlaporder); $i++ ) {
                    $points{$lastlaporder[$i]} += $PointsRaceDB[$i];
                    printf STDERR "Points[%d] %s %d\n", $i, $lastlaporder[$i], $points{$lastlaporder[$i]};
                }
                foreach my $key (keys %LapsDown) {
                    next unless($LapsDown{$key} > 0);
                    $points{$key} -= 20 * $LapsDown{$key};
                    printf STDERR "Lapped %s %d\n", $key, $points{$key};
                }
            }

            my %laporder;
            my $i = 0;
            for ($i = 0; $i < $#lastlaporder; $i++) {
                $laporder{$lastlaporder[$i]} = $i;
            }
            foreach my $key (sort keys %Riders) {
                next if (defined($laporder{$key}));
                $laporder{$key} = $i++;
            }

            #for (my $i = 0; $i < $finished; $i++);


            foreach my $key (sort { $laporder{$a} <=> $laporder{$b}} keys %laporder)  {

                #printf STDERR "m: %d i: %d\n", $m, $i;

                #my $key = $LastLapOrder[$i];

                #my $key = $lastlaporder[$i];
                my $lapsdown = $LapsDown{$key};

                printf STDERR "[%d:%d] %s lapsdown: %d Points: %s\n", $m, $i, $key, $LapsDown{$key}, $points{$key};

                next unless ($lapsdown == $m); 

                #printf STDERR "OK\n";

                my $behind_ref = $laparraybehind{$key};

                my $tr_class = ($count % 2)  ? 'tr_odd' : 'tr_even';
                push(@Content, 
                        $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" }, 
                            dump_tr($cgi, $racetype, $count, $lapcurrent, $MaxLapsDown, $key, $m, $first, $last, $points{$key}, 0, @{$behind_ref})));

                $count++;
            }
        }
        push(@Content, 
                $cgi->end_table(),
                $cgi->br());

        $first = $last + 1;
    }
    return @Content;
}


1;

