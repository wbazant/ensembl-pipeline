#
# Object for storing details of a job on the LSF queue
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

Bio::EnsEMBL::Pipeline::LSFJob

=head1 SYNOPSIS

=head1 DESCRIPTION

Stores details of a job on the LSF queue

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::EnsEMBL::Pipeline::LSFJob;

use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI;
use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);

sub _initialize {
    my ($self,@args) = @_;

    my $make = $self->SUPER::_initialize;

    my ($id,$user,$status,$queue,$from_host,$exec_host,$job_name,$submission_time) = 
	$self->_rearrange([qw(ID
			      USER
			      STATUS
			      QUEUE
			      FROM_HOST
			      EXEC_HOST
			      JOB_NAME
			      SUBMISSION_TIME
			      )],@args);
    $self->id             ($id);
    $self->user           ($user);
    $self->status         ($status);
    $self->queue          ($queue);
    $self->from_host      ($from_host);
    $self->exec_host      ($exec_host);
    $self->job_name       ($job_name);
    $self->submission_time($submission_time);
    
    return $make; # success - we hope!
}

=head2 id

  Title   : id
  Usage   : $self->id($id)
  Function: Get/set method for the id of the job itself
            This will usually be generated by the
            back end database the jobs are stored in
  Returns : int
  Args    : int

=cut


sub id {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_id} = $arg;
    }
    return $self->{_id};

}


=head2 user

  Title   : user
    Usage   : $self->user($user);
  Function: Get/set method for the owner of the job itself
  Returns : string
  Args    : string

=cut


sub user {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_user} = $arg;
    }
    return $self->{_user};

}


=head2 status

  Title   : status
    Usage   : $self->status;
  Function: Get/set method for the status of the job
  Returns : string
  Args    : string

=cut


sub status {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_status} = $arg;
    }
    return $self->{_status};

}

=head2 queue

  Title   : queue
    Usage   : $self->queue
  Function: Get/set method for the job queue
  Returns : string
  Args    : string

=cut


sub queue {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_queue} = $arg;
    }
    return $self->{_queue};

}

=head2 from_host

  Title   : from_host
  Usage   : $self->from_host
  Function: Get/set method for the host the job
            was submitted from
  Returns : string
  Args    : string

=cut


sub from_host {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_from_host} = $arg;
    }
    return $self->{_from_host};

}

=head2 exec_host

  Title   : exec_host
    Usage   : $self->exec_host
  Function: Get/set method for the host the
            job is running on
  Returns : string
  Args    : string

=cut


sub exec_host {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_exec_host} = $arg;
    }
    return $self->{_exec_host};

}


=head2 job_name

  Title   : job_name
  Usage   : $self->job_name
  Function: Get/set method for the name of the job
  Returns : string
  Args    : string

=cut


sub job_name {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_job_name} = $arg;
    }
    return $self->{_job_name};

}

=head2 submission_time

  Title   : submission_time
    Usage   : $self->submission_time
  Function: Get/set method for the submission time
            of the job
  Returns : string
  Args    : string

=cut


sub submission_time {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_submission_time} = $arg;
    }
    return $self->{_submission_time};

}


sub submit {
    my ($self,$cmd) = @_;

    open (SUB,"$cmd |");

    my $lsfid = 0;

    while (<SUB>) {
	if (/Job <(\d+)>/) {
	    $lsfid = $1;
	    $self->id($lsfid);
	    print (STDERR $_);
	}
    }
		   
    close(SUB);

}


sub print {
    my ($self,$arg) = @_;

    if ($arg eq "l") {
	print("\n");
	$self->print_var("ID"               , $self->id                     );
	$self->print_var("From_machine"     , $self->from_host           );
	$self->print_var("Exec_machine"     , $self->exec_host           );
	$self->print_var("Queue"            , $self->queue                  );
	$self->print_var("Status"          , $self->status     );
	$self->print_var("User"          , $self->user      );
	$self->print_var("Submission time"  , $self->submission_time );
	$self->print_var("Job name"     , $self->job_name ); 
    } else {
	printf("%8d %15s %15s %15s %10s %10s %20s\n",$self->id,
	       $self->from_host,
	       $self->exec_host,
	       $self->queue,
	       $self->status,
	       $self->user,
	       $self->submission_time
	       );
    }
}

sub print_var {
    my ($self,$str,$var) = @_;
    printf("%20s %20s\n",$str,$var);
}

1;

