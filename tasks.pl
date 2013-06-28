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
use Smart::Comments;
use File::Spec::Functions;
use POSIX qw(strftime);
use Cwd;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $script = basename $0;
my $myversion = '0.2.0';


my $usage = "
Usage: $script [option]... <files/dirs>

       -t <tag>[,tag,..], --tags=<tag>[,tag,..]
            The tags for research, separated by \',\'. 
            Such as: FIXME,TODO,BUG.

       -e <ext>[,ext,..], --exts=<ext>[,ext,..]             
            Source code file extents for research file, separated by \',\'.
            such as: .c,.h,.pl etc.

       --exclude-dir=<D1>[,D2,]             
            Exclude the given comma separated directories D1, D2 et cetera,
            from being scanned. For example --exclude-dir=.cvs,.svn will
            skip all files that have /.cvs/ or /.svn/ as part of their path. 

       --exclude-exts=<ext1>[,ext2,]             
            Exclude the given comma separated extends ext1, ext2 et cetera,
            from being scanned. For example --exclude-dir=.out,.obj will
            skip all files that have those extends. 

       -o <file>, --output <file>
            Place the output into <file>.

       -i, --ignore-case
            Ignore case distinctions in both the PATTERN and the input 
            files. (-i is specified by POSIX.)

       -u   Display the filename first and then the match line. 
            Default is disable. Form like:
            -------------[filename]-------------
            [tag] [lineno] [content]

       -h, --help 
            Display this help and exit.

       -V,  --version
            output version information and exit.
";

if ($^O ne 'linux') {
    die "Only linux is supported but I am on $^O.\n";
}

MAIN: {
    &main();
}

sub main {
    my ($tag, $exts, $output, $ignorecase, $unite, $ret, $exclude, $exclude_exts); 
    $unite = 0;

    $ret = GetOptions( 
        'tags|t=s'  => \$tag,
        'exts|e=s'  => \$exts,
        'exclude-dir=s' => \$exclude,
        'exclude-exts=s' => \$exclude_exts,
        'output|o=s'=> \$output,
        'help'	    => \&usage,
        'ignore-case|i' => \$ignorecase,
        'unite|u'   => \$unite,
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
        print "+------------------------------------------+\n";
        print "+\tThe search tag is: @tags.\n";
    }

    my @extents = ();
    if(! $exts) {
        print("+\tSearch for all text file.\n");
    } else {
        @extents = split(",", $exts);
        print "+\tThe search file suffix is: @extents.\n";
    }

    my @exclude_dir = ();
    if($exclude) {
        @exclude_dir = split(",", $exclude);
        @exclude_dir = grep(!/^\.+$/, @exclude_dir);
        print "+\tThe exclude dir is: @exclude_dir.\n";
    }

    my @exclude_extends = ();
    if($exclude_exts) {
        @exclude_extends = split(",", $exclude_exts);
        print "+\tThe exclude extends is: @exclude_extends.\n";
    }
    print "+------------------------------------------+\n";

    ##--------start search the files----------------------
    #
    my @files = sort by_code @ARGV;
    my @failed;
    if($output) {
        open(STDOUT, ">$output") || print("Redirect stdout failed.\n");
    }
    ## @files
    if(scalar @files <= 0) {
        push @files, ".";
    }
    foreach my $file (@files) {
        if(-e $file) {
            if(-f _) {
                if(scalar @exclude_extends >= 1) {
                    if(&map_extends($file, @exclude_extends)) {
                        next;
                    } 
                }
                if(scalar @extents >= 1) {
                    if(&map_extends($file, @extents)) {
                        &scan_file($file, $ignorecase, $unite, @tags);
                    }
                } else {
                    &scan_file($file, $ignorecase, $unite, @tags);
                }
            } elsif (-d _) {
                if(&map_word($file, @exclude_dir)) {
                    next;
                }
                
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
}
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
    my ($filename, $fd, $ignorecase, $unite, $found);
    $filename = shift;
    $ignorecase = shift;
    $unite = shift;
    $found = 0;
    ## $filename
    ## @_

    open($fd, "<", "$filename");
    my ($line, $lineno);

    if($fd) {
        $lineno = 0;
        while($line = <$fd>) {
            $lineno++;
            foreach my $tag (@_) {
                # TODO support the regx.
                my $re = qr/$tag/;
                if($ignorecase) {
                    unless($line =~ /$re/i) {
                        next;
                    }
                } else {
                    unless($line =~ /$re/) {
                        next;
                    }
                }
                #if($line =~ m/$tag/) {
                    if(!$found and $unite) {
                        print "---------------$filename---------------\n";
                        $found = 1;
                    }
                    $line =~ s/^\s+//;
                    if($unite) {
                        print("[$tag], ($lineno), $line");
                    } else {
                        print("[$tag], $filename, ($lineno), $line");
                    }
                #}
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
    opendir my $dh, $dir or return undef;

    my @files = readdir $dh;
    closedir($dh);
    @files = sort by_code @files;
    
    # skip the hidden file or dir, such as .git/
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

sub map_word {
    my $word = shift;
    my @array = @_;

    map { if($word =~ /($_)$/) { return 1; } } @array;

    return 0;
}

sub map_extends {
    my $word = shift;
    my @array = @_;

    if($word =~ /(\.(\w+))$/) {
        map { if($word =~ /($_)$/) { return 1; } } @array;
    }
    
    return 0;
}
