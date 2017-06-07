#!/usr/bin/perl -w
# Author : Charles VAN GOETHEM

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use Vcf;

my $addAF_VER = '0.0.1';

################################################################################
################################################################################

# Mandatory arguments
my ($vcf_file);

# Mandatory arguments
my ($output,$example);

# Supports arguments
my ($opt_help, $opt_man, $opt_versions);

GetOptions(
    'e|example'	    => \$example,
    'v|vcf=s'		=> \$vcf_file,
    'o|output=s'	=> \$output,
    'help|?'		=> \$opt_help,
    'version!'		=> \$opt_versions,
    'man!'			=> \$opt_man
) or pod2usage(-verbose => 1) && exit;

pod2usage(-verbose => 1) && exit if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# check args

# check if launch example :
if($example) {
    $vcf_file = "test/call/s1.rg.sort.vcf";
    undef $output;
}

# Mandatory
if (not defined $vcf_file) {
	pod2usage(-verbose => 1, -message => "Error : parameters \"-v|--vcf\" is undefined.");
	exit;
} elsif ($vcf_file !~ /(.+\.vcf)$/o) {
	pod2usage(-verbose => 1, -message => "Error : parameters \"-v|--vcf\" not correctly format (expected *.vcf)");
	exit;
} else {
    $vcf_file = $1;
}

# Optional output
if (defined $output) {
    if ($output !~ /(.+\.vcf)$/o) {
    	pod2usage(-verbose => 1, -message => "Error : parameters \"-o|--output\" not correctly format (expected *.vcf)");
    	exit;
    } else {
        $output = $1;
        open(OUT , ">$output") or die "Could not open file '$output' $!";
    }
} else {
    open(OUT, '>&', \*STDOUT) or die "Could not open 'STDOUT' $!";
}
################################################################################
################################################################################

# Create new object Vcf
my $vcf = Vcf->new(file=>$vcf_file);

# Get the header.
$vcf->parse_header();

# Get all samples on vcf
my (@samples) = $vcf->get_samples();

# Add field FORMAT/AF on the header
$vcf->add_header_line({
    key=>'FORMAT',
    ID=>'AF',Number=>1,
    Type=>'Integer',
    Description=>'Allelic Frequence'
});

# Begin the new file : print the new header with FORMAT/AF
print OUT $vcf->format_header();

# For each line of the vcf...
while( my $line = $vcf->next_data_hash()) {
    # ...create new FORMAT/AF field for all samples...
    $vcf->add_format_field($line,'AF');
    # ...and treat each samples.
    foreach my $sample (@samples) {
        # Get AD field...
        my @AD = split(',',$$line{'gtypes'}{$sample}{'AD'});
        # ...and  DP field.
        my $DP = $$line{'gtypes'}{$sample}{'DP'};

        # Then calculate AF...
        my $AF = $AD[1]/$DP;
        # ...and add it to FORMAT/AF.
        $$line{'gtypes'}{$sample}{'AF'}=$AF;
        # Finally print it on the output
        print OUT $vcf->format_line($line);
    }
}

# close the vcf
$vcf->close();
# close the output
close(OUT);

##########################################################################################
##########################################################################################

BEGIN {
	delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV', 'PATH'};
}

END{
  if(defined $opt_versions){
    print
      "\nModules, Perl, OS, Program info:\n",
	  "    strict          $strict::VERSION\n",
	  "    warnings        $warnings::VERSION\n",
	  "    Getopt::Long    $Getopt::Long::VERSION\n",
	  "    Pod::Usage      $Pod::Usage::VERSION\n",
      "    Perl            $]\n",
      "    OS              $^O\n",
	  "    addAF.pl        $addAF_VER\n";
  }
}

##########################################################################################
##########################################################################################

__END__

=pod

=encoding UTF-8

=head1 NAME

addAF.pl

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

addAF.pl -v input.vcf [-o output.vcf]

Add Allelic Frequence (AF) on VCF from samtools/bcftools with FORMAT/AD and FORMAT/DP.

=head1 DESCRIPTION

This script add Allelic Frequence (AF) of each variant on a VCF from
samtools/bcftools with FORMAT/AD and FORMAT/DP.

=head1 ARGUMENTS

=head2 General

    -h,--help       Print this help
    -m,--man        Open man page

=head2 Mandatory arguments

    -v,--vcf        input.vcf     Specify the fastq file you want use (possible multiple file)

=head2 Optional arguments

    -o,--output     output.vcf    You can specify an output file (default: stdout)
    -e,--example    launch example (equivalent to: 'perl addAF.pl -v test/call/s1.rg.sort.vcf')

=head1 AUTHORS

=over 4

=item -

Charles VAN GOETHEM

=back

=cut
