package App::Files2Feed;

use Moose;
with 'App::Files2Feed::ConfigRole', 'MooseX::Getopt';

use File::Find           ();
use Path::Class          ();
use XML::Feed            ();
use XML::Feed::Enclosure ();
use DateTime             ();
use MIME::Types          ();
use FileHandle           ();


##################################

has '+configfile' => (default => './.files2feed');

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

has 'output' => (
  isa => 'Str',
  is  => 'ro',
);

has 'include' => (
  isa     => 'ArrayRef',
  is      => 'ro',
  default => sub { [] },
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
  isa      => 'Str',
  is       => 'ro',
  required => 1,
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

has mime_types => (
  isa        => 'MIME::Types',
  is         => 'ro',
  lazy_build => 1,
);

sub _build_mime_types { return MIME::Types->new }


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
  my ($self) = @_;

  my $feed = $self->_create_feed;

  my @files = $self->_sort_files;
  foreach my $file_info (@files) {
    $self->_add_file_to_feed($file_info, $feed);
  }

  if (my $file = $self->output) {
    my $tmp = Path::Class::file("$file.tmp");
    my $fh  = $tmp->openw;
    $fh->print($feed->as_xml);
    $fh->close;
    rename("$tmp", $file) || unlink("$tmp");
  }
  else {
    print $feed->as_xml;
  }
}


##################################

sub _process_file {
  my ($self) = @_;
  my $file = -d $_ ? Path::Class::dir($_) : Path::Class::file($_);
  my $modt = -M _;
  my $size = -s _;

  return if $file->is_dir && $self->skip_directories;

  my $selected;
  my $include = $self->include;
  if (@$include) {
    $selected = 0;

  RULE: foreach my $rule (@$include) {
      $selected = 1, last RULE if "$file" =~ m/$rule/;
    }
  }
  return if defined $selected && !$selected;

  my $exclude = $self->exclude;
  if (@$exclude) {
    $selected = 1;

  RULE: foreach my $rule (@$exclude) {
      $selected = 0, last RULE if "$file" =~ m/$rule/;
    }
  }
  return if defined $selected && !$selected;

  $self->files->{"$file"} = [$file, $modt, $size];
}

sub _sort_files {
  my ($self) = @_;
  my $files = $self->files;

  my @files = sort { $a->[1] <=> $b->[1] } values %$files;

  return splice(@files, 0, $self->limit);
}


##################################

sub _create_feed {
  my ($self) = @_;

  my $now = DateTime->now;

  my $feed = XML::Feed->new($self->format);
  $feed->title($self->title);
  $feed->id($self->homepage);
  $feed->link($self->homepage);
  $feed->self_link($self->feed_url)      if $self->feed_url;
  $feed->tagline($self->tagline)         if $self->tagline;
  $feed->description($self->description) if $self->description;
  $feed->author($self->author)           if $self->author;

  $feed->modified($now);
  $feed->generator("App::Files2Feed 0.1");

  return $feed;
}

sub _add_file_to_feed {
  my ($self, $file_info, $feed) = @_;
  my ($file, $modt,      $size) = @$file_info;

  my $m_epoch  = $^T - $modt * 86600;
  my $rel_file = $file->relative($self->dir);
  my $url      = $self->base_url . "/$rel_file";

  my $entry = XML::Feed::Entry->new($self->format);
  $entry->title($file->basename);
  $entry->author($self->author);
  $entry->link($url);
  $entry->id($url);

  $entry->issued(DateTime->from_epoch(epoch => $m_epoch)->set_time_zone('UTC'));
  $entry->modified(DateTime->from_epoch(epoch => $m_epoch)->set_time_zone('UTC'));

  my ($purl, $pname) = $url =~ m!^(.+/([^/]+)/)[^/]+$!;

  $entry->content(<<"  EOC");
  <p>Inside <a href="$purl">$pname</a>:</p>
  <dl>
    <dt>File</dt>
    <dd>$rel_file</dd>
    <dt>Size</dt>
    <dd>$size</dd>
  </dl>
  EOC

  my $enc = XML::Feed::Enclosure->new(
    { url    => $url,
      type   => $self->mime_types->mimeTypeOf("$file"),
      length => $size,
    }
  );
  $entry->enclosure($enc);

  $feed->add_entry($entry);
}

1;

__END__

=head1 NAME

App::Files2Feed - create a feed for a directory of files


=head1 SYNOPSIS

    # Check the files2feed script first
    
    use App::Files2Feed;
    
    my $f2f = App::Files2Feed->new({
    });


=head1 DESCRIPTION

...

=head1 API

...

=head2 new

    my $f2f = App::Files2Feed->new(\%options);

...


=head2 run

    $f2f->run;

...


=head2 find_files

    $f2f->find_files;

...


=head2 generate_feed

    $f2f->generate_feed;

...


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Melo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
