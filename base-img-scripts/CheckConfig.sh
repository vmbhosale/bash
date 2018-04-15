#!/bin/bash
PROPS=dummy
BASE="/apps/.Support"

function DECRYPTCONFIG()
{
. /root/.bash_profile
/bin/echo "$PROPS has following params:"
for param in `/bin/cat $PROPS | grep ENC | cut -d '(' -f2,2 | cut -d ')' -f1,1`
do
$JASYPT_HOME/bin/decrypt.sh input="$param" password=$ID verbose=false
done
}

PROPS=$BASE/AppProperties/config.properties
DECRYPTCONFIG
