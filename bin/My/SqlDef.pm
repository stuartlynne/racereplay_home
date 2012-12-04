# 

package SqlDef;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(SqlConfig);


sub SqlDef::SqlConfig {

    my $DATABASE = "racetest";
    my $DBUSER = "racetest";
    my $DBPASSWORD = "aa.bb.cc";

    return ($DATABASE, $DBUSER, $DBPASSWORD);

}

1;




