#!/usr/bin/env perl

use strict;
use warnings;
use GD::Simple;

# always use latest and gratest libraries, not the system ones
use FindBin qw($Bin);
use File::Basename qw(dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

my $tpl = <<"TT";
    <h1>Image example</h1>
    <div>
    <form>
        <input type="submit" name="mod" value="--">
        <input type="submit" name="mod" value="++"><br>
        <input name="size" value="[% size %]">
        <input type="submit" value="&gt;&gt;">
    </form>
    </div>
    <img src="/forms/04-img.cgi?size=[% size %]" width="[% size %]" height="[% size %]">
TT

MVC::Neaf->route( "/" => sub {
    my $req = shift;

    my $size = $req->param( size => qr/\d+/, 100 );
    my $mod  = $req->param( 'mod' => qr/.*/ );
    $mod =~ /\+/ and $size++;
    $mod =~ /\-/ and $size--;

    $size = 1000 if ($size > 1000); # some safety...
    $size = 10   if ( $size < 10 );

    return {
        size => $size,
        -template => \$tpl,
    };
});

MVC::Neaf->route( "/forms/04-img.cgi" => sub {
    my $req = shift;
    my $size = $req->param( size => qr/\d+/, 100 );

    my $r = int ($size / 2);
    my $img = GD::Simple->new( $size, $size );
    $img->moveTo ( $r, $r );
    $img->bgcolor('orange');
    $img->ellipse( $size, $size );

    return {
        -content => $img->png,
        -type    => 'image/png',
    };
});

MVC::Neaf->run;

