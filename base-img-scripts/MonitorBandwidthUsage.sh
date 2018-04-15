#!/bin/bash
BW_LIMIT_IN_GB=10
BW_LIMIT_IN_MB=`echo 'scale=2;'$BW_LIMIT_IN_GB'*(1024)' | bc`
NOTIFYLIST=sysadmins

function CheckBandWidth()
{
Bandwidth=`/usr/bin/vnstat --dumpdb | awk --field-separator ";" '{if($1=="m"&&$8=="1"){if($5>'$BW_LIMIT_IN_MB'){print ""$5""}}}'`
if [ -z "$Bandwidth" ]
then
  echo "Utilized bandwidth is within limits (ie. less than $BW_LIMIT_IN_GB GB)"
else
  echo "Utilized bandwidth is out of bounds (ie. more than $BW_LIMIT_IN_GB GB)"
  /bin/mail -s "Bandwidth limits are out of bounds!" $NOTIFYLIST < /dev/null
fi
}

function InitVnstatDB()
{
for interface in `netstat -i | awk {'print $1'} | grep "eth"`
do
/usr/bin/vnstat --force --delete -i $interface
/usr/bin/vnstat -u -i $interface
done
}

if [ `date +%d` != "01" ] 
then
	CheckBandWidth
else
	InitVnstatDB
fi
