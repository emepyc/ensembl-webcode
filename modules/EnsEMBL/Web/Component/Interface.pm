package EnsEMBL::Web::Component::Interface;

### Module to create generic forms for Document::Interface and its associated modules

use EnsEMBL::Web::Component;
use EnsEMBL::Web::Form;

our @ISA = qw( EnsEMBL::Web::Component);
use strict;
use warnings;
no warnings "uninitialized";

sub add_form {
  ### Builds an empty HTML form for a new record
  my($panel, $object) = @_;
  my $form = _data_form($panel, $object, 'add');

  ## navigation elements
  $form->add_element( 'type' => 'Hidden', 'name' => 'prev_action', 'value' => 'Save Record');
  $form->add_element( 'type' => 'Hidden', 'name' => 'db_action', 'value' => 'save');
  $form->add_element( 'type' => 'Hidden', 'name' => 'dataview', 'value' => 'preview');
  $form->add_element( 'type' => 'Submit', 'value' => 'Next');

  return $form ;
}

sub select_to_edit_form {
  ### Builds a form consisting of a dropdown widget that lists all records
  ### Sends the user to a second form where the record can be edited
  my($panel, $object) = @_;

  my $form = _record_select($panel, $object, 'select');

  ## navigation elements
  $form->add_element( 'type' => 'Hidden', 'name' => 'dataview', 'value' => 'edit');
  $form->add_element( 'type' => 'Submit', 'value' => 'Next');
  return $form ;
}

sub edit_form {
  ### Builds an HTML form populated with a database record
  my($panel, $object) = @_;

  my $primary_key = $panel->interface->data->get_primary_key;
  my $id = $object->param($primary_key);
  
  my $form = _data_form($panel, $object, 'edit');
  $form->add_element(
          'type'  => 'Hidden',
          'name'  => $primary_key,
          'value' => $id,  
        );

  ## Show creation/modification details?
  if ($panel->interface->show_history) {
    my $history = $panel->interface->history_fields($id);
    foreach my $field (@$history) {
      $form->add_element(%$field);
    }
  }

  ## navigation elements
  $form->add_element( 'type' => 'Hidden', 'name' => 'db_action', 'value' => 'save');
  $form->add_element( 'type' => 'Hidden', 'name' => 'dataview', 'value' => 'preview');
  $form->add_element( 'type' => 'Submit', 'value' => 'Next');
  return $form ;
}

sub select_to_delete_form {
  ### Builds a form consisting of a dropdown widget that lists all records
  ### Sends the user to a page where the record can be previewed before deletion
  my($panel, $object) = @_;
  
  my $form = _record_select($panel, $object, 'select');

  ## navigation elements
  $form->add_element( 'type' => 'Hidden', 'name' => 'db_action', 'value' => 'delete');
  $form->add_element( 'type' => 'Hidden', 'name' => 'dataview', 'value' => 'preview');
  $form->add_element( 'type' => 'Submit', 'value' => 'View Record');
  return $form ;
}

sub script_name {
  my ($panel, $object) = @_;
  if ($panel->interface->script_name) {
    return $panel->interface->script_name;
  }
  return $object->script;
}

sub preview_form {
  ### Displays a record or form input as non-editable text, 
  ### and also passes the data as hidden form elements
  my($panel, $object) = @_;
  
  ## Create form  
  my $script = script_name($panel, $object);
  my $form = EnsEMBL::Web::Form->new('preview', "/common/$script", 'post');

  ## get data and assemble form
  my $primary_key = $panel->interface->data->get_primary_key;
  my $id = $object->param($primary_key);
  my $db_action = $object->param('db_action');

  if ($db_action eq 'delete') {
    $panel->interface->data->populate($id);
  }
  else {
    $panel->interface->cgi_populate($object, $id);
  }

  ## add form elements
  $form->add_element(
            'type'  => 'Hidden',
            'name'  => $primary_key,
            'value' => $id,  
        );
  my $preview_fields = $panel->interface->preview_fields($id);
  my $element;
  foreach $element (@$preview_fields) {
    $form->add_element(%$element);
  }
  my $pass_fields = $panel->interface->pass_fields($id);
  foreach $element (@$pass_fields) {
    $form->add_element(%$element);
  }

  ## navigation elements
  $form->add_element( 'type' => 'Hidden', 'name' => 'dataview', 'value' => $db_action);
  $form->add_element( 'type' => 'Submit', 'value' => 'OK' );
  return $form ;
}

sub _data_form {
  ### Function to build a record editing form
  my($panel, $object, $name) = @_;
  warn "PANEL: " . $panel; 
  my $script = script_name($panel, $object);
  my $form = EnsEMBL::Web::Form->new($name, "/common/$script", 'post');

  ## form widgets
  my $key = $panel->interface->data->get_primary_key;
  my $id = $object->param($key);
  if ($id) {
    $panel->interface->data->populate($id);
  }
  else {
    $panel->interface->cgi_populate($object, '');
  }
  my @widgets = @{$panel->interface->edit_fields};

  foreach my $element (@widgets) {
    $form->add_element(%$element);
  }
  return $form;
}

sub _record_select {
  ### Function to build a record selection form
  my($panel, $object, $name) = @_;
  
  my $script = script_name($panel, $object);
  my $form = EnsEMBL::Web::Form->new($name, "/common/$script", 'post');

  my $select  = $panel->interface->dropdown ? 'select' : '';
  my @options;
  if ($select) {
    push @options, {'name'=>'--- Choose ---', 'value'=>''};
  }

  ## Get record index
  my @unsorted_list = @{$panel->interface->record_list};
  my @columns = @{$panel->interface->option_columns};

  ## Create field type lookup, for sorting purposes
  my %lookup;
  my @all_fields = @{$panel->interface->data->get_all_fields};
  foreach my $field (@all_fields) {
    $lookup{$field->get_name} = $field->get_type;
  }

  ## Do custom sort
  my ($sort_code, $repeat);
  foreach my $sort_col (@{$panel->interface->option_order}) {
    if ($repeat > 0) {
      $sort_code .= ' || ';
    }
    ## build sort function
    ## try to guess appropriate sort type
    if ($lookup{$sort_col} =~ /^int/ || $lookup{$sort_col} =~ /^float/) {
      $sort_code .= '$a->'.$sort_col.' <=> $b->'.$sort_col.' ';
    }
    else {
      $sort_code .= 'lc $a->'.$sort_col.' cmp lc $b->'.$sort_col.' ';
    }
    $repeat++;
  }
  my $subref = eval "sub { $sort_code }";
  my @list = sort $subref @unsorted_list;

  ## Output sorted list
  foreach my $entry (@list) {
    my $value = $entry->id;
    my $text;
    foreach my $col (@columns) {
      $text .= $entry->$col.' - ';
    }
    $text =~ s/ - $//;
    push @options, {'name'=>$text, 'value'=>$value};
  }
  
  $form->add_element( 
            'type'    => 'DropDown', 
            'select'  => $select,
            'title'   => 'Select a Record', 
            'name'    => $panel->interface->data->get_primary_key, 
            'values'  => \@options,
          
          );
  
  return $form;
}

sub select_to_edit {
  ### Panel rendering for select_form
  my($panel, $object) = @_;
  my $html;
  if ($panel->interface->panel_header('select_to_edit')) {
    $html .= $panel->interface->panel_header('select_to_edit');
  }
  $html .= _render_form($panel, 'select', $panel->interface->panel_style);
  if ($panel->interface->panel_footer('select_to_edit')) {
    $html .= $panel->interface->panel_footer('select_to_edit');
  }
  $panel->print($html);
}

sub select_to_delete {
  ### Panel rendering for select_form
  my($panel, $object) = @_;
  my $html;
  if ($panel->interface->panel_header('select_to_delete')) {
    $html .= $panel->interface->panel_header('select_to_delete');
  }
  $html .= _render_form($panel, 'select', $panel->interface->panel_style);
  if ($panel->interface->panel_footer('select_to_delete')) {
    $html .= $panel->interface->panel_footer('select_to_delete');
  }
  $panel->print($html);
}

sub add {
  ### Panel rendering for add_form
  my($panel, $object) = @_;
  my $html;
  if ($panel->interface->panel_header('add')) {
    $html .= $panel->interface->panel_header('add');
  }
  $html .= _render_form($panel, 'add', $panel->interface->panel_style);
  if ($panel->interface->panel_footer('add')) {
    $html .= $panel->interface->panel_footer('add');
  }
  $panel->print($html);
}

sub edit {
  ### Panel rendering for edit_form
  my($panel, $object) = @_;
  my $html;
  if ($panel->interface->panel_header('edit')) {
    $html .= $panel->interface->panel_header('edit');
  }
  $html .= _render_form($panel, 'edit');
  if ($panel->interface->panel_footer('edit')) {
    $html .= $panel->interface->panel_footer('edit');
  }
  $panel->print($html);
}

sub preview {
  ### Panel rendering for preview_form
  my($panel, $object) = @_;
  my $html;
  if ($panel->interface->panel_header('preview')) {
    $html .= $panel->interface->panel_header('preview');
  }
  $html .= _render_form($panel, 'preview');
  if ($panel->interface->panel_footer('preview')) {
    $html .= $panel->interface->panel_footer('preview');
  }
  $panel->print($html);
}

sub _render_form {
  ### Wrapper for form rendering - optionally adds a bordered DIV
  my ( $panel, $form, $style ) = @_;
  my $html = qq(<div style="width:80%"); 
  if ($style && $style eq 'border') {
    $html .= ' class="formpanel"';
  }
  $html .= '>';
  $html .= $panel->form($form)->render();
  $html .= '</div>';
  return $html;
}

sub on_success {
  ### Static panel displaying database feedback on success
  my($panel, $object) = @_;
  my $script = script_name($panel, $object);
  my $html = qq(<p>Your changes were saved to the database. 
<ul>
<li><a href="/common/$script?dataview=add">Add another record</a></li>
<li><a href="/common/$script?dataview=select_to_edit">Select a record to edit</a></li>
);
  if ($panel->interface->permit_delete) {
    $html .= qq(<li><a href="/common/$script?dataview=select_to_delete">Select a record to delete</a></li>
);
  }
  $html .= '</ul>';
  $panel->print($html);
}

sub on_failure {
  ### Static panel displaying database feedback on failure
  my($panel, $object) = @_;
  my $html = qq(<p>Sorry, there was a problem saving your changes.</p>);
  $panel->print($html);
}

1;