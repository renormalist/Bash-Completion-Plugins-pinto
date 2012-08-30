#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;
use Bash::Completion::Request;
use Bash::Completion::Plugins::pinto;
use Data::Dumper;
use Test::Deep "cmp_deeply";

sub complete {
        my ($line) = @_;

        local %ENV;

        $ENV{'COMP_LINE'} = $line;
        $ENV{'COMP_POINT'} = length($line);

        my $r = Bash::Completion::Request->new();
        my $c = Bash::Completion::Plugins::pinto->new();

        $c->complete($r);
        return [sort $r->candidates];
}

my %spec = (
            "pinto m" => [qw(manual merge)],
            "pinto s" => [qw(stacks statistics)],
            "pinto ma" => [qw(manual)],
            "pinto man" => [qw(manual)],
            "pinto manu" => [qw(manual)],
           );

foreach my $line (sort keys %spec) {
        my $expect = $spec{$line};
        my $result = complete($line);
        cmp_deeply($result, $expect, "$line => [".join(",", @$result)."]");
}

done_testing;
