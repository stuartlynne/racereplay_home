

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
    my ($dbh, $cgi, $venue, $venueid, $event, $eventid, $startdate, $starttime, $finishtime, $distance) = @_;

    my $total = 0;

    #my $sth = $dbh->prepare("SELECT * FROM lapsets l JOIN chips c ON l.chipid = c.chipid
    #        WHERE venueid = (SELECT venueid FROM venues 
    #        WHERE venue=?) AND starttime >= ? and finishtime  <= ? ORDER BY starttime ASC");
    my $sth = $dbh->prepare("SELECT * FROM lapsets l JOIN chips c ON l.chipid = c.chipid
            WHERE venueid = (SELECT venueid FROM venues 
            WHERE venue=?) AND starttime between ? and ? ORDER BY starttime ASC");

    $sth->execute($venue, sprintf("%s%s", $starttime, "%"), sprintf("%s%s", $finishtime, "%")) || die "Execute failed\n";

    my $count = 0;

    my (%Workouts, %Laps, %TotalMS, %BestLapMS, %StartTime, %FinishTime, %ChipName, %UserName, %Chips, %ChipIDs, %ReplaceBattery);


    while ( my $row = $sth->fetchrow_hashref()) {

        #printf STDERR Dumper(%Workouts);
        #printf STDERR Dumper($row);
        my $totalms = $row->{'totalms'};
        next unless ($totalms != 0);;
        my $laps = $row->{'laps'};
        next unless($laps > 2);

        printf STDERR "[%d] lapsetid: %s start: %s finish: %s\n", $count, $row->{'lapsetid'}, $row->{'starttime'}, $row->{'finishtime'};

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
            $cgi->hidden('event', $event),
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
            SELECT g.groupsetid, g.members, l.lapnumber, g.datestamp, l.lapsetid
            FROM groupsets g 
            JOIN events e ON e.venueid = g.venueid
            JOIN laps l ON l.groupsetid = g.groupsetid
            JOIN lapsets s ON l.lapsetid = s.lapsetid
            WHERE 
                g.datestamp BETWEEN e.starttime AND e.finishtime 
                AND e.eventid = ? 
                AND l.lapnumber = 0
                and g.members > 3
            ");

    $sth->execute($eventid) || die "Execute failed\n";

    my $count = 0;
    my %GroupSetCount;
    my %GroupSetDateStamp;
    my %GroupSetMembers;
    while ( my $row = $sth->fetchrow_hashref()) {
        printf STDERR Dumper($row);

        my $groupsetid = $row->{'groupsetid'};

        unless (defined($GroupSetMembers{$groupsetid})) {
            $GroupSetDateStamp{$groupsetid} = $row->{'datestamp'};
            $GroupSetMembers{$groupsetid} = $row->{'members'};
            $GroupSetCount{$groupsetid} = 0;
        }
        $GroupSetCount{$groupsetid}++;
    }
    $sth->finish();

    my @Content = ();

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


    my %MaxLaps;
    my $count = 0;
    foreach my $key (sort keys(%GroupSetMembers)) {
        printf STDERR "groupsetid: %s members: %d count: %d\n", $key, $GroupSetMembers{$key}, $GroupSetCount{$key};

        next unless ($GroupSetCount{$key} >= ($GroupSetMembers{$key} - 1));
        next unless ($GroupSetMembers{$key} > 3);

#       my $sthn = $dbh->prepare("
#               SELECT MAX(L.lapnumber) MAXLAP, L.lapsetid
#               FROM laps L0
#               JOIN lapsets S ON L0.lapsetid = S.lapsetid 
#               JOIN laps L ON L.lapsetid = S.lapsetid
#               WHERE L0.groupsetid = ?
#               ");
#
#       $sthn->execute($key) || die "Execute failed\n";
#       my $row = $sthn->fetchrow_hashref();
#       $sthn->finish();
#       $MaxLaps{$key} = $row->{'MAXLAP'};
#       next unless ($MaxLaps{$key} > 5);

        my $sthn = $dbh->prepare("
                SELECT S.laps
                FROM laps L
                JOIN lapsets S ON L.lapsetid = S.lapsetid 
                WHERE L.groupsetid = ?
                ");

        $sthn->execute($key) || die "Execute failed\n";
        my %allmaxlaps;
        while (my $row = $sthn->fetchrow_hashref()) {

            #printf STDERR Dumper($row);
            my $maxlaps = $row->{'laps'};
            #next unless ($maxlaps > 5);
            $allmaxlaps{$maxlaps}++;
            printf STDERR "MAXLAP: %d %d\n", $maxlaps, $allmaxlaps{$maxlaps};
        }
        $sthn->finish();

        my $maxlapcount = 0;
        foreach my $akey (sort keys(%allmaxlaps)) {
            printf STDERR "allmaxlaps{%s} %d\n", $akey, $allmaxlaps{$akey};
            next if ($maxlapcount >= $allmaxlaps{$akey});
            $MaxLaps{$key} = $akey;
            $maxlapcount = $allmaxlaps{$akey};
        }



        my %CorrectionLabels = ( '-2' => 'Down 2', '-1' => 'Down 1', '0' => '0', '1' => 'Up 1', '2' => 'Up 2' );
        my @CorrectionValues = [-2, -1, 0, 1, 2];

        my %SprintLabels = ( '10' => '10 laps', '12' => '12 laps', '8' => '8 laps', '5' => '5 laps', '3' => '3 laps', '2' => '2 laps' );
        my @SprintValues = [10, 12, 8, 5, 3, 2];

        my %RaceTypeLabels = ( 
                'Lap Race' => 'Lap Race', 
                'Points Race' => 'Points Race', 
                'Scratch Race' => 'Scratch Race', 
                'Elimination Race' => 'Elimination Race', 
                );
        my @RaceTypeValues = ['Lap Race', 'Points Race', 'Scratch Race', 'Elimination Race'];

        my $datestamp = $GroupSetDateStamp{$key};
        $datestamp =~ s/.* //;
        my $tr_class = ($count++ % 2) ? 'tr_odd' : 'tr_even';
        push(@Content,
            $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" },
                $cgi->td([
                        $cgi->a({ href => sprintf("/race.pl?venueid=%d&eventid=%d&groupsetid=%d&maxlaps=%d", 
                                $venueid, $eventid, $key, $MaxLaps{$key}),},$datestamp),
                        $GroupSetMembers{$key}, 
                        #$GroupSetCount{$key},
                        $MaxLaps{$key}, 
 #                       $cgi->checkbox(sprintf("race-%s", $key),0, $key,""),
 #                      $cgi->popup_menu(
 #                          -name => sprintf("correction-%s", $key),
 #                          -values =>  @CorrectionValues,
 #                          -default => '0',
 #                          -linebreak => 'true',
 #                          -labels => \%CorrectionLabels,
 #                          -columns=>2
 #                          ),
 #                      $cgi->popup_menu(
 #                          -name => sprintf("racetype-%s", $key),
 #                          -values =>  @RaceTypeValues,
 #                          -default => '0',
 #                          -linebreak => 'true',
 #                          -labels => \%RaceTypeLabels,
 #                          -columns=>2
 #                          ),
 #                      $cgi->popup_menu(
 #                          -name => sprintf("sprint-%s", $key),
 #                          -values =>  @SprintValues,
 #                          -default => '0',
 #                          -linebreak => 'true',
 #                          -labels => \%SprintLabels,
 #                          -columns=>2
 #                          ),
                       ]
                    )
                )
            );
    }
    push(@Content,
            $cgi->end_table(),
        );

    foreach my $key (sort keys(%GroupSetMembers)) {
        printf STDERR "groupsetid: %s members: %d count: %d\n", $key, $GroupSetMembers{$key}, $GroupSetCount{$key};

        next unless ($GroupSetCount{$key} >= ($GroupSetMembers{$key} - 1));
        next unless ($GroupSetMembers{$key} > 3);

        push(@Content, $cgi->hidden(sprintf("maxlap-%s", $key), $MaxLaps{$key}));
        push(@Content, $cgi->hidden(sprintf("members-%s", $key), $GroupSetMembers{$key}));
        push(@Content, $cgi->hidden(sprintf("datestamp-%s", $key), $GroupSetDateStamp{$key}));

    }


    #my $reportcount = 0;
    #foreach my $key (sort keys(%GroupSetMembers)) {
    #    next unless ($GroupSetCount{$key} >= ($GroupSetMembers{$key} - 1));
    #    next unless ($GroupSetMembers{$key} > 3);
    #    printf STDERR "groupsetid: %s members: %d count: %d\n", $key, $GroupSetMembers{$key}, $GroupSetCount{$key};
    #    push(@Content, do_analysis ($dbh, $cgi, $reportcount++, $key, -1, 0));
    #}

    return @Content;
}


1;

