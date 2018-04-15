#!/bin/bash
function die()
{
echo "Error in $0 - Invalid Argument Count"
echo "Syntax: $0 PACKAGENAME"
echo "Syntax: $0 zlib-devel"
exit 0
}

if [ $# -ne 1 ]
then
die
else
/bin/rpm -q --queryformat "%{name}.%{arch}\n" $1
fi
