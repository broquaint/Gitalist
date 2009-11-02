#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'Gitalist';
all_from 'lib/Gitalist.pm';

requires 'Catalyst::Runtime' => '5.80003';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::View::ContentNegotiation::XHTML';
requires 'Template::Plugin::Cycle';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
requires 'MooseX::Types::Common';
requires 'File::Find::Rule';
requires 'File::Stat::ModeString';
requires 'File::Slurp';
requires 'DateTime::Format::Mail';
requires 'IO::Capture::Stdout';
requires 'File::Which';
requires 'CGI';
requires 'DateTime';
requires 'Git::PurePerl';
requires 'List::MoreUtils';
requires 'MooseX::Declare';
requires 'Path::Class' => '0.17';
requires 'Sub::Exporter';
requires 'Syntax::Highlight::Engine::Kate';
requires 'Moose::Autobox';
requires 'DateTime::Format::Human::Duration';

test_requires 'Test::More' => '0.88';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
