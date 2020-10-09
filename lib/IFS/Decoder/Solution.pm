#!/usr/bin/perl
use 5.030;
package IFS::Decoder::Solution;
use Moose;
 
has 'header' => (is => 'rw', isa => 'Any');
has 'solution' => (is => 'rw', isa => 'Any');
 
has 'symbols' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] }
);
 
has 'submission_time' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] }
);






42;

