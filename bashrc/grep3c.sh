#!/usr/bin/env bash

# if there is only one argument, exit

case $# in 
        1);;
        *) echo "Usage: $0 pattern";exit;;
esac;

# again - I hope the argument doesn't contain a /

sed -n '
'/$1/' !{
        # put the non-matching line in the hold buffer
        h
}
'/$1/' {
        # found a line that matches
        # add the next line to the pattern space
        N
        # exchange the previous line with the 
        # 2 in pattern space
        x
        # now add the two lines back
        G
        # and print it.
        p
        # add the three hyphens as a marker
        a\
---
        # remove first 2 lines
        s/.*\n.*\n\(.*\)$/\1/
        # and place in the hold buffer for next time
        h
}'
