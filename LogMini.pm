package LogMini;
#
# Author: soarpenguin <soarpenguin@gmail.com>
# First release Mar.29 2014
##################################################
# usage of LogMini.pm, add code like:
#   use lib "path"; #path is the file of LogMini.pm
#   use LogMini;
#
#   LogMini log libirary for perl.
##################################################
use strict;
use warnings;
use Term::ANSIColor qw//;
use Data::Dumper;
$| = 1;

BEGIN {
    use Exporter();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
    $VERSION = 0.0.1;
    @ISA = qw(Exporter);
    @EXPORT = map { ("log_" . $_) } qw/crit critf warn warnf info infof debug debugf croak croakf/;
    push @EXPORT, 'ddf';
}

sub __FUNC__ { (caller(0))[3] }

#[2014.3.29 21:7:37][Trace][[Notice][main::usage()]][test.pl:13]teesssss
our $PRINT = sub {
    my ( $time, $type, $message, $trace, $raw_message) = @_;
    warn "[$time][$type][$trace]$message\n";
};

our $DIE = sub {
    my ( $time, $type, $message, $trace, $raw_message) = @_;
    die "[$time][$type][$trace]$message\n";
};

our $DEFAULT_COLOR = {
    info  => {
        text => 'green',
    },
    debug => {
        text       => 'red',
        background => 'white',
    },
    'warn' => {
        text       => 'black',
        background => 'yellow',
    },
    'critical' => {
        text       => 'black',
        background => 'red'
    },
    'error' => {
        text       => 'red',
        background => 'black'
    }
};

if ($ENV{LM_DEFAULT_COLOR}) {
    # LEVEL=FG;BG:LEVEL=FG;BG:...
    for my $level_color (split /:/, $ENV{LM_DEFAULT_COLOR}) {
        my($level, $color) = split /=/, $level_color, 2;
        my($fg, $bg)       = split /;/, $color, 2;
        $LogMini::DEFAULT_COLOR->{$level} = {
            $fg ? (text       => $fg) : (),
            $bg ? (background => $bg) : (),
        };
    }
}

our $ENV_DEBUG = "LM_DEBUG";
our $AUTODUMP = 0;
our $LOG_LEVEL = 'DEBUG';
our $TRACE_LEVEL = 0;
#our $COLOR = $ENV{LM_COLOR} || 0;
our $COLOR = 1;
our $ESCAPE_WHITESPACE = 1;

my %log_level_map = (
    DEBUG    => 1,
    INFO     => 2,
    WARN     => 3,
    CRITICAL => 4,
    MUTE     => 0,
    ERROR    => 99,
);

sub import {
    my $class   = shift;
    my $package = caller(0);
    my @args = @_;

    my %want_export;
    my $env_debug;
    while ( my $arg = shift @args ) {
        if ( $arg eq 'env_debug' ) {
            $env_debug = shift @args;
        } else {
            $want_export{$arg} = 1;
        }
    }

    if ( ! keys %want_export ) {
        #all
        $want_export{$_} = 1 for @EXPORT;
    }

    no strict 'refs';
    for my $f (grep !/^debug/, @EXPORT) {
        if ( $want_export{$f} ) {
            *{"$package\::$f"} = \&$f;
        }
    }

    for my $f (map { ($_ . 'f', $_ . 'ff') } qw/debug/) {
        if ( $want_export{$f} ) {
            if ( $env_debug ) {
                *{"$package\::$f"} = sub {
                    local $TRACE_LEVEL = $TRACE_LEVEL + 1;
                    local $ENV_DEBUG   = $env_debug;
                    $f->(@_);
                };
            } else {
                *{"$package\::$f"} = \&$f;
            }
        }
    }

}

sub log_crit {
    print_log( "CRITICAL", 0, @_ );
}

sub log_warn {
    print_log( "WARN", 0, @_ );
}

sub log_info {
    print_log( "INFO", 0, @_ );
}

sub log_debug {
    return if !$ENV{$ENV_DEBUG} || $log_level_map{DEBUG} < $log_level_map{uc $LOG_LEVEL};
    print_log( "DEBUG", 0, @_ );
}

sub log_critf {
    print_log( "CRITICAL", 1, @_ );
}

sub log_warnf {
    print_log( "WARN", 1, @_ );
}

sub log_infof {
    print_log( "INFO", 1, @_ );
}

sub log_debugf {
    return if !$ENV{$ENV_DEBUG} || $log_level_map{DEBUG} < $log_level_map{uc $LOG_LEVEL};

    print_log( "DEBUG", 1, @_ );
}

sub log_croak {
    local $PRINT = $DIE;
    local $LOG_LEVEL = 'DEBUG';

    print_log( "ERROR", 0, @_ );
}

sub log_croakf {
    local $PRINT = $DIE;
    local $LOG_LEVEL = 'DEBUG';

    print_log( "ERROR", 1, @_ );
}

sub print_log {
    my $tag = shift;
    my $full = shift;

    my $_log_level = $log_level_map{uc $LOG_LEVEL} || return;
    return unless $log_level_map{$tag} >= $_log_level;

    my $time = &get_now_time();

    my $trace;
    if ( $full ) {
        my $i = $TRACE_LEVEL + 1;
        my @stack;
        while ( my @caller = caller($i) ) {
            #($package, $filename, $line $subroutine) = caller;
            push @stack, $caller[1] . ":" . $caller[2];
            $i++;
        }
        $trace = join " ,", @stack;
    } else {
        my @caller = caller($TRACE_LEVEL + 1);
        #($package, $filename, $line, $subroutine) = caller;
        $trace = $caller[1] . ":" . $caller[2];
    }

    my $messages = '';
    if ( @_ == 1 && defined $_[0]) {
        $messages = $AUTODUMP ? '' . LogMini::Dumper->new($_[0]) : $_[0];
    } elsif ( @_ >= 2 )  {
        $messages = sprintf(shift, map { $AUTODUMP ? LogMini::Dumper->new($_) : $_ } @_);
    }

    if ($ESCAPE_WHITESPACE) {
        $messages =~ s/\x0d/\\r/g;
        $messages =~ s/\x0a/\\n/g;
        $messages =~ s/\x09/\\t/g;
    }

    my $raw_message = $messages;
    if ( $COLOR ) {
        $messages = Term::ANSIColor::color($DEFAULT_COLOR->{lc($tag)}->{text})
            . $messages . Term::ANSIColor::color("reset")
                if $DEFAULT_COLOR->{lc($tag)}->{text};
        $messages = Term::ANSIColor::color("on_" . $DEFAULT_COLOR->{lc($tag)}->{background})
            . $messages . Term::ANSIColor::color("reset")
                if $DEFAULT_COLOR->{lc($tag)}->{background};
    }

    $PRINT->(
        $time,
        $tag,
        $messages,
        $trace,
        $raw_message
    );
}

sub ddf {
    my $value = shift;
    LogMini::Dumper::dumper($value);
}

sub get_now_time {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    my $now_time = sprintf("%d.%d.%d %02d:%02d:%02d",
                            $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

    return "$now_time";
}
1;

#####################################################################
package LogMini::Dumper;

use strict;
use warnings;
use base qw/Exporter/;
use Data::Dumper;
use Scalar::Util qw/blessed/;

use overload
    '""' => \&stringfy,
    '0+' => \&numeric,
    fallback => 1;

sub new {
    my ($class, $value) = @_;
    bless \$value, $class;
}

sub stringfy {
    my $self = shift;
    my $value = $$self;

    if ( blessed($value) && (my $stringify = overload::Method( $value, '""' )
         || overload::Method( $value, '0+' )) ) {
        $value = $stringify->($value);
    }
    dumper($value);
}

sub numeric {
    my $self = shift;
    my $value = $$self;

    if ( blessed($value) && (my $numeric = overload::Method( $value, '0+' )
         || overload::Method( $value, '""' )) ) {
        $value = $numeric->($value);
    }
    $value;
}

sub dumper {
    my $value = shift;

    if ( defined $value && ref($value) ) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Sortkeys = 1;
        $value = Data::Dumper::Dumper($value);
    }
    $value;
}

1;
__END__

