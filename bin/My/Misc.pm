

package Misc;

use strict;
use Exporter;
use Data::Dumper;


use My::FKey qw(init find finish kph hhmm mmss diemsg);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(find_chipid_all find_chipid find_shortname 
                        find_shortname_all find_health get_venue_info get_event_info get_user_name get_loaner);

#my %ChipIDByChipDate;
#my %ShortnameByChipDate;
#
#   sub Misc::find_chipid_bydate_all {
#       my ($dbsql, $chip, $date, $cache) = @_;
#
#       my $key = join(":", $chip, $date);
#
#       # cached value
#       if ($cache && defined($ChipIDByChipDate{$key})) {
#           printf STDERR "CACHED: Chip: %s ChipID: %s Shortname: %s\n", $chip, $ChipIDByChipDate{$key}, $ShortnameByChipDate{$key};
#           return ($ChipIDByChipDate{$key}, $ShortnameByChipDate{$key}) if(defined($ChipIDByChipDate{$key}));
#       }
#
#       # search for it
#       my $cSth = $dbsql->prepare( "SELECT chipid, shortname FROM chips WHERE chip=? AND batterydate <= ? ORDER BY batterydate DESC LIMIT 1");
#       $cSth->execute($chip,$date) || die "Select from chips failed\n";
#       my $srow = $cSth->fetchrow_hashref();
#
#       # found it
#       if (defined($srow)) {
#           $ChipIDByChipDate{$key} = $srow->{'chipid'};
#           $ShortnameByChipDate{$key} = $srow->{'shortname'};
#           $cSth->finish();
#           printf STDERR "FOUND: Chip: %s ChipID: %s Shortname: %s\n", $chip, $ChipIDByChipDate{$key}, $ShortnameByChipDate{$key};
#           return ($ChipIDByChipDate{$key}, $ShortnameByChipDate{$key});
#       }
#
#       # insert it
#       my $iSth = $dbsql->prepare("INSERT INTO chips (chip) VALUES(?)");
#       $iSth->execute($chip) || die "Failed to insert chipid\n";
#
#       # now find it
#       $cSth->execute($chip) || die "Insert into chips failed\n";
#       $srow = $cSth->fetchrow_hashref();
#       
#       unless (defined($srow)) { die "Cannot find chip!\n"; }
#
#       # cache it
#       $ChipIDByChipDate{$key} = $srow->{'chipid'};
#       $ShortnameByChipDate{$key} = "";
#       
#       $cSth->finish();
#       $iSth->finish();
#       printf STDERR "INSERTED: Chip: %s ChipID: %s Shortname: %s\n", $chip, $ChipIDByChipDate{$key}, $ShortnameByChipDate{$key};
#       return ($ChipIDByChipDate{$key}, $ShortnameByChipDate{$key});
#   }
#
#   sub Misc::find_chipid_bydate {
#       my ($dbsql, $chip, $date) = @_;
#
#       my ($chipid, $loaner) = Misc::find_chipid_all($dbsql, $chip, $date, 0);
#       return $chipid;
#   }

my %ChipIDByChip;
my %ShortnameByChip;

sub Misc::find_chipid_all {
    my ($dbsql, $chip, $cache) = @_;

    # cached value
    if ($cache && defined($ChipIDByChip{$chip})) {
        printf STDERR "CACHED: Chip: %s ChipID: %s Shortname: %s\n", $chip, $ChipIDByChip{$chip}, $ShortnameByChip{$chip};
        return ($ChipIDByChip{$chip}, $ShortnameByChip{$chip}) if(defined($ChipIDByChip{$chip}));
    }

    # search for it
    my $cSth = $dbsql->prepare( "SELECT chipid, shortname FROM chips WHERE chip=? ");
    $cSth->execute($chip) || die "Select from chips failed\n";
    my $srow = $cSth->fetchrow_hashref();

    # found it
    if (defined($srow)) {
        $ChipIDByChip{$chip} = $srow->{'chipid'};
        $ShortnameByChip{$chip} = $srow->{'shortname'};
        $cSth->finish();
        printf STDERR "FOUND: Chip: %s ChipID: %s Shortname: %s\n", $chip, $ChipIDByChip{$chip}, $ShortnameByChip{$chip};
        return ($ChipIDByChip{$chip}, $ShortnameByChip{$chip});
    }

    # insert it
    my $iSth = $dbsql->prepare("INSERT INTO chips (chip) VALUES(?)");
    $iSth->execute($chip) || die "Failed to insert chipid\n";

    # now find it
    $cSth->execute($chip) || die "Insert into chips failed\n";
    $srow = $cSth->fetchrow_hashref();
    
    unless (defined($srow)) { die "Cannot find chip!\n"; }

    # cache it
    $ChipIDByChip{$chip} = $srow->{'chipid'};
    $ShortnameByChip{$chip} = "";
    
    $cSth->finish();
    $iSth->finish();
    printf STDERR "INSERTED: Chip: %s ChipID: %s Shortname: %s\n", $chip, $ChipIDByChip{$chip}, $ShortnameByChip{$chip};
    return ($ChipIDByChip{$chip}, $ShortnameByChip{$chip});
}

sub Misc::find_chipid {
    my ($dbsql, $chip) = @_;

    my ($chipid, $loaner) = Misc::find_chipid_all($dbsql, $chip, 0);
    return $chipid;
}

my %ChipIDByShortname;
my %ChipByShortname;
sub Misc::find_shortname_all {
    my ($dbsql, $shortname, $cache) = @_;

    # cached value
    if($cache && defined($ChipIDByShortname{$shortname})) {
        printf "CACHED: Shortname: %s ChipID: %s Chip: %s\n", $shortname, $ChipIDByShortname{$shortname}, $ChipByShortname{$shortname};
        return ($ChipIDByShortname{$shortname}, $ChipByShortname{$shortname}) if(defined($ChipIDByShortname{$shortname}));
    }

    printf STDERR "SELECT chipid FROM chips WHERE shortname=%s\n", $shortname;

    # search for it
    my $cSth = $dbsql->prepare( "SELECT chipid, chip FROM chips WHERE shortname=?");
    $cSth->execute($shortname) || die "Select from chips failed\n";
    my $srow = $cSth->fetchrow_hashref();

    # found it
    if (defined($srow)) {
        my $chipid = $srow->{'chipid'};
        $ChipIDByShortname{$shortname} = $srow->{'chipid'};
        $ChipByShortname{$shortname} = $srow->{'chip'};
        $cSth->finish();
        printf "FOUND: Shortname: %s ChipID: %s Chip: %s\n", $shortname, $ChipIDByShortname{$shortname}, $ChipByShortname{$shortname};
        return ($ChipIDByShortname{$shortname}, $ChipByShortname{$shortname});
    }
    $cSth->finish();
    return undef;
}


sub Misc::find_shortname {
    my ($dbsql, $shortname) = @_;
    my ($chipid, $shortname) = Misc::find_shortname_all($dbsql, $shortname, 0);
    return $chipid;
}

# find_healthid
#
# get or create a healthid
#
sub find_healthid {
    my ($dbsql, $chipid, $date) = @_;

    # search for it
    my $cSth = $dbsql->prepare( "SELECT healthid FROM health WHERE chipid=? AND datestamp=?");
    $cSth->execute($chipid, $date) || die "Select from health failed\n";
    my $srow = $cSth->fetchrow_hashref();

    # found it
    if (defined($srow)) {
        return $srow->{'healthid'};
    }

    # insert it
    #printf STDERR "INSERT INTO health (chipid,datestamp,activations,corrections,skippedcount,battery,batteryreplaced) VALUES(%s,%s,0,0,0,0,0)\n", $chipid, $date;

    my $iSth = $dbsql->prepare("INSERT INTO health (chipid,datestamp,activations,corrections,skippedcount,battery,batteryreplacedflag) VALUES(?,?,0,0,0,0,0)");
    $iSth->execute($chipid, $date) || die sprintf("Failed to insert healthid %s\n", $iSth->errstr);

    # now find it
    $cSth->execute($chipid, $date) || die "Insert into health failed\n";
    $srow = $cSth->fetchrow_hashref();
    
    unless (defined($srow)) { die "Cannot find health!\n"; }

    # cache it
    return $srow->{'healthid'};
}


sub get_venue_info {

    my ($dbh, $active) = @_;

    my $sql = sprintf ( "SELECT * FROM venues where Venue = '%s'", $active);
    my $sth = $dbh->prepare($sql);;
    $sth->execute() || die "Execute failed\n";

    my $row_ref = $sth->fetchrow_hashref;
    $sth->finish();

    unless(defined($row_ref)) {
        printf STDERR "No venue\n";
        return;
    }

    unless(defined($row_ref->{'venue'})) {
        printf STDERR "No venue\n";
        return "novenue";
    }

    # return hashref
    #
    #printf STDERR "Organizer: %s description %s\n", $active, $row_ref->{ 'description' }, $TZ if ($DEBUG);
    return $row_ref;
}



sub get_event_info {
    my ($dbh, $starttime, $venue, $description) = @_;


    my $sth = $dbh->prepare("SELECT * FROM events WHERE venueid = (SELECT venueid FROM venues WHERE venue=?) AND starttime LIKE ? AND description LIKE ?");

    $sth->execute($venue, sprintf("%s%s", $starttime, "%"), $description) || die sprintf("Failed to find event %s\n", $sth->errstr);
    my $row_ref = $sth->fetchrow_hashref;
    $sth->finish();

    unless(defined($row_ref)) {
        printf STDERR "Missing row_ref event: \"%s\" \"%s\" \"%s\"\n", $starttime, $venue, $description;
        return undef;
    }

    #print STDERR Dumper($row_ref);

    unless(defined($row_ref->{'venueid'})) {
        printf STDERR "Cannot find field: \"%s\" \"%s\" \"%s\"\n", $starttime, $venue, $description;
        return undef;
    }

    # return hashref
    #
    #printf STDERR "tagid: %s organizer %s\n", $row_ref->{ 'starttime' };
    return $row_ref;

}

# get_user_name
# Get the user who was using a chip during a specific time period.
#
sub get_user_name {
    my ($dbh, $shortname, $chipid, $starttime) = @_;
    
    #printf STDERR "get_user_name: %s %s\n", $starttime, $chipid;

    #my $sth = $dbh->prepare("SELECT c.userid, u.firstname, u.lastname, c.starttime FROM chiphistory c JOIN users u ON c.userid = u.userid
    #        WHERE c.chipid=? AND c.starttime<=?  AND (c.finishtime>=? or c.finishtime like '0000-00-00 00:00:00')");

    my $sth = $dbh->prepare("
            SELECT h.userid, u.firstname, u.lastname, h.starttime 
            FROM chiphistory h 
            JOIN users u ON h.userid = u.userid
            WHERE h.chipid=? AND (
                ( ? BETWEEN h.starttime AND h.finishtime)  OR
                ( (? >= h.starttime) AND (h.finishtime = '0000-00-00 00:00:00'))) ");

    $sth->execute($chipid, $starttime, $starttime) || die "Execute failed --- Selecting user from chiphistory table\n";

    my $row_ref = $sth->fetchrow_hashref();

    #printf STDERR Dumper($row_ref);
    $sth->finish();

    #my $name = "-";
    my $name = $shortname;
    my $userid = 0;

    unless (defined($row_ref)) {
        return ($userid, $name);
    }

    $name = sprintf("%s,%s", $row_ref->{ 'lastname' }, $row_ref->{ 'firstname' });
    $userid = $row_ref->{'userid'};
    #printf STDERR "%s %s userid: %s name: %s\n", $starttime, $row_ref->{'starttime'}, $row_ref->{'userid'}, $name;
    return ($userid, $name);
}

# get_user_name_extended
# Get the user who was using a chip during a specific time period.
#
sub get_user_name_extended {
    my ($dbh, $shortname, $chipid, $starttime) = @_;
    
    printf STDERR "get_user_name_extended: starttime: %s chipid: %s\n", $starttime, $chipid;

    #my $sth = $dbh->prepare("SELECT c.userid, u.firstname, u.lastname, c.starttime FROM chiphistory c JOIN users u ON c.userid = u.userid
    #        WHERE c.chipid=? AND c.starttime<=?  AND (c.finishtime>=? or c.finishtime like '0000-00-00 00:00:00')");

    #my $sth = $dbh->prepare("
    #        SELECT h.userid, u.firstname, u.lastname, h.starttime, c.chip
    #        FROM chiphistory h 
    #        JOIN chips c ON c.chipid = h.chipid
    #        LEFT JOIN users u ON h.userid = u.userid
    #        WHERE h.chipid=? AND (
    #            ( ? BETWEEN h.starttime AND h.finishtime)  OR
    #            ( (? >= h.starttime) AND (h.finishtime = '0000-00-00 00:00:00'))) ");

    my $sth = $dbh->prepare("
            SELECT c.chip, CHIPS.chipid, CHIPS.starttime, CHIPS.finishtime, CHIPS.firstname, CHIPS.lastname, c.shortname
            FROM chips c
            LEFT JOIN ( 
                SELECT h.userid, h.chipid, h.starttime, h.finishtime, u.firstname, u.lastname from chiphistory h 
                JOIN users u 
                ON h.userid = u.userid AND (( ? BETWEEN h.starttime AND h.finishtime) OR 
                    (? >= h.starttime) AND (h.finishtime = '0000-00-00 00:00:00'))
            ) CHIPS on CHIPS.chipid = c.chipid
            WHERE c.chipid=?
            ");

    $sth->execute($starttime, $starttime, $chipid) || die "Execute failed --- Selecting user from chiphistory table\n";

    my $row_ref = $sth->fetchrow_hashref();

    printf STDERR Dumper($row_ref);
    $sth->finish();

    my $chip = $row_ref->{'chip'};

    #my $name = "-";
    my $name = $shortname;
    my $userid = 0;

    unless (defined($row_ref)) {
        return ($userid, $name);
    }

    my $lastname = $row_ref->{ 'lastname' };
    my $firstname = $row_ref->{ 'firstname' };
    $name = sprintf("%s,%s", $lastname, $firstname) if (defined($lastname) || defined($firstname));
    $userid = $row_ref->{'userid'};
    printf STDERR "%s %s userid: %s name: %s chip: %s\n", $starttime, $row_ref->{'starttime'}, $row_ref->{'userid'}, $name, $chip;
    return ($userid, $name, $shortname, $chip);
}


# get_loaner
# Get the name of a chip or return the tagid
#
sub get_loaner {
    my ($dbh, $chipid, $chip) = @_;
    my $sth = $dbh->prepare("SELECT shortname FROM chips where chipid=?");;
    $sth->execute($chipid) || die "Execute failed --- Selecting user from tags table\n";
    my $row_ref = $sth->fetchrow_hashref;
    $sth->finish();

    unless (defined($row_ref)) {
        return $chip;
    }
    my $shortname = $row_ref->{'shortname'};
    return $shortname if ($shortname ne "");
    return $chip;
}



sub Misc::kph {
    my ($distance, $ms) = @_;
    return 0 unless($ms);
    #printf STDERR "KPH distance: %d ms: %d\n", $distance, $ms;
    my $kph = (3600/($ms/1000)) * $distance;
    return sprintf("%4.1f", $kph);
}


sub Misc::hhmm {
    my ($datestamp) = @_;
    my @values = split(/ /,$datestamp);
    my @hhmmss = split(/:/,$values[1]);
    return sprintf("%s:%s", $hhmmss[0], $hhmmss[1]);
}



sub Misc::mmss {
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
        #$mmss = sprintf("%4.1f", $seconds);
    }
    #printf STDERR "[%6.2f] %s minutes: %d seconds: %d tenths: %d\n", $totalseconds, $mmss, $minutes, $seconds, $tenths;
    return $mmss;
}


sub Misc::diemsg {
        my ($line, $msg, $sth) = @_;
        unless (defined($msg) && defined($sth)) {
            die sprintf("LINE: %d msg or sth not defined\n", $line);
        }
        if (defined($sth)) {
            if (defined($sth->{'statement'})) {
                die sprintf("%s(%d):%s\n%s\n", $msg, $line, $sth->errstr, $sth->{'statement'});
            }
            else {
                die sprintf("%s(%d):%s\n", $msg, $line, $sth->errstr);
            }
        }
        die sprintf("%s\nSTH NOT DEFINED\n", $msg);
}


1;


