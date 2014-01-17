package EnsEMBL::Web::Filter::PasswordValid;

### Checks if a password matches the encrypted value stored in the database

use strict;

use EnsEMBL::Web::Data::User;
use EnsEMBL::Web::Tools::Encryption qw(encryptPassword);

use base qw(EnsEMBL::Web::Filter);

sub init {
  my $self = shift;
  
  $self->messages = {
    empty_password   => 'You did not supply a password. Please try again.',
    invalid_password => "Sorry, the email address or password was entered incorrectly and could not be validated. Please try again.<br /><br />If you are unsure of your password, click the 'Lost Password' link in the lefthand menu to reactivate your account."
  };
}

sub catch {
  my $self     = shift;
  my $object   = $self->object;
  my $password = $object->param('password');
  
  $self->redirect = '/Account/Login';
  
  if ($password) {
    my $user = EnsEMBL::Web::Data::User->find(email => $object->param('email'));
    
    if ($user) { 
      my $encrypted = encryptPassword($password, $user->salt);
      
      $self->error_code = 'invalid_password' if $user->password ne $encrypted;
    } else {
      # N.B. for security reasons, we do not distinguish between an invalid email address and an invalid password
      $self->error_code = 'invalid_password';
    }
  } else {
    $self->error_code = 'empty_password';
  }
}

1;