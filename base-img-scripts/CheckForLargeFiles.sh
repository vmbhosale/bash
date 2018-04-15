#!/bin/bash
# This script will notify sysadmins of files larger than 100M under /apps
APPS=/apps
NO_OF_LARGE_FILES=`/bin/find $APPS -type f -size +100M -exec ls -lh {} \; | awk '{ print $9 ": " $5 }' | wc -l`
if [ $NO_OF_LARGE_FILES -gt 0 ]; then
TMPFILE=/tmp/`date +%s | sha256sum | base64 | head -c 11 ; echo`.tmp
NOTIFYLIST=sysadmins
/bin/find $APPS -type f -size +100M -print0 | xargs -0 du -h | sort -nr > $TMPFILE
/bin/mail -s "Large file(s) notification!" $NOTIFYLIST < $TMPFILE
/bin/rm -rf $TMPFILE
else
echo "Good news! No large files exist under $APPS."
fi
