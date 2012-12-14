#!/usr/bin/perl


my $DATABASE = "racereplay";
my $DBUSER = "racereplay";
my $DBPASSWORD = "aa.bb.cc";

my $DEBUG = 1;
my $VERBOSE = 1;

use strict;
use warnings;

use DBI;
use CGI qw/:standard *table start_ul/;
use Time::CTime;
use Sys::Hostname;

use Text::CSV;
use Date::Simple('date','today');

#use DateTime;
#use DateTime::TimeZone;
use DateTime::Locale;
use DateTime::Format::Strptime;
use DateTime::Duration;
use Data::Dumper;

use Time::HiRes;


my $time;
my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
#my $user = sprintf("%s@%s", $ENV{ "USER" }, hostname);

#my $TZ = $ENV{ 'TZ' };
my $TZ = "PST8PDT";

#printf STDERR "TZ: %s\n", $TZ if ($DEBUG);
 
my $date_format = new DateTime::Format::Strptime( pattern => '%F %T', time_zone => $TZ,);

my %Venues;
my %Descriptions;
my @VenueNames;

# ################################################################################################################### #

my $headerfirst = 1;

sub do_header {
    my ($dbh, $cgi) = @_;

    if ($headerfirst) {
        $headerfirst = 0;
        printf $cgi->header;
        printf $cgi->start_html("Race Replay Form");
    }
    else {
        print $cgi->hr;
        printf $cgi->start_html();
    }
    

}

sub do_footer {
    my ($dbh, $cgi) = @_;
    print $cgi->Dump() if ($VERBOSE);
    printf $cgi->end_html();
}


sub dodef {
    my ($ref) = @_;
    return $ref if (defined($ref));
    return "";
}


# ################################################################################################################### #
sub percent {
    my ($count, $total) = @_;
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

sub do_health {

    my ($dbh, $cgi, $chipid) = @_;

    #printf STDERR "do_health: name; %s chipid: %s\n", $name, $chipid;

    #printf "Content-Type: application/octet-stream\n";
    do_header($dbh, $cgi);
    print $cgi->start_form();
    print $cgi->hidden('chipid', $chipid);
    
    my $sthl = $dbh->prepare("SELECT datestamp,chip,shortname,currentactivations,totalactivations,replacebattery,activations,battery,skippedcount,corrections 
            FROM chips c LEFT JOIN health h ON c.chipid = h.chipid
            WHERE c.chipid = ? ORDER BY datestamp DESC");

    $sthl->execute($chipid) || die "Execute failed\n";

    my $count = 0;

    my (%Workouts, %Laps, %TotalMS, %BestLapMS, %StartTime, %FinishTime, %ChipName, %Chips, %ChipIDs);

    my $firstflag = 1;
    while ( my $row = $sthl->fetchrow_hashref()) {

        my $chip = $row->{'chip'};
        my $shortname = $row->{'shortname'};
        my $replacebattery = $row->{'replacebattery'} ? "BAD" : "OK";
        my $currentactivations = $row->{'currentactivations'};
        my $totalactivations = $row->{'totalactivations'};
        my $activations = $row->{'activations'};

        if ($firstflag) {
            $firstflag = 0;

            $chip = $shortname if (defined($shortname) && $shortname ne "");

            print $cgi->h1(sprintf ("Race Replay - Chip Health"));
            #print $cgi->h2(sprintf ("%s - Battery Status: %s - Total Activations: %d", $chip, $replacebattery, $totalactivations));

            print $cgi->start_table({ -border => 1, -cellpadding => 3 });
            my $BatStatColor = $greencolor;
            if ($replacebattery eq "BAD") {
                $BatStatColor = $redcolor;
            }
            print $cgi->Tr({ -align => "CENTER", -valign => "TOP" },
                    $cgi->td( [
                        $cgi->b("TagID"), 
                        $cgi->b("Name"), 
                        $cgi->b("Battery Status"), 
                        $cgi->b("Current Activations"), 
                        $cgi->b("Total Activations"), 
                        ]));
            print $cgi->Tr({ -align => "CENTER", -valign => "TOP" },
                    $cgi->td($chip),
                    $cgi->td($shortname),
                    $cgi->td({-bgcolor => $BatStatColor}, $replacebattery),
                    $cgi->td($currentactivations),
                    $cgi->td($totalactivations),
                    );

            print $cgi->end_table();
            print $cgi->br;
            print $cgi->start_table({ -border => 1, -cellpadding => 3 });
            print $cgi->Tr({ -align => "CENTER", -valign => "TOP" },
                    $cgi->td( [
                        $cgi->b("Date"), 
                        $cgi->b("Activations"), 
                        $cgi->b("BATT OK (Low is Bad)"), 
                        $cgi->b("Corrections (High is Bad)"), 
                        $cgi->b("Skipped (High is Bad)"), 
                        ]));
        }
        printf STDERR Dumper($row);
        printf STDERR "date: %s\n", $row->{'datestamp'};

        my ($batterypc, $batterypcf) = percent($row->{'battery'}, $activations);
        my ($correctionspc, $correctionspcf) = percent($row->{'corrections'}, $activations);
        my ($skippedcountpc, $skippedcountpcf) = percent($row->{'skippedcount'}, $activations);

        my $batterycolor = colorlow($batterypc, 90, 98);
        my $correctionscolor = colorhigh($correctionspc, 10, 5);
        my $skippedcountcolor = colorhigh($skippedcountpc, 10, 5);

        print $cgi->Tr({ -align => "CENTER", -valign => "TOP" },
                $cgi->td($row->{'datestamp'}),
                $cgi->td($row->{'activations'}),
                $cgi->td({-bgcolor => $batterycolor},$batterypcf),
                $cgi->td({-bgcolor => $correctionscolor},$correctionspcf),
                $cgi->td({-bgcolor => $skippedcountcolor},$skippedcountpcf),
                );
    }


    $sthl->finish();

    print $cgi->end_table();

    print $cgi->defaults('Restart form');
    print $cgi->end_form();

    print $cgi->br;
    print $cgi->hr;

    do_footer($dbh, $cgi);

    return;


}

sub do_chip_health {

    my ($dbh, $cgi) = @_;

    printf STDERR "do_chip_health\n";

    do_header($dbh, $cgi);
    print $cgi->h2("Chip Health");
    #print $cgi->start_form();

    for my $key (param) {
        my $parameter = param($key);

        next unless ($key =~ /select-/);

        $key =~ s/select-//;
        printf STDERR "key: %s\n", $key;
        printf STDERR "parameter: %s\n", $parameter;
        do_health($dbh, $cgi, $key);

    }

    print $cgi->h2("Battery Status");
    print "If there is a significant number of BATT OK flags being seen as FALSE then this will be set to BAD.\n";
    print "This will be set if there has been a workout with at least 20 activations where the BATT OK count is less than 90%.\n";

    print $cgi->h2("Current Activations");
    print "The total number of activations the Race Replay system has recorded for this transponder chip since the last battery change.\n";

    print $cgi->h2("Total Activations");
    print "The total number of activations the Race Replay system has recorded for this transponder chip.\n";

    print $cgi->h2("BATT OK");
    print "This is the total number of battery OK flags counted. The closer to 100% the better your battery is. \n";
    print "Anything less than 100% indicates that the transponder chip has reported that the battery voltage was low.\n";
    print "When the voltage is near the cutoff (3.0V) this may not happen on every activation, but will still be a warning that the battery will need to be changed soon.\n";

    print $cgi->h2("Corrections");
    print "This is the number of times that the transponder chip had to re-transmit its ID before the timing system recieved a valid response. \n";
    print "Numbers close to zero are best.\n";
    print "High numbers can indicate two different problems, either that the battery is low or that the transponder chip is not mounted in a good location.\n";

    print $cgi->h2("Skipped");
    print "As the timing data is imported into the Race Replay Database it can in some cases recognize if the timing system did not receive an activation message \n";
    print "from the transponder chip. This should be zero.\n";
    print "This can be due to various problems. Typically it could be one of a low battery, bad mounting location and very occasionally \n";
    print "some external issue such as too many other riders on the track (which can block the signal).\n";

    print $cgi->hr();

    #print $cgi->end_form();

    print $cgi->br;
    do_footer($dbh, $cgi);
}


# ################################################################################################################### #
my @Titles;

sub do_test {

    my ($dbh, $cgi) = @_;

    #printf STDERR "do_health: name; %s chipid: %s\n", $name, $chipid;

    #printf "Content-Type: application/octet-stream\n";
    do_header($dbh, $cgi);
    print $cgi->start_form();
    print $cgi->hr();
    print $cgi->defaults('Restart form');
    print $cgi->submit('action',"Chip Health");


    print $cgi->end_table();

    print $cgi->defaults('Restart form');
    print $cgi->end_form();

    do_footer($dbh, $cgi);

    return;


}



# ################################################################################################################### #

sub do_battery {

    my ($dbh, $cgi, $today, $chipid) = @_;

    #printf STDERR "do_health: name; %s chipid: %s\n", $name, $chipid;

    #printf "Content-Type: application/octet-stream\n";
    do_header($dbh, $cgi);
    print $cgi->start_form();
    print $cgi->hidden('chipid', $chipid);

    
    #my $sthl = $dbh->prepare("SELECT datestamp,chip,shortname,currentactivations,totalactivations,replacebattery,activations,battery,skippedcount,corrections 
    #        FROM chips c LEFT JOIN health h ON c.chipid = h.chipid
    #        WHERE c.chipid = ? ORDER BY datestamp DESC");

    #$sthl->finish();

    print $cgi->end_table();

    print $cgi->defaults('Restart form');
    print $cgi->end_form();

    print $cgi->br;
    print $cgi->hr;

    do_footer($dbh, $cgi);

    return;


}

sub do_new_battery {

    my ($dbh, $cgi) = @_;

    printf STDERR "do_new_battery\n";

    my $today = today();

    do_header($dbh, $cgi);
    print $cgi->h2("Chip Health");

    #print $cgi->start_form();

    for my $key (param) {
        my $parameter = param($key);

        next unless ($key =~ /select-/);

        $key =~ s/select-//;
        printf STDERR "key: %s\n", $key;
        printf STDERR "parameter: %s\n", $parameter;
        do_battery($dbh, $cgi, $today, $key);

    }

    print $cgi->br;
    do_footer($dbh, $cgi);
}
# ################################################################################################################### #


sub do_chip_summary {

    my ($dbh, $cgi) = @_;

    #printf STDERR "do_health: name; %s chipid: %s\n", $name, $chipid;

    #printf "Content-Type: application/octet-stream\n";
    do_header($dbh, $cgi);
    print $cgi->start_form();
    
    my $sthl = $dbh->prepare("SELECT c.chipid, chip, shortname, currentactivations, totalactivations, replacebattery, batteryreplaced, lastname, firstname, organizer  FROM chips c 
            LEFT JOIN organizers o ON c.organizerid = o.organizerid 
            LEFT JOIN chiphistory h ON c.chipid = h.chipid AND h.finishtime = '00-00-00 00:00:00'
            LEFT JOIN users u ON h.userid = u.userid 
            ORDER BY replacebattery DESC, currentactivations DESC, chip ASC");

    $sthl->execute() || die "Execute failed\n";

    my $count = 0;

    my $firstflag = 1;
    print $cgi->start_table({ -border => 1, -cellpadding => 3 });
    print $cgi->Tr({ -align => "CENTER", -valign => "TOP" },
            $cgi->td( [
                $cgi->b("Select"),
                $cgi->b("Chip"), 
                $cgi->b("Shortname"), 
                $cgi->b("User"), 
                $cgi->b("Replace Battery"), 
                $cgi->b("Current Activations"), 
                $cgi->b("Total Activations"), 
                $cgi->b("Organizer"), 
                $cgi->b("Last Battery"), 
                ]));
    while ( my $row = $sthl->fetchrow_hashref()) {

        #printf STDERR Dumper($row);
        #my $lastname = $row->{'lastname'} if (defined($row->{'lastname'}));
        #my $firstname = $row->{'firstname'} if (defined($row->{'firstname'}));

        my $lastname = dodef($row->{'lastname'});
        my $firstname = dodef($row->{'firstname'});
        my $chipid = $row->{'chipid'};
        my $batteryreplaced = dodef($row->{'batteryreplaced'});

        my $batterystatus = $row->{'replacebattery'} ? "REPLACE" : "OK";
        

        print $cgi->Tr({ -align => "CENTER", -valign => "TOP" },
                $cgi->td(checkbox(sprintf("select-%s", $chipid),0, $chipid,"")),
                $cgi->td($row->{'chip'}),
                $cgi->td($row->{'shortname'}),
                $cgi->td(sprintf("%s,%s", $lastname, $firstname)),
                $cgi->td($batterystatus),
                $cgi->td($row->{'currentactivations'}),
                $cgi->td($row->{'totalactivations'}),
                $cgi->td($row->{'organizer'}),
                $cgi->td($batteryreplaced),
                );
    }
    $sthl->finish();

    print $cgi->end_table();

    print $cgi->hr();
    print $cgi->defaults('Restart form');
    print $cgi->submit('action',"Chip Health");
    print $cgi->submit('action',"New Battery");

    print $cgi->end_form();

    do_footer($dbh, $cgi);

    return;


}

# ################################################################################################################### #
# ################################################################################################################### #

sub do_params {

    my ($cgi) = @_;

    #return unless ($VERBOSE);

    for my $key (param) {
        #printf "<strong>$key</strong> -> ";
        #print $cgi->strong(sprintf("%s -> ", $key));


        my @values = param($key);
        printf STDERR "param(%s) %s\n", $key, join(", ",@values);
    }
}


sub do_work {

    my ($dbh, $cgi) = @_;

    #do_test($dbh, $cgi);
    #return;

    unless (defined(param('action'))) {
        #do_test($dbh, $cgi);
        do_chip_summary($dbh, $cgi);
        return;
    }

    my $action = param('action');

    printf STDERR "action: %s\n", $action;

    if ($action eq "Chip Health") {
        do_chip_health($dbh, $cgi);
    }
    if ($action eq "New Battery") {
        do_new_battery($dbh, $cgi);
    }
    return;
}


sub printf_tail {
}

# ################################################################################################################### #

my $cgi = new CGI;

my $dbh = DBI->connect("dbi:mysql:$DATABASE", $DBUSER, $DBPASSWORD) || die "Cannot connect to mysql\n";


do_params($cgi);
do_work($dbh, $cgi);

