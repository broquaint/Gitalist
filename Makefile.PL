#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;
use Module::AutoInstall;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::ReadmeFromPod;

name 'Gitalist';
all_from 'lib/Gitalist.pm';
readme_from 'lib/Gitalist.pm';

author 'Dan Brook <broq@cpan.org>';

license 'gpl2';

requires 'Catalyst::Runtime' => '5.80003';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
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

requires 'Git::PurePerl'; # Note - need the git version in broquaint's fork

requires 'aliased';
requires 'CGI';
requires 'DateTime';
requires 'DateTime::Format::Mail';
requires 'File::Copy::Recursive';
requires 'File::Stat::ModeString';
requires 'File::Which';
requires 'HTML::Entities';
requires 'IO::Capture::Stdout';
requires 'IPC::Run';
requires 'List::MoreUtils';
requires 'Path::Class' => '0.17';
requires 'Sub::Exporter';
requires 'Syntax::Highlight::Engine::Kate';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

test_requires 'Test::More' => '0.88';

catalyst;

author_tests 't/author';
install_script glob('script/*.pl');
auto_install;
WriteAll;
