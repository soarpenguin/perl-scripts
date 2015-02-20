#!/usr/bin/env bash

#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
#curdir=$(cd `dirname $0`; pwd)

set -x
export PS4='+ [`basename ${BASH_SOURCE[0]}`:$LINENO ${FUNCNAME[0]} \D{%F %T} $$ ] '
#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
curdir=$(cd "$(dirname "$0")"; pwd)
#curdir=$(dirname $(readlink -f "$0")) #bad use under darwin

MYNAME="${0##*/}"
report_err() { echo "${MYNAME}: Error: $*" >&2 ; }

cleanup() { rm -f "tmp.*" ; }
trap cleanup EXIT

#
# Auto-detect the package manager.
#
if   command -v apt-get >/dev/null; then package_manager="apt"
elif command -v yum     >/dev/null; then package_manager="yum"
elif command -v port    >/dev/null; then package_manager="port"
elif command -v brew    >/dev/null; then package_manager="brew"
elif command -v pacman  >/dev/null; then package_manager="pacman"
fi

#
# Auto-detect the downloader.
#
if   command -v wget >/dev/null; then downloader="wget"
elif command -v curl >/dev/null; then downloader="curl"
fi

# Reset text attributes to normal + without clearing screen.
alias reset="tput sgr0"

# Color-echo.
# arg $1 = message
# arg $2 = Color
function cecho() {
    echo "${2}${1}"
    reset # Reset to normal.
    return
}

# Ask for the administrator password upfront
#sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
#while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

function install_packages()
{
	case "$package_manager" in
		apt)	$sudo apt-get install -y $* || return $? ;;
		yum)	$sudo yum install -y $* || return $?     ;;
		port)   $sudo port install $* || return $?       ;;
		brew)
			local brew_owner="$(/usr/bin/stat -f %Su "$(command -v brew)")"
			sudo -u "$brew_owner" brew install $* ||
			sudo -u "$brew_owner" brew upgrade $* || return $?
			;;
		pacman)
			local missing_pkgs="$(pacman -T $*)"

			if [[ -n "$missing_pkgs" ]]; then
				$sudo pacman -S $missing_pkgs || return $?
			fi
			;;
		"")	_warning "Could not determine Package Manager. Proceeding anyway." ;;
	esac
}

#
# Downloads a URL.
#
function download()
{
	local url="$1"
	local dest="$2"

	[[ -d "$dest" ]] && dest="$dest/${url##*/}"
	[[ -f "$dest" ]] && return

	case "$downloader" in
		wget) wget -c -O "$dest.part" "$url" || return $?         ;;
		curl) curl -f -L -C - -o "$dest.part" "$url" || return $? ;;
		"")
			_print_fatal "Could not find wget or curl"
			return 1
			;;
	esac

	mv "$dest.part" "$dest" || return $?
}

#
# Extracts an archive.
#
function extract()
{
	local archive="$1"
	local dest="${2:-${archive%/*}}"

	case "$archive" in
		*.tgz|*.tar.gz) tar -xzf "$archive" -C "$dest" || return $? ;;
		*.tbz|*.tbz2|*.tar.bz2)	tar -xjf "$archive" -C "$dest" || return $? ;;
		*.zip) unzip "$archive" -d "$dest" || return $? ;;
		*)
			_print_fatal "Unknown archive format: $archive"
			return 1
			;;
	esac
}

#
# Prints usage information.
#
function usage()
{
	cat <<USAGE
usage: command.sh [OPTIONS] [xxx [VERSION] [-- CONFIGURE_OPTS ...]]

Options:

	-m, --md5 MD5		MD5 checksum of the archive
	--no-download		Use the previously downloaded archive
	-V, --version		Prints the version
	-h, --help		    Prints this message

Examples:

	$ command.sh -V

USAGE
}

#
# Parses command-line options.
#  usage: parse_options "$@" || exit $?
#
function parse_options()
{
	local argv=()

	while [[ $# -gt 0 ]]; do
		case $1 in
			-m|--md5)
				md5="$2"
				shift 2
				;;
			--no-download)
				no_download=1
				shift
				;;
			-V|--version)
				_print_fatal "$0: $version"
				exit
				;;
			-h|--help)
				usage
				exit
				;;
			--)
				shift
				configure_opts=("$@")
				break
				;;
			-*)
				_print_fatal "command line: unrecognized option $1" >&2
				return 1
				;;
			*)
				argv+=($1)
				shift
				;;
		esac
	done

	case ${#argv[*]} in
		2)
			software="${argv[0]}"
			version="${argv[1]}"
			;;
		1)
			software="${argv[0]}"
			version=""
			;;
		0)
			usage 1>&2
			return 1
			;;
		*)
			usage 1>&2
			return 1
			;;
	esac
}

#tar -cf - ./* | ( cd "${dir}" && tar -xf - )
#if [[ "${PIPESTATUS[0]}" -ne 0 || "${PIPESTATUS[1]}" -ne 0 ]]; then
#  echo "Unable to tar files to ${dir}" >&2
#fi

#'-t FD'
#     True if file descriptor FD is open and refers to a terminal.

# colour macros
if [ -t 1 ]
then
    BLACK="$( echo -e "\e[30m" )"
    RED="$( echo -e "\e[31m" )"
    GREEN="$( echo -e "\e[32m" )"
    YELLOW="$( echo -e "\e[33m" )"
    BLUE="$( echo -e "\e[34m" )"
    PURPLE="$( echo -e "\e[35m" )"
    CYAN="$( echo -e "\e[36m" )"
    WHITE="$( echo -e "\e[37m" )"

    HL_BLACK="$( echo -e "\e[30;1m" )"
    HL_RED="$( echo -e "\e[31;1m" )"
    HL_GREEN="$( echo -e "\e[32;1m" )"
    HL_YELLOW="$( echo -e "\e[33;1m" )"
    HL_BLUE="$( echo -e "\e[34;1m" )"
    HL_PURPLE="$( echo -e "\e[35;1m" )"
    HL_CYAN="$( echo -e "\e[36;1m" )"
    HL_WHITE="$( echo -e "\e[37;1m" )"

    BG_BLACK="$( echo -e "\e[40m" )"
    BG_RED="$( echo -e "\e[41m" )"
    BG_GREEN="$( echo -e "\e[42m" )"
    BG_YELLOW="$( echo -e "\e[43m" )"
    BG_BLUE="$( echo -e "\e[44m" )"
    BG_PURPLE="$( echo -e "\e[45m" )"
    BG_CYAN="$( echo -e "\e[46m" )"
    BG_WHITE="$( echo -e "\e[47m" )"

    NORMAL="$( echo -e "\e[0m" )"
fi

_black()  { echo "$BLACK""$@""$NORMAL";}
_red()    { echo "$RED""$@""$NORMAL";}
_green()  { echo "$GREEN""$@""$NORMAL";}
_yellow() { echo "$YELLOW""$@""$NORMAL";}
_blue()   { echo "$BLUE""$@""$NORMAL";}
_purple() { echo "$PURPLE""$@""$NORMAL";}
_cyan()   { echo "$CYAN""$@""$NORMAL";}
_white()  { echo "$WHITE""$@""$NORMAL";}

_hl_black()  { echo "$HL_BLACK""$@""$NORMAL";}
_hl_red()    { echo "$HL_RED""$@""$NORMAL";}
_hl_green()  { echo "$HL_GREEN""$@""$NORMAL";}
_hl_yellow() { echo "$HL_YELLOW""$@""$NORMAL";}
_hl_blue()   { echo "$HL_BLUE""$@""$NORMAL";}
_hl_purple() { echo "$HL_PURPLE""$@""$NORMAL";}
_hl_cyan()   { echo "$HL_CYAN""$@""$NORMAL";}
_hl_white()  { echo "$HL_WHITE""$@""$NORMAL";}

_bg_black()  { echo "$BG_BLACK""$@""$NORMAL";}
_bg_red()    { echo "$BG_RED""$@""$NORMAL";}
_bg_green()  { echo "$BG_GREEN""$@""$NORMAL";}
_bg_yellow() { echo "$BG_YELLOW""$@""$NORMAL";}
_bg_blue()   { echo "$BG_BLUE""$@""$NORMAL";}
_bg_purple() { echo "$BG_PURPLE""$@""$NORMAL";}
_bg_cyan()   { echo "$BG_CYAN""$@""$NORMAL";}
_bg_white()  { echo "$BG_WHITE""$@""$NORMAL";}

# helper functions
_message() {
    echo "$@" >&2
}

_trace() {
    echo $(_hl_blue '  ->') "$@" >&2
}

_notice() {
    echo $(_hl_green '==>') "$@" >&2
}

_warning() {
    echo $(_hl_yellow '==> WARNING:') "$@" >&2
}

_fatal() {
    echo $(_hl_red '==> ERROR:') "$@" >&2
    exit 1
}

_print_fatal() {
    echo $(_hl_red '==> ERROR:') "$@" >&2
}

#_print_fatal "Command '$cmd' does not exist!"
ERR_ACCESS=3
check_user() {
    owner=`stat -c "%u" "$0"`;
    current_userid=`id -u`;

    if [ x"$owner" != x"$current_userid" ]; then
        exit ${ERR_ACCESS};
    fi
}

pushd . &>/dev/null
cd ../../ && touch test.file;
popd 

try() {
    "$@"
    if [ $? -ne 0 ]; then
        _fatal "Command failure: $@"
    fi
}

debug=1
function log()
{    
    local epath=$(pwd)
    local timestamp=$(date +%Y%m%d-%H:%M:%S)
    #echo "##########################################################"
    echo "[$timestamp][$epath]$1"
}

function do_cmd()
{    
    log "[exec] $*   please wait............"
    if [ $debug -eq 1 ];then
        $@
    else
        $@ >/dev/null 2>&1
    fi
    if [[ $? -ne 0 ]];then
        log "[fail] $@"
        exit 1
    else
        log "[succ] $@"
    fi
}

# root/bin   root/log
function log_error()
{
    local ERRFILE=$(dirname $0)/../log/err.log
    if [ -f ${ERRFILE} ]; then
        echo $* >> ${ERRFILE}
    else
        echo $*
    fi
}

function log_link()
{
    local LOGFILE=$(dirname $0)/../log/links.log
    if [ -d $(dirname $LOGFILE) ]; then
        echo $* >> ${LOGFILE}
    else
        echo $*
    fi
}

function log_msg()
{
    local LOGFILE=$(dirname $0)/../log/msg.log
    if [ -d $(dirname $LOGFILE) ]; then
        echo $* >> ${LOGFILE}
    else
        echo $*
    fi
}

function command_exists {
    hash "$1" 2>/dev/null ;
}

# Use the funtions provided by Red Hat or use our own
if [ -f /etc/rc.d/init.d/functions ]
then
  . /etc/rc.d/init.d/functions
else
  function action {
    echo "$1"
    shift
    $@
  }
  function success {
    echo -n "Success"
  }
  function failure {
    echo -n "Failed"
  }
fi

action "Message echo:" ls -l
ls && \
success "Success message." || \
failure "Failure message."

