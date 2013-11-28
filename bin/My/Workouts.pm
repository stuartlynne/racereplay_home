

package Workouts;

use strict;
use Exporter;
use Data::Dumper;
use CGI qw/:standard *table start_ul div/;


use My::FKey qw(init find finish);
use My::Misc qw(kph hhmm);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(do_summary_workouts do_summary_races);



# do_summary_workouts
#
sub Workouts::do_summary_workouts {
    my ($dbh, $cgi, $venue, $venueid, $startdate, $distance) = @_;

    my $total = 0;

    printf STDERR "do_summary_workouts: startdate: %s starttime: %s\n", $startdate;

    my $sth = $dbh->prepare("SELECT * FROM workouts l JOIN chips c ON l.chipid = c.chipid
            WHERE venueid = (SELECT venueid FROM venues 
            WHERE venue=?) AND starttime between ? and (? + INTERVAL 1 DAY) ORDER BY starttime ASC");

    $sth->execute($venue, $startdate, $startdate) || die "Execute failed\n";

    my $count = 0;

    my (%Workouts, %Laps, %TotalMS, %BestLapMS, %StartTime, %FinishTime, %ChipName, %UserName, %Chips, %ChipIDs, %ReplaceBattery);


    while ( my $row = $sth->fetchrow_hashref()) {

        #printf STDERR Dumper(%Workouts);
        #printf STDERR Dumper($row);
        my $totalms = $row->{'totalms'};
        next unless ($totalms != 0);;
        my $laps = $row->{'laps'};
        next unless($laps > 2);

        printf STDERR "[%d] workoutid: %s start: %s finish: %s\n", $count, $row->{'workoutid'}, $row->{'starttime'}, $row->{'finishtime'};

        my $chipid = $row->{'chipid'};
        my $chip = $row->{'chip'};

        unless ($Chips{$chip}) {
            my $shortname = Misc::get_loaner($dbh, $chipid, $row->{'chip'});
            $Chips{$chipid} = $shortname;
        }

        # derive user info from chipid via chiphistory table
        #
        my ($userid, $name) = Misc::get_user_name($dbh, $Chips{$chipid}, $chipid, $row->{'starttime'});
        my $key = sprintf("%s-%s", $name, $chip);

        unless (defined($Workouts{$key})) {
            $Workouts{$key} = 1;
            $Laps{$key} = $row->{'laps'};
            $TotalMS{$key} = $row->{'totalms'};
            $StartTime{$key} = $row->{'starttime'};
            $FinishTime{$key} = $row->{'finishtime'};
            $BestLapMS{$key} = $row->{'bestlapms'};
            $ChipName{$key} = $Chips{$chipid};
            #$ChipName{$key} = $Chips{$chipid};
            $ChipIDs{$key} = $chipid;
            $UserName{$key} = $name;
            $ReplaceBattery{$key} = $row->{'replacebattery'};
            printf STDERR "name: %s chipid: %s\n", $key, $chipid;
        }
        else {
            $Workouts{$key}++;
            $Laps{$key} += $row->{'laps'};
            $TotalMS{$key} += $row->{'totalms'};
            $FinishTime{$key} = $row->{'finishtime'};
            $ReplaceBattery{$key} |= $row->{'replacebattery'};
            #printf STDERR "BestLaps: %s > %s\n", $BestLapMS{$key},$row->{'bestlapms'};
            if ($BestLapMS{$key} > $row->{'bestlapms'}) {
                $BestLapMS{$key} = $row->{'bestlapms'};
            }
        }

        printf STDERR "[%d] %s %s %3s %s %s %s ms: %s laps: %s\n", 
               $count++, $row->{'chip'}, $Chips{$chipid}, $userid, $key, $row->{'starttime'}, $row->{'finishtime'}, $row->{'totalms'}, $row->{'laps'};

    }
    $sth->finish();


    my @Content;

    push(@Content, 
            $cgi->start_form(),
            $cgi->hidden('venue', $venue),
            #$cgi->hidden('event', $event),
            $cgi->hidden('startdate', $startdate),
        );

    # dump a table out
    #
    

    push(@Content, 
            $cgi->start_table({ -class => 'table', -cellpadding => 3 }),
            $cgi->caption({-class => "small_left_caption"}, ),
            $cgi->Tr({ -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" },
                $cgi->th( [
                    $cgi->b("Start"), 
                    $cgi->b("Finish"), 
                    $cgi->b("Name"), 
                    $cgi->b("Chip"), 
                    $cgi->b("HH:MM"), 
                    $cgi->b("Workouts"), 
                    $cgi->b("Laps"), 
                    $cgi->b("Distance (km)"), 
                    $cgi->b("Avg (kph"), 
                    $cgi->b("Fastest"), 
                    $cgi->b("Best Lap (kph)"),
                    $cgi->b("Battery"),
                    $cgi->b("Select")
                    ]))
        );

    print STDERR "StartTime\n", Dumper(%StartTime);

    # iterate across %Laps to generate table, sort on starttime
    #
    $count = 0;
    foreach my $key (sort { $StartTime{$a} cmp $StartTime{$b}} keys(%StartTime)  ) 
    {

        my $seconds = $TotalMS{$key} / 1000;
        my $minutes = ($seconds / 60) %60;
        my $hours = ($seconds / (60 * 60));
        $seconds = $seconds % 60;

        printf STDERR "name: %s\n", $key;

        my $bestlapms = $BestLapMS{$key} / 1000;
        my $fastest = Misc::kph($distance, $bestlapms); 

        printf STDERR "%-30s %s Laps: %3d %4.1f km Fastest: %5.2f %5.2f \n",
               $key, $ChipName{$key}, $Laps{$key}, $Laps{$key} * $distance, $bestlapms, $fastest;

        my $starttime = Misc::hhmm($StartTime{$key});
        my $finishtime = Misc::hhmm($FinishTime{$key});

        my $myself = $cgi->self_url();

        my $replacebattery = $ReplaceBattery{$key} ? "BAD" : "OK";

        my $tr_class = ($count % 2) ? 'tr_odd' : 'tr_even';

        push(@Content, 
                $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" },
                    $cgi->td($starttime),
                    $cgi->td($finishtime),
                    #$cgi->td( sprintf("<a href=\"%s&doworkouts=%s\">%s</a>", $myself, $key, $key)),
                    $cgi->td( $UserName{$key}),
                    $cgi->td($ChipName{$key}),
                    $cgi->td(sprintf("%d:%02d", $hours, $minutes)),
                    $cgi->td($Workouts{$key}),
                    $cgi->td($Laps{$key}),
                    $cgi->td(sprintf("%5.1f", $Laps{$key} * $distance)),
                    $cgi->td(sprintf("%5.1f", Misc::kph(($Laps{$key} * $distance), $TotalMS{$key}))),
                    $cgi->td(sprintf("%5.1f", $BestLapMS{$key}/1000)),
                    $cgi->td(sprintf("%5.1f", Misc::kph(($distance), $BestLapMS{$key}))),
                    #$cgi->td($cgi->submit('action', $key, $key))
                    $cgi->td($replacebattery),
                    $cgi->td(checkbox(sprintf("select-%s", $key),0, $ChipIDs{$key},""))
                    )
                );

        $count++;
    }

    push(@Content, 
            $cgi->end_table(),
            $cgi->br(),
            #$cgi->reset("Defaults"),
            #$cgi->defaults('Restart form'),
            #$cgi->submit('action',"Details"),
            #$cgi->end_form(),
        );
    
    return @Content;
}

# do_summary_races
#
sub Workouts::do_summary_races {
    my ($dbh, $cgi, $venue, $venueid, $event, $eventid, $startdate, $starttime, $finishtime, $distance) = @_;

    my $total = 0;

    my $sth = $dbh->prepare("
            SELECT R.raceid, R.entries, R.lastlap, G.datestamp, G.groupsetid
            FROM races R
            JOIN events E ON E.eventid = ?
            JOIN groupsets G on G.groupsetid = R.groupsetid
            WHERE G.datestamp BETWEEN E.starttime AND E.finishtime
            ORDER by G.datestamp
            ");

    $sth->execute($eventid) || die sprintf("Execute failed: %s\n", $sth->errstr);

    my @Races;

    while ( my $row = $sth->fetchrow_hashref()) {
        push (@Races, $row);
        printf STDERR Dumper($row);
    }
    $sth->finish();

    my @Content = ();

    return @Content unless($#Races);

    push(@Content,

            $cgi->start_table({ -class => 'table', -cellpadding => 3 }),
            $cgi->caption({-class => "small_left_caption"},),
            $cgi->Tr({ -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" },
                $cgi->th( [
                    $cgi->b("Races"), 
                    $cgi->b("Riders"), 
                    $cgi->b("Laps"), 
                    #$cgi->b("Select"), 
                    #$cgi->b("Correction"), 
                    #$cgi->b("Type"), 
                    #$cgi->b("Sprints"), 
                    ])),
        );

    my $count = 0;
    for (my $i = 0; $i <= $#Races; $i++) {

        my $row = $Races[$i];
        printf STDERR Dumper($row);

    
        my $datestamp = $row->{'datestamp'};
        my $groupsetid = $row->{'groupsetid'};
        my $raceid = $row->{'raceid'};
        my $lastlap = $row->{'lastlap'};
        my $entries = $row->{'entries'};


        $datestamp =~ s/.* //;

        my $tr_class = ($count++ % 2) ? 'tr_odd' : 'tr_even';
        push(@Content,
            $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" },
                $cgi->td([
                        $cgi->a({ href => sprintf("/race.pl?venueid=%d&eventid=%d&groupsetid=%d&raceid=%d&maxlaps=%d", 
                                $venueid, $eventid, $groupsetid, $raceid, $lastlap),},$datestamp),
                        $entries, 
                        $lastlap, 
                       ]
                    )
                )
            );
    }
    push(@Content,
            $cgi->end_table(),
        );

    #foreach my $key (sort keys(%GroupSetMembers)) {
    #    printf STDERR "groupsetid: %s members: %d count: %d\n", $key, $GroupSetMembers{$key}, $GroupSetCount{$key};

    #    next unless ($GroupSetCount{$key} >= ($GroupSetMembers{$key} - 1));
    #    next unless ($GroupSetMembers{$key} > 3);

    #    push(@Content, $cgi->hidden(sprintf("maxlap-%s", $key), $MaxLaps{$key}));
    #    push(@Content, $cgi->hidden(sprintf("members-%s", $key), $GroupSetMembers{$key}));
    #    push(@Content, $cgi->hidden(sprintf("datestamp-%s", $key), $GroupSetDateStamp{$key}));

    #}

    return @Content;
}


1;

