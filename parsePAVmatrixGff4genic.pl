#!/usr/bin/perl
use strict;
use warnings;

# Subroutine to parse GFF file and store gene information
sub parse_gff {
    my ($gff_file) = @_;
    my %genes;

    open my $gff_fh, '<', $gff_file or die "Could not open GFF file '$gff_file': $!";

    while (my $line = <$gff_fh>) {
        chomp $line;
        next if $line =~ /^\#/; # Skip comment lines
        my @columns = split("\t", $line);

        # Check for gene entries
        if ($columns[2] eq 'gene') {
            my ($chromosome, $start, $end, $attributes) = @columns[0, 3, 4, 8];
            
            # Extract gene ID from the attributes column
            if ($attributes =~ /ID=([^;]+)/) {
                my $gene_id = $1;
                push @{$genes{$chromosome}}, { 
                    start => $start, 
                    end => $end, 
                    gene_id => $gene_id 
                };
            }
        }
    }
    close $gff_fh;
    return %genes;
}

# Subroutine to identify genic SSRs from the PAV matrix and gene data
sub identify_genic_ssrs {
    my ($pav_file, $genes_ref) = @_;
    my %genes = %$genes_ref;
    my @output;

    open my $pav_fh, '<', $pav_file or die "Could not open PAV file '$pav_file': $!";

    # Read header line
    my $header = <$pav_fh>;
    chomp $header;

    # Process each SSR entry
    while (my $line = <$pav_fh>) {
        chomp $line;
        my @fields = split("\t", $line);
        my ($ssr_chrom, $ssr_start, $ssr_end) = @fields[0..2];

        # Check if SSR falls within any gene coordinates
        if (exists $genes{$ssr_chrom}) {
            foreach my $gene (@{$genes{$ssr_chrom}}) {
                if ($ssr_start >= $gene->{start} && $ssr_end <= $gene->{end}) {
                    push @output, join("\t", $ssr_chrom, $ssr_start, $ssr_end, $gene->{gene_id}, $ssr_chrom, $gene->{start}, $gene->{end});
                }
            }
        }
    }
    close $pav_fh;
    return @output;
}

# Main execution block
sub main {
    my ($pav_file, $gff_file) = @ARGV;
    die "Usage: perl script.pl <SSR_PAV_matrix_file> <genes_gff_file>\n" unless @ARGV == 2;

    # Parse GFF file to get gene coordinates
    my %genes = parse_gff($gff_file);

    # Identify genic SSRs from PAV matrix
    my @genic_ssrs = identify_genic_ssrs($pav_file, \%genes);

    # Write output to a file
    open my $out_fh, '>', 'genic_ssrs_output.txt' or die "Could not open output file: $!";
    print $out_fh "SSR_Chromosome\tSSR_Start\tSSR_End\tGeneID\tGene_Chromosome\tGene_Start\tGene_End\n";
    print $out_fh "$_\n" for @genic_ssrs;
    close $out_fh;

    print "Output written to genic_ssrs_output.txt\n";
}

# Run main subroutine
main();

