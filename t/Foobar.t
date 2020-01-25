use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Foobar

=cut

=abstract

Turns Foos into Bars

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

ok 1 and done_testing;
