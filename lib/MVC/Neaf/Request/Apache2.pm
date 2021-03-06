package MVC::Neaf::Request::Apache2;

use strict;
use warnings;

our $VERSION = 0.05;

=head1 NAME

MVC::Neaf::Request::Apache - Apache2 (mod_perl) driver for Not Even A Framework.

=head1 DESCRIPTION

Apache2 request that will invoke MVC::Neaf core functions from under mod_perl.

Much to the author's disgrace, this module currently uses
BOTH Apache2::RequestRec and Apache2::Request from libapreq.

=head1 SYNOPSIS

The following apache configuration should work with this module:

    LoadModule perl_module        modules/mod_perl.so
        PerlSwitches -I[% YOUR_LIB_DIRECTORY %]
    LoadModule apreq_module       [% modules %]/mod_apreq2.so

    # later...
    PerlModule MVC::Neaf::Request::Apache2
    PerlPostConfigRequire [% YOUR_APPLICATION %]
    <Location /[% SOME_URL_PREFIX %]>
        SetHandler perl-script
        PerlResponseHandler MVC::Neaf::Request::Apache2
    </Location>

=head1 METHODS

=cut

use URI::Escape;
use HTTP::Headers;
use Carp;

my %fail_apache;
foreach my $mod (qw(
    Apache2::RequestRec
    Apache2::RequestIO
    Apache2::Connection
    APR::SockAddr
    Apache2::Request
    Apache2::Upload
    Apache2::Const
)) {
    eval "require $mod" and next; ## no critic
    # warn "Failed to load $mod: $@";
    $fail_apache{$mod} = $@;
};

if (%fail_apache) {
    carp "WARNING: Some Apache2 modules failed to load, "
        . __PACKAGE__ . " may not be fully operational";
    no warnings 'redefine'; ## no critic
    *do_get_path = sub {
        my $self = shift;
        croak( (ref $self)."->do_get_path: "
            ."apache modules failed to load on startup: "
            . join ", ", keys %fail_apache);
    };
} else {
    Apache2::Const->import( -compile => 'OK' );
};

use MVC::Neaf;
use parent qw(MVC::Neaf::Request);

=head2 do_get_client_ip

=cut

sub do_get_client_ip {
    my $self = shift;

    my $conn = $self->{driver_raw}->connection;
    return $conn->remote_ip;
};

=head2 do_get_http_version

=cut

sub do_get_http_version {
    my $self = shift;
    my $proto = $self->{driver_raw}->proto_num;
    $proto =~ /^\D*(\d+?)\D*(\d\d?\d?)$/;
    return join ".", 0+$1, 0+$2;
};

=head2 do_get_scheme

=cut

sub do_get_scheme {
    my $self = shift;

    # Shamelessly stolen from Catalyst
    my $https = $self->{driver_raw}->subprocess_env('HTTPS');
    return $https and uc $https eq 'ON' ? "https" : "http";
};

=head2 do_get_hostname

=cut

sub do_get_hostname {
    my $self = shift;
    return $self->{driver_raw}->hostname;
};

=head2 do_get_port()

=cut

sub do_get_port {
    my $self = shift;

    my $conn = $self->{driver_raw}->connection;
    return $conn->local_addr->port;
};

=head2 do_get_method()

=cut

sub do_get_method {
    my $self = shift;

    return $self->{driver_raw}->method;
};

=head2 do_get_path()

=cut

sub do_get_path {
    my $self = shift;

    return $self->{driver_raw}->uri;
};

=head2 do_get_params()

=cut

sub do_get_params {
    my $self = shift;

    my %hash;
    my $r = $self->{driver};
    $hash{$_} = $r->param($_) for $r->param;

    return \%hash;
};

=head2 do_get_header_in()

=cut

sub do_get_header_in {
    my $self = shift;

    my %head;
    $self->{driver_raw}->headers_in->do( sub {
        my ($key, $val) = @_;
        push @{ $head{$key} }, $val;
    });

    return HTTP::Headers->new( %head );
};

=head2 do_get_upload( "name" )

Convert apache upload object into MCV::Neaf::Upload.

=cut

sub do_get_upload {
    my ($self, $name) = @_;

    my $r = $self->{driver};
    my $upload = $r->upload($name);

    return $upload ? {
        handle => $upload->fh,
        tempfile => $upload->tempname,
        filename => $upload->filename,
    } : ();
};

=head2 do_reply( $status, \%headers, $content )

=cut

sub do_reply {
    my ($self, $status, $header, $content) = @_;

    my $r = $self->{driver_raw};

    $r->status( $status );
    $r->content_type( delete $header->{'Content-Type'} );

    my $head = $r->headers_out;
    foreach my $name (keys %$header) {
        my $val = $header->{$name};
        $val = [ $val ]
            if (ref $val ne 'ARRAY');
        $head->add( $name, $_ ) for @$val;
    };

    $r->print( $content );
};

=head2 handler( $apache_request )

A valid Apache2/mod_perl handler.

This invokes MCV::Neaf->handle_request when called.

Unfortunately, libapreq (in addition to mod_perl) is required currently.

=cut

sub handler : method {
    my ($class, $r) = @_;

    my $self = $class->new(
        driver_raw => $r,
        driver => Apache2::Request->new($r),
    );
    my $reply = MVC::Neaf->handle_request( $self );

    return Apache2::Const::OK();
};

=head2 failed_startup()

If Apache modules failed to load on startup, report error here.

This is done so because adding Apache2::* as dependencies would impose
a HUGE headache on PSGI users.

Ideally, this module should be mover out of the repository altogether.

=cut

sub failed_startup {
       return %fail_apache ? \%fail_apache : ();
};

1;
