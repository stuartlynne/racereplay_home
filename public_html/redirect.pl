#!/usr/bin/perl


use CGI qw/:standard *table start_ul div/;

my $cgi = new CGI;
    
print $cgi->redirect("/racereplay.pl");

