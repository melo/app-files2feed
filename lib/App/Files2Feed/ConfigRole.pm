package App::Files2Feed::ConfigRole;

use Moose::Role;
use Config::Any;
with 'MooseX::ConfigFromFile';

has '+configfile' => (default => './.files2feed');

sub get_config_from_file {
  my ($class, $file) = @_;

  my $files = Config::Any->load_files(
    {files => [$file], use_ext => 1, flatten_to_hash => 1});

  $files = Config::Any->load_stems(
    {stems => [$file], use_ext => 1, flatten_to_hash => 1})
    unless %$files;

  return unless %$files;
  return (values %$files)[0];
}

1;
