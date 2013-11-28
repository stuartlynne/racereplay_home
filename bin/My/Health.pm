
package Health;

use strict;
use Exporter;
use Data::Dumper;
use CGI qw/:standard *table start_ul div/;


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(do_health);


sub percent {
    my ($count, $total) = @_;
    return (0,0) unless($total);
    my $pc1 = sprintf("%3.1f", ($count / $total) * 100);
    my $pc2 = sprintf("%3.1f%s", ($count / $total) * 100, "%");
    return ($pc1, $pc2);
}

my $redcolor = "#FF6633";
my $greencolor = "#33CC66";
my $yellowcolor = "#FFCC33";
#my $redcolor = "red";

sub colorlow {
    my ($count,$red, $yellow) = @_;
    return $redcolor if ($count <= $red);
    return $yellowcolor if ($count <= $yellow);
    return $greencolor;
}
sub colorhigh {
    my ($count,$red, $yellow) = @_;

    return $greencolor if ($count <= $yellow);
    return $yellowcolor if ($count < $red);
    return $redcolor;
}


sub dodef {
    my ($ref, $def) = @_;
    return $ref if (defined($ref));
    return $def;
}
# ################################################################################################################### #
# do_health
#
sub Health::do_health {

    my ($dbh, $cgi, $venue, $startdate, $action) = @_;

    my $chipid = param('chipid'),

    my @Content;
    my @Aside;

    my $sthl = $dbh->prepare("
        select DATE(w.starttime) AS DATE, COUNT(w.workoutid) WORKOUTS, SUM(w.laps) LAPS, 
            SUM(w.laps) + COUNT(w.workoutid) AS ACTIVATIONS, 
            round((SUM(w.skippedcount) / (SUM(w.laps) + COUNT(w.workoutid))) *100, 1) SKIPPED, 
            round((SUM(w.corrections) / (SUM(w.laps) + COUNT(w.workoutid))) *100, 1) CORRECTIONS,
            round((SUM(w.battery) / (SUM(w.laps) + COUNT(w.workoutid))) *100 ,1)  BATT,
            DATES.D1, c.chip, c.shortname
        from workouts w
        left join chips c on c.chipid = w.chipid
        left join 
            (select b1.chipid, b1.batteryid B1, b1.batterydate D1, b2.batteryid B2, b2.batterydate D2 
             from batteryhistory b1
             left join batteryhistory b2 on b1.chipid = b2.chipid and b2.batterydate > b1.batterydate 
             group by b1.batterydate) 
            DATES on DATES.chipid = w.chipid and (D1 is not null and D1 < w.starttime and ( D2 is null or D2 > w.starttime))
            where w.chipid = ?
            group by WEEK(w.starttime)
        order by w.workoutid asc
        ");

    $sthl->execute($chipid) || die "Execute failed\n";

    my (%Workouts, %Laps, %TotalMS, %BestLapMS, %StartTime, %FinishTime, %ChipName, %Chips, %ChipIDs);

    my $firstflag = 1;

    my $count = 0;

    my $totalactivations = 0;
    my $totalworkouts = 0;
    my $totalbatt = 0;
    my $totalskipped = 0;
    my $totalcorrections = 0;

    my $chip = "";
    my $shortname = "";

    my $lastdate = "";

    while ( my $row = $sthl->fetchrow_hashref()) {

        printf STDERR Dumper($row);

        my $chip = $row->{'chip'} if (defined($row->{'chip'}));
        my $shortname = $row->{'shortname'} if (defined($row->{'shortname'}));

        my $date = $row->{'DATE'};
        my $workouts = $row->{'WORKOUTS'};
        my $activations = $row->{'ACTIVATIONS'};
        my $skipped = $row->{'SKIPPED'};
        my $corrections = $row->{'CORRECTIONS'};
        my $batt = $row->{'BATT'};
        my $batterydate = dodef($row->{'D1'}, "-");

        $totalactivations += $activations;
        $totalworkouts += $workouts;
        $totalbatt += $batt;
        $totalskipped += $skipped;
        $totalcorrections += $corrections;

        if ($lastdate eq $batterydate) {
            $batterydate = "-";
        }
        else {
            $lastdate = $batterydate;
        }

        my $batterycolor = colorlow($batt, 90, 98);
        my $correctionscolor = colorhigh($corrections, 10, 5);
        my $skippedcountcolor = colorhigh($skipped, 10, 5);

        my $datestamp = dodef($row->{'datestamp'}, "-");

        #my $tr_class = ($count % 2) ? 'tr_odd' : 'tr_even';
        my $tr_class = "";
        unshift(@Content, 
                $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" },
                    $cgi->td($date),
                    $cgi->td($workouts),
                    $cgi->td($activations),
                    #$cgi->td({-bgcolor => $batterycolor},$batt),
                    #$cgi->td({-bgcolor => $correctionscolor},$corrections),
                    $cgi->td({-bgcolor => $skippedcountcolor},$skipped),
                    #$cgi->td($batterydate),
                    )
            );

        $count++;
    }
    $sthl->finish();
    my $tr_class = "";
    push(@Content, 
            $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" },
                $cgi->td(""),
                $cgi->td($totalworkouts),
                $cgi->td($totalactivations),
                #$cgi->td(sprintf("%3.0f", $totalbatt / $count)),
                #$cgi->td(sprintf("%3.0f", $totalcorrections / $count)),
                $cgi->td(sprintf("%3.0f", $totalskipped / $count)),
                #$cgi->td(""),
                )
           );


    unshift(@Content,
            $cgi->start_form(),
            $cgi->hidden('venue', $venue),
            $cgi->hidden('chipid', $chipid),

            $cgi->h1(sprintf ("Race Replay - Chip Health")),
            $cgi->start_table({ -border => 1, -cellpadding => 3 }),

            $cgi->start_table({ -class => "table", -border => 1, -cellpadding => 3 }),
            $cgi->caption({-class => "large_left_caption"}, "Health"),
            $cgi->Tr({ -align => "CENTER", -valign => "BOTTOM" },
                $cgi->td( [
                    $cgi->b("Date"), 
                    $cgi->b("Workouts"), 
                    $cgi->b("Laps"), 
                    #$cgi->b("BATT OK (Low is Bad)"), 
                    #$cgi->b("Corrections (High is Bad)"), 
                    $cgi->b("Skipped (High is Bad)"), 
                    #$cgi->b("Last Battery"), 
                    ])),
           );

    push(@Content, 

            $cgi->end_table(),

            $cgi->defaults('Restart form'),
            $cgi->end_form(),

            $cgi->br,
            $cgi->hr,
        );

    push(@Aside,
        $cgi->h2("Battery Status"),
        "If there is a significant number of BATT OK flags being seen as FALSE then this will be set to BAD.\n",
        "This will be set if there has been a workout with at least 20 activations where the BATT OK count is less than 90%.\n",

        $cgi->h2("Total Activations"),
            "The total number of activations the Race Replay system has recorded for this transponder chip.\n",

            #$cgi->h2("BATT OK"),
            #"This is the total number of battery OK flags counted. The closer to 100% the better your battery is. \n",
            #"Anything less than 100% indicates that the transponder chip has reported that the battery voltage was low.\n",
            #"When the voltage is near the cutoff (3.0V) this may not happen on every activation, but will still be a warning that the battery will need to be changed soon.\n",

            #$cgi->h2("Corrections"),
            #"This is the number of times that the transponder chip had to re-transmit its ID before the timing system recieved a valid response. \n",
            #"Numbers close to zero are best.\n",
            #"High numbers can indicate two different problems, either that the battery is low or that the transponder chip is not mounted in a good location.\n",

            $cgi->h2("Skipped"),
            "As the timing data is imported into the Race Replay Database it can in some cases recognize if the timing system did not receive an activation message \n",
            "from the transponder chip. This should be zero.\n",
            "This can be due to various problems. Typically it could be one of a low battery, bad mounting location and very occasionally \n",
            "some external issue such as too many other riders on the track (which can block the signal).\n",

            );

    return (\@Content, \@Aside);
}




1;

