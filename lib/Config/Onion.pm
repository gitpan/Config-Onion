package Config::Onion;

use strict;
use warnings;

our $VERSION = 1.000;

use Config::Any;
use Hash::Merge::Simple 'merge';
use Moo;

has cfg => ( is => 'lazy', clearer => '_reset_cfg' );
sub get { goto &cfg }

has [qw( default main local override )]
  => ( is => 'rwp', default => sub { {} } );

sub set_default {
  my $self = shift;
  $self = $self->new unless ref $self;

  my $default = $self->default;
  $default = merge $default, shift while ref $_[0] eq 'HASH';
  $default = merge $default, { @_ } if @_;

  $self->_set_default($default);
  $self->_reset_cfg;
  return $self;
}

sub set_override {
  my $self = shift;
  $self = $self->new unless ref $self;

  my $override = $self->override;
  $override = merge $override, shift while ref $_[0] eq 'HASH';
  $override = merge $override, { @_ } if @_;

  $self->_set_override($override);
  $self->_reset_cfg;
  return $self;
}

sub load {
  my $self = shift;
  $self = $self->new unless ref $self;

  my %ca_opts = $self->_ca_opts;
  my $main  = Config::Any->load_stems({ stems => \@_ , %ca_opts });
  my $local = Config::Any->load_stems({ stems => [ map { "$_.local" } @_ ],
    %ca_opts });

  $self->_add_loaded($main, $local);
  return $self;
}

sub load_glob {
  my $self = shift;
  $self = $self->new unless ref $self;

  my (@main_files, @local_files);
  for my $globspec (@_) {
    for (glob $globspec) {
      if (/\.local\./) { push @local_files, $_ }
      else             { push @main_files,  $_ }
    }
  }

  my %ca_opts = $self->_ca_opts;
  my $main  = Config::Any->load_files({ files => \@main_files,  %ca_opts });
  my $local = Config::Any->load_files({ files => \@local_files, %ca_opts });

  $self->_add_loaded($main, $local);
  return $self;
}

sub _add_loaded {
  my $self = shift;
  my ($main, $local) = @_;

  $self->_set_main( merge $self->main,  map { values %$_ } @$main )
    if @$main;
  $self->_set_local(merge $self->local, map { values %$_ } @$local)
    if @$local;

  $self->_reset_cfg;
}

sub _build_cfg {
  my $self = shift;
  merge $self->default, $self->main, $self->local, $self->override;
}

sub _ca_opts { ( use_ext => 1 ) }

1;

=pod

=head1 NAME

Config::Onion - Layered configuration, because configs are like ogres

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  my $cfg = Config::Onion->new;
  my $cfg = Config::Onion->set_default(db => {name => 'foo', password => 'bar'});
  my $cfg = Config::Onion->load('/etc/myapp', './myapp');
  my $cfg = Config::Onion->load_glob('./plugins/*');

  $cfg->set_default(font => 'Comic Sans');
  $cfg->load('config');
  $cfg->load_glob('conf.d/myapp*');
  $cfg->set_override(font => 'Arial');

  my $dbname = $cfg->get->{db}{name};
  my $plain_hashref_conf = $cfg->get;
  my $dbpassword = $plain_hashref_conf->{db}{password};

=head1 DESCRIPTION

All too often, configuration is not a universal or one-time thing, yet most
configuration-handling treats it as such.  Perhaps you can only load one config
file.  If you can load more than one, you often have to load all of them at the
same time or each is stored completely independently, preventing one from being
able to override another.  Config::Onion changes that.

Config::Onion stores all configuration settings in four layers: Defaults,
Main, Local, and Override.  Each layer can be added to as many times as you
like.  Within each layer, settings which are given multiple times will take the
last specified value, while those which are not repeated will remain untouched.

  $cfg->set_default(name => 'Arthur Dent', location => 'Earth');
  $cfg->set_default(location => 'Magrathea');
  # In the Default layer, 'name' is still 'Arthur Dent', but 'location' has
  # been changed to 'Magrathea'.

Regardless of the order in which they are set, values in Main will always
override values in the Default layer, the Local layer always overrides both
Default and Main, and the Override layer overrides all the others.

The design intent for each layer is:

=over 4

=item * Default

Hardcoded default values to be used when no further configuration is present

=item * Main

Values loaded from standard configuration files shipped with the application

=item * Local

Values loaded from local configuration files which are kept separate to prevent
them from being overwritten by application upgrades, etc.

=item * Override

Settings provided at run-time which take precendence over all configuration
files, such as settings provided via command line switches

=head1 METHODS

=head2 new

Returns a new, empty configuration object.

=head2 load(@file_stems)

Loads files matching the given stems using C<< Config::Any->load_stems >> into
the Main layer.  Also concatenates ".local" to each stem and loads matching
files into the Local layer.  e.g., C<< $cfg->load('myapp') >> would load
C<myapp.yml> into Main and C<myapp.local.js> into Local.  All filename
extensions supported by C<Config::Any> are recognized along with their
corresponding formats.

=head2 load_glob(@globs)

Uses the Perl C<glob> function to expand each parameter into a list of
filenames and loads each file using C<Config::Any>.  Files whose names contain
the string ".local." are loaded into the Local layer.  All other files are
loaded into the Main layer.

=head2 set_default([\%settings,...,] %settings)

=head2 set_override([\%settings,...,] %settings)

Imports C<%settings> into the Default or Override layer.  Accepts settings both
as a plain hash and as hash references, but, if the two are mixed, all hash
references must appear at the beginning of the parameter list, before any
non-hashref settings.

=head1 PROPERTIES

=head2 cfg

=head2 get

Returns the complete configuration as a hash reference.

=head2 default

=head2 main

=head2 local

=head2 override

These properties each return a single layer of the configuration.  This is
not likely to be useful other than for debugging.  For most other purposes,
you probably want to use C<get> instead.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests at
L<https://github.com/dsheroh/Config-Onion/issues>

=head1 AUTHOR

Dave Sherohman <dsheroh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lund University Library.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Layered configuration, because configs are like ogres

