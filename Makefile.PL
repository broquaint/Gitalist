#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

name 'Gitalist';
all_from 'lib/Gitalist.pm';

author 'Dan Brook <broq@cpan.org>';

license 'gpl2';

if ($ENV{GITALIST_RELEASE_TESTING}) {
    # Nasty hack as Module::Install kindly re-loads all of these :/
    local $SIG{__WARN__} = sub { return if $_[0] =~ /redefined/; warn shift };
    require Module::Install::AuthorRequires;
    require Module::Install::AuthorTests;

    author_tests('t/author');
    author_requires('Test::NoTabs');
    author_requires('Test::Pod' => '1.14');
    author_requires('Test::Pod::Coverage' => '1.04');

    require File::Find;
    require FindBin;
    require ExtUtils::MM_Unix;
    # Fill in provides info so that indexing works right (in the face of MX::Declare)
    # by just smashing filenames to package names and not trying to be smart..
    File::Find::find(sub {
        return unless /^\w.*?\.pm$/;
        my $fn = $File::Find::name;
        my $ver = ExtUtils::MM_Unix->parse_version($fn);

        $fn =~ s/.+?lib/lib/;
        my $pn = $fn;
        $pn =~ s|^lib/||;
        $pn =~ s|/|::|g;
        $pn =~ s/\.pm$//;

        provides(
            $pn => {
                file => $fn,
                # Ewww
                $ver ne 'undef' ? (version => $ver) : (),
            },
        );
    }, $FindBin::Bin . "/lib");
}

requires 'Catalyst::Runtime' => '5.8001402';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Plugin::SubRequest' => '0.15';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Component::InstancePerContext';
requires 'Catalyst::Controller::ActionRole';
requires 'Catalyst::View::Component::SubInclude' => '0.07';
requires 'Catalyst::View::TT';
requires 'Try::Tiny';
requires 'Template';
requires 'Template::Provider::Encoding';
requires 'Template::Plugin::Cycle';

requires 'Config::General';

requires 'Moose';
requires 'Moose::Autobox';
requires 'MooseX::MultiMethods' => '0.10';
requires 'MooseX::Declare' => '0.32';
requires 'MooseX::Types::Common';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types';
requires 'namespace::autoclean';

requires 'Git::PurePerl' => '0.46';

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

test_requires 'Test::More' => '0.88';
test_requires 'Test::utf8' => '0.02';

resources bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Gitalist';
resources repository => 'git://git.shadowcat.co.uk/catagits/Gitalist.git';

catalyst;

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Gitalist.pm > README")
        and die $!;
}

if ($ENV{GITALIST_RELEASE_TESTING}) {
    author_tests 't/author';
    author_requires 'Test::NoTabs';
    author_requires 'Test::Pod' => '1.14';
    author_requires 'Test::Pod::Coverage' => '1.04';
    author_requires 'Test::WWW::Mechanize::Catalyst' => '0.51';
    author_requires 'HTML::TreeBuilder::XPath';
    author_requires 'WWW::Mechanize::TreeBuilder';
}

install_script glob('script/*.pl');
auto_install;

{   # Make sure you REALLY REALLY have to have the env variable set to run
    # any of the dist actions.
    package # PAUSE HIDE
    MY;

    sub dist_core { # MakeMaker is awesome fun to customise. And when I say
        my ($self, @args) = @_; # fun I mean OH GOD MY EYES.
        my $text = $self->SUPER::dist_core(@args);
        my @lines = split /\n/, $text;
        unless ($ENV{GITALIST_RELEASE_TESTING}) {
            my ($printed, @out_lines);
            foreach my $in (@lines) {
                if ($in =~ /^\S/) {
                    undef $printed;
                    $in =~ s/:.*$/:/g;
                    push @out_lines, $in;
                }
                elsif ($in =~ /^\s+$/) {
                    push @out_lines, $in;
                }
                elsif (!$printed) {
                    push @out_lines, "\techo Get stuffed mate - set GITALIST_RELEASE_TESTING if you really want to do this..";
                    $printed = 1;
                }
                else {}
            }
            @lines = @out_lines;
        }
        return join "\n", @lines;
    }
}

WriteAll;

