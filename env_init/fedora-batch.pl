#!/usr/bin/env perl
#

# fedora-batch.pl -- batch command for install softwares. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Jan.13 2011
# 1}}}

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
#use Smart::Comments;
use File::Spec::Functions;
use POSIX qw(strftime);
use Cwd;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $script = basename $0;
my $myversion = '0.2.0';

# usage string.
my $usage = "
Usage: $script [option...] file

       -c <cmd>, --command <cmd>
            The command for install software. 
            such as: yum, apt-get, aptitude 

       -f <file>, --file <file>
            File contains the softwares need to be installed. 
            One software a line. like: 
                gvim
                git

       -r <line1,line2>, --range <line1,line2>
            Set the range for install software in softlist.
            From (line1 to line2).

       -h, --help 
            Display this help and exit

       -l <file>, --list <file> 
            Display the file content of software list.

       -V,  --version  
            output version information and exit
";

# check for platform.
if ($^O ne 'linux') {
    die "Only linux is supported but I am on $^O.\n";
}

my ($file, $command, $ret, $list, $range); 
# command option resolving.
$ret = GetOptions( 
    'command|c=s' => \$command,
    'file|f=s'  => \$file,
    'help|h'	=> \&usage,
    'list|l=s'  => \$list,
    'range|r=s' => \$range,
    'version|V' => \&version
);

# check command resolving correctly.
if(! $ret) {
    &usage();
}

# set the range
my ($n1, $n2);
if($range) {
    ($n1, $n2) = split(",", $range);
    if($n1 and $n1 =~ /^\d+$/g) {
        if($n2 and $n2 =~ /^\d+$/g) {
            if($n2 < $n1) {
                my $tmp = $n1;
                $n1 = $n2;
                $n2 = $tmp;
            }
            print "The range your set is: $n1 ~ $n2.\n";
        } else {
            print "Skip the range your set, check the range valid!\n";
            $range = undef;
        }
    } else {
        print "Skip the range your set, check the range valid!\n";
        $range = undef;
    }
}

# list the software file.
if($list) {
    open(my $fd, "<", $list);
    if(!$fd) {
        print "Open the file $list failed!\n";
        exit;
    }
    print "The software list is:\n";
    while(my $l = <$fd>) {
        print $l
    }
    exit;
}

# set install command.
my @commands = ("yum", "apt-get", "aptitude");
my (@array, $found);

if(! $command) {
    foreach my $cmd (@commands) {
        if(&searchCmd($cmd)) {
           $found = 1;
           $command = $cmd;
           last;
        }
    }
    if(! $found) {
        print "Follow install commands not supported in your platform.\n";
        print "++\t@commands\n";
        print "Please choose a supported command for try again!\n";
        exit;
    }
} else {
    $found = &searchCmd($command);
    if(! $found) {
        print "The install command \"$array[0]\" not support in your platform.\n";
        exit;
    }
}

# set the file of the software list.
if(! $file) {
    if(@ARGV > 0) {
        $file = $ARGV[0];
    } else {
        &myprint("A file must be specified.");
        &usage();
    }
}
if(! -e $file) {
    &myprint("The file \"$file\" is not exists.");
    exit;
}

# check the install privilege.
if($> ne 0) {
    &myprint("Must run as root when install softwares.");
    exit;
}

##------begin install softwares-----------
$| = 1;
my ($fd, $line);
open($fd, "<", $file);
if(! $fd) {
    &myprint("Failed to open the file \"$file\". Try it again.");
    exit;
}

my $search = $command . ' search ';
my $install = $command . ' -y install ';
my ($result, $etimes, $count);
$etimes = 0;
$count = 1;
my (@successed, @failed);
print "Start install software: use the command \"$command\"\n";
print "==========================================\n";
while ($line = <$fd>) {
    chomp($line);
    ### $line;
    if($line =~ /(^(\s)*#)|(^$)|(^(\s)*\/\/)/) {
        $count++;
        next;
    }
    if($range) {
        if($count < $n1) {
            $count++;
            next;
        } elsif($count > $n2){
            last;
        }
    }
    &yesinstall("###Trying install the software of $line.");
    &yesinstall("Please waitting for a minuter......");
    $result = `$install $line 2>&1`;
    if($result =~ "already installed" or $result =~ "Installed:"
        or $result =~ "Updated:" or $result =~ "already"
        or $result =~ "newly installed") {
        print color("blue");
        print("+++The $line installed successful.\n\n");
        print color("reset");
        push @successed, $line;
        $etimes = 0;
        $count++;
    } elsif ($result =~ "No package $line available") {
        &myprint("Check the name of software: $line\n");
        push @failed, $line;
        if(++$etimes > 5) {
            last;
        }
    } else {
        &myprint("$result\n");
        push @failed, $line;
        if(++$etimes > 5) {
            last;
        }
    }
    ### $result
}

## Summary for installed software.
&clrscr();
print "Transaction Summary\n";
print "==========================================\nInstalled:\n";
if(scalar @successed > 0) {
    print color("blue");
    foreach my $element (@successed) {
        print "   $element\n";
    }
    print color("reset");
}

if(scalar @failed > 0) {
    print "\nFail Installed:\n";
    print color("red");
    foreach my $element (@failed) {
        print "   $element\n";
    }
    print color("reset");
}

if(&searchCmd("notify-send")) {
    $ret = `notify-send -t 5000 \"Software install finished.\"`;
}

print "\a";
#-----------------------------------------------------
# functions
sub usage {
    print $usage;
    exit;
}

sub version {
    print "$script version $myversion\n";
    &usage();
}

sub mydie {
    print color("red");
    print("@_ \n");
    print color("reset");
    &usage();
}

sub myprint {
    print color("red");
    print("@_ \n");
    print color("reset");
}

sub yesinstall {
    print color("green");
    print("@_ \n");
    print color("reset");
}

sub searchCmd {
    my $cmd = shift;
    my ($ret, @array, $found);

    chomp($ret = `whereis $cmd`);
    @array = split(":", $ret);
    if(scalar @array <= 1) {
        $found = 0;
    } else {
        $found = 1;
    }
    return $found;
}

# Esc[2JEsc[1;1H    - Clear screen and move cursor to 1,1 (upper left) pos.
#define clrscr()              puts ("\e[2J\e[1;1H")
sub clrscr {
    print "\e[2J\e[1;1H";
}
