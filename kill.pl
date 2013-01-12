#!/usr/bin/env perl
#
use Smart::Comments;
use File::Temp qw { tempfile tempdir };

## %SIG

my @keys;

@keys = keys(%SIG);
@keys = sort(@keys);
foreach my $key (@keys) {
    #print "$key\n";
}

sub Install_IPC_Signal {                # {{{1


    my $Signal_Code = <<'EOSignal'; # {{{2
package IPC::Signal;

use 5.003_94;	# __PACKAGE__
use strict;
use vars	qw($VERSION @ISA @EXPORT_OK $AUTOLOAD %Sig_num @Sig_name);

require Exporter;

$VERSION	= '1.00';
@ISA		= qw(Exporter);
@EXPORT_OK	= qw(sig_num sig_name sig_translate_setup %Sig_num @Sig_name);
%Sig_num	= ();
@Sig_name	= ();

sub sig_num  ($);
sub sig_name ($);

sub sig_translate_setup () {
    return if %Sig_num && @Sig_name;

    require Config;

    # In 5.005 the sig_num entries are comma separated and there's a
    # trailing 0.
    my $num = $Config::Config{'sig_num'};
    if ($num =~ s/,//g) {
	$num =~ s/\s+0$//;
    }

    my @name	= split ' ', $Config::Config{'sig_name'};
    my @num	= split ' ', $num;

    @name			or die 'No signals defined';
    @name == @num		or die 'Signal name/number mismatch';

    @Sig_num{@name} = @num;
    keys %Sig_num == @name	or die 'Duplicate signal names present';
    for (@name) {
	$Sig_name[$Sig_num{$_}] = $_
	    unless defined $Sig_name[$Sig_num{$_}];
    }
}

# This autoload routine just is just for sig_num() and sig_name().  It
# calls sig_translate_setup() and then snaps the real function definitions
# into place.

sub AUTOLOAD {
    if ($AUTOLOAD ne __PACKAGE__ . '::sig_num'
	    && $AUTOLOAD ne __PACKAGE__ . '::sig_name') {
	require Carp;
	Carp::croak("Undefined subroutine &$AUTOLOAD called");
    }
    sig_translate_setup;
    *sig_num  = sub ($) { $Sig_num{$_[0]} };
    *sig_name = sub ($) { $Sig_name[$_[0]] };
    goto &$AUTOLOAD;
}

#1

#__END__
EOSignal
# 2}}}
    
    my $problems = 0;
    my $dir = tempdir( CLEANUP => 0 );  #
    print "Using temp dir [$dir] to install IPC::Signal.\n";

    mkdir "$dir/IPC";
    my $OUT = new IO::File "$dir/IPC/Signal.pm", "w";
    if (defined $OUT) {
       print $OUT $Signal_Code;
       $OUT->close;
    } else {
        warn "Failed to install IPC::Signal.pm.";
        $problems = 1;
    }

    push @INC, $dir;
    eval "use IPC::Signal qw /sig_translate_setup/";
}   # 1}}}

Install_IPC_Signal();
#use IPC::Signal;
IPC::Signal::sig_translate_setup();
### IPC::Signal::%Sig_num
### @Sig_name

#print &sig_name("HUP");

