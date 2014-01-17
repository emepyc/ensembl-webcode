#!/usr/local/bin/perl

use strict;
use warnings;
use Carp;

use FindBin qw($Bin);
use File::Basename qw( dirname );

use Pod::Usage;
use Getopt::Long;

my ( $SERVERROOT, $help, $info, $date);

BEGIN{
  &GetOptions( 
	      'help'      => \$help,
	      'info'      => \$info,
          'date=s'    => \$date,
	     );
  
  pod2usage(-verbose => 2) if $info;
  pod2usage(1) if $help;
  
  $SERVERROOT = dirname( $Bin );
  unshift @INC, "$SERVERROOT/conf";
  eval{ require SiteDefs };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;
}

use EnsEMBL::Web::SpeciesDefs;                  
use EnsEMBL::Web::DBSQL::NewsAdaptor;

my $SD = EnsEMBL::Web::SpeciesDefs->new;
my $release_id = $SiteDefs::VERSION;
print "\n\n";

# Connect to web database and get news adaptor
use EnsEMBL::Web::RegObj;

$ENSEMBL_WEB_REGISTRY = EnsEMBL::Web::Registry->new();
my $wa = $ENSEMBL_WEB_REGISTRY->newsAdaptor;

# Check database to see if this release is included already, then
# give the user the option to update the release date
my $release_details = $wa->fetch_releases({'release'=>$release_id});

if ($release_details && $$release_details[0]) {

    my $release_date = $$release_details[0]{'full_date'};

    print "Release $release_id is currently scheduled for $release_date.
            Is this correct? [y/n]";

    while (<STDIN>) {
        chomp;
        unless (/^y$/i) {
            print "Please give the correct release date, formatted as yyyy-mm-dd:";  
            INPUT: while (<STDIN>) {
                chomp;
                if (/\d{4}-\d{2}-\d{2}/) {
                    print "Setting release date to $_\n\n";
                    $wa->set_release_date($release_id, $_);
                    last INPUT;
                }
                print "Sorry, that was not a valid date format.\nPlease input a date in format yyyy-mm-dd:";
            }
        }
        last;
    }
}
else {
    if (!$date || $date !~ /\d{4}-\d{2}-\d{2}/) { 
        # no valid date supplied, so default to 1st of next month
        my @today = localtime(time);
        my $year = $today[5]+1900;
        my $nextmonth = $today[4]+2;
        if ($nextmonth > 12) {
            $nextmonth - 12;
            $year++;
        }
        $nextmonth = sprintf "%02d", $nextmonth;
        $date = $year.'-'.$nextmonth.'-01';
    }
    my $archive = $SiteDefs::ARCHIVE_VERSION;
    $release_details = {
        'release_id'    => $release_id,
        'number'        => $release_id,
        'date'          => $date,
        'archive'       => $archive,
        };
    print "Inserting release $release_id ($archive), scheduled for $date.\n\n";
    $wa->add_release($release_details);
}

# get the hash of all species in the database
my $all_spp = $wa->fetch_species;
my %rev_hash = reverse %$all_spp;

# get a list of valid (configured) species
my @species = $SD->valid_species();
my ($record, $result, $species_id);

foreach my $sp (sort @species) {

    # check if this species is in the database yet
    if (!$rev_hash{$sp}) {
        my $record = {
            'name'          => $SD->get_config($sp, 'SPECIES_BIO_NAME'),
            'common_name'   => $SD->get_config($sp, 'SPECIES_COMMON_NAME'),
            'code'          => $SD->get_config($sp, 'SPECIES_CODE'),
            };
        $species_id = $wa->add_species($record);
        print "Adding new species $sp to database, with ID $species_id\n";
    }
    else {
        $species_id = $rev_hash{$sp};
    }

    if ($species_id) {
        my $a_code = $SD->get_config($sp, 'ENSEMBL_GOLDEN_PATH');
        my $a_name = $SD->get_config($sp, 'ASSEMBLY_ID');
        my $record = { 
            'release_id' => $release_id,
            'species_id' => $species_id,
            'assembly_code' => $a_code,
            'assembly_name' => $a_name,
            };
        $result = $wa->add_release_species($record);
        print "$sp - $result\n";
    }
    else {
        print "Sorry, unable to add record for $sp as no species ID found\n";
    }
}

#exit if this is Vega with no presites
my $st = $SD->get_config( $species[0],'ENSEMBL_SITE_NAME');
exit if ($st eq 'Vega');

## Add pre species to release_species table

my $pre_dir = $SERVERROOT.'/sanger-plugins/pre/conf/';
my $sitedefs = $pre_dir.'SiteDefs.pm';
my $ini_dir = $pre_dir.'ini-files/';

## get list of current pre species from SiteDefs.pm
my @pre_species;

open (IN, '<', $sitedefs) or die "Couldn't open SiteDefs.pm :(\n";
while (<IN>) {
  my $line = $_;
  next unless $line =~ /SiteDefs::__species_aliases/;
  next if $line =~ /^#/;
  my @A = split("'", $line);
  push @pre_species, $A[1];
}  

## parse ini files for species info
opendir(DIR, $ini_dir) || die "Cannot opendir $ini_dir: $!";
print "Adding pre entries for:\n";

foreach my $sp_name (@pre_species) {

  print "- $sp_name\n";
  $species_id = $rev_hash{$sp_name};

  my $inifile = $ini_dir.$sp_name.'.ini';  
  open IN, "< $inifile" or die "Couldn't open ini file $inifile :(\n";

  my ($a_name, $a_code, $common);
  while (<IN>) {
    my $line = $_;
    if ($line =~ /^ASSEMBLY_ID/) {
      my @A = split('=', $line);
      my $value = $A[1];
      my @B = split(';', $value);
      $a_name = $B[0];
      $a_name =~ s/^\s*//; 
      $a_name =~ s/\s*$//; 
    }
    elsif ($line =~ /^ENSEMBL_GOLDEN_PATH/) {
      my @A = split('=', $line);
      my $value = $A[1];
      my @B = split(';', $value);
      $a_code = $B[0];
      $a_code =~ s/^\s*//; 
      $a_code =~ s/\s*$//; 
    }
    elsif ($line =~ /^SPECIES_COMMON_NAME/) {
      my @A = split('=', $line);
      $common = $A[1];
      $common =~ s/^\s*//; 
      $common =~ s/\s*$//; 
      last;
    }
    else {
      next;
    }
  }

  my $record = { 
    'release_id'  => $release_id,
    'species_id'  => $species_id,
    'common_name' => $common,
    'pre_code'    => $a_code,
    'pre_name'    => $a_name,
  };
  $result = $wa->add_release_species($record); 
}

=head1 NAME

update_webdb.pl

=head1 SYNOPSIS

update_webdb.pl [options]

Options:
  --help, --info, --date

B<-h,--help>
  Prints a brief help message and exits.

B<-i,--info>
  Prints man page and exits.

B<-d,--date>
  Release date (optional). If this is the first time you have run this script for a release,
  you should specify a release date in the format yyyy-mm-dd - otherwise it will default to
  the first day of next month!

=head1 DESCRIPTION

B<This program:>

Updates the ensembl_website database by inserting records from the current release's ini files.

It will add information about the release itself (if not already present), based on variables in
the SiteDefs.pm module, and also prompts the user for a release date. If the release record is
present, it asks the user if the release date is still correct.

It then either adds a cross-reference record between the release and the species configured for 
that release, or reports on existing cross-reference records. If a new species has been added to 
this release, a species record will be added to the database provided there is an ini file for it 
in the correct location.

The database location is specified in Ensembl web config file:
  ../conf/ini-files/DEFAULTS.ini

=head1 AUTHOR

Anne Parker, Ensembl Web Team

Enquiries about this script should be addressed to helpdesk@ensembl.org

=cut