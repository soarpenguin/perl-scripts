#!/usr/bin/perl
#####################################
# URLgrep v0.5.7                    #
# by x0rz <hourto_c@epita.fr>       #
#                                   #
# http://code.google.com/p/urlgrep/ #
#####################################

########## usage example ###########
#   ./urlgrep.pl -u \
#   "http://www.comptechdoc.org/os/linux/howlinuxworks/linux_hlproc.html" \ 
#   -r "\.html$" -d 1 -o file
#####################################

# debug
use strict;
use warnings;

use LWP::Simple qw($ua get);;
use HTML::LinkExtor;
use HTML::HeadParser;
use Term::ANSIColor;
use Getopt::Long;
use Smart::Comments;

use threads;
use threads::shared;

# Globals
our @crawled : shared;		# list of crawled urls
our @targets : shared;		# list of urls that matches the regexp
our @targets_misc : shared;	# list of misc links
our %UGCONF;			# URLgrep configuration

$UGCONF{'VERSION'}	= "0.5.7-dev";
$UGCONF{'TIMEOUT'}	= 5;
$UGCONF{'DEPTH'}	= 1;
$UGCONF{'MAXTHREADS'}	= 4;
$UGCONF{'NOTHREADS'}	= 0;

# Options
our $entry_url = "";
our $regexp = "^.*\$";
our $verbose = 0;
our $help = 0;
our $output = "";
our $casei = 0;
our $invert = 0;
our $all = 0;
our $cookie_file = "";

# Catching Ctrl-C
$SIG{INT} = \&tsktsk;

GetOptions ('v|verbose' => \$verbose,
	    'depth=i' => \$UGCONF{'DEPTH'},
	    'url=s' => \$entry_url,
	    'regexp=s' => \$regexp,
	    'i|ignore-case' => \$casei,
	    'm|invert-match' => \$invert,
	    'output=s' => \$output,
	    'help' => sub { helpmessage() },
	    'version' => sub { helpmessage() },
	    'all' => \$all,
	    'timeout=i' => \$UGCONF{'TIMEOUT'},
	    'cookie=s' => \$cookie_file,
	    'no-threads' => \$UGCONF{'NOTHREADS'});


## $entry_url
$ua->env_proxy(); # load env proxy (*_proxy)
$ua->timeout($UGCONF{'TIMEOUT'});
$ua->agent('Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3');

# Load cookie (if asked)
if ($cookie_file ne "") {
    $ua->cookie_jar({ file => $cookie_file });
}

# Catching Ctrl-C
$SIG{INT} = \&tsktsk;

# check for mandatory options
if ($entry_url eq "") {
    print_comm (&usage());
    exit 1;
}

# Computing host
my $host = find_hostname($entry_url);
## $host
print_comm ("Running URLgrep on " . $entry_url ."\n");
print_comm ("Regexp: ".($invert? "!" : "")."/".$regexp."/".($casei? "i" : "")."\n");
print_comm ("Started on ".gmtime()." \n");

# Call first root URL
parseURL($entry_url, 0);

if ($verbose == 0) {
    print ("\n");
}

finishing();

# Functions  ##############################

# Ctrl-C catcher
sub tsktsk {
    print ("\n");
    print_comm ("Catching Ctrl-C!\n");

    # terminating threads
    if (!$UGCONF{'NOTHREADS'}) {
        print_comm ("Killing threads... \n");

        my @threads = threads->list();

        foreach my $thr (@threads) {
            $thr->detach();
            print "Thread ".$thr->tid()." killed.\n"
        }
    }

    finishing();
    exit 0;
}

# show usage
sub usage {
    return "usage: ./urlgrep.pl -u URL [-r -i -m -d -a -o -t -c -v -h]\n";
}

# show the help
sub helpmessage {
    print_comm ("URLgrep v".$UGCONF{'VERSION'}."\n");
    print_comm ("by x0rz <hourto_c\@epita.fr>\n");
    print_comm ("http://code.google.com/p/urlgrep/\n");
    print_comm ("\n");
    print_comm (&usage());
    print_comm ("-u http_url, --url http_url\n", "bold");
    print_comm ("	target webpage's url\n");
    print_comm ("-d n, --depth n\n", "bold");
    print_comm ("	set the depth of the crawler (default=1)\n");
    print_comm ("-a, --all\n", "bold");
    print_comm ("	will search outside of the specified website\n");
    print_comm ("-r exp, --regexp exp\n", "bold");
    print_comm ("	the regular expression you want to apply\n");
    print_comm ("-i, --ignore-case\n", "bold");
    print_comm ("	ignore case distinctions\n");
    print_comm ("-m, --invert-match\n", "bold");
    print_comm ("       invert the sense of matching\n");
    print_comm ("-o file, --output file\n", "bold");
    print_comm ("	specify the output file if you want to log the search\n");
    print_comm ("-t n, --timeout n\n", "bold");
    print_comm ("	set the timeout when requesting a page (default=5s)\n");
    print_comm ("-c file, --cookie file\n", "bold");
    print_comm ("	specify your cookie file\n");
    print_comm ("-n, --no-threads\n", "bold");
    print_comm ("       won't use threads\n");
    print_comm ("-v, --verbose\n", "bold");
    print_comm ("	verbose mode\n");
    print_comm ("-h, --help\n", "bold");
    print_comm ("       show the help message\n");
    exit 0;
}

# return domain
sub find_hostname {
    my $url = $_[0];
    $url =~ s!^https?://(?:www\.)?!!i;
    $url =~ s!/.*!!;
    $url =~ s/[\?\#\:].*//;

    return $url;
}

# return domain and sub-domains
sub find_wwwhost {
    return (URI->new($_[0])->host);
}

# grep the list with the given options and regexp
sub greplist {
    my @grep = {};

    if ($casei) {
	    if ($invert) {
	        @grep = grep(!/$regexp/i, @{$_[0]});
	    }
	    else {
	        @grep = grep(/$regexp/i, @{$_[0]});
	    }
    } else {
	    if ($invert) {
            @grep = grep(!/$regexp/, @{$_[0]});
        } else {
            @grep = grep(/$regexp/, @{$_[0]});
        }
    }

    return @grep;
}

sub remove_duplicates {
    my %seen = ();
    my @unique;

    foreach my $item (@{$_[0]}) {
        push(@unique, $item) unless $seen{$item}++;
    }

    return @unique;
}

sub finishing {
    # terminating threads
    if (!$UGCONF{'NOTHREADS'}) {
        my @threads = threads->list();

        foreach my $thr (@threads) {
            $thr->join();
            print "Thread ".$thr->tid()." terminated.\n"
        }
    }

    print_comm ("Finished on ".gmtime()." \n");

    print_ok();
    print "Crawl done [".scalar(@crawled)." URL(s) visited].\n";

    # removing duplicates
    @targets = remove_duplicates(\@targets);

    # searching in misc links
    @targets_misc  = greplist(\@targets_misc);

    # removing duplicates for misc links
    @targets_misc = remove_duplicates(\@targets_misc);


    if (scalar(@targets) == 0) {
        print_ko();
        print color 'red';
        print "No target found.\n";
        print color 'reset';
    } else {
        print_ok();
        print color 'red';
        print scalar(@targets)." URL(s) found matching /".$regexp."/".($casei? "i" : "")."\n";
        foreach my $link (@targets) {
            print_info();
            print $link."\n";
        }

        if ($output ne "") {
            print_comm ("Generating output...\n");
            if (!open FILE, ">", $output) {
                print_ko();
                print "Couldn't create file.\n";
            } else {
                foreach my $link (@targets) {
                    print FILE $link."\n";
                }
                print_ok();
                print "URLs correctly written in " .$output. "\n";
            }

        }
    }

    if (scalar(@targets_misc) != 0) {
        print_comm ("Also found ".scalar(@targets_misc)." special link(s) that may interest you:\n");
    }

    foreach my $link (@targets_misc) {
        print_info();
        print $link."\n";
    }
}

sub parseURL {
    if ($verbose == 1) {
        print_ok();
        print "Trying (d:".$_[1].") " . $_[0] . "\n";
    } else {
        print ".";
        $|++;
    }

    # adding url to crawled list (with mutex)
    {
        lock(@crawled);
        push(@crawled, "$_[0]");
    }
    ## @crawled

    # Get the HTML page
    my $content = get($_[0]);
    ## $content
    if (!defined $content) {
        if ($verbose) {
            print_ko();
            print "Couldn't reach the page.\n";
        }
        return;
    }

    # Extract header data (for <base> tag essentially)
    my $head = HTML::HeadParser->new;
    $head->parse($content);
    # Setting up the current base (can be null)
    my $base = $head->header('Content-Base');

    # Extract links
    my $parser = HTML::LinkExtor->new();

    $parser->parse($content);
    my @parse = $parser->links;

    my @links : shared;

    foreach my $link (@parse) {
        push @links, "".constructURL($link->[2], $_[0], $base);
    }

    # remving empty links
    @links = grep(!/^\ *$/, @links);

    # Adding the grep results to the targets list
    my @grep : shared = greplist(\@links);
    {
        lock (@targets);
        @targets = (@targets, @grep);
    }

    if ($verbose == 1) {
        print_ok();
        print scalar(@links) . " link(s) found.\n";
        if (scalar(@grep) != 0) {
            print "     > " . scalar(@grep)." matched!\n";
        }
    }

    # Testing current depth
    if ($_[1] < $UGCONF{'DEPTH'}) {
        # Grabbing all urls
        foreach my $link (@links) {
            my $visited = 0;

            # Checking if already done
            # wainting lock...
            {
                lock (@crawled);
                # cond_wait(@crawled);
                foreach my $url_done (@crawled) {
                    if ($link eq $url_done){
                        $visited = 1;
                    }
                }
            }

            # if not visited yet, parse it
            if ($visited == 0) {
                # do not browse css/js/images/etc.
                if (!($link =~ m/.*\.(gif|jpe?g|png|css|js|ico|swf|axd|jsp|pdf)$/i)) {
                    crawl_rec($link, $_[1]);
                }
            }
        }
    }
}


sub crawl_rec {
    # if we want to go through all the links (not only local to the website)
    if ($all) {
        parse_thread($_[0], $_[1]);
    } else {
        # Calculating host of the link
        my $link_host = find_hostname($_[0]);
	
        if ($link_host eq $host) {
            parse_thread($_[0], $_[1]);
        }
    }
}

sub parse_thread {
    my $thread_count = threads->list();
    
    if ($UGCONF{'NOTHREADS'} || $thread_count >= $UGCONF{'MAXTHREADS'}) {
        parseURL($_[0], $_[1] + 1);
    } else {
        threads->create(\&parseURL, $_[0], int($_[1] + 1));
    }
}


sub constructURL {
    # 0 = link
    # 1 = page
    # 2 = base (from <base> tag, can be null)

    my $complete_url;

    local $URI::ABS_REMOTE_LEADING_DOTS = 1;
    local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;

    # capture weird links (javascript, anchor, others protocols, etc.)
    if (($_[0] =~ m!^(\w+:.+|#).*!) &&
	    !($_[0] =~ m!^(https?://).*!i)) {
	    # we keep it in our misc list but not anchor links
        if (! ($_[0] =~ m!^#.*!)) {
	        lock (@targets_misc);
            push (@targets_misc, $_[0]);
	    }

	    # return "" so it won't be part of the list
	    return "";
    }

    # building correct link
    if (defined $_[2]) {
	    $complete_url = URI->new($_[0])->abs($_[2]);
    } else {
	    $complete_url = URI->new($_[0])->abs($_[1]);
    }

    return $complete_url;

    #print ("0  " . $_[0]."\n");
    #print ("1  " .$_[1]."\n");
    #print("==> " . $newURL."\n");
}

# Misc
sub print_ok {
    print color 'bold white';
    print "[";
    print color 'green';
    print "OK";
    print color 'white';
    print "] ";
    print color 'reset';
}

sub print_ko {
    print color 'bold white';
    print "[";
    print color 'red';
    print "KO";
    print color 'white';
    print "] ";
    print color 'reset';
}

sub print_info {
    print color 'bold white';
    print "[";
    print color 'blue';
    print ">>";
    print color 'white';
    print "] ";
    print color 'reset';
}

sub print_comm {
    print color 'bold red';
    print "# ";

    if (!((defined $_[1]) && $_[1] eq "bold")) {
        print color 'reset';
    }

    print color 'yellow';
    print $_[0];
    print color 'reset';
}

