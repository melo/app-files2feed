package App::Files2Feed;

use Moose;
use MooseX::Types::Path::Class;
with 'App::Files2Feed::ConfigRole', 'MooseX::Getopt';

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


1;
