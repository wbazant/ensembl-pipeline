
#!/usr/local/bin/perl

#
#
# Cared for by Michele Clamp  <michele@sanger.ac.uk>
#
# Copyright Michele Clamp
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=pod 

=head1 NAME

Bio::EnsEMBL::Pipeline::Runnable::Est2Genome - Runs Est2Genome

=head1 SYNOPSIS

    my $obj = Bio::EnsEMBL::Pipeline::Runnable::Est2Genome->new(
                                             -genomic => $genseq,
                                             -est     => $estseq 
                                             );
    or
    
    my $obj = Bio::EnsEMBL::Pipeline::Runnable::Est2Genome->new()
    
=head1 DESCRIPTION

Object to store the details of an est2genome run.
Stores the est2genome matches as an array of Bio::EnsEMBL::FeaturePair

Methods
new,
genomic_sequence,
est_sequence,
run.
output

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::EnsEMBL::Pipeline::Runnable::Est2Genome;

use vars qw(@ISA);
use strict;
# Object preamble - inherits from Bio::Root::Object;

use Bio::EnsEMBL::Pipeline::RunnableI;
use Bio::EnsEMBL::FeaturePair;
use Bio::EnsEMBL::SeqFeature;
use Bio::Seq;
use Bio::SeqIO;

@ISA = qw(Bio::EnsEMBL::Pipeline::RunnableI);

sub _initialize {
    my ($self,@args) = @_;
    my $make = $self->SUPER::_initialize(@_);    
           
    $self->{'_fplist'} = []; #create key to an array of feature pairs
    
    my( $genomic, $est ) = $self->_rearrange(['GENOMIC','EST'], @args);
        
    $self->genomic_sequence($genomic) if $genomic; #create & fill key to Bio::Seq
    $self->est_sequence($est) if $est; #create & fill key to Bio::Seq
    
    return $self; # success - we hope!
}

=head2 genomic_sequence

    Title   :   genomic_sequence
    Usage   :   $self->genomic_sequence($seq)
    Function:   Get/set method for genomic sequence
    Returns :   Bio::Seq object
    Args    :   Bio::Seq object

=cut 

sub genomic_sequence {
    my( $self, $value ) = @_;    
    
    if ($value) {
        #need to check if passed sequence is Bio::Seq object
        $value->isa("Bio::Seq") || $self->throw("Input isn't a Bio::Seq");
        $self->{'_genomic_sequence'} = $value;
    }
    return $self->{'_genomic_sequence'};
}

=head2 est_sequence

    Title   :   est_sequence
    Usage   :   $self->est_sequence($seq)
    Function:   Get/set method for est sequence
    Returns :   Bio::Seq object
    Args    :   Bio::Seq object

=cut

sub est_sequence {
    my( $self, $value ) = @_;
    
    if ($value) {
        #need to check if passed sequence is Bio::Seq object
        $value->isa("Bio::Seq") || $self->throw("Input isn't a Bio::Seq");
        $self->{'_est_sequence'} = $value;
    }
    return $self->{'_est_sequence'};
}

=head2 run

  Title   : run
  Usage   : $self->run()
            or
            $self->run("genomic.seq", "est.seq")
  Function: Runs est2genome and stores results as FeaturePairs
  Returns : none
  Args    : Temporary filenames for genomic and est sequences

=cut

sub run {
    my ($self, @args) = @_;
    
    # some constant strings
    my $source_tag = "est2genome";
    my $primary_tag = "similarity";
    my $estOrientation; #flag for est strand orientation

    #check inputs
    my $genomicseq = $self->genomic_sequence ||
        $self->throw("Genomic sequence not provided");
    my $estseq = $self->est_sequence ||
        $self->throw("EST sequence not provided");
    
    my ($genfile, $estfile) = $self->_rearrange(['genomic', 'est'], @args);
    #check or set filenames
    unless ($genfile) { $genfile = "genomic.seq"; }
    unless ($estfile) { $estfile = "est.seq"; }    
    
    #use appropriate Bio::Seq method to write fasta format files
    {
        my $genOutput = Bio::SeqIO->new(-file => ">$genfile" , '-format' => 'Fasta')
                    or $self->throw("Can't create new Bio::SeqIO from $genfile '$' : $!");
        my $estOutput = Bio::SeqIO->new(-file => ">$estfile" , '-format' => 'Fasta')
                    or $self->throw("Can't create new Bio::SeqIO from $estfile '$' : $!");

        #fill inputs
        $genOutput->write_seq($self->{'_genomic_sequence'}); 
        $estOutput->write_seq($self->{'_est_sequence'});
    }
    
    #run est2genome 
    #The -reverse switch ensure correct numbering on EST seq in either orientation
    my $est_genome_command = "est_genome -reverse -genome $genfile -est $estfile |";
    open (ESTGENOME, $est_genome_command) 
                or $self->throw("Can't open pipe from '$est_genome_command' : $!");

    #Use the first line to get EST orientation
    my $firstline = <ESTGENOME>;
    if ($firstline =~ /reverse/i) {$estOrientation = -1;}
    else {$estOrientation = 1}
      
    #read output
    while (<ESTGENOME>)
    {
        if ($_ =~ /^Exon/)
        {
              warn $_;
 
              #split on whitespace
              my @elements = split;

              #extract values from output line
              my $f1score = $elements[1];
              my $f1start = $elements[3];
              my $f1end = $elements[4];
              my $f1id = $elements[5];
              my $f2start = $elements[6];
              my $f2end = $elements [7];
              my $f2id = $elements[8];
              my $f1source = $source_tag;
              my $f2source = $source_tag;
              my $f1strand = 1;
              my $f2strand = $estOrientation;
              my $f1primary = $primary_tag;
              my $f2primary = $primary_tag;

              #create features
              my $feat1 = new Bio::EnsEMBL::SeqFeature  (-start =>  $f1start,
                                                        -end =>     $f1end,
                                                        -seqname =>      $f1id,
                                                        -strand =>  $f1strand,
                                                        -score =>   $f1score,
                                                        -source =>  $f1source,
                                                        -primary => $f1primary,
                                                        -analysis => undef );
 
               my $feat2 = new Bio::EnsEMBL::SeqFeature  (-start =>  $f2start,
                                                          -end =>    $f2end,
                                                          -seqname =>$f2id,
                                                          -strand => $f2strand,
                                                          -score =>  undef,
                                                          -source => $f2source,
                                                          -primary =>$f2primary,
                                                          -analysis => undef );
              #create featurepair
              my $fp = new Bio::EnsEMBL::FeaturePair  (-feature1 => $feat1,
                                                       -feature2 => $feat2) ;
 
              #load fp onto array
              push(@{$self->{'_fplist'}}, $fp);
              warn Dumper ($fp);
        }    
    }
    close(ESTGENOME) or $self->throw("Error running '$est_genome_command' ($?)");
           
    #clean up temp files
    unlink ("$genfile");
    unlink ("$estfile");

}

=head2 output

  Title   : output
  Usage   : $self->output
  Function: Returns results of est2genome as array of FeaturePair
  Returns : An array of Bio::EnsEMBL::FeaturePair
  Args    : none

=cut

sub output {
    my ($self) = @_;
    return @{$self->{'_fplist'}};
}


    
1;


