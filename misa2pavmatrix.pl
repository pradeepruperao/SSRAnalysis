#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

# Check if the correct number of arguments is provided
if (@ARGV != 1) {
    die "Usage: perl script.pl <input_file_with_folders>\n";
}

# Input file containing list of folders
my $input_file = $ARGV[0];

# Output file for presence-absence matrix
my $output_file = "presence_absence_matrix.tsv";

# Open the input file and read the list of folders
open(my $fh, '<', $input_file) or die "Could not open file '$input_file' $!";
my @folders = <$fh>;
chomp @folders;
close($fh);

# Hash to store SSR data and presence-absence information
my %ssr_data;
my @samples;

# Process each folder (sample)
foreach my $folder (@folders) {
    # Get the sample name from the folder name
    my $sample_name = basename($folder);
    push @samples, $sample_name;

    # Get the list of GFF files in the folder
    my @gff_files = glob("$folder/*.gff");

    # Process each GFF file in the folder
    foreach my $gff_file (@gff_files) {
        open(my $gff_fh, '<', $gff_file) or die "Could not open GFF file '$gff_file' $!";

        # Read and process each line of the GFF file
        while (my $line = <$gff_fh>) {
            chomp $line;
            
            # Skip comment lines
            next if $line =~ /^#/;

            # Split the GFF line into fields
            my @fields = split(/\t/, $line);

            # Extract necessary information from GFF fields
            my $chrom = $fields[0];
            my $start = $fields[3];
            my $end = $fields[4];
            my $ssr_key = "$chrom\t$start\t$end";  # Unique key for each SSR based on its location

            # Initialize presence-absence information for this SSR if not already initialized
            $ssr_data{$ssr_key} //= { map { $_ => 0 } @samples };

            # Mark the SSR as present for this sample
            $ssr_data{$ssr_key}->{$sample_name} = 1;
        }
        close($gff_fh);
    }
}

# Open the output file for writing
open(my $out_fh, '>', $output_file) or die "Could not open output file '$output_file' $!";

# Print header row
print $out_fh "Chromosome\tStart\tEnd\t" . join("\t", @samples) . "\n";

# Print SSR data and presence-absence matrix
foreach my $ssr_key (sort keys %ssr_data) {
    print $out_fh "$ssr_key";
    foreach my $sample (@samples) {
        print $out_fh "\t$ssr_data{$ssr_key}->{$sample}";
    }
    print $out_fh "\n";
}

# Close the output file
close($out_fh);

print "Presence-absence matrix has been created in file '$output_file'.\n";

