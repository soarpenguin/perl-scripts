#!/usr/bin/perl -w
#

# ***.pl -- ***********. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Nov.14 2012
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
my $myversion = '0.1.0';

my $usage1 = "Usage: $script [OPTION]... [FILE]...

List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -A, --almost-all           do not list implied . and ..
      --author               with -l, print the author of each file
  -b, --escape               print C-style escapes for nongraphic characters
      --block-size=SIZE      scale sizes by SIZE before printing them.  E.g.,
                               `--block-size=M' prints sizes in units of
                               1,048,576 bytes.  See SIZE format below.
  -B, --ignore-backups       do not list implied entries ending with ~
  -c                         with -lt: sort by, and show, ctime (time of last
                               modification of file status information)
                               with -l: show ctime and sort by name
                               otherwise: sort by ctime, newest first
  -C                         list entries by columns
      --color[=WHEN]         colorize the output.  WHEN defaults to `always'
                               or can be `never' or `auto'.  More info below
  -d, --directory            list directory entries instead of contents,
                               and do not dereference symbolic links
  -D, --dired                generate output designed for Emacs' dired mode
  -f                         do not sort, enable -aU, disable -ls --color
  -F, --classify             append indicator (one of */=>@|) to entries
      --file-type            likewise, except do not append `*'
      --format=WORD          across -x, commas -m, horizontal -x, long -l,
                               single-column -1, verbose -l, vertical -C
      --full-time            like -l --time-style=full-iso
  -g                         like -l, but do not list owner
      --group-directories-first
                             group directories before files.
                               augment with a --sort option, but any
                               use of --sort=none (-U) disables grouping
  -G, --no-group             in a long listing, don't print group names
  -h, --human-readable       with -l, print sizes in human readable format
                               (e.g., 1K 234M 2G)
      --si                   likewise, but use powers of 1000 not 1024
  -H, --dereference-command-line
                             follow symbolic links listed on the command line
      --dereference-command-line-symlink-to-dir
                             follow each command line symbolic link
                             that points to a directory
      --hide=PATTERN         do not list implied entries matching shell PATTERN
                               (overridden by -a or -A)
      --indicator-style=WORD  append indicator with style WORD to entry names:
                               none (default), slash (-p),
                               file-type (--file-type), classify (-F)
  -i, --inode                print the index number of each file
  -I, --ignore=PATTERN       do not list implied entries matching shell PATTERN
  -k                         like --block-size=1K
  -l                         use a long listing format
  -L, --dereference          when showing file information for a symbolic
                               link, show information for the file the link
                               references rather than for the link itself
  -m                         fill width with a comma separated list of entries
  -n, --numeric-uid-gid      like -l, but list numeric user and group IDs
  -N, --literal              print raw entry names (don't treat e.g. control
                               characters specially)
  -o                         like -l, but do not list group information
  -p, --indicator-style=slash
                             append / indicator to directories
  -q, --hide-control-chars   print ? instead of non graphic characters
      --show-control-chars   show non graphic characters as-is (default
                             unless program is `ls' and output is a terminal)
  -Q, --quote-name           enclose entry names in double quotes
      --quoting-style=WORD   use quoting style WORD for entry names:
                               literal, locale, shell, shell-always, c, escape
  -r, --reverse              reverse order while sorting
  -R, --recursive            list subdirectories recursively
  -s, --size                 print the allocated size of each file, in blocks
  -S                         sort by file size
      --sort=WORD            sort by WORD instead of name: none -U,
                             extension -X, size -S, time -t, version -v
      --time=WORD            with -l, show time as WORD instead of modification
                             time: atime -u, access -u, use -u, ctime -c,
                             or status -c; use specified time as sort key
                             if --sort=time
      --time-style=STYLE     with -l, show times using style STYLE:
                             full-iso, long-iso, iso, locale, +FORMAT.
                             FORMAT is interpreted like `date'; if FORMAT is
                             FORMAT1<newline>FORMAT2, FORMAT1 applies to
                             non-recent files and FORMAT2 to recent files;
                             if STYLE is prefixed with `posix-', STYLE
                             takes effect only outside the POSIX locale
  -t                         sort by modification time, newest first
  -T, --tabsize=COLS         assume tab stops at each COLS instead of 8
  -u                         with -lt: sort by, and show, access time
                               with -l: show access time and sort by name
                               otherwise: sort by access time
  -U                         do not sort; list entries in directory order
  -v                         natural sort of (version) numbers within text
  -w, --width=COLS           assume screen width instead of current value
  -x                         list entries by lines instead of by columns
  -X                         sort alphabetically by entry extension
  -Z, --context              print any SELinux security context of each file
  -1                         list one file per line
      --help     display this help and exit
      --version  output version information and exit

SIZE may be (or may be an integer optionally followed by) one of following:
KB 1000, K 1024, MB 1000*1000, M 1024*1024, and so on for G, T, P, E, Z, Y.

Using color to distinguish file types is disabled both by default and
with --color=never.  With --color=auto, ls emits color codes only when
standard output is connected to a terminal.  The LS_COLORS environment
variable can change the settings.  Use the dircolors command to set it.

Exit status:
 0  if OK,
 1  if minor problems (e.g., cannot access subdirectory),
 2  if serious trouble (e.g., cannot access command-line argument).
";

my $usage = "Usage: $script [OPTION]... [FILE]...

List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -1                         list one file per line
      --help     display this help and exit
      --version  output version information and exit

SIZE may be (or may be an integer optionally followed by) one of following:
KB 1000, K 1024, MB 1000*1000, M 1024*1024, and so on for G, T, P, E, Z, Y.

Using color to distinguish file types is disabled both by default and
with --color=never.  With --color=auto, ls emits color codes only when
standard output is connected to a terminal.  The LS_COLORS environment
variable can change the settings.  Use the dircolors command to set it.

Exit status:
 0  if OK,
 1  if minor problems (e.g., cannot access subdirectory),
 2  if serious trouble (e.g., cannot access command-line argument).
";
my ($all, $list); 

my $ret = GetOptions( 
    'l'         => \$list,
    'a'         => \$all,
	'help'	    => \&usage,
	'version|V' => \&version
);

if(! $ret) {
	&usage();
}

#------------------------------------------------------
my $myfile;
my $mytime;

if (@ARGV == 0) {
    $ARGV[0] = getcwd();
}

foreach $myfile (@ARGV) {
    #$mytime = -M $myfile;
    #print "$mytime\n";
    ## $myfile
	if($myfile eq '.') {
		$myfile = getcwd();
	}

    print "---------------------$myfile-----------------------\n";
    if(-e $myfile) {
        if(-d -x _) {
            ## $myfile
            &listdir($myfile);
           # opendir($myfile)
        } elsif (-f _) {
            printf "%18s", "$myfile";
        } else {
            print "$myfile unknown type.\n"
        }
    } else {
        print "$myfile is not existed.\n";
    }

}

#------------------------------------------------------
my $count = 0;

# list dir
sub listdir {
    my $mydir = shift;
    ## $mydir
    my $dh;
    opendir $dh, $mydir or die "Can't open the $myfile";
   
    $| = 1;
	my @files = readdir $dh;
	close $dh;
	@files = sort by_code @files;

    foreach my $file (@files) {
        ## $file;
        if($list) {
            unless ($all) {
                next if($file =~ /^\.+$/);
            }
            
            my $fname = $file;
            $file = catfile($mydir, $file);
            $count++;
            ## $file
            my @info = stat($file);
            ## @info
            my ($type, $right, $nlink, $ctime, $size, $uid, $gid);
            if (-f $file) {
                $type = '-';
            } elsif (-d $file) {
                $type = 'd';
            } elsif (-l $file) {
                $type = 'l';
            } elsif (-S $file) {
                $type = 's';
            } elsif (-b $file) {
                $type = 'b';
            } elsif (-c $file) {
                $type = 'c';
            } elsif (-p $file) {
                $type = 'p';
            } else {
                $type = 'u';
            }
            
            #my $dec_perms = $info[2] & 07777;
            #my $oct_perm_str = sprintf "%o", $dec_perms;
            $right = sprintf "%o", $info[2] & 0777;
            $right =~ s/0/---/g;
            $right =~ s/1/--x/g;
            $right =~ s/2/-w-/g;
            $right =~ s/3/-wx/g;
            $right =~ s/4/r--/g;
            $right =~ s/5/r-x/g;
            $right =~ s/6/rw-/g;
            $right =~ s/7/rwx/g;
            ## $right
            $nlink = $info[3];
            $uid   = getpwuid($info[4]); #from user id to user name.
            $gid   = getgrgid($info[5]); #from group id to group name.
            $size  = $info[7];
            # the format of below: Sun Nov 11 14:18:02 2012
            # $ctime = strftime "%a %b %e %H:%M:%S %Y", localtime($info[10]);
            $ctime = strftime "%b %e %H:%M %Y", localtime($info[10]);
            printf "%1s%9s %3d %8s %8s %8d %12s", $type, $right, $nlink, $uid, $gid, $size, $ctime;
            #printf "%-2d %-4d %-4d %-8d", $nlink, $uid, $gid, $size;
            if(-d $file) {
                print color("blue");
            } elsif (-x _) {
                print color("green"); 
            }
            printf " %-18s", $fname;
            print color("reset");
            print "\n";
            ## @info

        } else {
            unless ($all) {
                next if($file =~ /^\.+$/);
            }
            my $fname = $file;
            $file = catfile($mydir, $file);
            $count++;
            ## $file
            if(-d $file) {
                print color("blue");
            } elsif (-x _) {
                print color("green"); 
            }
            printf "%-18s", $fname;
            print color("reset");

            if($count % 5 == 0) {
                print "\n";
            } 
        }
    }

    if($count % 5 and !$list) {
        print "\n";
    }
    closedir($dh);
}

# function for signal action
sub catch_int {
	my $signame = shift;
	print color("red"), "Stoped by SIG$signame\n", color("reset");
	exit;
}
$SIG{INT} = __PACKAGE__ . "::catch_int";
$SIG{INT} = \&catch_int; # best strategy

sub usage {
	print $usage;
	exit;
}

sub version {
	print "$script version $myversion\n";
	exit;
}

sub by_code {
	return "\L$a" cmp "\L$b";
}

sub by_code_reverse {
	return "\L$b" cmp "\L$a";
}
## $myfile
## @ARGV

