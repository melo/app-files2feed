package App::Files2Feed::ConfigRole;

use Moose::Role;
use Config::Any;
with 'MooseX::ConfigFromFile';

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

__END__

=head1 NAME

App::Files2Feed::ConfigRole - A role for loading configuration from a file


=head1 SYNOPSIS

    # Internal module, not for direct use


=head1 DESCRIPTION

...

=head1 API

...

=head2 get_config_from_file

...


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Melo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
