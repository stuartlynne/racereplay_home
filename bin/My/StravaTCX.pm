

package StravaTCX;

use strict;
use Exporter;
use Data::Dumper;
use DateTime::Duration;
use CGI qw/:standard *table start_ul div/;


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(do_strava_tcx);


my $TZ = "PST8PDT";
my $date_format = new DateTime::Format::Strptime( pattern => '%F %T', time_zone => $TZ,);

my @Lat = ( 
    "49.289084", "49.289127", "49.289162", "49.289197", "49.289239", "49.289264", "49.289287",
    "49.289305", "49.289322", "49.289312", "49.289251", "49.289190", "49.289155", "49.289148", 
    "49.289092", "49.289030", "49.288947", "49.288890", "49.288831", "49.288797", "49.288774", 
    "49.288790", "49.288807", "49.288874", "49.288940", "49.289007", "49.289043"       ); 

my @Lon = ( 
     "-122.940027", "-122.940025", "-122.940037", "-122.940055", "-122.940088", "-122.940135", "-122.940175",
     "-122.940239", "-122.940308", "-122.940403", "-122.940580", "-122.940758", "-122.940862", "-122.940880", 
     "-122.940963", "-122.940988", "-122.940987", "-122.940951", "-122.940886", "-122.940818", "-122.940717", 
     "-122.940627", "-122.940563", "-122.940414", "-122.940264", "-122.940115", "-122.940061"      ); 



sub do_strava_tcx_process {
    my ($count, $lapcount, $dt, $lapms) = @_;
    my $gpsms = $lapms / 27;
    my $duration = DateTime::Duration->new( nanoseconds => $gpsms * 1000000 );

    printf STDERR "do_strava_tcx_process: %s count: %d lapcount: %d mod: %d\n", $duration, $count, $lapcount, $lapcount ? $count % $lapcount : 0;


    my $firstflag = 1;

    for (my $i = 0; $i < 27; $i++) {
        my $newdate = $dt;
        $newdate += $i * $duration;
        $newdate->set_time_zone("GMT");
        my $datestr = $newdate->strftime("%Y-%m-%dT%H:%M:%SZ");

        if ($firstflag) {
            $firstflag = 0;

            #printf STDOUT "    <Lap StartTime=\"%s\"> <TriggerMethod>Manual</TriggerMethod> <Track>\n", $datestr;

        }
        #printf STDOUT "[%2d] %s\n", $i, $datestr;

        printf STDOUT "        <Trackpoint><Time>%s</Time>\n", $datestr;
        printf STDOUT "<Position> <LatitudeDegrees>%s</LatitudeDegrees> <LongitudeDegrees>%s</LongitudeDegrees> </Position>",, $Lat[$i], $Lon[$i];
        printf STDOUT "<AltitudeMeters>80.0000000</AltitudeMeters> </Trackpoint>\n";

#       printf STDOUT "<trkpt lat=\"%s\" lon=\"%s\">", $Lat[$i], $Lon[$i];
#       printf STDOUT "<ele>80.0</ele>";
#       printf STDOUT "<time>%s</time></trkpt>\n", $datestr;
    }

    #printf STDOUT "    </Track> <Extensions> </Extensions> </Lap>\n";

}


sub do_strava_tcx {
    my ($dbh, $cgi, $lapcount, $startdate, $venue, $event, $name, $chipid) = @_;

    my $Venue_ref = Misc::get_venue_info($dbh, $venue);
    my $Event_info = Misc::get_event_info($dbh, $startdate, $venue, $event);

    print STDERR Dumper($Event_info);

    my $starttime = $Event_info->{'starttime'};
    my $finishtime = $Event_info->{'finishtime'};

    #my $name = param('name');
    #my $chipid = param('chipid');


    printf STDERR "do_strava_tcx: name; %s chipid: %s\n", $name, $chipid;

    #printf "Content-Type: application/octet-stream\n";
    printf $cgi->header( '-Content-Disposition' => sprintf("attachment;filename=\"%s-%s.tcx\"", $name, $starttime),
            '-Content-Type' => "text/plain");
    
    my $sthl = $dbh->prepare("SELECT * FROM workouts l JOIN chips c ON l.chipid = c.chipid
            WHERE venueid = (SELECT venueid FROM venues 
                WHERE venue=?) AND starttime >= ? and finishtime  <= ? and l.chipid = ? ORDER BY starttime ASC");

    $sthl->execute($venue, sprintf("%s%s", $starttime, "%"), sprintf("%s%s", $finishtime, "%"), $chipid) || die "Execute failed\n";

    my $count = 0;

    my (%Workouts, %Laps, %TotalMS, %BestLapMS, %StartTime, %FinishTime, %ChipName, %Chips, %ChipIDs);

    my $dt = $date_format->parse_datetime($starttime);
    my $datestr = $dt->strftime("%Y-%m-%dT%H:%M:%SZ");


    printf STDOUT "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n";


    printf STDOUT "    <TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\" \n";
    printf STDOUT "        xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \n";
    printf STDOUT "        xsi:schemaLocation=\"http://www.garmin.com/xmlschemas/ActivityExtension/v2 ";
    printf STDOUT "            http://www.garmin.com/xmlschemas/ActivityExtensionv2.xsd ";
    printf STDOUT "            http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 ";
    printf STDOUT "            http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd\">\n";


    printf STDOUT "<Activities> <Activity Sport=\"Biking\"> <Id>%s</Id>\n", $datestr;


    while ( my $row = $sthl->fetchrow_hashref()) {

        my $workoutid = $row->{'workoutid'};

        printf STDERR "do_strava_tcx: workoutid: %s\n", $workoutid;

        printf STDERR "SELECT * FROM laps WHERE workoutid = %s  ORDER BY datestamp ASC\n", $workoutid;

        my $sthd = $dbh->prepare("SELECT * FROM laps WHERE workoutid = ?  ORDER BY datestamp ASC");

        $sthd->execute($workoutid) || die "Execute failed\n";

        my $count = 0;
        unless ($lapcount) {
            printf STDERR "[%d:%d:%d] TRACK START\n", $count, $lapcount, 0;
            printf STDOUT "    <Lap StartTime=\"%s\"> <TriggerMethod>Manual</TriggerMethod> <Track>\n", $datestr;
        }
        while ( my $row = $sthd->fetchrow_hashref()) {

            my $newdate = $date_format->parse_datetime($row->{'datestamp'});
            $newdate->set_time_zone("GMT");
            my $datestr = $newdate->strftime("%Y-%m-%dT%H:%M:%SZ");

            if ($lapcount) {
                if ($count && !($count % $lapcount)) {
                    printf STDERR "[%d:%d:%d] TRACK END\n", $count, $lapcount, $count % $lapcount;
                    printf STDOUT "    </Track> <Extensions> </Extensions> </Lap>\n";
                }
                if (!($count % $lapcount)) {
                    printf STDERR "[%d:%d:%d] TRACK START\n", $count, $lapcount, $count % $lapcount;
                    printf STDOUT "    <Lap StartTime=\"%s\"> <TriggerMethod>Manual</TriggerMethod> <Track>\n", $datestr;
                }
            }

            do_strava_tcx_process($count++, $lapcount, $date_format->parse_datetime($row->{'datestamp'}), $row->{'lapms'});

        }
        printf STDERR "TRACK END LAST\n";
        printf STDOUT "    </Track> <Extensions> </Extensions> </Lap>\n";
        $sthd->finish();
    }

    $sthl->finish();

#   printf STDOUT "</trkseg></trk></gpx>\n";


    printf STDOUT "   <Creator xsi:type=\"Device_t\"> <Name>EDGE705</Name> <UnitId>3475571344</UnitId> <ProductID>625</ProductID>\n";

    printf STDOUT "   <Version> <VersionMajor>3</VersionMajor> <VersionMinor>30</VersionMinor> <BuildMajor>0</BuildMajor> <BuildMinor>0</BuildMinor> </Version> </Creator> \n";

    printf STDOUT "</Activity></Activities>\n";

    printf STDOUT "<Author xsi:type=\"Application_t\"> <Name>Garmin Training Center(r)</Name>\n";

    printf STDOUT "<Build> <Version> <VersionMajor>3</VersionMajor> <VersionMinor>6</VersionMinor> <BuildMajor>5</BuildMajor> <BuildMinor>0</BuildMinor> </Version>\n";

    printf STDOUT "<Type>Release</Type> <Time>Aug 17 2011, 11:13:24</Time> <Builder>sqa</Builder> </Build> <LangID>EN</LangID> <PartNumber>006-A0119-00</PartNumber> </Author>\n";

    printf STDOUT "</TrainingCenterDatabase>\n";
    return;
}

