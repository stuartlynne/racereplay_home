

package Misc;

use strict;
use Exporter;
use Data::Dumper;


use My::FKey qw(init find finish);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(find_chipid find_loaner find_health get_venue_info get_event_info get_user_name get_loaner);

my %Chips;

sub Misc::find_chipid {
    my ($dbsql, $tagid) = @_;

    # cached value
    return $Chips{$tagid} if(defined($Chips{$tagid}));

    # search for it
    my $cSth = $dbsql->prepare( "SELECT chipid FROM chips WHERE chip=?");
    $cSth->execute($tagid) || die "Select from chips failed\n";
    my $srow = $cSth->fetchrow_hashref();

    # found it
    if (defined($srow)) {
        my $chipid = $srow->{'chipid'};
        $Chips{$tagid} = $chipid;
        return $chipid;
    }

    # insert it
    my $iSth = $dbsql->prepare("INSERT INTO chips (chip,totalactivations,replacebattery,batteryreplaced,currentactivations) VALUES(?,0,0,?,0)");
    $iSth->execute($tagid, "00-00-00 00:00:00") || die "Failed to insert chipid\n";

    # now find it
    $cSth->execute($tagid) || die "Insert into chips failed\n";
    $srow = $cSth->fetchrow_hashref();
    
    unless (defined($srow)) { die "Cannot find chip!\n"; }

    # cache it
    my $chipid = $srow->{'chipid'};
    $Chips{$tagid} = $chipid;
    return $chipid;
}

sub Misc::find_loaner {
    my ($dbsql, $shortname) = @_;

    # cached value
    return $Chips{$shortname} if(defined($Chips{$shortname}));

    printf STDERR "SELECT chipid FROM chips WHERE shortname=%s\n", $shortname;

    # search for it
    my $cSth = $dbsql->prepare( "SELECT chipid FROM chips WHERE shortname=?");
    $cSth->execute($shortname) || die "Select from chips failed\n";
    my $srow = $cSth->fetchrow_hashref();

    # found it
    if (defined($srow)) {
        my $chipid = $srow->{'chipid'};
        $Chips{$shortname} = $chipid;
        return $chipid;
    }

    return undef;
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
    printf STDERR "INSERT INTO health (chipid,datestamp,activations,corrections,skippedcount,battery,batteryreplaced) VALUES(%s,%s,0,0,0,0,0)\n", $chipid, $date;

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

    my $sth = $dbh->prepare("SELECT c.userid, u.firstname, u.lastname, c.starttime FROM chiphistory c JOIN users u ON c.userid = u.userid
            WHERE c.chipid=? AND c.starttime<=?  AND (c.finishtime>=? or c.finishtime like '0000-00-00 00:00:00')");

    $sth->execute($chipid, $starttime, $starttime) || die "Execute failed --- Selecting user from chiphistory table\n";

    my $row_ref = $sth->fetchrow_hashref();
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





1;


