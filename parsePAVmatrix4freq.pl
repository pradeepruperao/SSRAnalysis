#!/usr/bin/perl
use strict;
use warnings;

# Check if the correct number of arguments is provided
if (@ARGV != 1) {
    die "Usage: perl script.pl <input_file_with_SSR_matrix>\n";
}

# Input file containing the SSR presence-absence matrix
my $input_file = $ARGV[0];

# Output file to store SSR presence frequency
my $output_file = "ssr_presence_frequency.tsv";

# Open the input file for reading
open(my $in_fh, '<', $input_file) or die "Could not open file '$input_file' $!";

# Open the output file for writing
open(my $out_fh, '>', $output_file) or die "Could not open output file '$output_file' $!";

# Print header for the output file
print $out_fh "Chromosome\tStart\tEnd\tFrequency\n";

# Process each line in the input file
while (my $line = <$in_fh>) {
    chomp $line;

    # Skip the header line
    next if $. == 1;

    # Split the line into fields (Chromosome, Start, End, Sample1, Sample2, ...)
    my @fields = split(/\t/, $line);

    # Extract chromosome, start, and end positions
    my $chrom = $fields[0];
    my $start = $fields[1];
    my $end = $fields[2];

    # Extract the presence-absence values (0s and 1s) from sample columns
    my @presence_absence = @fields[3..$#fields];

    # Calculate the frequency of SSR presence (number of 1s)
    my $count_present = 0;
    $count_present += $_ for @presence_absence;

    # Calculate the frequency as the proportion of samples with SSR present
    my $frequency = $count_present / scalar(@presence_absence);

    # Print the result to the output file with frequency formatted to two decimal places
    printf $out_fh "%s\t%s\t%s\t%.2f\n", $chrom, $start, $end, $frequency;
}

# Close the file handles
close($in_fh);
close($out_fh);

print "SSR presence frequency file has been created: '$output_file'.\n";

