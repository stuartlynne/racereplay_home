# 

package SqlDef;

use strict;
use Exporter;
use Cwd;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_TAGS);

$VERSION        = 1.00;
@ISA            = qw(Exporter);
@EXPORT         = qw(SqlConfig);


sub SqlDef::SqlConfig {
    
    my $dir = fastcwd;
    my @values = split(/\//, $dir);

    my $DATABASE = $values[2];
    my $DBUSER = $values[2];
    my $DBPASSWORD = "aa.bb.cc";

    return ($DATABASE, $DBUSER, $DBPASSWORD);

}

1;




