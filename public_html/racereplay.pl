#!/usr/bin/perl

# workouts cgi script
#
#       Copyright (c) 2012 Stuart.Lynne@gmail.com
#
#
# This CGI script will query a RaceReplay database to produce workout summaries, reports etc.
#
#
#
# N.B.
#       CSS - Two Column Liquid originally from http://www.maxdesign.com.au/articles/css-layouts/two-liquid
#

my $DEBUG = 1;
my $VERBOSE = 1;

use strict;
use warnings;

use DBI;
use CGI qw/:standard *table start_ul div/;
use Time::CTime;
use Sys::Hostname;

use Text::CSV;
#use Date::Simple;

use DateTime::Locale;
use DateTime::Format::Strptime;
use DateTime::Duration;
use Data::Dumper;


# Module configuration
# This will get a localized bin directory from /home/XXX/bin, to add to the 
# perl INC path. 
use Cwd;
BEGIN {
    my $dir = fastcwd;
    my @values = split(/\//, $dir);
    push (@INC, sprintf("/%s/%s/%s/bin", $values[1], $values[2], $values[3]));
    printf STDERR "INC: %s\n", join(";", @INC); 
}

use My::SqlDef qw(SqlConfig);
use My::FKey qw(init find finish);
use My::Health qw(do_health );
use My::Misc qw(find_chipid get_venue_info );
use My::StravaTCX qw(do_strava_tcx);
use My::FileCSV qw(do_csv);
use My::Race qw(do_analysis);
use My::Workouts qw(do_summary_workouts do_summary_races);

my ($DATABASE, $DBUSER, $DBPASSWORD) = SqlDef::SqlConfig();
#printf STDERR "%s %s %s\n", $DATABASE, $DBUSER, $DBPASSWORD;

my $time;
my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime(time));

#my $TZ = $ENV{ 'TZ' };
my $TZ = "PST8PDT";

my $date_format = new DateTime::Format::Strptime( pattern => '%F %T', time_zone => $TZ,);


# ################################################################################################################### #

my $CSS = "/css/two-liquid.css";

# do_page
#
# Title         - page title
# Content_ref   - array reference pointing to the page content, display in CSS Div for "content"
# Aside_ref     - array reference pointing to the page content, display in CSS Div for "aside"
#
# The display hierarchy is:
#
#    hmtl
#       container
#           header
#           content-container
#               content
#               aside
#           footer
#
# Changes to this must be related to equivalent changes in the /css/two-liquid.css file.
#
sub do_page {
    my ($dbh, $cgi, $Title, $Script, $Content_ref, $Aside_ref) = @_;
    return (
            # HTML Header
            $cgi->header, 

            # Start HTML
            $cgi->start_html( 
                -title => "Race Replay", 
                -script => $Script,
                -style => {'src' => $CSS},),

            # Encapsulate into container division
            $cgi->div ( { -id => 'container', }, 

                # header division
                $cgi->div( { -id => "header", }, 
                    $cgi->h1(sprintf("Race Replay - %s", $Title)),
                    ), "\n",

                # content container division
                $cgi->div ( { -id => 'content-container', }, 
                    # contents and aside
                    $cgi->div ( { -id => 'content', }, @{ $Content_ref }), "\n",
                    $cgi->div ( { -id => 'aside', }, @{ $Aside_ref }), "\n",
                    ), "\n",

                # footer divsion
                $cgi->div({-id => 'footer'},"Copyright(c) 2012"), "\n",
                ), "\n",

            # End HTML
            $cgi->comment("Copyright(c)2012 Stuart.Lynne\@gmail.com"),
            $cgi->end_html(), "\n",
        );
}

# ################################################################################################################### #

sub dist2ms {
    my ($distance, $speed) = @_;
    return ($distance / $speed) *60 * 60 * 1000;
}

#sub kph {
#    my ($distance, $ms) = @_;
#    my $kph = (3600/($ms/1000)) * $distance;
#    return sprintf("%5.2f", $kph);
#}

#sub hhmm {
#    my ($datestamp) = @_;
#    my @values = split(/ /,$datestamp);
#    my @hhmmss = split(/:/,$values[1]);
#    return sprintf("%s:%s", $hhmmss[0], $hhmmss[1]);
#}


# ################################################################################################################### #



# do_summary
#
sub do_summary {


    my ($dbh, $cgi, $venue, $startdate) = @_;

    my $Venue_ref = Misc::get_venue_info($dbh, $venue);

    printf STDERR "do_summary: startdate: %s venue: %s \n", $startdate, $venue;

    my $venueid = -1;
    #my $organizer = "";
    my $distance = "";
    #my $minspeed = 0;
    #my $maxspeed = 0;
    #my $mintime = 0;
    #my $maxtime = 0;
    #my $gaptime = 0;

    if ($Venue_ref) {
        $venueid = $Venue_ref->{'venueid'};
        #$organizer = $Venue_ref->{'organizer'};
        $distance = $Venue_ref->{'distance'};
        #$minspeed = $Venue_ref->{'minspeed'};
        #$maxspeed = $Venue_ref->{'maxspeed'};
        #$gaptime = $Venue_ref->{'gaptime'} * 1000;
        #$mintime = dist2ms($distance, $maxspeed);
        #$maxtime = dist2ms($distance, $minspeed);
    }

    my @Content;
    push(@Content, Workouts::do_summary_workouts($dbh, $cgi, $venue, $venueid, $startdate, $distance));

    push(@Content, 
            $cgi->br(),
            $cgi->reset("Defaults"),
            $cgi->defaults('Restart form'),
            $cgi->submit('action',"Details"),
            #$cgi->submit('action',"Analyze Race"),
            $cgi->end_form(),
        );
    

    my @Aside;
    push(@Aside,
            $cgi->p($cgi->em("[Details]"), "Show more details for the selected workouts."),
            $cgi->p($cgi->em("[Restart Form]"), "Start over."),
            #$cgi->p($cgi->em("[Analyze Race]"), "The second table shows possible race starts, this button will generate a report for selected races."),
            #$cgi->p($cgi->em("[Correction]"), "The Laps column shows the maximum recorded laps, this may be too high, use the correction menu to adjust down if required."),
            $cgi->p($cgi->em("[Type]"), "Select the type of race."),
            $cgi->p($cgi->em("[Sprints]"), "The number between sprints. For lap races this will also be used to help set the table width."),

        );

    return do_page($dbh, $cgi, sprintf ("%s - %s", "Workouts", $startdate), "", \@Content, \@Aside);
}

# ################################################################################################################### #

# Display list of Venues that are available
#
sub select_venue_form {

    my ($dbh, $cgi) = @_;
    
    my $sth = $dbh->prepare("SELECT venue FROM venues ORDER BY venue ASC");
    $sth->execute() || die "Execute failed\n";
    my $ref = $sth->fetchall_hashref( 'venue' );
    $sth->finish();

    my %Labels;
    my $Count = 0;
    my @Values;
    foreach my $key (sort keys %$ref) { 
        $Labels{$key} = $key;
        $Values[$Count++] = $key;
    }
    
    my @Content;
    my @Aside;
    push(@Content, 
             $cgi->start_form(),
             $cgi->popup_menu(
                 -name => 'Selected Venue',
                 -values => [@Values],
                 -linebreak => 'true',
                 -labels => \%Labels,
                 -columns=>2
                 ),
             $cgi->submit('action','Venue Selected'),
             $cgi->br(),
             $cgi->reset("Defaults"),
             $cgi->defaults('Restart form'),
             $cgi->end_form(),
            );
    push(@Aside,
            $cgi->p("This website provides access to timing data collected by the Cycling BC electonic timing system"),
            $cgi->p($cgi->em("[Venue Selected]"), "Select the venue where your workout or race was recorded"),
            $cgi->p($cgi->em("[Defaults]"), "Reset selection."),
            $cgi->p($cgi->em("[Restart Form]"), "Start over."),
        );


    printf STDERR "Content: ";
    print STDERR @Content;
    printf STDERR "\n";
    printf STDERR "Aside: ";
    print STDERR @Aside;
    printf STDERR "\n";


    return do_page($dbh, $cgi, "Venue Selection", "", \@Content, \@Aside, );

}

# ################################################################################################################### #

# Display a list of dates for the selected Venue
#
sub select_date_form {

    my ($dbh, $cgi, $venue) = @_;


    my $sth = $dbh->prepare("SELECT DISTINCT DATE_FORMAT(w.starttime, '%Y-%m-%d %a') as STARTTIME FROM workouts w ORDER BY w.starttime DESC");
    $sth->execute() || die "Execute failed\n";
    #my $row = $sth->fetchrow_hashref(); 
    my $ref = $sth->fetchall_hashref( 'STARTTIME' );
    $sth->finish();

    my %Days;
    foreach my $key (keys %$ref) { 
        #printf STDERR "select_date: %s\n", $key;
        #my $startdt = $date_format->parse_datetime($key) || die $DateTime::Format::Strptime::errmsg;
        my $startdt = $key;
        $startdt =~ s/ ...//;
        $Days{$startdt} = $key;
    }
    printf STDERR Dumper(%Days);

    my %Labels;
    my @Values;
    my $Count = 0;
    foreach my $key (reverse sort keys %Days) {
        $Values[$Count] = $key;
        $Labels{$key} = $Days{$key};
        $Count++;
    }

    my @Content;
    my @Aside;
    push(@Content, 
            $cgi->start_form(),
            $cgi->popup_menu(
                -name => 'Selected Date',
                -values => [@Values],
                -linebreak => 'true',
                -labels => \%Labels,
                -columns=>2
                ),
            $cgi->submit('action','Date Selected'),
            $cgi->hidden('venue', $venue),
            $cgi->br(),
            $cgi->reset("Defaults"),
            $cgi->defaults('Restart form'),
            $cgi->end_form(),
        );
    push(@Aside,
            $cgi->p($cgi->em("[Date Selected]"), "Select the date on which your workout or race was recorded"),
            $cgi->p($cgi->em("[Restart Form]"), "Start over."),
        );
    return do_page($dbh, $cgi, "Select Date", "", \@Content, \@Aside, );

}

# ################################################################################################################### #

# do_workouts
#
sub do_workouts {

    my ($dbh, $cgi, $count, $startdate, $venue, $name, $chipid) = @_;

    my @Content;


    unless ($count) {
        push(@Content, 
                $cgi->h1(sprintf ("%s - %s", "Workouts", $startdate))
            );
    }

    # dump a table out
    push(@Content, 
            $cgi->start_form(),
            $cgi->hidden('venue', $venue),
            $cgi->hidden('startdate', $startdate),
            $cgi->hidden('name', $name),
            $cgi->hidden('chipid', $chipid),
    
            $cgi->start_table({ -border => 1, -cellpadding => 3 }),
            $cgi->caption({-class => "large_left_caption"}, "Workouts"),
            $cgi->Tr({ -class => 'tr_odd', -align => "CENTER", -valign => "BOTTOM" },
                $cgi->th( [
                    $cgi->b("Start"), 
                    $cgi->b("Finish"), 
                    $cgi->b("Name"), 
                    $cgi->b("Chip"), 
                    $cgi->b("HH:MM"), 
                    $cgi->b("Laps"), 
                    $cgi->b("Distance (km)"), 
                    $cgi->b("Avg (kph"), 
                    $cgi->b("Fastest"), 
                    $cgi->b("Best Lap (kph)"),
                    #$cgi->b("Batt"),
                    #$cgi->b("Corr"),
                    $cgi->b("Skipped"),
                    $cgi->b("Select"),
                    ]))
        );


    my $Venue_ref = Misc::get_venue_info($dbh, $venue);
    #my $organizer = "";
    my $distance = "";
    #my $minspeed = 0;
    #my $maxspeed = 0;
    #my $mintime = 0;
    #my $maxtime = 0;
    #my $gaptime = 0;

    if ($Venue_ref) {
        #$organizer = $Venue_ref->{'organizer'};
        $distance = $Venue_ref->{'distance'};
        #$minspeed = $Venue_ref->{'minspeed'};
        #$maxspeed = $Venue_ref->{'maxspeed'};
        #$gaptime = $Venue_ref->{'gaptime'} * 1000;
        #$mintime = dist2ms($distance, $maxspeed);
        #$maxtime = dist2ms($distance, $minspeed);
    }


    my $total = 0;

    #my $sth = $dbh->prepare("SELECT * FROM workouts l JOIN chips c ON l.chipid = c.chipid
    #        WHERE venueid = (SELECT venueid FROM venues 
    #            WHERE venue=?) AND starttime >= ? and finishtime  <= ? and l.chipid = ? ORDER BY starttime ASC");
    
    my $sth = $dbh->prepare("SELECT * FROM workouts l JOIN chips c ON l.chipid = c.chipid
            WHERE venueid = (SELECT venueid FROM venues 
                WHERE venue=?) AND (starttime BETWEEN ? AND (? + INTERVAL 1 DAY )) AND l.chipid = ? ORDER BY starttime ASC");

    #$sth->execute($venue, sprintf("%s%s", $starttime, "%"), sprintf("%s%s", $finishtime, "%"), $chipid) || die "Execute failed\n";
    $sth->execute($venue, $startdate, $startdate, $chipid) || die "Execute failed\n";

    #my $count = 0;

    my (%Workouts, %Laps, %TotalMS, %BestLapMS, %StartTime, %FinishTime, %ChipName, %Chips, %ChipIDs);

    $count = 0;
    my $MaxLaps = 0;
    while ( my $row = $sth->fetchrow_hashref()) {

        printf STDERR "**************************************************\n";
        printf STDERR Dumper($row);

        my $totalms = $row->{'totalms'};
        next unless ($totalms != 0);;
        my $laps = $row->{'laps'};
        next unless($laps > 2);
        #printf STDERR Dumper($row);
        #printf STDERR "start: %s finish: %s\n", $row->{'starttime'}, $row->{'finishtime'};

        my $chipid = $row->{'chipid'};
        my $chip = $row->{'chip'};

        unless ($Chips{$chip}) {
            my $shortname = Misc::get_loaner($dbh, $chipid, $row->{'chip'});
            $Chips{$chipid} = $shortname;
        }


        my $shortname = Misc::get_loaner($dbh, $chipid, $row->{'chip'});

        # derive user info from chipid via chiphistory table
        #
        my ($userid, $name) = Misc::get_user_name($dbh, $Chips{$chipid}, $chipid, $row->{'starttime'});


        my $starttime = Misc::hhmm($row->{'starttime'});
        my $finishtime = Misc::hhmm($row->{'finishtime'});


        unless (defined($Workouts{$name})) {
            $Workouts{$name} = 1;
            $Laps{$name} = $row->{'laps'};
            $TotalMS{$name} = $row->{'totalms'};
            $StartTime{$name} = $row->{'starttime'};
            $FinishTime{$name} = $row->{'finishtime'};
            $BestLapMS{$name} = $row->{'bestlapms'};
            $ChipName{$name} = $Chips{$chipid};
            $ChipIDs{$name} = $chipid;
            #printf STDERR "name: %s chipid: %s\n", $name, $chipid;
        }
        $MaxLaps = $Laps{$name} if ($Laps{$name} > $MaxLaps);

        my $seconds = $row->{'totalms'} / 1000;
        my $minutes = ($seconds / 60) %60;
        my $hours = ($seconds / (60 * 60));
        $seconds = $seconds % 60;

        my $bestlapms = $row->{'bestlapms'};

        my $tr_class = ($count % 2) ? 'tr_odd' : 'tr_even';
        push(@Content,
                
                $cgi->Tr({ -class => $tr_class, -align => "CENTER", -valign => "BOTTOM" },
                    $cgi->td($starttime),
                    $cgi->td($finishtime),
                    $cgi->td( $name),
                    $cgi->td($shortname),
                    $cgi->td(sprintf("%d:%02d", $hours, $minutes)),
                    $cgi->td($laps),
                    $cgi->td(sprintf("%5.1f", $laps * $distance)),
                    $cgi->td(sprintf("%5.1f", Misc::kph(($laps * $distance), $row->{'totalms'}))),
                    $cgi->td(sprintf("%5.1f", $bestlapms/1000)),
                    $cgi->td(sprintf("%5.1f", Misc::kph(($distance), $bestlapms))),
                    #$cgi->td($row->{'battery'}),
                    #$cgi->td($row->{'corrections'}),
                    $cgi->td($row->{'skippedcount'}),
                    $cgi->td(checkbox(sprintf("workoutid-%s-%s", $starttime, $finishtime),0, $row->{'workoutid'},""))
                    ));
        $count++;
    }

    $sth->finish();

    push(@Content, 
            $cgi->end_table(),
            $cgi->defaults('Restart form'),
            $cgi->submit('action',"Strava TCX"),
            $cgi->submit('action',"Strava TCX 5"),
            $cgi->submit('action',"Strava Workouts"),
            $cgi->submit('action',"Workout CSV"),
            $cgi->submit('action',"Chip Health"),
            #$cgi->submit('action',"Compare"),
            #"Laps:",
            #$cgi->textfield(-name => 'laps', -value => $MaxLaps, -size => 10, -maxlength => 20),
            $cgi->end_form(),
            $cgi->hr(),
        );

    return @Content;
}


# ################################################################################################################### #
# do_details
#
sub do_details {

    my ($dbh, $cgi, $venue, $startdate, $action) = @_;

    printf STDERR "do_details: venue: %s date: %s action: %s\n", $venue, $startdate, $action if ($DEBUG);
    
    printf STDERR "Action: %s\n", $action;
    printf STDERR "Details\n";

    # Create Content
    #
    my @Content;
    my $workoutcount = 0;
    for my $key (param) {
        my $parameter = param($key);

        next unless ($key =~ /select-/);

        $key =~ s/select-//;
        #printf STDERR "key: %s\n", $key;
        #printf STDERR "parameter: %s\n", $parameter;

        push(@Content, 
                do_workouts ($dbh, $cgi, $workoutcount++,
                    $startdate,
                    $venue, 
                    $key,
                    $parameter
                    )
            );
    }

    # Create Aside
    #
    my @Aside;
    push(@Aside, 
            $cgi->h2("Strava TCX"),
            $cgi->p(
                "This will generate a TCX file suitable for Strava. It can be directly uploaded via your Strava account.\n",
                "Or you may also email the files to upload\@strava.com from the email address you are registered with.\n",
                sprintf("<a href=%s>%s</a>", "https://strava.zendesk.com/entries/20426301-import-from-garmin-connect", "Strava Helpdesk - Garmin Import"),
                ),
            $cgi->h2("Strava TCX 5"),
            $cgi->p(
                "This will generate a TCX file suitable for Strava with the the TCX \"lap\" being set to 5 recorded laps.\n",
                "For files from Burnaby Velodrome this can make the Strava Performance Analysis work better as it is working with 1km insteadm of 200m.\n",
                ),

            $cgi->h2("Strava TCX Workouts"),
            $cgi->p("This will generate a TCX file suitable for Strava with the the TCX \"lap\" being each workout.\n"),


            $cgi->h2("Workout CSV"),
            $cgi->p("This will generate a CSV file containing the raw workout data. This can be imported into Excel or OpenOffice for further analysis.\n"),


            $cgi->h2("Chip Health"),
            $cgi->p("This will generate a Chip Health Report. This shows the possibly skipped laps for an RFID tag.\n"),

            #$cgi->h2("Compare"),
            #$cgi->p("This will generate a comparison report.\n"),
            );

    return do_page($dbh, $cgi, "Details", "", \@Content, \@Aside);
}

# ################################################################################################################### #


# do_compare
#
sub do_compare {

    my ($dbh, $cgi, $venue, $startdate, $action) = @_;

    printf STDERR "Action: %s\n", $action;

    # Create Content
    #
    my @Content;
    my $workoutcount = 0;

    my $workoutid = -1;
    my $laps = -1;

    for my $key (param) {
        my $parameter = param($key);

        if ($key =~ /workoutid-/) {
            $key =~ s/select-//;
            printf STDERR "key: %s\n", $key;
            printf STDERR "parameter: %s\n", $parameter;
            $workoutid = $parameter;
        }

        if ($key eq "laps") {
            $laps = $parameter;
        }
    }

    if ($workoutid) {
        push(@Content, Race::do_analysis ($dbh, $cgi, $workoutcount++, -1, $workoutid, $laps, 0, "", "", "", "", 0));
    }

    # Create Aside
    #
    my @Aside;
    push(@Aside, "");


    return do_page($dbh, $cgi, "Workout Compare", "", \@Content, \@Aside);
}

# ################################################################################################################### #

# do_file
# 
# produce a download file
#
sub do_file {

    my ($dbh, $cgi, $venue, $startdate, $action) = @_;

    my $name = param('name');
    my $chipid = param('chipid');
    
    if ($action eq "Workout CSV") {
        printf STDERR "Workout CSV\n";
        FileCSV::do_csv ($dbh, $cgi, $startdate, $venue, $name, $chipid);
    }

    if ($action eq "Strava TCX") {
        printf STDERR "Strava TCX\n";
        StravaTCX::do_strava_tcx ($dbh, $cgi, 1, $startdate, $venue, $name, $chipid);
    }

    if ($action eq "Strava TCX 5") {
        printf STDERR "Strava TCX 5\n";
        StravaTCX::do_strava_tcx ($dbh, $cgi, 5, $startdate, $venue, $name, $chipid);
    }

    if ($action eq "Strava Workouts") {
        printf STDERR "Strava Workouts\n";
        StravaTCX::do_strava_tcx ($dbh, $cgi, 0, $startdate, $venue, $name, $chipid);
    }
}

# ################################################################################################################### #

# do_work
#
sub do_work {

    my ($dbh, $cgi) = @_;

    # if there is no action parameter then start with the select venue form
    #
    unless (defined(param('action'))) {
        print select_venue_form($dbh, $cgi);
        return;
    }

    my $action = param('action');

    # get date
    #
    if ($action eq "Venue Selected") {

        if (defined(param('Selected Venue'))) {
            #printf STDERR "Selected Venue: %s\n", param('Selected Venue'), $TZ if ($DEBUG);
            my $venue = param('Selected Venue');
            print select_date_form($dbh, $cgi, $venue);
            return;
        }
    }

    # produce summary
    #
    if ($action eq "Date Selected") {
        if (defined(param('Selected Date')) && defined(param('venue'))) {
            #printf STDERR "Selected Date: %s\n", param('Selected Date'), $TZ if ($DEBUG);
            my $venue = param('venue');
            my $startdate = param('Selected Date');
            print do_summary($dbh, $cgi, $venue, $startdate);
            return;
        }
    }

    # Detail Report 
    #
    if ( $action eq "Details" ) {
        if (defined(param('venue') && defined(param('startdate')))) {
            my $venue = param('venue');
            my $startdate = param('startdate');
            print do_details($dbh, $cgi, $venue, $startdate, $action);
            return;
        }
    }

    # Race Report 
    #
#   if ( $action eq "Analyze Race" ) {
#       if (defined(param('venue') && defined(param('startdate')))) {
#           my $venue = param('venue');
#           my $startdate = param('startdate');
#           print do_analyze_races($dbh, $cgi, $venue, $startdate, $action);
#           return;
#       }
#   }

    if ($action eq "Chip Health") {
        if (defined(param('venue') && defined(param('startdate')))) {
            my $venue = param('venue');
            my $startdate = param('startdate');

            my ($Content_ref, $Aside_ref) = Health::do_health($dbh, $cgi, $venue, $startdate, $action);
            my @Content = @$Content_ref;
            my @Aside = @$Aside_ref;
            print do_page($dbh, $cgi, "Transponder Chip Health", "", \@Content, \@Aside);
            return;
        }
    }

#    if ($action eq "Compare") {
#        if (defined(param('venue') && defined(param('startdate')))) {
#            my $venue = param('venue');
#            my $startdate = param('startdate');
#            print do_compare($dbh, $cgi, $venue, $startdate, $action);
#            return;
#        }
#    }

    if (
            $action eq "Strava TCX" || 
            $action eq "Strava TCX 5" || 
            $action eq "Strava Workouts" || 
            $action eq "Workout CSV" ) 
    {
        if (defined(param('venue') && defined(param('startdate')))) {
            my $venue = param('venue');
            my $startdate = param('startdate');
            do_file($dbh, $cgi, $venue, $startdate, $action);
            return;
        }
    }
}

# ################################################################################################################### #

my $cgi = new CGI;

my $dbh = DBI->connect("dbi:mysql:$DATABASE", $DBUSER, $DBPASSWORD) || die "Cannot connect to mysql\n";

for my $key (param) {
    #printf "<strong>$key</strong> -> ";
    #print $cgi->strong(sprintf("%s -> ", $key));


    my @values = param($key);
    printf STDERR "param(%s) %s\n", $key, join(", ",@values);
}

do_work($dbh, $cgi);

