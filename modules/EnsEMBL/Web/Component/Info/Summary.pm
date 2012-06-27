package EnsEMBL::Web::Component::Info::Summary;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Document::HTML::HomeSearch;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}


sub content {
  my $self   = shift;
  my $search = EnsEMBL::Web::Document::HTML::HomeSearch->new($self->hub);
  return $search->render;
}

1;
