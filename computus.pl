#!/usr/bin/env perl

use Date::Easter;
$year=@ARGV[0];
($month, $day)=orthodox_easter($year);
if($month==3) {
    $month_string="March";
} elsif ($month==4) {
    $month_string="April";
} elsif ($month==5) {
    $month_string="May";
}
printf("%s, %d\n", $month_string, $day);
