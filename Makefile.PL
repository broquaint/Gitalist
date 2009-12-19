#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::ReadmeFromPod;

name 'Gitalist';
all_from 'lib/Gitalist.pm';
readme_from 'lib/Gitalist.pm';

author 'Dan Brook <broq@cpan.org>';

license 'gpl2';

requires 'Catalyst::Runtime' => '5.8001402';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Component::InstancePerContext';
requires 'Catalyst::View::TT';

requires 'Template';
requires 'Template::Provider::Encoding';
requires 'Template::Plugin::Cycle';

requires 'Config::General';

requires 'Moose';
requires 'Moose::Autobox';
requires 'MooseX::Declare';
requires 'MooseX::Types::Common';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types';
requires 'namespace::autoclean';

requires 'Git::PurePerl' => '0.43';

requires 'aliased';
requires 'CGI';
requires 'DateTime';
requires 'DateTime::Format::Mail';
requires 'File::Copy::Recursive';
requires 'File::Which';
requires 'HTML::Entities';
requires 'IPC::Run';
requires 'List::MoreUtils';
requires 'Path::Class' => '0.17';
requires 'Sub::Exporter';
requires 'Syntax::Highlight::Engine::Kate';
requires 'Sys::Hostname';
requires 'XML::Atom';
requires 'XML::RSS';
requires 'XML::OPML::SimpleGen';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

test_requires 'Test::More' => '0.88';
test_requires 'Test::utf8' => '0.02';

resources bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Gitalist';
resources repository => 'git://git.shadowcat.co.uk/catagits/Gitalist.git';

catalyst;

author_tests 't/author';
install_script glob('script/*.pl');
auto_install;

# This is totally gross :)
# However, it is also much more effective than Module::Install::ProvidesClass
# which a) just does not work very well for us, b) totally won't install from
# cpan right now..
author_requires 'Module::Find';
author_requires 'B::Hooks::OP::Check::StashChange';
author_requires 'B::Compiling';
if ($Module::Install::AUTHOR) {
    require Module::Find;
    require B::Hooks::OP::Check::StashChange;
    require B::Compiling;
    require FindBin;
    require lib;

    my $libdir = "$FindBin::Bin/lib";
    lib->import($libdir);

    my %packages;

    our $id = B::Hooks::OP::Check::StashChange::register(sub {
        my ($new, $old) = @_;
        my $file = B::Compiling::PL_compiling()->file;
        return unless $file =~ s/^$libdir/lib/;
        $packages{$new} ||= $file
            if $new =~ /^Gitalist/;
    });

    require Gitalist;
    Module::Find::useall(qw/Gitalist/);
    undef $id;

    no strict 'refs';
    provides($_ => {
        file => $packages{$_},
        ${$_.'::VERSION'} ? ( version => $_->VERSION() ) : ()
    }) for keys %packages;
}

WriteAll;

