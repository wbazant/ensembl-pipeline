use strict;
use warnings;
package Bio::EnsEMBL::Pipeline::Task::RDB;

use vars qw(@ISA);

use Bio::EnsEMBL::Pipeline::Task;
use Bio::EnsEMBL::DBSQL::DBAdaptor;


@ISA = ('Bio::EnsEMBL::Pipeline::Task');


#the new is used from the base class as this constructor wouldn't need
#to do any additional work


=head2 logic_name

  Arg [1]   : none
  Function  : returns a string which is the logic_name of a particular
  analysis
  Returntype: string 
  Exceptions: This method will throw as it is an abstract method but
  sub classes should implement this method and as such shouldn't throw'
  Caller    : 
  Example   : my $logic_name = $self->logic_name

=cut


sub logic_name{
  my ($self) = @_;

  $self->throw("logic_name should be implemented by subclass $!");
}


=head2 parameter_string

  Arg [1]   : none
  Function  : returns a string which contains information about
  database connection and analysis type required by RunnableDBs
  Returntype: string
  Exceptions: throws if PipelineManager has no config object
  Caller    : 
  Example   : my $parameters = $self->parameter_string

=cut


sub parameter_string{
  my ($self) = @_;


  if(!$self->{'parameter_string'}){
    my $config = $self->get_Config;

    if(!$config){
      $self->throw("PipelineManager ".$self->get_PipelineManager.
                   " seems to be missing its config $!");
    }

    my $dbhost = $config->get_parameter('ensembl_database', 'host');
    my $dbuser = $config->get_parameter('ensembl_database', 'user');
    my $dbpass = $config->get_parameter('ensembl_database', 'pass');
    my $dbname = $config->get_parameter('ensembl_database', 'dbname');
    my $dbport = $config->get_parameter('ensembl_database', 'port');
    my $logic_name = $self->logic_name;

    my $string = "$dbhost:$dbport:$dbuser:$dbpass:$dbname:$logic_name";
    $self->{'parameter_string'} = $string;
    return $self->{'parameter_string'};
  }

  return $self->{'parameter_string'};
}


=head2 db

  Arg [1]   : none
  Function  : instantiates a core dbadaptor and returns it
  Returntype: Bio::EnsEMBL::DBSQL::DBAdaptor
  Exceptions: throws if the PipelineManager has no config object
  Caller    : 
  Example   : my $db = $self->db;

=cut

sub db{
  my ($self) = @_;

  if(!$self->{'core_db'}){
    my $config = $self->get_Config;
    
    if(!$config){
      $self->throw("PipelineManager ".$self->get_PipelineManager.
		   " seems to be missing its config $!");
    }

    my $dbhost = $config->get_parameter('ensembl_database', 'host');
    my $dbuser = $config->get_parameter('ensembl_database', 'user');
    my $dbpass = $config->get_parameter('ensembl_database', 'pass');
    my $dbname = $config->get_parameter('ensembl_database', 'dbname');
    my $dbport = $config->get_parameter('ensembl_database', 'port');
    
    my $dbadaptor = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
							-dbname => $dbname,
							-host => $dbhost,
							-user => $dbuser,
							-pass => $dbpass,
							-port => $dbport
						       );

    $self->{'core_db'} = $dbadaptor;
  }

  return $self->{'core_db'};
}


=head2 max_create

  Arg [1]   : none
  Function  : returns a number which represents the maximum number of ids
  a Task should submit at once
  Returntype: integer
  Exceptions: none
  Caller    : 
  Example   : my $id_set = $potential->not($existing)->subset($self->max_create); 

=cut


sub max_create{
  my ($self) = @_;

  if(!$self->{'max_create'}){
    my $config = $self->get_Config;
    my $max_create = $config->get_parameter($self->name, 'max_create');
    $self->{'max_create'} = $max_create;
  }
  return $self->{'max_create'};
}

sub get_Config{
  my ($self) = @_;
  if(!$self->{'config'}){
    $self->{'config'} = $self->get_PipelineManager->get_Config;
  }

  return $self->{'config'};
}

1;
