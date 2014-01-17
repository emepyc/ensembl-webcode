package EnsEMBL::Web::Component::Account::Password;

### Module to create password entry/update form 

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Account);
use EnsEMBL::Web::Form;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;

  my $form;

  # Use different destination, so we can apply different access filters
  if ($object->param('code')) {
    $form = EnsEMBL::Web::Form->new('enter_password', "/Account/SavePassword", 'post');
    $form->add_element('type' => 'SubHeader', 'value' => 'Activate your account');
  } else {
    $form = EnsEMBL::Web::Form->new('enter_password', "/Account/ResetPassword", 'post');
    $form->add_element('type' => 'SubHeader', 'value' => 'Change your password');
    $form->add_element('type' => 'Password', 'name' => 'password', 'label' => 'Old password', 'required' => 'yes');
  }

  # Logged-in user, changing own password
  if (my $user = $object->user) {
    my $email = $user->email;
    my $species = $object->species;
    $species = '' if $species !~ /_/;
    
    $form->add_element('type' => 'Hidden', 'name' => 'email', 'value' => $email);
    $form->add_element('type' => 'Hidden', 'name' => 'cp_species', 'value' => $species);
  } else {
    # Setting new/forgotten password
    $form->add_element('type' => 'Hidden', 'name' => 'user_id', 'value' => $object->param('user_id'));
    $form->add_element('type' => 'Hidden', 'name' => 'email',   'value' => $object->param('email'));
    $form->add_element('type' => 'Hidden', 'name' => 'code',    'value' => $object->param('code'));
  }

  if ($object->param('record_id')) {
    $form->add_element(
      'type'  => 'Hidden',
      'name'  => 'record_id',
      'value' => $object->param('record_id')
    );
  }

  $form->add_element('type' => 'Password', 'name' => 'new_password_1', 'label' => 'New password', 'required' => 'yes');
  $form->add_element('type' => 'Password', 'name' => 'new_password_2', 'label' => 'Confirm new password', 'required' => 'yes');
  $form->add_element('type' => 'Submit',   'name' => 'submit',   'value' => 'Save', 'class' => 'modal_link');

  return $form->render;
}

1;