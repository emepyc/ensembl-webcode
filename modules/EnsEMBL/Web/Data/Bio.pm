=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Data::Bio;

### NAME: EnsEMBL::Web::Data::Bio
### Base class - wrapper around a Bio::EnsEMBL API object 

### STATUS: Under Development
### Replacement for EnsEMBL::Web::Object

### DESCRIPTION:
### This module and its children provide additional data-handling
### capabilities on top of those provided by the API

use strict;
use warnings;
no warnings qw(uninitialized);

use base qw(EnsEMBL::Web::Data);

sub _init {
  my $self = shift;
  $self->data_objects(@_);
}

sub convert_to_drawing_parameters {
### Stub - individual object types probably need to implement this separately
  my $self = shift;
  return [];
}

sub coord_systems {
  my $self = shift;
  return [map { $_->name } @{ $self->hub->database('core')->get_CoordSystemAdaptor()->fetch_all() }];
}

1;