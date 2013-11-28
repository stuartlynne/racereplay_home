
package FileCSV;

use strict;
use Exporter;
use Data::Dumper;
use CGI qw/:standard *table start_ul div/;


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(do_csv);



sub print_csv_str {
    my ($cell, $last) = @_;
    unless(defined($cell)) { $cell = ""; }
    printf "\"%s\"", $cell;
    if ($last) { printf "\n"; }
    else { printf ","; }
}




sub do_csv {

    my ($dbh, $cgi, $startdate, $venue, $name, $chipid) = @_;

    my $Venue_ref = Misc::get_venue_info($dbh, $venue);
#    my $Event_info = Misc::get_event_info($dbh, $startdate, $venue, $event);
#
#    print STDERR Dumper($Event_info);
#
#    my $starttime = $Event_info->{'starttime'};
#    my $finishtime = $Event_info->{'finishtime'};

    #printf STDERR "do_csv: name; %s chipid: %s\n", $name, $chipid;

    #printf "Content-Type: application/octet-stream\n";
    printf $cgi->header( '-Content-Disposition' => sprintf("attachment;filename=\"%s-%s.csv\"", $name, $startdate),
            '-Content-Type' => "text/plain");
    
#    my $sthl = $dbh->prepare("SELECT * FROM workouts l JOIN chips c ON l.chipid = c.chipid
#            WHERE venueid = (SELECT venueid FROM venues 
#                WHERE venue=?) AND starttime >= ? and finishtime  <= ? and l.chipid = ? ORDER BY starttime ASC");
#
#    $sthl->execute($venue, sprintf("%s%s", $starttime, "%"), sprintf("%s%s", $finishtime, "%"), $chipid) || die "Execute failed\n";
    
    my $sthl = $dbh->prepare("SELECT * FROM workouts l JOIN chips c ON l.chipid = c.chipid
            WHERE venueid = (SELECT venueid FROM venues 
            WHERE venue=?) AND starttime between ? and (? + INTERVAL 1 DAY) ORDER BY starttime ASC");

    $sthl->execute($venue, $startdate, $startdate) || die "Execute failed\n";


    my $count = 0;

    my (%Workouts, %Laps, %TotalMS, %BestLapMS, %StartTime, %FinishTime, %ChipName, %Chips, %ChipIDs);

    print_csv_str("datestamp",0);
    print_csv_str("workoutlap",0);
    print_csv_str("finishms",0);
    print_csv_str("startms",0);
    print_csv_str("groupms",0);
    print_csv_str("lapms",0);
    print_csv_str("groupnumber",0);
    print_csv_str("batt",0);
    print_csv_str("corr",0);
    print_csv_str("skipped",1);

    while ( my $row = $sthl->fetchrow_hashref()) {

        my $workoutid = $row->{'workoutid'};

        #printf STDERR "workoutid: %s\n", $workoutid;

        my $sthd = $dbh->prepare("SELECT * FROM laps WHERE workoutid = ?  ORDER BY datestamp ASC");
        $sthd->execute($workoutid) || die "Execute failed\n";

        while ( my $row = $sthd->fetchrow_hashref()) {
            print_csv_str($row->{'datestamp'},0);
            print_csv_str($row->{'workoutlap'},0);
            print_csv_str($row->{'finishms'},0);
            print_csv_str($row->{'startms'},0);
            print_csv_str($row->{'groupms'},0);
            print_csv_str($row->{'lapms'},0);
            print_csv_str($row->{'groupnumber'},0);
            print_csv_str($row->{'battery'},0);
            print_csv_str($row->{'correction'},0);
            print_csv_str($row->{'skippedflag'},1);
        }
        $sthd->finish();
    }

    $sthl->finish();

    return;


}

