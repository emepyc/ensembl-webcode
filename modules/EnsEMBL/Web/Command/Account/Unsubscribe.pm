package EnsEMBL::Web::Command::Account::Unsubscribe;

use strict;
use warnings;

use EnsEMBL::Web::Data::Group;
use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $object = $self->object;

  my $group = EnsEMBL::Web::Data::Group->new($object->param('id'));
  $group->assign_status_to_user($ENV{'ENSEMBL_USER_ID'}, 'inactive');

  $self->ajax_redirect('/Account/MemberGroups', {'reload' => 1});

}

1;