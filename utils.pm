#!/usr/bin/env perl
#
# Author: soarpenguin <soarpenguin@gmail.com>
# First release May.14 2013
##################################################
# usage of utils.pm, add code like:
#   use lib "path"; #path is the file of utils.pm 
#   use utils;
##################################################

package utils;

use FileHandle;
use Getopt::Long;
use Time::Local qw(timelocal);
use Term::ANSIColor;
use strict;
$|=1;

BEGIN {
    use Exporter();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
    $VERSION = 0.0.1;
    @ISA = qw(Exporter);
    @EXPORT = qw(
    	clrscr clreol delline gotoxy hidecursor showcursor 
        notice warning fatal_warning attention debug_stdout
        __FUNC__ __func__ get_now_time trim fopen print_log
    );
    @EXPORT_OK = qw(&mk_fd_nonblocking &read_rcfile &get_winsize);
}

#read the content of configure file.
sub read_rcfile {
    my $file = shift;

    return unless defined $file && -e $file;

    my @lines;

    open( my $fh, '<', $file ) or die( "Unable to read $file: $!" );
    while ( my $line = <$fh> ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next if $line eq '';
        next if $line =~ /^#/;

        push( @lines, $line );
    }
    close $fh;

    return @lines;
}

sub warn {
    my $program = shift;

    return CORE::warn( $program, ': ', @_, "\n" );
}

sub die {
    my $program = shift;

    return CORE::die( $program, ': ', @_, "\n" );
}

# set socket nonblocking.
sub mk_fd_nonblocking {
    use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

    my $fd = shift;
    my $flags = fcntl($fd, F_GETFL, 0)
        or warn "Can't get flags for the fd: $!\n";

    $flags = fcntl($fd, F_SETFL, $flags | O_NONBLOCK)
        or warn "Can't set flags for the fd: $!\n";
}

######################## terminal screen operator ###############
# Esc[2JEsc[1;1H    - Clear screen and move cursor to 1,1 (upper left) pos.
#define clrscr()              puts ("\e[2J\e[1;1H")
sub clrscr {
    print "\e[2J\e[1;1H";
}

# Esc[K     - Erases from the current cursor position to the end of the current line.
#define clreol()              puts ("\e[K")
sub clreol {
    print "\e[K";
}

# Esc[2K            - Erases the entire current line.
#define delline()             puts ("\e[2K")
sub delline {
    print "\e[2K";
}

# Esc[Line;ColumnH    - Moves the cursor to the specified position (coordinates)
#define gotoxy(x,y)           printf("\e[%d;%dH", y, x)
sub gotoxy {
    my ($x, $y) = @_;

    printf("\e[%d;%dH", $x, $y);
}

# Esc[?25l (lower case L)    - Hide Cursor
#define hidecursor()          puts ("\e[?25l")
sub hidecursor {
    print "\e[?25l";
}

# Esc[?25h (lower case H)    - Show Cursor
#define showcursor()          puts ("\e[?25h")
sub showcursor {
    print "\e[?25h";
}

# get the size of the terminal.
sub get_winsize {
    require 'sys/ioctl.ph';
    CORE::warn "no TIOCGWINSZ \n" unless defined &TIOCGWINSZ;
    open(my $tty_fh, "+</dev/tty") or CORE::warn "No tty: $!\n";
    my $winsize;
    unless (ioctl($tty_fh, &TIOCGWINSZ, $winsize='')) {
        CORE::warn sprintf "ioctl TIOCGWINSZ (%08x: $!)\n", &TIOCGWINSZ;
    }
    close($tty_fh);

    #my ($col, $row, $xpixel, $ypixel) = unpack('S4', $winsize);
    my ($row, $col) = unpack('S4', $winsize);

    return ($row, $col);
}

# print notice message in color of green.
sub notice {
    my $message = shift;

    print color "green";
    print "$message\n";
    print color "reset";
}

# print warning message in color of yellow.
sub warning {
    my $message = shift;

    print color "yellow";
    print "$message\n";
    print color "reset";
}

# print fatal_warning message in color of red.
sub fatal_warning {
    my $message = shift;

    print color "red";
    print "$message\n";
    print color "reset";
}

# print attention message in color of blue.
sub attention {
    my $message = shift;

    print color "blue";
    print "$message\n";
    print color "reset";
}

# print debug infomation to stderr.
sub debug_stdout
{
    my $debug = shift;

	if ($debug)
	{
		my ($msg) = @_;
		print STDERR "$msg\n";
	}
}

sub get_now_time {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    my $now_time = sprintf("%d.%d.%d %d:%d:%d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

    return "[$now_time]";
}

sub print_error
{
    my ($string,$string2, $file, $line) = @_;
    use File::Basename;
    $file = basename($file);
    chomp $string;

    print STDOUT get_now_time() . $string . "[" . $file . ":" . $line . "]" . $string2."\n";

}

# print_log("[Notice][name]","xxxx", __FILE__, __LINE__);
sub print_log
{
    my ($method, $string, $file, $line) = @_;
    use File::Basename;
    $file = basename($file);
    chomp $string;
    my $components = '[Trace][';
    if($method eq 'main'){
        $components .= 'main]'
    } else{
        $components .= $method . "]";
    }
    print STDOUT get_now_time() . $components . "[" . $file . ":" . $line . "]" . $string. "\n";
}

sub trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Retrieve the name of the current function
sub __FUNC__ { (caller(1))[3] . '()' }
# display the name of the current function
sub __func__ { (caller(1))[3] . '(' . join(', ', @_) . ')' }

use constant DEFAULT_FILE_OPEN_MODE => 'r';
sub fopen
{
    my ($file, $mode) = @_;
    my $fh;

    my $err_msg;

    if(!defined($file) || $file eq "") {
        return -1;
    }

    if(!defined($mode) || $file eq "") {
        $mode = DEFAULT_FILE_OPEN_MODE;
    }

    if($mode ne "r" && $mode ne "r+"
       && $mode ne "w" && $mode ne "w+"
       && $mode ne "a" && $mode ne "a+" ) {
        print_log("[Error][" . __FUNC__. "]", "open file [$file] ERROR: [$mode] is invalid",
                  __FILE__, __LINE__);

        return -1;
    }

    $fh = new FileHandle "$file", "$mode";
    if(defined $fh) {
        return $fh;

    } else {
        print_log("[Error][" . __FUNC__. "]", "open file [$file] [$mode] ERROR: [$@]",
                  __FILE__, __LINE__);
        return -1;
    }
}

#@param $dir_path dir to list
#@param $files file list reference
#@param $tag static empty dir or not,1:yes, 0:no
sub print_filelist_of_dir {
    my ($dir_path, $tag)  = @_;
    my @dirs = ( $dir_path . '/' );

    my ($dir, $file);
    print "Start to list the files\n";
    while ($dir = pop(@dirs)) {
        local *DH;
        if (!opendir (DH, $dir)) {
            print "[Fail][Can't open the dir: $dir: $!] \n";
            next;
        }
        foreach (readdir(DH)) {
            if ($_ eq '.' || $_ eq '..') {
                next;
            }
            $file = $dir . $_;
            if (!-l $file && -d _) {
                $file .= '/';
                push (@dirs, $file);
                if (defined $tag && $tag) {
                    print "$file\n";
                }
            }else {
                print "$file\n";
            }
        }
        closedir(DH);
    }
    print "End of list the files\n";
}

my $warnings = 0;

# Print a usuage message on a unknown option.
# Requires my patch to Getopt::Std of 25 Feb 1999.
$SIG {__WARN__} = sub {
    if (substr ($_[0], 0, 14) eq "Unknown option") {die "Usage"};
    require File::Basename;
    $0 = File::Basename::basename ($0);
    $warnings = 1;
    warn "$0: @_";
};

$SIG {__DIE__} = sub {
    require File::Basename;
    $0 = File::Basename::basename ($0);
    if ( substr($_ [0], 0,  5) eq "Usage") {
    	my $usage = shift;
        die <<EOF;
$usage;
EOF
    }
    die "$0: @_";
};


################################################################
my %gAnswerSize;
my %gCheckAnswerFct;
my %gHelper;
my %gOption;

$gOption{'default'} = 0;

# Create a temporary directory
#
# They are a lot of small utility programs to create temporary files in a
# secure way, but none of them is standard. So I wrote this
sub make_tmp_dir {
  my $prefix = shift;
  my $tmp;
  my $serial;
  my $loop;

  $tmp = defined($ENV{'TMPDIR'}) ? $ENV{'TMPDIR'} : '/tmp';

  # Don't overwrite existing user data
  # -> Create a directory with a name that didn't exist before
  #
  # This may never succeed (if we are racing with a malicious process), but at
  # least it is secure
  $serial = 0;
  for (;;) {
    # Check the validity of the temporary directory. We do this in the loop
    # because it can change over time
    if (not (-d $tmp)) {
      print_error('"' . $tmp . '" is not a directory.' . "\n\n");
      exit -1;
    }
    if (not ((-w $tmp) && (-x $tmp))) {
      print_error('"' . $tmp . '" should be writable and executable.' . "\n\n");
      exit -1;
    }

    # Be secure
    # -> Don't give write access to other users (so that they can not use this
    # directory to launch a symlink attack)
    if (mkdir($tmp . '/' . $prefix . $serial, 0755)) {
      last;
    }

    $serial++;
    if ($serial % 200 == 0) {
      print STDERR 'Warning: The "' . $tmp . '" directory may be under attack.' . "\n\n";
    }
  }

  return $tmp . '/' . $prefix . $serial;
}

# Determine whether SELinux is enabled.
sub is_selinux_enabled {
   if (-x "/usr/sbin/selinuxenabled") {
      my $rv = system("/usr/sbin/selinuxenabled");
      return ($rv eq 0);
   } else {
      return 0;
   }
}

# Convert a string to its equivalent shell representation
sub shell_string {
  my $single_quoted = shift;

  $single_quoted =~ s/'/'"'"'/g;
  # This comment is a fix for emacs's broken syntax-highlighting code
  return '\'' . $single_quoted . '\'';
}

# chmod() that reports errors
sub safe_chmod {
  my $mode = shift;
  my $file = shift;

  if (chmod($mode, $file) != 1) {
    print_error('Unable to change the access rights of the file ' . $file . '.'
          . "\n\n");
  }
}

# Remove leading and trailing whitespaces
sub remove_whitespaces {
  my $string = shift;

  $string =~ s/^\s*//;
  $string =~ s/\s*$//;
  return $string;
}

# Execute the command passed as an argument
# _without_ interpolating variables (Perl does it by default)
sub direct_command {
  return `$_[0]`;
}

# If there is a pid for this process, consider it running.
sub check_is_running {
  my $proc_name = shift;
  my $rv = system(shell_string($gHelper{'pidof'}) . " " . $proc_name . " > /dev/null");
  return $rv eq 0;
}

# Emulate a simplified ls program for directories
sub internal_ls {
  my $dir = shift;
  my @fn;

  opendir(LS, $dir) or return ();
  @fn = grep(!/^\.\.?$/, readdir(LS));
  closedir(LS);

  return @fn;
}


# Emulate a simplified dirname program
sub internal_dirname {
  my $path = shift;
  my $pos;

  $path = dir_remove_trailing_slashes($path);

  $pos = rindex($path, '/');
  if ($pos == -1) {
    # No slash
    return '.';
  }

  if ($pos == 0) {
    # The only slash is at the beginning
    return '/';
  }

  return substr($path, 0, $pos);
}

# Compares variable length version strings against one another.
# Returns 1 if the first version is greater, -1 if the second
# version is greater, or 0 if they are equal.
sub dot_version_compare {
  my $str1 = shift;
  my $str2 = shift;

  if ("$str1" eq '' or "$str2" eq '') {
    if ("$str1" eq '' and "$str2" eq '') {
      return 0;
    } else {
      return (("$str1" eq '') ? -1 : 1);
    }
  }

  if ("$str1" =~ /[^0-9\.]+/ or "$str2" =~ /[^0-9\.]+/) {
    print_error("Bad character detected in dot_version_compare.\n");
  }

  my @arr1 = split(/\./, "$str1");
  my @arr2 = split(/\./, "$str2");
  my $indx = 0;
  while(1) {
     if (!defined $arr1[$indx] and !defined $arr2[$indx]) {
        return 0;
     }

     $arr1[$indx] = 0 if not defined $arr1[$indx];
     $arr2[$indx] = 0 if not defined $arr2[$indx];

     if ($arr1[$indx] != $arr2[$indx]) {
        return (($arr1[$indx] > $arr2[$indx]) ? 1 : -1);
     }
     $indx++;
  }
  print_error("NOT REACHED IN DOT_VERSION_COMPARE\n");
}

# Contrary to a popular belief, 'which' is not always a shell builtin command.
# So we can not trust it to determine the location of other binaries.
# Moreover, SuSE 6.1's 'which' is unable to handle program names beginning with
# a '/'...
#
# Return value is the complete path if found, or '' if not found
sub internal_which {
  my $bin = shift;

  if (substr($bin, 0, 1) eq '/') {
    # Absolute name
    if ((-f $bin) && (-x $bin)) {
      return $bin;
    }
  } else {
    # Relative name
    my @paths;
    my $path;

    if (index($bin, '/') == -1) {
      # There is no other '/' in the name
      @paths = split(':', $ENV{'PATH'});
      foreach $path (@paths) {
   my $fullbin;

   $fullbin = $path . '/' . $bin;
   if ((-f $fullbin) && (-x $fullbin)) {
     return $fullbin;
   }
      }
    }
  }

  return '';
}

# Check if a file name exists
sub file_name_exist {
  my $file = shift;

  # Note: We must test for -l before, because if an existing symlink points to
  #       a non-existing file, -e will be false
  return ((-l $file) || (-e $file))
}

# Remove trailing slashes in a dir path
sub dir_remove_trailing_slashes {
  my $path = shift;

  for(;;) {
    my $len;
    my $pos;

    $len = length($path);
    if ($len < 2) {
      # Could be '/' or any other character. Ok.
      return $path;
    }

    $pos = rindex($path, '/');
    if ($pos != $len - 1) {
      # No trailing slash
      return $path;
    }

    # Remove the trailing slash
    $path = substr($path, 0, $len - 1)
  }
}

# Emulate a simplified basename program
sub internal_basename {
  return substr($_[0], rindex($_[0], '/') + 1);
}

#############################################################
my $cTerminalLineSize = 79;

# Wordwrap system: append some content to the output
sub append_output {
  my $output = shift;
  my $pos = shift;
  my $append = shift;

  $output .= $append;
  $pos += length($append);
  if ($pos >= $cTerminalLineSize) {
    $output .= "\n";
    $pos = 0;
  }

  return ($output, $pos);
}

# Wordwrap system: deal with the next character
sub wrap_one_char {
  my $output = shift;
  my $pos = shift;
  my $word = shift;
  my $char = shift;
  my $reserved = shift;
  my $length;

  if (not (($char eq "\n") || ($char eq ' ') || ($char eq ''))) {
    $word .= $char;

    return ($output, $pos, $word);
  }

  # We found a separator.  Process the last word

  $length = length($word) + $reserved;
  if (($pos + $length) > $cTerminalLineSize) {
    # The last word doesn't fit in the end of the line. Break the line before
    # it
    $output .= "\n";
    $pos = 0;
  }
  ($output, $pos) = append_output($output, $pos, $word);
  $word = '';

  if ($char eq "\n") {
    $output .= "\n";
    $pos = 0;
  } elsif ($char eq ' ') {
    if ($pos) {
      ($output, $pos) = append_output($output, $pos, ' ');
    }
  }

  return ($output, $pos, $word);
}

# Wordwrap system: word-wrap a string plus some reserved trailing space
sub wrap {
  my $input = shift;
  my $reserved = shift;
  my $output;
  my $pos;
  my $word;
  my $i;

  if (!defined($reserved)) {
      $reserved = 0;
  }

  $output = '';
  $pos = 0;
  $word = '';
  for ($i = 0; $i < length($input); $i++) {
    ($output, $pos, $word) = wrap_one_char($output, $pos, $word,
                                           substr($input, $i, 1), 0);
  }
  # Use an artifical last '' separator to process the last word
  ($output, $pos, $word) = wrap_one_char($output, $pos, $word, '', $reserved);

  return $output;
}

# Check the validity of an answer whose type is yesno
# Return a clean answer if valid, or ''
sub check_answer_yesno {
  my $answer = shift;
  my $source = shift;

  if (lc($answer) =~ /^y(es)?$/) {
    return 'yes';
  }

  if (lc($answer) =~ /^n(o)?$/) {
    return 'no';
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid. It must be one of "y" or "n".' . "\n\n", 0);
  }
  return '';
}

$gAnswerSize{'yesno'} = 3;
$gCheckAnswerFct{'yesno'} = \&check_answer_yesno;

# Check the validity of an answer based on its type
# Return a clean answer if valid, or ''
sub check_answer {
  my $answer = shift;
  my $type = shift;
  my $source = shift;

  if (not defined($gCheckAnswerFct{$type})) {
    die 'check_answer(): type ' . $type . ' not implemented :(' . "\n\n";
  }
  return &{$gCheckAnswerFct{$type}}($answer, $source);
}

# Ask a question to the user and propose an optional default value
# Use this when you don't care about the validity of the answer
sub query {
    my $message = shift;
    my $defaultreply = shift;
    my $reserved = shift;
    my $reply;
    my $default_value = $defaultreply eq '' ? '' : ' [' . $defaultreply . ']';
    my $terse = 'no';

    # Allow the script to limit output in terse mode.  Usually dictated by
    # vix in a nested install and the '--default' option.
    #if (db_get_answer_if_exists('TERSE')) {
    #  $terse = db_get_answer('TERSE');
    #  if ($terse eq 'yes') {
    #    $reply = remove_whitespaces($defaultreply);
    #    return $reply;
    #  }
    #}

    # Reserve some room for the reply
    print wrap($message . $default_value, 1 + $reserved);

    # This is what the 1 is for
    print ' ';

    if ($gOption{'default'} == 1) {
      # Simulate the enter key
      print "\n";
      $reply = '';
    } else {
      $reply = <STDIN>;
      $reply = '' unless defined($reply);
      chomp($reply);
    }

    print "\n";
    $reply = remove_whitespaces($reply);
    if ($reply eq '') {
      $reply = $defaultreply;
    }
    return $reply;
}

# Get a valid non-persistent answer to a question
# Use this when the answer shouldn't be stored in the database
sub get_answer {
  my $msg = shift;
  my $type = shift;
  my $default = shift;
  my $answer;

  if (not defined($gAnswerSize{$type})) {
    die 'get_answer(): type ' . $type . ' not implemented :(' . "\n\n";
  }
  for (;;) {
    $answer = check_answer(query($msg, $default, $gAnswerSize{$type}), $type, 'user');
    if (not ($answer eq '')) {
      return $answer;
    }
    if ($gOption{'default'} == 1) {
      print_error('Invalid default answer!' . "\n");
    }
  }
}

# Check the validity of an answer whose type is yesno
# Return a clean answer if valid, or ''
sub check_answer_binpath {
  my $answer = shift;
  my $source = shift;

  my $fullpath = internal_which($answer);
  if (not ("$fullpath" eq '')) {
    return $fullpath;
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid. It must be the complete name of a binary file.' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'binpath'} = 20;
$gCheckAnswerFct{'binpath'} = \&check_answer_binpath;

# Prompts the user if a binary is not found
# Return value is:
#  '': the binary has not been found
#  the binary name if it has been found
sub DoesBinaryExist_Prompt {
  my $bin = shift;
  my $answer;

  $answer = check_answer_binpath($bin, 'default');
  if (not ($answer eq '')) {
    return $answer;
  }

  if (get_answer('Setup is unable to find the "' . $bin . '" program on your machine. Please make sure it is installed. Do you want to specify the location of this program by hand?', 'yesno', 'yes') eq 'no') {
    return '';
  }

  return get_answer('What is the location of the "' . $bin . '" program on your machine?', 'binpath', '');
}

# Return the specific VMware product
sub vmware_product {
  return 'tools-for-linux';
}

# Set up the location of external helpers
sub initialize_external_helpers {
  my $program;
  my @programList;

  if (not defined($gHelper{'more'})) {
    $gHelper{'more'} = '';
    if (defined($ENV{'PAGER'})) {
      my @tokens;

      # The environment variable sometimes contains the pager name _followed by
      # a few command line options_.
      #
      # Isolate the program name (we are certain it does not contain a
      # whitespace) before dealing with it.
      @tokens = split(' ', $ENV{'PAGER'});
      $tokens[0] = DoesBinaryExist_Prompt($tokens[0]);
      if (not ($tokens[0] eq '')) {
        # This is _already_ a shell string
        $gHelper{'more'} = join(' ', @tokens);
      }
    }
    if ($gHelper{'more'} eq '') {
      $gHelper{'more'} = DoesBinaryExist_Prompt('more');
      if ($gHelper{'more'} eq '') {
        error('Unable to continue.' . "\n\n");
      }
      # Save it as a shell string
      $gHelper{'more'} = shell_string($gHelper{'more'});
    }
  }

  if (vmware_product() eq 'tools-for-freebsd') {
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'kldload',
                    'kldunload', 'mv', 'rm', 'ldconfig');
  } elsif (vmware_product() eq 'tools-for-solaris') {
    # Note that svcprop(1) is added for Solaris 10 and later after it is
    # guaranteed that uname(1) has been found
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'modload', 'modinfo',
                    'modunload', 'add_drv', 'rem_drv', 'update_drv',
                    'rm', 'isainfo', 'ifconfig', 'cat', 'mv', 'sed',
                    'cut','pkginfo');
  } elsif (vmware_product() eq 'server') {
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'depmod', 'insmod',
                    'lsmod', 'modprobe', 'rmmod', 'ifconfig', 'rm', 'tar',
                    'killall', 'perl', 'mv', 'touch', 'hostname', 'pidof');
  } else {
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'depmod', 'insmod',
                    'lsmod', 'modprobe', 'mv', 'rmmod', 'ifconfig', 'rm',
                    'tar', 'modinfo');
  }

  foreach $program (@programList) {
    if (not defined($gHelper{$program})) {
      $gHelper{$program} = DoesBinaryExist_Prompt($program);
      if ($gHelper{$program} eq '') {
        error('Unable to continue.' . "\n\n");
      }
    }
  }

  $gHelper{'insserv'} = internal_which('insserv');
  $gHelper{'chkconfig'} = internal_which('/sbin/chkconfig');
  $gHelper{'update-rc.d'} = internal_which('update-rc.d');
  if (vmware_product() eq 'server' &&
      $gHelper{'chkconfig'} eq '') {
         error('No initscript installer found.' . "\n\n");
  }
}


my $file = "/usr/bin/bash";
print (get_answer('The file ' . $file . ' that this program was about to '
                     . 'install already exists. Overwrite?',
                     'yesno', 'yes') eq 'yes') ? 0 : 1;
1;
