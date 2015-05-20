#! /bin/sh

# Create the AUTHORS file, by searching the git history.

# Run as "AUTHORS.sh" to get complete history
# Run with "AUTHORS.sh commitish..commitish" for history between tags

# shortlog will canonicalize the names using the file .mailmap
git shortlog -s ${1-} |
cut -b8- # strip the commit counts
