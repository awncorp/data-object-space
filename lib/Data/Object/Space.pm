package Data::Object::Space;

use 5.014;

use strict;
use warnings;
use routines;

use parent 'Data::Object::Name';

# VERSION

# METHODS

method append(@args) {
  my $class = $self->class;

  my $path = join '/',
    $self->path, map $class->new($_)->path, @args;

  return $class->new($path);
}

method array($name) {
  no strict 'refs';

  my $class = $self->package;

  return [@{"${class}::${name}"}];
}

method arrays() {
  no strict 'refs';

  my $class = $self->package;

  my $arrays = [
    sort grep !!@{"${class}::$_"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];

  return $arrays;
}

method base() {

  return $self->parse->[-1];
}

method bless($data = {}) {
  my $class = $self->load;

  return CORE::bless $data, $class;
}

method build(@args) {
  my $class = $self->load;

  return $self->call('new', $class, @args);
}

method call($func, @args) {
  my $class = $self->load;

  unless ($func) {
    require Carp;

    my $text = qq[Attempt to call undefined object method in package "$class"];

    Carp::confess $text;
  }

  my $next = $class->can($func);

  unless ($next) {
    require Carp;

    my $text = qq[Unable to locate object method "$func" via package "$class"];

    Carp::confess $text;
  }

  @_ = @args; goto $next;
}

method child(@args) {

  return $self->append(@args);
}

method children() {
  my %list;
  my $path;
  my $type;

  $path = quotemeta $self->path;
  $type = 'pm';

  my $regexp = qr/$path\/[^\/]+\.$type/;

  for my $item (keys %INC) {
    $list{$item}++ if $item =~ /$regexp$/;
  }

  my %seen;

  for my $dir (@INC) {
    next if $seen{$dir}++;

    my $re = quotemeta $dir;
    map { s/^$re\///; $list{$_}++ }
    grep !$list{$_}, glob "$dir/@{[$self->path]}/*.$type";
  }

  my $class = $self->class;

  return [
    map $class->new($_),
    map {s/(.*)\.$type$/$1/r}
    sort keys %list
  ];
}

method class() {

  return ref $self;
}

method cop($func, @args) {
  my $class = $self->load;

  unless ($func) {
    require Carp;

    my $text = qq[Attempt to cop undefined object method from package "$class"];

    Carp::confess $text;
  }

  my $next = $class->can($func);

  unless ($next) {
    require Carp;

    my $text = qq[Unable to locate object method "$func" via package "$class"];

    Carp::confess $text;
  }

  return sub { $next->(@args ? (@args, @_) : @_) };
}

method functions() {
  my @functions;

  no strict 'refs';

  require Function::Parameters::Info;

  my $class = $self->package;
  for my $routine (@{$self->routines}) {
    my $code = $class->can($routine) or next;
    my $data = Function::Parameters::info($code);

    push @functions, $routine if $data && !$data->invocant;
  }

  return [sort @functions];
}

method hash($name) {
  no strict 'refs';

  my $class = $self->package;

  return {%{"${class}::${name}"}};
}

method hashes() {
  no strict 'refs';

  my $class = $self->package;

  return [
    sort grep !!%{"${class}::$_"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];
}

method id() {

  return $self->label;
}

method inherits() {

  return $self->array('ISA');
}

method inc() {

  return $INC{$self->format('path', '%s.pm')};
}

my $loaded_spaces = {};

method load() {
  my $class = $self->package;

  return $class if $loaded_spaces->{$class};

  my $failed = !$class || $class !~ /^\w(?:[\w:']*\w)?$/;
  my $loaded;

  my $error = do {
    local $@;
    no strict 'refs';
    $loaded = !!$class->can('new');
    $loaded = !!$class->can('import') if !$loaded;
    $loaded = !!$class->can('meta') if !$loaded;
    $loaded = !!$class->can('with') if !$loaded;
    $loaded = eval "require $class; 1" if !$loaded;
    $@;
  }
  if !$failed;

  do {
    require Carp;

    my $message = $error || "cause unknown";

    Carp::confess "Error attempting to load $class: $message";
  }
  if $error
  or $failed
  or not $loaded;

  $loaded_spaces->{$class} = 1;

  return $class;
}

method methods() {
  my @methods;

  no strict 'refs';

  require Function::Parameters::Info;

  my $class = $self->package;
  for my $routine (@{$self->routines}) {
    my $code = $class->can($routine) or next;
    my $data = Function::Parameters::info($code);

    push @methods, $routine if $data && $data->invocant;
  }

  return [sort @methods];
}

method name() {

  return $self->package;
}

method parent() {
  my @parts = @{$self->parse};

  pop @parts if @parts > 1;

  my $class = $self->class;

  return $class->new(join '/', @parts);
}

method parse() {

  return [
    map ucfirst,
    map join('', map(ucfirst, split /[-_]/)),
    split /[^-_a-zA-Z0-9.]+/,
    $self->path
  ];
}

method parts() {

  return $self->parse;
}

method prepend(@args) {
  my $class = $self->class;

  my $path = join '/',
    (map $class->new($_)->path, @args), $self->path;

  return $class->new($path);
}

method root() {

  return $self->parse->[0];
}

method routine($name) {
  no strict 'refs';

  my $class = $self->package;

  return *{"${class}::${name}"}{"CODE"};
}

method routines() {
  no strict 'refs';

  my $class = $self->package;

  return [
    sort grep *{"${class}::$_"}{"CODE"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];
}

method scalar($name) {
  no strict 'refs';

  my $class = $self->package;

  return ${"${class}::${name}"};
}

method scalars() {
  no strict 'refs';

  my $class = $self->package;

  return [
    sort grep defined ${"${class}::$_"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];
}

method sibling(@args) {

  return $self->parent->append(@args);
}

method siblings() {
  my %list;
  my $path;
  my $type;

  $path = quotemeta $self->parent->path;
  $type = 'pm';

  my $regexp = qr/$path\/[^\/]+\.$type/;

  for my $item (keys %INC) {
    $list{$item}++ if $item =~ /$regexp$/;
  }

  my %seen;

  for my $dir (@INC) {
    next if $seen{$dir}++;

    my $re = quotemeta $dir;
    map { s/^$re\///; $list{$_}++ }
    grep !$list{$_}, glob "$dir/@{[$self->path]}/*.$type";
  }

  my $class = $self->class;

  return [
    map $class->new($_),
    map {s/(.*)\.$type$/$1/r}
    sort keys %list
  ];
}

method used() {
  my $class = $self->package;
  my $loaded = $loaded_spaces->{$class};
  my $path = $self->path;
  my $regexp = quotemeta $path;

  if ($loaded) {

    return $path;
  }
  for my $item (keys %INC) {

    return $path if $item =~ /$regexp\.pm$/;
  }

  return '';
}

method variables() {

  return [map [$_, [sort @{$self->$_}]], qw(arrays hashes scalars)];
}

method version() {

  return $self->scalar('VERSION');
}

1;