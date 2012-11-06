#!/usr/bin/perl
#vim:et:ts=4:

# converts vim documentation to simple html
# Sirtaj Singh Kang (taj@kde.org)
# Wed Oct  8 01:15:48 EST 1997

# Edited and extended by Dion Nicolaas <dion@erebus.demon.nl> 
# (version 2.0, 3.0, 3.1, 3.3, 3.3.1)

# Made into a CGI by Thorsten Maerz <torte@netztorte.de>
# (version 3.2)

# New in version 2.0:
# - Added Windows NT date command
# - fixed ARGV bug
# - Let Vim do the HTMLizing, just add links afterwards (this adds syntax 
#   highlighting)
# Wed 27-09-2000

# New in version 3.0:
# - Use Perl date
# - Use lowercase html tags to work with vim 6.0
# - Match every keyword that appears in the text
# Tue 25-09-01
#
# New in version 3.1:
# - Option for HTML level
# - Do replace < and > when no HTML
# Thu 27-09-01

# New in version 3.2:
# - works as cgi script
# Thu 27-09-01

# New in version 3.3:
# - More nevermatch words
# - Remove modelines from files
# - improved Perl HTMLising
# Fri 28-09-01


# New in version 3.3.1:
# - use vims colorschemes (quickndirty)

use strict;

# set $isCGI to 1 to run as a cgi-script
my $isCGI = 1;
# Set this to your executable of Vim
#my $vimcmd = "d:/bin/vim/vim60/gvim.exe";
my $vimcmd = "vim";
# Set this to all words you don't want to match, in between **
my $nevermatch = "*is* *as* *end* *section* *various* *case* *put* *help* *starting* *go*";
# ======================================================================
# Nothing below this line should have to be changed.
# ======================================================================

my %syn;
my $CGIfilename;
my $CGIsearch;
my $CGIbasename;
if ($isCGI) {
  use Fcntl;
  use POSIX qw(tmpnam);
  use CGI qw/:standard/;
  ($CGIbasename = $0) =~ s#.*/([^/]+)#$1#;
}

my $date = gmtime;
my %url = ();
my %file = ();
my $opt_htmlising = 2;
my $progID = "vim2html.pl 3.2";

sub readTagFile
{
    my($tagfile) = @_;
    my($tag, $file);

    open(TAGS,"$tagfile") || die "can't read tags\n";

    while (<TAGS>) {
        s/</&lt;/g;
        s/>/&gt;/g;

        /^(.*)\t(.*)\t/;

        $tag = $1;
        if ($isCGI) {
            $file{$tag}= $2;
#            $url{$tag} = "<A HREF=\"$CGIbasename?$file{$tag}#$tag\">$tag</A>";
            $url{$tag} = "<A HREF=\"$CGIbasename";
            if (param('cs')) {
                $url{$tag} .= "?cs=".param('cs').'&';
            }
            else {
                $url{$tag} .= '?';
            
            }
        $url{$tag} .= "page=$file{$tag}#$tag\">$tag</A>";
        }
        else {
            ($file{$tag}= $2) =~ s/.txt$/.html/g;
            $url{$tag} = "<A HREF=\"$file{$tag}#$tag\">$tag</A>";
        }
    }
    close(TAGS);
}

sub vim2html
{
    # viminfile is the original which will be munched by vim.
    my ($viminfile) = @_;
    my $infile;
    $infile = "$viminfile.html";
    if ($opt_htmlising < 2) {
        open (IN, "$viminfile") or die "Can't read input file $viminfile: $?";
        if ($isCGI) {
            # try new temporary filenames until we get one that didn't already
            # exist;  the check should be unnecessary, but you can't be too careful
            do { $infile = tmpnam() } 
            until sysopen(INTER, $infile, O_RDWR|O_CREAT|O_EXCL);
        }
        else {
            open(INTER, ">$infile") 
            or die "Can't write intermediate file $infile: $?";
        }
        if ($opt_htmlising == 1) {
            # write header 
            print INTER "<html><head></head><body><pre>";
        }
        my ($example, $examplecount) = 0;
        my $curly = 0;
        # Create a "safe" file
        while (<IN>) {
            # Replace tabs with spaces (ts=8)
            my $pos;
            while (($pos = index($_, "\t")) != -1) {
                $pos %= 8;
                if ($pos == 8) { $pos = 0; }
                my $padding = substr("        ", 0, 8 - $pos);
                s/\t/$padding/;
            }
            s/</&lt;/g;
            s/>/&gt;/g;
            if ($opt_htmlising == 1 || $isCGI) {
		# bugs
		# intro.txt:*CTRL-{char}* 
		
                # do syntax highlighting in Perl
                s/^\&lt;$//;                                                    # only <
                s/^\&lt;(\s)/ $1/;                                              # leading <
                s/\&gt;$//      unless /\&lt;/;                                 # trailing >

                s/(.*)~$/$syn{'Header'}$1$syn{'end'}/;                          # trailing ~

                s/^[-=]+$/$syn{'SectionDelim'}$&$syn{'end'}/g;                  # ===== or ----
                # dont highlight ^*word* : wouldnt be recognized as jump target later
                s/ \*[^ *]*\*/$syn{'HyperTextEntry'}$&$syn{'end'}/g;            # *Entry*
                s/(?<! \*)'[^' ]{2,}'/$syn{'Option'}$&$syn{'end'}/g;            # 'Option'

                s/(?<! \*)\&lt;[^&]*\&gt;/$syn{'Special'}$&$syn{'end'}/g;       # <Special>
                s/(?<! \*)\[[^\] ]{2,}\]/$syn{'Special'}$&$syn{'end'}/g;        # [Special]

                s/(?<! \*){[^}]*}/$syn{'Special'}$&$syn{'end'}/g;               # {Special}
                # multiline fails on usr_40.txt
                #s/(?<! \*)(?<!'){[^}]{2,}}/$syn{'Special'}$&$syn{'end'}/g;     # {Special}
                #if (s/(?<! \*){[^}]*$/$syn{'Special'}$&/g) { $curly = 1; }
                #if ($curly) { s/[^}]*}/$&$syn{'end'}/g and $curly = 0; }
                
                s/(?<! \*)CTRL-\?/$syn{'Special'}$&$syn{'end'}/g;
                s/(?<! \*)CTRL-\./$syn{'Special'}$&$syn{'end'}/g;
                s/(?<! \*)CTRL-Break/$syn{'Special'}$&$syn{'end'}/g;
                s/(?<! \*)CTRL-PageUp/$syn{'Special'}$&$syn{'end'}/g;
                s/(?<! \*)CTRL-PageDown/$syn{'Special'}$&$syn{'end'}/g;
                s/(?<! \*)CTRL-Insert/$syn{'Special'}$&$syn{'end'}/g;
                s/(?<! \*)CTRL-Del/$syn{'Special'}$&$syn{'end'}/g;
                s/^CTRL-./$syn{'Special'}$&$syn{'end'}/g;
                                
                s/\bN\b/$syn{'Special'}$&$syn{'end'}/g;		        # Not quite right
                #s/"(.*)"/<b>$&<\/b>/g;                  # bold "word"

            }
            print  INTER $_;
        }
        if ($opt_htmlising == 1) {
            # write footer 
            print INTER "</pre></body></html>";
        }
        close(INTER);
    }
    else {
        # execute
        # gvim $viminfile -c "so $VIMRUNTIME/syntax/2html.vim" -c "wq" -c "q"
        # to let vim do the HTMLizing
        my $socmd;
        if ($ENV{'OSTYPE'} =~ /linux/i) {
            $socmd = "so \$VIMRUNTIME/syntax/2html.vim"
        }
        else {
            $socmd = "\"so \$VIMRUNTIME/syntax/2html.vim\""
        }
        my (@args) = ($vimcmd, $viminfile, "-c", $socmd, "-c", "wq", "-c", "q");
        
        print @args;
        system(@args) == 0
            or die "system @args failed: $?";
    }                      
    my $outfile;

    open(IN, "$infile") || die "Couldn't read from $infile.\n";

    ($outfile = $infile) =~ s/.*\///g;
    # infile is called .txt.html
    $outfile =~ s/\.txt\.html$//g;
    if ($isCGI) {
        open(OUT, ">-");
    }
    else { 
        open(OUT, ">$outfile.html")
                || die "Couldn't write to $outfile.html.\n";
    }


    my $dontmatch = "";     # tags not to match in this paragraph
    my $currentlabel = "";  # used to build $dontmatch
    # Replace applicable parts
    while (<IN>) {
        # Change the title and add an H1
        s/<title>.*<\/title>/<title>Vim documentation: $outfile<\/title>/g;
        s/<pre>/<h1>Vim documentation: $outfile<\/h1><hr><pre>/g;
        # Add bottom line
        s/<\/pre>/<\/pre><hr><p><i>Generated by <tt>$progID<\/tt> on $date<\/i><\/p>/g;
        # Remove modeline
        s/ vim:.*:\s*$//;

        # Links
        # We don't want to link to the section we're reading, so we remember
        # where we are.
        if (m/\*[^ *]+\*/) {   # label in this line?
            # remember it
            $currentlabel .= $_;
            $dontmatch = $nevermatch . $currentlabel;
        } else {
            # first line of this section
            $currentlabel = "";
        }
        # replace all applicable words with a link
        chomp;
        my $out = "";   # we'll build the output in here.
    REPLACE:
        while (length $_ ) {
            # copy various pieces of line to $out, changing them into
            # links where appropriate. The order here is significant, as we
            # don't want to touch e.g. HTML tags.

            # copy leading spaces
            if (s/^(\s+)//) {
                $out .= $1;
                next REPLACE;
            }
            # copy html tags
            if (s/^(<[^>]+>)//)
            {
                $out .= $1;
                next REPLACE;
            }
            # copy keywords in **
            if (s/^(\*[^| ]+\*)//)
            {
                $out .= $1;
                next REPLACE;
            }

            # keywords in ""
            # Mostly appear in sentences like: 'the "/" command ...'
            # So we replace them almost always with a link.
            if (s/^\&quot;([^| ]+)\&quot;//) {
                my $tag = $1;
                # don't link when it appears in $dontmatch
                my $skip = ($dontmatch =~ m/\*\Q$tag\E\*/);
                if ($url{$tag} and not $skip) {
                    $out .= "\&quot;$url{$tag}\&quot;";
                }
                else {
                    $out .= "\&quot;$tag\&quot;";
                }
                next REPLACE;
            }    
            # keywords in ||
            # We always replace them with a link, if the link exists.
            if (s/^\|([^| ]+)\|//) {
                if ($url{$1}) {
                    $out .= "\|$url{$1}\|";
                }
                else {
                    $out .= "\|$1\|";
                }
                next REPLACE;
            }
            # plain word
            # We replace them if not in $dontmatch and longer than 1 char, to
            # prevent changing a and I and many others
            if (s/^([^ |<"]+)//) {
                my $tag = $1;
                my $skip = ($dontmatch =~ m/\*\Q$tag\E\*/);
                # no one char hits (includes &gt; and &lt;)
                if (length($tag) > 1 and
                        $tag ne "&lt;" and
                        $tag ne "&gt;"
                            and
                        $url{$tag}
                            and not $skip) {
                    $out .= "$url{$tag}";
                }
                else {
                    $out .= $tag;
                }
                next REPLACE;
            }
            # unmatched <"|, copy.
            if (s/^([|<"])//) {
                $out .= $1;
                next REPLACE;
            }

            # NOTREACHED
            die "Nothing matched? line = \"$_\"\n";
        }
        # *keyword* is only replaced now, to make skipping them earlier easier
        $out =~ s/\*([^ *]+)\*/\*<a name="$1">$1<\/a>\*/g;
        print OUT "$out\n";
    }
    # infile is intermediate, can now go
    unlink $infile;
}

sub usage
{
die<<EOF;
$progID (Thu 27-09-2001)
Converts vim documentation to HTML.
usage:
    vim2html.pl [-v{0|1|2}] <tag file> <text files>
    
    -v0 means no HTMLising (apart from links)
    -v1 means basic HTML
    -v2 means let Vim do the HTMLising.
    Default is -v2.

    <text files> should have the extension .txt
    The output files will have the extension .html
EOF
}

# CGI / HTML header and footer
sub CGIStartHTML
{
my $color=param('cs');
print <<EOF;
Content-type: text/html

<HTML>
<HEAD><TITLE>Vim online doc: $CGIfilename</TITLE></HEAD>
<BODY $syn{'color'}>
<table width="100%"><tr>
  <td align="left">
    <H1>VimDoc: $CGIfilename</H1>
  </td>
  <td align="center">
    <a href="http://vimdoc.sf.net/cgi-bin/vimfaq2html3.pl?&cs=$color">FAQ</a><br>
    <a href="/vimdocschemes.html">select color</a>
  </td>
  <td align="center">
    <a href="$CGIbasename?cs=$color">help</a><br>
    <a href="$CGIbasename?cs=$color&page=usr_toc.txt">manual</a>
  </td>
  <td align="center">
    <a href="/mike/index.html">PS / PDF</a><br>
    <a href="/dion/vimum.html">single file</a><br>
  </td>
  <td align="center">
    <a href="http://vim.sf.net">VimOnline</a><br>
    <a href="http://www.vim.org">Vim.org</a><br>
  </td>
  <td align="center">
    <a href="#search">search</a><br>
    <a href="/">VimDoc</a><br>
  </td>
</tr></table>
<HR>
<PRE>
EOF
}

sub CGIEndHTML
{
$CGIsearch=param('search') || '';
my $color=param('cs');
print <<EOF
</PRE>
<hr>
<a name="search"></a>
<form method="GET" action="$CGIbasename">
<input type="text" name="search" value="$CGIsearch">
<input type="submit" value="Search tag (regex)">
<input type="hidden" name="cs" value="$color">
</form>
<a href="$CGIbasename?cs=$color">Main help</a>&nbsp;&nbsp;&nbsp;
<a href="$CGIbasename?cs=$color&page=usr_toc.txt">Table Of Contents</a>
<p align="right"><font size=-2>Automatically generated by <a href="dumpvim2html.pl">$progID</a> on $date</font></p>
</BODY>
</HTML>
EOF
}

sub searchTag
{
    my( $file, $name );
    my $CGIsearch = shift;
    my $count;
    foreach (keys(%url)) {
        if (/$CGIsearch/i) {
            $count++;
            print "$file{$_} : $url{$_}\n";
        }
    }
                        
    $count = $count || 'no';
    print "\n<br>$count hits";
}

# main

if ($isCGI) {

    my $pipecmd='cvs -z9 -d:pserver:anonymous@cvs1:/cvsroot/vim co -p vim/runtime/doc/';
    $opt_htmlising=0;
    $CGIfilename=param('page') || 'help.txt';
    $CGIfilename = 'search &quot;'.param('search').'&quot;' if param('search');
    if (param('cs') eq 'blue') {
        $syn{'Header'}          = '<font color="#00fc00">';
        $syn{'SectionDelim'}    = '<font color="#00fc00">';
        $syn{'Example'}         = '<font color="#b8bcb8">';
        $syn{'HyperTextJump'}   = '<font color="#b8bcb8">';
        $syn{'HyperTextEntry'}  = '<font color="#00fcf8">';
        $syn{'Option'}          = '<font color="#f8a400">';
        $syn{'Special'}         = '<font color="#f800f8">';
        $syn{'color'}           = 'bgcolor="#000088" text="#f8fcf8" '
                                .'LINK="#b8bcb8" '
                                .'VLINK="#888c88" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'elflord') {
        $syn{'Header'}          = '<font color="#f880f8">';
        $syn{'SectionDelim'}    = '<font color="#f880f8">';
        $syn{'Example'}         = '<font color="#80a0f8">';
        $syn{'HyperTextJump'}   = '<font color="#40fcf8">';
        $syn{'HyperTextEntry'}  = '<font color="#f800f8">';
        $syn{'Option'}          = '<font color="#60fc60">';
        $syn{'Special'}         = '<font color="#f80000">';
        $syn{'color'}           = 'bgcolor="#000000" text="#00fcf8" '
                                .'LINK="#40fcf8" '
                                .'VLINK="#30aca8" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'evening') {
        $syn{'Header'}          = '<font color="#f880f8">';
        $syn{'SectionDelim'}    = '<font color="#f880f8">';
        $syn{'Example'}         = '<font color="#80a0f8">';
        $syn{'HyperTextJump'}   = '<font color="#40fcf8">';
        $syn{'HyperTextEntry'}  = '<font color="#f8a0a0">';
        $syn{'Option'}          = '<font color="#60fc60">';
        $syn{'Special'}         = '<font color="#f8a400">';
        $syn{'color'}           = 'bgcolor="#303030" text="#f8fcf8" '
                                .'LINK="#40fcf8" '
                                .'VLINK="#30aca8" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'koehler') {
        $syn{'Header'}          = '<font color="#f880f8">';
        $syn{'SectionDelim'}    = '<font color="#f880f8">';
        $syn{'Example'}         = '<font color="#80a0f8">';
        $syn{'HyperTextJump'}   = '<font color="#40fcf8">';
        $syn{'HyperTextEntry'}  = '<font color="#f8a0a0">';
        $syn{'Option'}          = '<font color="#60fc60">';
        $syn{'Special'}         = '<font color="#f8a400">';
        $syn{'color'}           = 'bgcolor="#000000" text="#f8fcf8" '
                                .'LINK="#40fcf8" '
                                .'VLINK="#30aca8" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'morning') {
        $syn{'Header'}          = '<font color="#a020f0">';
        $syn{'SectionDelim'}    = '<font color="#a020f0">';
        $syn{'Example'}         = '<font color="#0000f8">';
        $syn{'HyperTextJump'}   = '<font color="#008888">';
        $syn{'HyperTextEntry'}  = '<font color="#f800f8">';
        $syn{'Option'}          = '<font color="#288850">';
        $syn{'Special'}         = '<font color="#6858c8">';
        $syn{'color'}            = 'bgcolor="#e0e4e0" text="#000000" '
                                .'LINK="#008888" '
                                .'VLINK="#006868" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'murphy') {
        $syn{'Header'}          = '<font color="#f0dcb0">';
        $syn{'SectionDelim'}    = '<font color="#f0dcb0">';
        $syn{'Example'}         = '<font color="#f8a400">';
        $syn{'HyperTextJump'}   = '<font color="#00fcf8">';
        $syn{'HyperTextEntry'}  = '<font color="#f8fcf8">';
        $syn{'Option'}          = '<font color="#b8bcb8">';
        $syn{'Special'}         = '<font color="#f800f8">';
        $syn{'color'}            = 'bgcolor="#000000" text="#90ec90" '
                                .'LINK="#00fcf8" '
                                .'VLINK="#00aca8" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'pablo') {
        $syn{'Header'}          = '<font color="#00fc00">';
        $syn{'SectionDelim'}    = '<font color="#00fc00">';
        $syn{'Example'}         = '<font color="#808080">';
        $syn{'HyperTextJump'}   = '<font color="#00c0c0">';
        $syn{'HyperTextEntry'}  = '<font color="#00fcf8">';
        $syn{'Option'}          = '<font color="#00c000">';
        $syn{'Special'}         = '<font color="#0000f8">';
        $syn{'color'}            = 'bgcolor="#000000" text="#f8fcf8" '
                                .'LINK="#00c0c0" '
                                .'VLINK="#008080" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'peachpuff') {
        $syn{'Header'}          = '<font color="#c800c8">';
        $syn{'SectionDelim'}    = '<font color="#c800c8">';
        $syn{'Example'}         = '<font color="#406090">';
        $syn{'HyperTextJump'}   = '<font color="#008888">';
        $syn{'HyperTextEntry'}  = '<font color="#c00058">';
        $syn{'Option'}          = '<font color="#288850">';
        $syn{'Special'}         = '<font color="#6858c8">';
        $syn{'color'}           = 'bgcolor="#f8d8b8" text="#000000" '
                                .'LINK="#008888" '
                                .'VLINK="#006868" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'printman') {
        $syn{'Header'}          = '<font color="#000000">';
        $syn{'SectionDelim'}    = '<font color="#000000">';
        $syn{'Example'}         = '<font color="#000000">';
        $syn{'HyperTextJump'}   = '<font color="#000000">';
        $syn{'HyperTextEntry'}  = '<font color="#000000">';
        $syn{'Option'}          = '<font color="#000000">';
        $syn{'Special'}         = '<font color="#000000">';
        $syn{'color'}           = 'bgcolor="#f8fcf8" text="#000000" '
                                .'LINK="#000000" '
                                .'VLINK="#a8aca8" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'ron') {
        $syn{'Header'}          = '<font color="#e8a8b8">';
        $syn{'SectionDelim'}    = '<font color="#e8a8b8">';
        $syn{'Example'}         = '<font color="#00fc00">';
        $syn{'HyperTextJump'}   = '<font color="#00fcf8">';
        $syn{'HyperTextEntry'}  = '<font color="#00fcf8">';
        $syn{'Option'}          = '<font color="#288850">';
        $syn{'Special'}         = '<font color="#f8fc00">';
        $syn{'color'}            = 'bgcolor="#000000" text="#00fcf8" '
                                .'LINK="#00fcf8" '
                                .'VLINK="#00aca8" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'shine') {
        $syn{'Header'}          = '<font color="#a020f0">';
        $syn{'SectionDelim'}    = '<font color="#a020f0">';
        $syn{'Example'}         = '<font color="#a8a8a8">';
        $syn{'HyperTextJump'}   = '<font color="#008888">';
        $syn{'HyperTextEntry'}  = '<font color="#a07070">';
        $syn{'Option'}          = '<font color="#288850">';
        $syn{'Special'}         = '<font color="#f88c00">';
        $syn{'color'}           = 'bgcolor="#f8fcf8" text="#000000" '
                                .'LINK="#008888" '
                                .'VLINK="#006868" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'torte') {
        $syn{'Header'}          = '<font color="#f880f8">';
        $syn{'SectionDelim'}    = '<font color="#f880f8">';
        $syn{'Example'}         = '<font color="#80a0f8">';
        $syn{'HyperTextJump'}   = '<font color="#00fc00">';
        $syn{'HyperTextEntry'}  = '<font color="#f8a0a0">';
        $syn{'Option'}          = '<font color="#60fc60">';
        $syn{'Special'}         = '<font color="#f8a400">';
        $syn{'color'}           = 'bgcolor="#000000" text="#c8ccc8" '
                                .'LINK="#00fc00" '
                                .'VLINK="#00ac00" '
                                ;
        $syn{'end'}             = '</font>';
    }
    elsif (param('cs') eq 'zellner') {
        $syn{'Header'}          = '<font color="#a020f0">';
        $syn{'SectionDelim'}    = '<font color="#a020f0">';
        $syn{'Example'}         = '<font color="#f80000">';
        $syn{'HyperTextJump'}   = '<font color="#0000f8">';
        $syn{'HyperTextEntry'}  = '<font color="#f800f8">';
        $syn{'Option'}          = '<font color="#0000f8">';
        $syn{'Special'}         = '<font color="#f800f8">';
        $syn{'color'}           = 'bgcolor="#f8fcf8" text="#000000" '
                                .'LINK="#0000f8" '
                                .'VLINK="#0000a8" '
                                ;
        $syn{'end'}             = '</font>';
    }
    else {      # (param('cs') eq 'default') {
        $syn{'Header'}          = '<font color="#a020f0">';
        $syn{'SectionDelim'}    = '<font color="#a020f0">';
        $syn{'Example'}         = '<font color="#0000f8">';
        $syn{'HyperTextJump'}   = '<font color="#008888">';
        $syn{'HyperTextEntry'}  = '<font color="#f800f8">';
        $syn{'Option'}          = '<font color="#288850">';
        $syn{'Special'}         = '<font color="#6858c8">';
        $syn{'color'}           = 'bgcolor="#ffffff" text="#000000" '
                                .'LINK="#008888" '
                                .'VLINK="#006868" '
                                ;
        $syn{'end'}             = '</font>';
    }

    CGIStartHTML();
    readTagFile($pipecmd.'tags|');
    if (param('search')) {
      searchTag(param('search'));
    }
    else {
      vim2html($pipecmd.$CGIfilename.'|');
      print "<p></p>";
    }
    CGIEndHTML();
}
else {
  if ($#ARGV < 1) {
      print "ERROR: too few arguments\n";
      usage();
  }

  my $nextarg = 0;
  my $more = 0;
  do {
      print "$ARGV[$nextarg]\n";
      $more = 0;
      if ($ARGV[$nextarg] eq "-h0") {
          $opt_htmlising = 0; # no html
          $nextarg++;
          $more = 1;
      }
      elsif ($ARGV[$nextarg] eq "-h1") {
          $opt_htmlising = 1; # basic html
          $nextarg++;
          $more = 1;
      }
      elsif ($ARGV[$nextarg] eq "-h2") {
          $opt_htmlising = 2; # Vim html
          $nextarg++;
          $more = 1;
      }
  } while ($more);

  print "Processing tags...\n";
  readTagFile($ARGV[$nextarg]);
  $nextarg++;

  foreach my $file ($nextarg..$#ARGV) {
      print "Processing ".$ARGV[ $file ]."...\n";
      vim2html($ARGV[$file]);
  }
}
