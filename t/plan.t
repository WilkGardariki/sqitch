#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10.1;
use utf8;
use Test::More tests => 9;
#use Test::More 'no_plan';
use App::Sqitch;
use Path::Class;
use Test::Exception;
use lib 't/lib';
use MockOutput;

my $CLASS;

BEGIN {
    $CLASS = 'App::Sqitch::Plan';
    use_ok $CLASS or die;
}

can_ok $CLASS, qw(
    plan
    _parse
);

my $sqitch = App::Sqitch->new;
isa_ok my $plan = App::Sqitch::Plan->new(sqitch => $sqitch), $CLASS;

sub tag {
    App::Sqitch::Plan::Tag->new(
        index => $_[0],
        names => $_[1],
        steps => $_[2]
    )
}

##############################################################################
# Test parsing.
my $file = file qw(t plans widgets.plan);
is_deeply $plan->_parse($file), [
    tag 0, [qw(foo)] => [qw(hey you)],
], 'Should parse simple "widgets.plan"';

# Plan with multiple tags.
$file = file qw(t plans multi.plan);
is_deeply $plan->_parse($file), [
    tag( 0, [qw(foo)] => [qw(hey you)] ),
    tag( 1, [qw(bar baz)] => [qw(this/rocks hey-there)] ),
], 'Should parse multi-tagged "multi.plan"';

# Try a plan with steps appearing without a tag.
$file = file qw(t plans steps-only.plan);
throws_ok { $plan->_parse($file) } qr/FAIL:/,
    'Should die on plan with steps beore tags';
is_deeply +MockOutput->get_fail, [[
    "Syntax error in $file at line ",
    5,
    ': step "hey" not associated with a tag',
]], 'And the error should have been output';

# Try a plan with a bad step name.
$file = file qw(t plans bad-step.plan);
throws_ok { $plan->_parse($file) } qr/FAIL:/,
    'Should die on plan with bad step name';
is_deeply +MockOutput->get_fail, [[
    "Syntax error in $file at line ",
    5,
    ': "what what what"',
]], 'And the error should have been output';

# $plan->seek($tag);
# while (my $tag = $plan->next) {
#     for my $step ($tag->steps) {
#         # Deploy.
#     }
# }
