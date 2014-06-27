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

package EnsEMBL::Web::Component::DataExport;

### Parent module for new data export interface

### STATUS: Under Development

### DESCRIPTION: Contains base functionality needed by all
### DataExport input forms

use strict;

use base qw(EnsEMBL::Web::Component);

sub create_form {
### Builds the input form used by DataExport
### Note that the form consists of a generic section (file name, format)
### plus multiple format-specific option fieldsets which are hidden by 
### JavaScript until the user chooses a format in the top section
### @param Hashref - form element configuration options
### @param Hashref - additional form settings for specific output formats
### @return EnsEMBL::Web::Form
  my ($self, $settings, $fields_by_format, $tutorial) = @_;
  my $hub  = $self->hub;

  my $format_label = {
    'RTF'   => 'RTF (Word-compatible)',
    'FASTA' => 'FASTA',
  };

  my $form_url  = sprintf('/%s/DataExport/Output', $hub->species);
  my $form      = $self->new_form({'id' => 'export', 'action' => $form_url, 'method' => 'post'});

  ## Generic fields
  my $fieldset  = $form->add_fieldset; 

  my $filename = $hub->param('filename') || $self->default_file_name;
  $filename =~ s/\.[\w|\.]+//;

  my @format_info;
  foreach (sort keys %$fields_by_format) {
    my $info = { 'value' => $_, 'caption' => $format_label->{$_}, 'class' => "_stt__$_ _action_$_"};
    $info->{'selected'} = 'selected' if $hub->param('format') eq $_;
    push @format_info, $info;
  }
  my $formats = [
      {'caption' => '-- Choose Format --', 'value' => 'tutorial'},
      @format_info
    ];
  ## Don't update this field from params, as there's no back 
  ## button for compressed formats!
  my $compress = [
      {'caption' => 'Uncompressed', 'value' => '', 'checked' => 1},
      {'caption' => 'Gzip', 'value' => 'gz'},
      #{'caption' => 'Zip', 'value' => 'zip'},
  ];
  $fieldset->add_field([
    {
      'type'    => 'String',
      'name'    => 'name',
      'label'   => 'File name',
      'value'   => $filename,
    },
    {
      'type'    => 'DropDown',
      'name'    => 'format',
      'label'   => 'File format',
      'values'  => $formats,
      'select'  => 'select',
      'class'   => '_stt _action',
    },
    {
      'type'    => 'Radiolist',
      'name'    => 'compression',
      'label'   => 'Output',
      'values'  => $compress,
    },
  ]);
  ## Hidden fields needed to fetch and process data
  $fieldset->add_hidden([
    {
      'name'    => 'data_type',
      'value'   => $hub->param('data_type'),
    },
    {
      'name'    => 'component',
      'value'   => $hub->param('component'),
    },
    {
      'name'    => 'export_action',
      'value'   => $hub->action,
    },
  ]);
  ## Don't forget the core params!
  my @core_params = keys %{$hub->core_object('parameters')};
  foreach (@core_params) {
    $fieldset->add_hidden([
      {
        'name'    => $_,
        'value'   => $hub->param($_),
      },
    ]);
  }

  ## Add tutorial "fieldset" that is shown by default
  if ($tutorial) {
    my $tutorial_fieldset = $form->add_fieldset({'class' => '_stt_tutorial'});
    my $html = '<p><b>Guide to file formats</b> (select from dropdown list above)</p>';
    foreach my $format (sort keys %$fields_by_format) {
      $html .= $self->get_tutorial($format);
    }
    $tutorial_fieldset->add_notes($html);
  }
  
  ## Create all options forms, then show only one using jQuery
  while (my($format, $fields) = each (%$fields_by_format)) {
    next if ($hub->param('format') && $hub->param('format') ne $format); ## from back button
    my $settings_fieldset  = $form->add_fieldset({'class' => '_stt_'.$format, 'legend' => 'Settings'});

    ## Add custom fields for this data type and format
    foreach (@$fields) {
      my ($name, @values) = @$_;
      ## IMPORTANT - use hashes here, not hashrefs, as Form code does weird stuff 
      ## in background that alters the contents of $settings!
      my %field_info = %{$settings->{$name}};
      next unless keys %field_info;
      ## Reset field name to include format, so we have unique field names
      $name .= '_'.$format;
      $field_info{'name'} = $name;
      @values = $hub->param($name) if $hub->param($name);
      ## Deal with multiple values, which have to be passed
      ## to Form::Fieldset as an arrayref
      my $params;
      if (scalar @values > 1) {
        if ($field_info{'type'} eq 'Hidden') {
          $params = [];
          foreach my $v (@values) {
            my %info = %field_info;
            $info{'value'} = $v;
            push @$params, \%info;
          }
        }
        else {
          $field_info{'value'} = \@values if scalar @values;
          $params = \%field_info;
        }
      }
      else {
        $field_info{'value'} = $values[0] if scalar @values;
        $params = \%field_info;
      }
      ## Add to form
      if ($field_info{'type'} eq 'Hidden') {
        $settings_fieldset->add_hidden($params);
      }
      else { 
        $settings_fieldset->add_field($params);
      }
    }

    ## Doesn't matter that each fieldset has a submit button, as we only ever
    ## display one of them - and putting it here forces user to choose format!
    $settings_fieldset->add_button({
      'type'    => 'Submit',
      'name'    => 'submit',
      'value'   => 'Export',
    });
  }

  return $form;
}

sub default_file_name { 
### Generic name - ideally should be overridden in children
  my $self = shift;
  return $self->hub->species_defs->ENSEMBL_SITETYPE.'_data_export';
}

sub get_tutorial {
  my ($self, $format) = @_;
  my $html = sprintf('<div style="float:left;padding-right:20px;"><p style="margin-bottom:0">%s</p><img src="/img/help/export/%s_tutorial.png"></div>', $format, lc($format));
  return $html;
}

1;