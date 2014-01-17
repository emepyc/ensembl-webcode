package EnsEMBL::Web::Controller::Command::Filter::Ajax;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;

our @ISA = qw(EnsEMBL::Web::Controller::Command::Filter);

{

sub header {
  my $self = shift;
  return "Content-Type: text/html\n\n" . $self->SUPER::header();
}

sub inherit {
  my ($self, $parent) = @_;
  unshift @ISA, ref $parent;
  return 1;
}

}

1;