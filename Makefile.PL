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
requires 'File::Stat::ModeString';
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

resources bugtracker => 'http://github.com/broquaint/Gitalist/issues';
resources repository => 'git://github.com/broquaint/Gitalist.git';

catalyst;

author_tests 't/author';
install_script glob('script/*.pl');
auto_install;
WriteAll;
