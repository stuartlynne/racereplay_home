

package SimpleCSV;

use strict;
use Exporter;
use Text::CSV;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(init,parse);


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


# SimpleCSV::init
#
# Create a Text::CSV object
sub SimpleCSV::init {
    my ($name) = @_;
    my %rcsv;                                   # declare associative array          
    $rcsv{'name'} = $name;
    $rcsv{'csv'} = Text::CSV->new({ binary=> 1, eol => $/ });
    return \%rcsv;                              # return array reference
}

# SimpleCSV::parse
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

# SimpleCSV::finish
#
#sub SimpleCSV::finish {
#    my (%rcsv) = @_;
#    delete %rcsv if (defined(%rcsv));
#}


1;


