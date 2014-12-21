#!/usr/bin/env bash 

RM=/bin/rm 
PHP=/usr/bin/php 
CURL=/usr/bin/curl 
DIFF=/usr/bin/diff 
VIMDIFF=/usr/bin/vimdiff 
COLORDIFF=/usr/bin/colordiff 

usage() { 
    echo "Usage: $0 --uri=<URI> --old=<IP> --new=<IP>" 
} 

format() { 
    $PHP -R ' 
        function ksort_recursive(&$array) { 
            if (!is_array($array)) { 
                return; 
            } 
            ksort($array); 
 
            foreach (array_keys($array) as $key) { 
                ksort_recursive($array[$key]); 
            } 
        } 
        $options = JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE; 
 
        $array = json_decode($argn, true); 
        ksort_recursive($array); 
 
        echo json_encode($array, $options); 
    ' 
} 

request() { 
    $CURL -s -H "Host: $1" "http://$2$3" 
} 
 
eval set -- $( 
    getopt -q -o "h" -l "host:,uri:,old:,new:,vim,help" -- "$@" 
) 

while true; do 
    case "$1" in 
        --host)    HOST=$2; shift 2;; 
        --uri)     URI=$2;  shift 2;; 
        --old)     OLD=$2;  shift 2;; 
        --new)     NEW=$2;  shift 2;; 
        --vim)     VIM="Y"; shift 1;; 
        -h|--help) usage;   exit 0;; 
        --)                 break;; 
    esac 
done 
if [[ -z "$URI" || -z "$OLD" || -z "$NEW" ]]; then 
    usage 
    exit 1 
fi 
if [[ -z "$HOST" ]]; then 
    HOST="www.foobar.com" 
fi 
OLD_FILE=$(mktemp) 
NEW_FILE=$(mktemp) 
request "$HOST" "$OLD" "$URI" | format > $OLD_FILE 
request "$HOST" "$NEW" "$URI" | format > $NEW_FILE 
if [[ "$VIM" == "Y" ]]; then 
    $VIMDIFF $OLD_FILE $NEW_FILE 
elif [[ -x "$COLORDIFF" ]]; then 
    $COLORDIFF -u $OLD_FILE $NEW_FILE 
else 
    $DIFF -u $OLD_FILE $NEW_FILE 
fi 
$RM -f $OLD_FILE 
$RM -f $NEW_FILE 

