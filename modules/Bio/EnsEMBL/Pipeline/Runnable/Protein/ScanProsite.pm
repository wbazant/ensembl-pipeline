
#
# Ensembl module for ScanProsite
#
# Cared for by Emmanuel Mongin <mongin@ebi.ac.uk>
#
# Copyright Emmanuel Mongin
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Profile - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::Pipeline::Runnable::Protein::ScanProsite;
use vars qw(@ISA);
use strict;

# Object preamble - inheriets from Bio::Root::Object

use Bio::Root::Object;


@ISA = qw(Bio::Root::Object);

use Bio::EnsEMBL::Pipeline::RunnableI;
use Bio::EnsEMBL::SeqFeature;
use Bio::EnsEMBL::FeaturePair;
use Bio::EnsEMBL::Analysis;
use Bio::Seq;
use Bio::SeqIO;
use Bio::EnsEMBL::Root;

@ISA = qw(Bio::EnsEMBL::Pipeline::RunnableI);



=head2 new

    Title   :   new
    Usage   :   my obj =  Bio::EnsEMBL::Pipeline::Runnable::CPG->new (-QUERY => $seq);
    Function:   Initialises CPG object
    Returns :   a CPG Object
    Args    :   A Bio::Seq object (-QUERY), any arguments (-LENGTH, -GC, -OE) 

=cut

sub new {
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);    
    
    $self->{'_flist'}     = [];    # an array of Bio::SeqFeatures
    $self->{'_sequence'}  = undef; # location of Bio::Seq object
    $self->{'_workdir'}   = undef; # location of temp directory
    $self->{'_filename'}  = undef; # file to store Bio::Seq object
    $self->{'_results'}   = undef; # file to store results of ScanProsite
    $self->{'_threshold'} = undef; # Value of the threshod
    $self->{'_parameters'}= undef;
    $self->{'_protected'} = [];    # a list of files protected from deletion ???
    
  
    my ($query, $analysis, $parameters) = $self->_rearrange([qw(QUERY 
								ANALYSIS
								PARAMETERS)], 
					       @args);
  
    $self->query ($query) if ($query);       
    $self->analysis ($analysis) if ($analysis);

    if ($parameters) {
        $self->parameters($parameters);
    }

    print STDERR "PAR: ".$self->parameters."\n";
        
    return $self; # success - we hope!
}

######
#Get set methods
######

=head2 query

 Title   : query
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub query{
    my ($self, $seq) = @_;
    if ($seq) {
	eval {
	    $seq->isa ("Bio::PrimarySeqI") || $seq->isa ("Bio::SeqI")
	    };
	
	if (!$@) {
	    $self->{'_sequence'} = $seq ;
	    $self->filename ("query.$$.seq");
	    $self->results ($self->filename.".out");
	}
	else {
	    print STDERR "WARNING: The input_id is not a Seq object but if its a peptide fasta file, it should go fine\n";
	    $self->{'_sequence'} = $seq ;
	    $self->filename ("$$.tmp.seq");
	    
	    $self->results ("scanprosite.$$.out");
	    
	}
    }
    return $self->{'_sequence'};
}


=head2 analysis

 Title   : analysis
 Usage   : $obj->analysis($newval)
 Function: 
 Returns : value of analysis
 Args    : newvalue (optional)


=cut

sub analysis{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'analysis'} = $value;
    }
    return $obj->{'analysis'};

}


###########
# Analysis methods
##########

=head2 run

    Title   :  run
    Usage   :   $obj->run()
    Function:   Runs blast and BPLite and creates array of feature pairs
    Returns :   none
    Args    :   none

=cut

sub run {
 my ($self, $dir) = @_;

    # check query
    my $seq = $self->query || $self->throw("Query required for Program");

    # set directory if provided
    $self->workdir ('/tmp') unless ($self->workdir($dir));
    $self->checkdir;

    # reset filename and results as necessary (adding the directory path)
    my $tmp = $self->workdir;
    my $input = $tmp."/".$self->filename;
    $self->filename ($input);
    $tmp .= "/".$self->results;
    $self->results ($tmp);


 eval {
	$seq->isa ("Bio::PrimarySeqI") || $seq->isa ("Bio::SeqI")
	};
	

    if (!$@) {
	#The inputId is a sequence file...got the normal way...

	# write sequence to file
	$self->writefile;        

	# run program
	$self->run_analysis;

	# parse output
	$self->parse_results;
	$self->deletefiles;
    }
    else {
	#The query object is not a seq object but a file.
	#Perhaps should check here or before if this file is fasta format...if not die
	#Here the file does not need to be created or deleted. Its already written and may be used by other runnables.

	$self->filename($self->query);

	# run program
	$self->run_analysis;

	# parse output
	$self->parse_results;
    }
}

=head2 run_analysis

    Title   :   run_analysis
    Usage   :   $obj->run_analysis
    Function:   Runs the blast query
    Returns :   nothing
    Args    :   none

=cut

sub run_analysis {
    my ($self) = @_;

    my $run = "/usr/local/bin/perl ".$self->analysis->program . 
	' -pattern ' .$self->analysis->db_file. 
	    ' -confirm  /acari/analysis/iprscan/data/confirm.patterns' .$self->parameters.' '.
		$self->filename . ' > ' .$self->results;

    print STDERR "RUNNING: $run\n";
    
    $self->throw("Failed during ScanProsite run $!\n")
	
	unless (system ($run) == 0) ;
}



=head2 parse_results

    Title   :  parse_results
    Usage   :   $obj->parse_results($filename)
    Function:   Parses cpg output to give a set of features
                parsefile can accept filenames, filehandles or pipes (\*STDIN)
    Returns :   none
    Args    :   optional filename

=cut
sub parse_results {
    my ($self) = @_;
    
    my $filehandle;
    my $resfile = $self->results();
    
    if (-e $resfile) {
        
        if (-z $self->results) {  
            print STDERR "pfscan didn't find any hits\n";
            return; }       
        else {
            open (CPGOUT, "<$resfile") or $self->throw("Error opening ", $resfile, " \n");#
            }
    }
    my %printsac;
    my $line;
    
    my @features;
    while (<CPGOUT>) {
        $line = $_;
        chomp $line;
        print STDERR "$line\n";
        my ($id,$hid,$name,$from,$to,$confirmed) = split (/\|/,$line);


        if ($hid) {
            my $feat = "$hid,$from,$to,$confirmed,$id";
            
            push (@features,$feat);
        }
    }
                
    foreach my $feats (@features) {
        $self->create_feature($feats);
        print STDERR "$feats\n";
    }
    @features = 0;
}


##############
# input/output methods
#############

=head2 output

    Title   :   output
    Usage   :   obj->output()
    Function:   Returns an array of features
    Returns :   Returns an array of features
    Args    :   none

=cut

sub output {
    my ($self) = @_;
    return @{$self->{'_flist'}};
}

=head2 create_feature

    Title   :   create_feature
    Usage   :   obj->create_feature($feature)
    Function:   Returns an array of features
    Returns :   Returns an array of features
    Args    :   none

=cut
sub create_feature {
    my ($self, $feat) = @_;
    
    #create analysis object
    my $analysis_obj = $self->analysis;
        
    
    my @f = split (/,/,$feat);

#Here the score is either the match has been confirmed by emotif patterns or not. If the match has been confirmed: score = 1 if not score = 0    
    my $score = $f[3];
    if ($score eq "?") {
        $score = 0;
    }
    else {
	$score = 1;
    }

    my $feat1 = new Bio::EnsEMBL::SeqFeature ( -start => $f[1],                   
                                               -end => $f[2],        
                                               -score => $score,
                                               -analysis => $analysis_obj,
                                               -seqname => $f[4],
					       -percent_id => 0,
					       -p_value => 0,
					       );
    
    my $feat2 = new Bio::EnsEMBL::SeqFeature (-start => 0,
                                              -end => 0,
                                              -analysis => $analysis_obj,
                                              -seqname => $f[0]);
    
    
    my $feature = new Bio::EnsEMBL::FeaturePair(-feature1 => $feat1,
                                                -feature2 => $feat2);
    
    if ($feature)
    {
        push(@{$self->{'_flist'}}, $feature);
    }
}

=head2 parameters

 Title   : parameters
 Usage   : $obj->parameters($newval)
 Function: 
 Returns : value of parameters
 Args    : newvalue (optional)


=cut

sub parameters{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'parameters'} = $value;
    }
    return $obj->{'parameters'};

}
