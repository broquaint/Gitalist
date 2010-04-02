package Gitalist::URIStructure::WithLog;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

sub log : Chained('find') PathPart('') CaptureArgs(0) {}

sub shortlog : Chained('log') Args(0) {}

sub longlog : Chained('log') PathPart('log') Args(0) {}

1;