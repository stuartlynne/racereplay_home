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

printf STDERR "ENTER\n";

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
use My::Misc qw(find_chipid get_venue_info get_event_info);
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
    my ($dbh, $cgi, $Title, $Script, $Content_ref) = @_;
    return (
            # HTML Header
            $cgi->header, 

            # Start HTML
            $cgi->start_html( 
                -title => "Race Replay", 
                -script => $Script,
                -style => {'src' => $CSS},),

            @{$Content_ref},

            # End HTML
            $cgi->comment("Copyright(c)2012 Stuart.Lynne\@gmail.com"),
            $cgi->end_html(), "\n",
        );
}

# ################################################################################################################### #
# do_analyze_races
#
#sub do_analyze_races_s {
#
#    my ($dbh, $cgi, $venueid, $eventid, $groupsetid, $action) = @_;
#
#    # Create Content
#    #
#    my @Content;
#    push(@Content, 
#            # seamless => 1
#            $cgi->iframe(
#                {name => "race analyze", 
#                src => "hello.html", 
#                width => "100%", 
#                height => "100%",
#                -id => "myiframe",
#                onload => "resize_iframe()",
#                },
#                ""),
#        );
#
#
#    my $Script = '
#        function resize_iframe() {
#            document.getElementById("myiframe").height = 
#                document.body.offsetHeight - 
#                document.getElementById("myiframe").offsetTop - 130;
#            console.log("resize_iframe called");
#        }
#        window.onresize = resize_iframe;
#    ';
#    
#    return do_page($dbh, $cgi, sprintf("Race Report - %s", $event), $Script, \@Content);
#}




# do_analyze_races
#
sub do_analyze_races {

    my ($dbh, $cgi, $venueid, $eventid, $groupsetid, $correction, $maxlaps, $racetype, $sprint, $action) = @_;

    $racetype = "Lap Race" unless(defined($racetype));
    $action = "" unless(defined($action));
    $sprint = '10' unless(defined($sprint));

    printf STDERR "do_event: venueid: %s eventid: %s action: %s correction: %s\n", $venueid, $eventid, $action, 
           defined($correction) ?  $correction : "UNDEF"
               if ($DEBUG);
    
    my $sth = $dbh->prepare("SELECT * 
            FROM events e
            JOIN venues v 
            JOIN groupsets g 
            WHERE v.venueid = ? AND e.eventid = ? AND g.groupsetid = ?
            ");

    $sth->execute($venueid, $eventid, $groupsetid) || die "Execute failed\n";
    my $row = $sth->fetchrow_hashref();
    $sth->finish();
    unless(defined($row)) { die "Cannot find event!\n"; }

    printf STDERR Dumper($row);

    my $description = $row->{'e.description'};
    my $distance = $row->{'distance'};
    my $datestamp = $row->{'datestamp'};

    printf STDERR "Action: %s\n", $action;
    printf STDERR "Analyze Races\n";

    # Create Content
    #
    my @Content;
    push(@Content, 
            $cgi->start_form(),
            $cgi->hidden('venueid', $venueid),
            $cgi->hidden('eventid', $eventid),
            $cgi->hidden('groupsetid', $groupsetid),
            );

    my $workoutcount = 0;
    my $key = $groupsetid;

        #$key =~ s/race-//;

        #my $groupsetid = param(sprintf("race-%s", $key));
        #my $maxlap = param(sprintf("maxlap-%s", $key));

    my $lapcorrection = 0;

    push(@Content, Race::do_analysis($dbh, $cgi, $groupsetid, $distance, $correction, $maxlaps, $datestamp, $racetype, $sprint)) ;

    #my ($dbh, $cgi, $reportcount, $reference_groupsetid, $reference_workoutid, $MaxLap, $LapCorrection) = @_;

    my %CorrectionLabels;
    my @CorrectionValues;

    unless (defined($correction)) {
        %CorrectionLabels = ( '-2' => 'Down 2', '-1' => 'Down 1', '0' => '0', '1' => 'Up 1', '2' => 'Up 2' );
        @CorrectionValues = [-2, -1, 0, 1, 2];
    }
    else {
        my @Values;
        for (my $i = ($correction - 3) ; $i <= ($correction + 3); $i++) {
            if ($i < 0) {
                $CorrectionLabels{sprintf("%d", $i)} = sprintf("Down %d", -$i);
            } elsif ($i > 0) {
                $CorrectionLabels{sprintf("%d", $i)} = sprintf("Up %d", $i);
            }
            else {
                $CorrectionLabels{"0"} = "0";
            }
            push(@Values, $i);
        }
        push(@CorrectionValues, \@Values);
    }


    printf STDERR "CorrectionLabels\n";
    printf STDERR Dumper(\%CorrectionLabels);
    printf STDERR "CorrectionValues\n";
    printf STDERR Dumper(\@CorrectionValues);
         

    my %SprintLabels = ( '10' => '10 laps', '12' => '12 laps', '20' => '20 laps', '8' => '8 laps', '5' => '5 laps', '3' => '3 laps', '2' => '2 laps' );
    my @SprintValues = [10, 12, 20, 8, 5, 3, 2];

    my %RaceTypeLabels = ( 
            'Lap Race' => 'Lap Race',
            'Points Race' => 'Points Race',
            'Scratch Race' => 'Scratch Race',
            'Elimination Race' => 'Elimination Race',
            );
    my @RaceTypeValues = ['Lap Race', 'Points Race', 'Scratch Race', 'Elimination Race'];


    push(@Content,
            #$cgi->reset("Defaults"),
            #$cgi->reset('Restart form'),

            $cgi->br(),
            $cgi->start_table({ -class => "table", -border => 1, -cellpadding => 3 }),
            $cgi->Tr(
                $cgi->th( [
                    $cgi->b(""), 
                    $cgi->b("Race Type"), 
                    $cgi->b("Lap Correction"), 
                    $cgi->b("Sprint"), 
                    $cgi->b("Action"), 
                    ],),
                ),
            $cgi->Tr(
                $cgi->td( [
                    $cgi->submit(sprintf('Reset-%s-%s-%s', $venueid, $eventid, $groupsetid), "Reset"),
                    #$cgi->submit('action',"Race CSV"),
                    $cgi->popup_menu(
                        -name => "racetype",
                        -values =>  @RaceTypeValues,
                        -default => '0',
                        -linebreak => 'true',
                        -labels => \%RaceTypeLabels,
                        -columns=>2
                        ),
                    $cgi->popup_menu(
                        -name => "correction", 
                        -values =>  @CorrectionValues,
                        -default => '0',
                        -selected => '0',
                        -linebreak => 'true',
                        -labels => \%CorrectionLabels,
                        -columns=>2
                        ),
                    $cgi->popup_menu(
                        -name => "sprint",
                        -values =>  @SprintValues,
                        -default => '0',
                        -linebreak => 'true',
                        -labels => \%SprintLabels,
                        -columns=>2
                        ),
                    $cgi->submit('Reload',"Reload"),
                    ]),
                ),
            $cgi->end_table(),
            $cgi->end_form(),
            );

    # Create Aside
    #
    my @Aside;
    push(@Aside, 
            $cgi->h2("Race Report"),
            $cgi->p( "This does a per lap report on a race.\n",),
            $cgi->p( "The Laps Down column shows the number of laps down any rider is or if a DNF.\n",),
            $cgi->p( "The yellow highlited entries are leading rider for each lap.\n",),
            $cgi->p( "The table is sorted on the finish times of the riders who where not lapped.\n",),
            $cgi->p( "The values displayed only show at most one tenth of a second accuracy. 
                The internal numbers have about one hundredth of a second accuracy and the sorted values will reflect the underlying recorded values.
                \n",),
            $cgi->p( "The timing accuracy depends on the location of the transponder chip. 
                Assuming correct placement.on the front fork then the system will be accurate to about ten milli-seconds. 
                Poor placement, e.g. rear stay, can add up to fifty or a hundred milli-seconds to the recorded time.
                \n",),
            );

    return do_page($dbh, $cgi, sprintf("Race Report - %s", $eventid), "", \@Content);
}
















# ################################################################################################################### #

# do_work
#
sub do_work {

    my ($dbh, $cgi) = @_;

    # Race Report 
    #
    if ( defined(param('venueid')) && defined(param('eventid')) && defined(param('groupsetid') )) {

        my $correction;
        if (defined(param('correction'))) {
            $correction = param('correction');
        }
        return do_analyze_races($dbh, $cgi, param('venueid'), param('eventid'), param('groupsetid') , 
                $correction,param('maxlaps'), param('racetype'), param('sprint'), param('action'),
                );
    }

    my @Content;
    return do_page($dbh, $cgi, "Failed", "", \@Content);

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

print do_work($dbh, $cgi);

