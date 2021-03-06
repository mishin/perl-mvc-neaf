# NAME

MVC::Neaf [ni:f] stands for Not Even A Framework.

# OVERVIEW

Neaf offers very simple rules to build very simple applications.
For the lazy, by the lazy.

**Model** is assumed to be a regular Perl module, and is totally out of scope.

**View** is assumed to have just one method, `render()`,
which receives a hashref and returns a pair of (content, content-type).

**Controller** is reduced to just one function, which gets a request object
and is expected to return a hashref.

A pre-defined set of dash-prefixed control keys allows to control the
framework's behaviour while all other keys are just sent to the view.

**Request** object will depend on the underlying web-server.
The same app, verbatim, should be able to run as PSGI app, CGI script, or
Apache handler.

# FOUNDATIONS

* Start out simple, then scale up.

* Enough magic already. Use simple constructs where possible.

* Zeroconf: everything can be configured, nothing needs to.

* It's not software unless you can run it.

* Trust nobody. Validate the data.

# EXAMPLE

The following would produce a greeting message depending
on the `?name=` parameter.

    use strict;
    use warnings;
    use MVC::Neaf;

    MVC::Neaf->route( "/" => sub {
		my $req = shift;

		return {
			-template => \'Hello, [% name %]!',
			-type     => 'text/plain',
			name      => $req->param( name => qr/\w+/, "Stranger" ),
		},
    });

    MVC::Neaf->run;

# FEATURES

* GET, POST requests, uploads, redirects, and cookies are supported
(not quite impressive, but it's 95% of what's needed);

* Template::Toolkit view out of the box;

* json/jsonp view out of the box (with sanitized callbacks);

* can serve raw content (e.g. generated images);

* sanitized query parameters and cookies out of the box
(LIVR-based form validation planned);

# NOT SO BORING FEATURES

* CLI-based debugging via `perl -MMVC::Neaf=view,Dumper controller.pl /?foo=bar`

* Can gather request performance statistics if needed;

* Can postpone lengthly actions until the request is served;

# EXAMPLES

The `example/` directory has an app explaining HTTP in a nutshell,
jsonp app and some 200-line wiki engine.

# BUGS

Lots of them. Still in alpha stage.

* Http headers handling is a mess;

* Apache handler is a mess;

Patches and proposals are welcome.

# ACKNOWLEDGEMENTS

Eugene Ponizovsky aka IPH had great influence over my understanding of MVC.

Ideas were shamelessly stolen from PSGI, Dancer, and Catalyst.

# LICENSE AND COPYRIGHT

Copyright 2016 Konstantin S. Uvarin aka KHEDIN

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

