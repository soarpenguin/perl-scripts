#!/usr/bin/env perl
#

# tasks.pl -- perl script for search tags for project. {{{1
#               tags such as: TODO, BUG, FIXME
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
my $myversion = '0.1.0';


my $usage = "
Usage: $script [option]... <files/dirs>

       -t <tag,tag,..>, --tags <tag,tag,..>
            The tags for research. 
            such as: FIXME,TODO,BUG  

       -e <ext,ext,..>, --exts <ext,ext,..>             
            Source code file extents for research file.
            such as: .c,.h,.pl etc

       -o <file>, --output <file>
            Place the output into <file>. 

       -h, --help 
            Display this help and exit

       -V,  --version  
            output version information and exit
";

if ($^O ne 'linux') {
    die "Only linux is supported but I am on $^O.\n";
}

my ($tag, $exts, $output, $ret); 

$ret = GetOptions( 
    'tags|t=s'  => \$tag,
    'exts|e=s'  => \$exts,
    'output|o=s'=> \$output,
    'help'	    => \&usage,
    'version|V' => \&version
);

if(! $ret) {
    &usage();
}

my @tags = ();
if(! $tag) {
    &myprint("A tag must be specified.");
    &usage();
} else {
    @tags = split(",", $tag);
}
### @tags

my @extents = ();
if(! $exts) {
    print("Search for all text file.\n");
} else {
    @extents = split(",", $exts);
}
### @extents

##--------start search the files----------------------
#
my @files = sort by_code @ARGV;
my @failed;

if($output) {
    open(STDOUT, ">$output") || print("Redirect stdout failed.\n");
}
## @files
foreach my $file (@files) {
    if(-e $file) {
        if(-f _) {
            if(scalar @extents >= 1) {
                foreach my $ext (@extents) {
                    if($file =~ /(\.(\w+))$/) {
                        if($1 eq $ext) {
                            &scan_file($file, @tags);
                        }
                    }
                }
            } else {
                &scan_file($file, @tags);
            }
        } elsif (-d _) {
            my @subfiles = &scan_folder($file);
            push(@files, @subfiles);
        } else {
            push(@failed, $file);
        }
    } else {
        push(@failed, $file);
    }
    #my @tmp = &scan_folder($file);
    ## @tmp
}
## @failed
close(STDOUT);
#-----------------------------------------------------
#
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

sub scan_file {
    my ($filename, $tags, $fd);
    $filename = shift;
    ## $filename
    ## @_

    open($fd, "<", "$filename");
    my ($line, $lineno);
    if($fd) {
        $lineno = 0;
        while($line = <$fd>) {
            $lineno++;
            foreach my $tag (@_) {
                if($line =~ $tag) {
                    $line =~ s/^\s+//;
                    print("[$tag], $filename, ($lineno), $line");
                }
            }
        }
        close($fd);
        return 1;
    } else {
        return 0;
    }
}

sub scan_folder {
    my $dir = shift;
    ## $dir
    my $dh;
    opendir $dh, $dir or return undef;

    my @files = readdir $dh;
    closedir($dh);
    @files = sort by_code @files;
    
    @files = grep(/^[^\.]/, @files); 
    for my $i(0..$#files) {
        $files[$i] = catfile($dir, $files[$i]);
    }
    ## @files    
    return @files;
}

sub by_code {
    return "\L$a" cmp "\L$b";
}
