package Bio::EnsEMBL::GlyphSet::SE_generic_match;
use strict;
use Bio::EnsEMBL::GlyphSet;
@Bio::EnsEMBL::GlyphSet::SE_generic_match::ISA = qw(Bio::EnsEMBL::GlyphSet);
use Data::Dumper;
$Data::Dumper::Maxdepth = 3;

sub init_label {
	my ($self) = @_;
	$self->init_label_text();
}

sub _init {
	my ($self)  = @_;
	my $offset  = $self->{'container'}->start - 1;

	my $h       = 8;
	my $colours = $self->colours();
	my( $fontname, $fontsize ) = $self->get_font_details( 'outertext' );
	my $Config        = $self->{'config'};
	my $pix_per_bp    = $Config->transform->{'scalex'};
	my $bitmap_length = $Config->image_width();
	my $length        = $Config->container_width(); 
	my $all_matches   = $Config->{'transcript'}{'evidence'};
	my $strand        = $Config->{'transcript'}->{'transcript'}->strand;
	my $H = 0;
	my( $font_w_bp, $font_h_bp);

	my $legend_priority = 4;

	my @draw_end_lines;

	#go through each combined hit sorted on total length
	foreach my $hit_details (sort { $b->{'hit_length'} <=> $a->{'hit_length'} } values %{$all_matches} ) {
		next unless @{$hit_details->{'data'}};
		my $start_x = 1000000;
		my $finish_x = 0;
		my $hit_name = $hit_details->{'hit_name'};
#		warn "drawing $hit_name";
#		if ($hit_name eq 'BC023530.2') {
#			warn Dumper($hit_details);
#		}
		my $last_end = 0; #true/false (prevents drawing of line from first exon

		#note the type of hit drawn, priority defines the order in the legend, height used to draw legend
		$Config->{'TSE_legend'}{'hit_feature'}{'found'}++;
		$Config->{'TSE_legend'}{'hit_feature'}{'priority'} = $legend_priority;
		$Config->{'TSE_legend'}{'hit_feature'}{'height'} = $h;

		#go through each component of the combined hit (ie each supporting_feature)
		foreach my $block (@{$hit_details->{'data'}}) {

warn Dumper($block);

			my $exon_stable_id = $block->[5]->stable_id;

			my $width = $block->[1]-$block->[0] +1;
			$start_x = $start_x > $block->[0] ? $block->[0] : $start_x;
			$finish_x = $finish_x < $block->[1] ? $block->[1] : $finish_x;

			#draw a line back to the end of the previous exon
			my ($w,$x);
			if ($strand == 1) {
				$x = $last_end + (1/$pix_per_bp);
				$w = $block->[0] - $last_end - (1/$pix_per_bp);
			}
			else {
				$x = $last_end - (1/$pix_per_bp);
				$w = $block->[1] - $last_end + (1/$pix_per_bp);
			}
			if ($last_end) {
				my $G = new Sanger::Graphics::Glyph::Line({
					'x'         => $x,
					'y'         => $H + $h/2,
					'h'         => 1,
					'width'     => $w,#-10/$pix_per_bp,
					'colour'    =>'black',
					'absolutey' => 1,});
				#add a red attribute if there is a part of the hit missing
				if (my $mismatch = $block->[7]) {
					$G->{'dotted'} = 1;
					$G->{'colour'} = 'red';
					$G->{'title'} = $mismatch > 0 ? "Missing $mismatch bp of hit" : "Overlapping ".abs($mismatch)." bp of hit";
				}
				$self->push($G);				
			}
			
			$last_end = $strand == 1 ? $block->[1] : $block->[0];

			#draw the location of the exon hit
			my $G = new Sanger::Graphics::Glyph::Rect({
				'x'            => $block->[0] ,
				'y'            => $H,
				'width'        => $width,
				'height'       => $h,
				'bordercolour' => 'black',
				'absolutey'    => 1,
				'title'        => $hit_name,
				'href'         => '',
			});	

			#second and third elements of $block define whether there is a mismatch between exon and hit boundries
			#(need some logic to add meaningfull terms to zmenu)
			if ($block->[3]) {
				my $c = $block->[3] > 0 ? 'red' : 'blue';
				push @draw_end_lines, [$block->[0],$H,$c];
				push @draw_end_lines, [$block->[0]+1/$pix_per_bp,$H,$c];
				$G->{'title'} = $hit_name." (".$block->[3].")";
			}
			if ($block->[4]) {
				my $c = $block->[4] > 0 ? 'red' : 'blue';
				push @draw_end_lines, [$block->[1]-1/$pix_per_bp,$H,$c];
				push @draw_end_lines, [$block->[1],$H,$c];
				$G->{'title'} = $hit_name." (".$block->[4].")";
			}
			$self->push( $G );
		}

		my @res = $self->get_text_width(0, "$hit_name", '', 'font'=>$fontname, 'ptsize'=>$fontsize);
		my $W = ($res[2])/$pix_per_bp;
		($font_w_bp, $font_h_bp) = ($res[2]/$pix_per_bp,$res[3]);
		my $tglyph = new Sanger::Graphics::Glyph::Text({
			'x'         => -$res[2],
			'y'         => $H,
			'height'    => $font_h_bp,
			'width'     => $res[2],
			'textwidth' => $res[2],
			'font'      => $fontname,
			'colour'    => 'blue',
			'text'      => $hit_name,
			'absolutey' => 1,
			'absolutex' => 1,
			'absolutewidth' => 1,
			'ptsize'    => $fontsize,
			'halign     '=> 'right',
		});
		$self->push($tglyph);

		$H += $font_h_bp + 4;
	}

	#draw lines for the exon / hit boundry mismatches (draw last so they're on top of everything else)
	foreach my $mismatch_line ( @draw_end_lines ) {
		my $G = new Sanger::Graphics::Glyph::Line({
			'x'         => $mismatch_line->[0] ,
			'y'         => $mismatch_line->[1],
			'width'     => 0,
			'height'    => $h,
			'colour'    => $mismatch_line->[2],
			'absolutey' => 1,
		});
		$self->push( $G );
	}
}

sub colours {
  my $self = shift;
  my $Config = $self->{'config'};
#  warn Dumper($Config->get('TSE_transcript','colours')); #
  return $Config->get('TSE_transcript','colours');
}

1;
