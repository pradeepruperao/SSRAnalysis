#!/usr/bin/perl
use strict;
use warnings;

# Check if the correct number of arguments is provided
if (@ARGV != 2) {
    die "Usage: perl ssr_to_genes.pl ssr_file gene_file\n";
}

# Open the SSR file and gene file
my ($ssr_file, $gene_file) = @ARGV;

open my $ssr_fh, '<', $ssr_file or die "Could not open '$ssr_file' $!\n";
open my $gene_fh, '<', $gene_file or die "Could not open '$gene_file' $!\n";

# Store genes from the gene file in a hash
my %genes;

while (my $line = <$gene_fh>) {
    chomp $line;
    my ($ssr_chr, $ssr_start, $ssr_end, $gene_id, $gene_chr, $gene_start, $gene_end) = split("\t", $line);

    # Store genes based on the chromosome as a key
    push @{$genes{$gene_chr}}, {
        gene_id    => $gene_id,
        gene_start => $gene_start,
        gene_end   => $gene_end
    };
}
close $gene_fh;

# Read the SSR file and find overlapping genes
while (my $line = <$ssr_fh>) {
    chomp $line;
    my ($chr, $start, $end) = split("\t", $line);

    # Check if there are any genes on this chromosome
    if (exists $genes{$chr}) {
        my $found_gene = 0;

        foreach my $gene (@{$genes{$chr}}) {
            # Check if the SSR falls within the gene region
            if ($start <= $gene->{gene_end} && $end >= $gene->{gene_start}) {
                print "SSR ($chr:$start-$end) overlaps with gene $gene->{gene_id} ($chr:$gene->{gene_start}-$gene->{gene_end})\n";
                $found_gene = 1;
            }
        }

        # If no overlapping gene is found
        print "SSR ($chr:$start-$end) does not overlap with any gene\n" unless $found_gene;
    } else {
        print "No genes found on chromosome $chr for SSR ($chr:$start-$end)\n";
    }
}
close $ssr_fh;

