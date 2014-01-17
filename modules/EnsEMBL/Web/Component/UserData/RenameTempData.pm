package EnsEMBL::Web::Component::UserData::RenameTempData;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::Form;

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;

  my $form = EnsEMBL::Web::Form->new('rename_tempdata', $object->species_path($object->data_species).'/UserData/SaveTempData', 'post');

  my $tempdata = $object->get_session->get_data('code' => $object->param('code'));

  return unless $tempdata;

  $form->add_element(
    'type'  => 'String',
    'name'  => 'name',
    'label' => 'Name',
    'value' => $tempdata->{'name'},
  );
  $form->add_element(
    'type'  => 'Hidden',
    'name'  =>  'code',
    'value' => $object->param('code'),
  );

  ## navigation elements
  $form->add_element( 'type' => 'Submit', 'value' => 'Save');

  return $form->render;
}

1;