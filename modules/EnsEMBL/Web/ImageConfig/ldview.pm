package EnsEMBL::Web::ImageConfig::ldview;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift; 

  $self->set_parameters({
    _userdatatype_ID    =>  30,
    _transcript_names_  =>  'yes',
    title               => 'LD slice',
    show_buttons        => 'no',    # show +/- buttons
    button_width        => 8,       # width of red "+/-" buttons
    show_labels         => 'yes',   # show track names on left-hand side
    label_width         => 100,     # width of labels on left-hand side
    margin              => 5,       # margin
    spacing             => 2,       # spacing
    image_width         => 800,
    context             => 20000,
  });

  $self->create_menus(
    transcript => 'Other Genes',
    prediction => 'Prediction transcripts',
    other      => 'Other',
    variation  => 'Variations',
    legends    => 'Legends'
  );

  $self->load_tracks;

  $self->modify_configs(
    ['variation_feature_genotyped_variation' ],
    { display => 'normal', strand => 'r', style => 'box', depth => 10000 }
  );

  $self->add_tracks('other',
    [ 'scalebar', '', 'scalebar', { display => 'normal', strand => 'r', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',    '', 'ruler',    { display => 'normal', strand => 'f', name => 'Ruler',     description => 'Shows the length of the region being displayed' }]
  );

  $self->add_tracks('legends',
    [ 'variation_legend', '', 'variation_legend', { variation_legend => 'on', strand => 'r', caption => 'Variation legend' }]
  );

  $self->modify_configs(
    [ 'transcript_core_ensembl' ],
    { display => 'normal' }
  );
  
  $self->modify_configs(
    [ 'variation_feature_variation' ],
    { display => 'normal', caption => 'Variations', strand => 'r' }
  );
}

1;
