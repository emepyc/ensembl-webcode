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

package EnsEMBL::Web::DOM::Node::Element::Textarea;

use strict;

use base qw(EnsEMBL::Web::DOM::Node::Element);

sub node_name {
  ## @overrides
  return 'textarea';
}

sub form {
  ## Returns a reference to the form object that contains the input
  return shift->get_ancestor_by_tag_name('form');
}

sub disabled {
  ## Accessor of disabled attribute
  return shift->_access_attribute('disabled', @_);
}

1;