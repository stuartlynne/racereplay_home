

package FKey;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(init find finish);

# FKey::init - Setup a foreign key search or insert 
#
# Give the key name:
#
#       table = keys
#       keyid = keyid
#
sub FKey::init {
    my ($dbsql, $fkey) = @_;
    my %fkey;

    my $ftable = sprintf("%ss", $fkey);
    my $fkeyid_name = sprintf("%sid", $fkey);
    
    my $sqlks = sprintf("SELECT %s FROM %s where %s=?", $fkeyid_name, $ftable, $fkey);
    my $sqlki = sprintf ("INSERT INTO %s (%s) VALUES(?)", $ftable, $fkey);

    $fkey{'sSth'} = $dbsql->prepare($sqlks);
    $fkey{'iSth'} = $dbsql->prepare($sqlki);
    $fkey{'key'} = $fkey;
    $fkey{'keyid'} = $fkeyid_name;
    $fkey{'table'} = $ftable;

    return %fkey;
}

# FKey::find - find a foreign key, insert if necessary
#
sub FKey::find {

    my ($keyval, %fkey) = @_;

    my $sSth = $fkey{'sSth'};
    my $iSth = $fkey{'iSth'};
    my $keyid_name = $fkey{'keyid'};
    

    # find foreign key, insert a record if it is not present
    #
    $sSth->execute($keyval);
    my $row = $sSth->fetchrow_hashref();

    unless (defined($row)) {
        $iSth->execute($keyval) || die "Could not insert $keyval\n";
        $sSth->execute($keyval) || die "Could not find or insert $keyval\n";
        $row = $sSth->fetchrow_hashref();
    }
    unless (defined($row)) {
        die "Could not find or insert $keyval\n";
    }
    
    my $keyid = $row->{$keyid_name};
    return $keyid;
}

# FKey::finish
#
sub FKey::finish {
    my (%fkey, $val) = @_;
    my $sSth = $fkey{'sSth'};
    my $iSth = $fkey{'iSth'};
    $sSth->finish();
    $iSth->finish();
}


# simple CSV parser
#
# This will use the first line of a CSV file to set column titles and then parse
# each row to create an associative array based on the column names.
#
# For this inpurt:
#
#       "First Name","Last Name","Sex"
#       "Fred","Smith","M"
#
# This would be returned after parsing the first data line:
#
#       {
#               'First Name' => 'Fred',
#               'Last Name' => 'Smith',
#               'Sex' => 'M'
#       };
#            


# simple_csv_init
#
# Create a Text::CSV object
sub SimpleCSV::init {
    my ($name) = @_;
    my %rcsv;                                   # declare associative array          
    $rcsv{'name'} = $name;
    $rcsv{'csv'} = Text::CSV->new({ binary=> 1, eol => $/ });
    return \%rcsv;                              # return array reference
}

# simple_csv_parse
#
# parse an input line.
sub SimpleCSV::parse {

    my ($rcsv, $line, $first) = @_;
    my %Results;

    chop($line);

    my $csv =  $rcsv->{'csv'};
    my $status = $csv->parse($line);

    if ($first) {
        printf STDERR "FIRST\n";

        if (defined($rcsv->{'names'})) {
            delete $rcsv->{'names'};
        }

        my @Names = $csv->fields();            # store array reference
        $rcsv->{'names'} = \@Names;
        return %Results;                        # not defined
    }

    my @Names = @{$rcsv->{'names'}};            # retrieve array reference
    my @Fields = $csv->fields();                # parse

    for (my $i = 0; $i <= $#Names; $i++) {
        $Results{$Names[$i]} = $Fields[$i];
    }

    return \%Results;
}

# simple_csv_finish
#
#sub simple_csv_finish {
#    my (%rcsv) = @_;
#    delete %rcsv if (defined(%rcsv));
#}


1;


