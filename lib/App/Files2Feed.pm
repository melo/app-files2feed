package App::Files2Feed;

use Moose;
use MooseX::Types::Path::Class;
with 'App::Files2Feed::ConfigRole', 'MooseX::Getopt';

use File::Find  ();
use Path::Class ();


##################################

has 'format' => (
  is            => 'ro',
  isa           => 'Str',
  default       => 'Atom',
  documentation => 'Feed format, one of Atom or RSS'
);

has 'exclude' => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

has 'skip_directories' => (
  isa           => 'Bool',
  is            => 'ro',
  default       => 1,
  documentation => 'if true (the default), directories will not be included',
);

has 'dir' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has 'base_url' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has 'title' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has 'homepage' => (
  isa => 'Str',
  is  => 'ro',
);

has 'feed_url' => (
  isa => 'Str',
  is  => 'ro',
);

has 'author' => (
  isa => 'Str',
  is  => 'ro',
);

has 'tagline' => (
  isa => 'Str',
  is  => 'ro',
);

has 'description' => (
  isa => 'Str',
  is  => 'ro',
);

has 'limit' => (
  isa      => 'Int',
  is       => 'ro',
  required => 1,
  default  => 50,
);

has 'files' => (
  metaclass  => 'NoGetopt',
  isa        => 'HashRef',
  is         => 'ro',
  lazy_build => 1,
);

sub _build_files { {} }


##################################

sub run {
  my ($self) = @_;

  $self->find_files;
  $self->generate_feed;
}

sub find_files {
  my ($self) = @_;

  $self->clear_files;
  File::Find::find(
    { wanted   => sub { $self->_process_file(@_) },
      follow   => 1,
      no_chdir => 1,
    },
    $self->dir
  );
}

sub generate_feed {
}


##################################

sub _process_file {
  my ($self) = @_;
  my $file = -d $_ ? Path::Class::dir($_) : Path::Class::file($_);

  return if $file->is_dir && $self->skip_directories;

  $self->files->{"$file"} = $file;
}

1;
