#!/usr/bin/env perl

use strict;
use warnings;
use Encode;

# always use latest and gratest libraries, not the system ones
use FindBin qw($Bin);
use File::Basename qw(dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

my $tpl = <<"TT";
<h1>Content analysis of [% IF name %][% name %][% ELSE %]files[% END %].</h1>
<form method="POST" enctype="multipart/form-data">
    <input type="file" name="count">
    <input type="submit" value="&gt;&gt;">
</form>
[% IF top %]
    <hr>
    <h2>Most common words[% IF name; " in " _ name; END %]</h2>
    [% FOREACH record IN top %]
        [% record.0 %]: [% record.1 %]<br>
    [% END %]
[% END %]
TT

MVC::Neaf->route("/" => sub {
    my $req = shift;

    my @top;
    my $up = $req->upload("count");
    if ($up) {
        my $fd = $up->handle;
        my %count;
        while (<$fd>) {
            $_ = decode_utf8($_);
            $count{$_}++ for /(\w\w\w+)/g;
        };

        # transform hash into set of tuples; filter count > 1;
        # sort tuples by count, then alphabetically
        @top = sort { $b->[1] <=> $a->[1] or $a->[0] cmp $b->[0] }
            grep { $_->[1] > 1 }
            map { [ $_, $count{$_} ] }
            keys %count;
    };

    return {
        -template => \$tpl,
        size      => $up && $up->size,
        name      => $up && $up->filename,
        top       => @top ? \@top : undef,
    };
});

MVC::Neaf->run;
