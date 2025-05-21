#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

# Check for input file argument
if (@ARGV != 2) {
    die "Usage: perl create_vcf_from_misa.pl <input_list_of_directories.txt> <output_vcf_file.vcf>\n";
}

my $input_file = $ARGV[0];  # File containing list of directories (each directory has MISA output files)
my $output_vcf = $ARGV[1];  # Output VCF file

# Read list of directories
open(my $dir_fh, '<', $input_file) or die "Cannot open $input_file: $!\n";
my @dirs = <$dir_fh>;
chomp(@dirs);
close($dir_fh);

# Hash to store SSR data
my %ssr_data;

# Process each directory
foreach my $dir (@dirs) {
    my $sample_name = basename($dir); # Assuming directory name is the sample name

    # Read all GFF files in the directory
    opendir(my $dh, $dir) or die "Cannot open directory $dir: $!\n";
    my @gff_files = grep { /\.gff$/ && -f "$dir/$_" } readdir($dh);
    closedir($dh);

    # Process each GFF file
    foreach my $gff_file (@gff_files) {
        my $file_path = "$dir/$gff_file";

        open(my $misa_fh, '<', $file_path) or die "Cannot open $file_path: $!\n";
        while (my $line = <$misa_fh>) {
            chomp($line);
            next if ($line =~ /^#/);  # Skip header lines

            # Parse GFF format (assuming a simple tab-delimited structure)
            my @fields = split("\t", $line);
            my ($chrom, $source, $feature, $start, $end, $score, $strand, $phase, $attributes) = @fields;
            my ($motif) = $attributes =~ /motif=([\w]+)/;

            # Create a unique ID for each SSR position
            my $ssr_id = join("_", $chrom, $start, $end);

            # Initialize hash if not present
            $ssr_data{$ssr_id}{'CHROM'} = $chrom;
            $ssr_data{$ssr_id}{'POS'} = $start;
            $ssr_data{$ssr_id}{'ID'} = '.';
            $ssr_data{$ssr_id}{'REF'} = 'N';
            $ssr_data{$ssr_id}{'ALT'} = $motif;
            $ssr_data{$ssr_id}{'QUAL'} = '.';
            $ssr_data{$ssr_id}{'FILTER'} = '.';
            $ssr_data{$ssr_id}{'INFO'} = '.';
            $ssr_data{$ssr_id}{'FORMAT'} = 'GT';

            # Mark presence/absence of SSR for this sample
            $ssr_data{$ssr_id}{'samples'}{$sample_name} = 1;
        }
        close($misa_fh);
    }
}

# Create VCF Header
open(my $vcf_fh, '>', $output_vcf) or die "Cannot write to $output_vcf: $!\n";
print $vcf_fh "##fileformat=VCFv4.2\n";
print $vcf_fh "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";

# Print sample names in header
foreach my $dir (@dirs) {
    my $sample_name = basename($dir); 
    print $vcf_fh "\t$sample_name";
}
print $vcf_fh "\n";

# Print VCF Data
foreach my $ssr_id (sort keys %ssr_data) {
    my $chrom = $ssr_data{$ssr_id}{'CHROM'};
    my $pos = $ssr_data{$ssr_id}{'POS'};
    my $id = $ssr_data{$ssr_id}{'ID'};
    my $ref = $ssr_data{$ssr_id}{'REF'};
    my $alt = $ssr_data{$ssr_id}{'ALT'};
    my $qual = $ssr_data{$ssr_id}{'QUAL'};
    my $filter = $ssr_data{$ssr_id}{'FILTER'};
    my $info = $ssr_data{$ssr_id}{'INFO'};
    my $format = $ssr_data{$ssr_id}{'FORMAT'};

    print $vcf_fh "$chrom\t$pos\t$id\t$ref\t$alt\t$qual\t$filter\t$info\t$format";

    # Print presence/absence for each sample
    foreach my $dir (@dirs) {
        my $sample_name = basename($dir); 
        if (exists $ssr_data{$ssr_id}{'samples'}{$sample_name}) {
            print $vcf_fh "\t1";  # SSR present
        } else {
            print $vcf_fh "\t0";  # SSR absent
        }
    }
    print $vcf_fh "\n";
}
close($vcf_fh);

print "VCF file created successfully: $output_vcf\n";

