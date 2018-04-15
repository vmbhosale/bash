#!/bin/bash
NOW=`date +%d-%b-%Y-%H%M`
SSHPORT=422
DBSERVER=10.177.15.223
DBUSER=NGNkOTQyYjI
DEPLOYMGR=MDQ1ZjYzYWM
SHELLSCRIPT_DB_PLAYAREA=/apps/.Support/ScriptDBPlayArea
MYIP="000.000.000.001"
NOTIFYLIST=sysadmins
RECORD_DATE=`date +%Y-%m-%d" "%H":"%M":"%S`
OUTGOING_TMPFILE=/tmp/`/usr/bin/openssl rand -base64 32 | sha256sum | base64 | head -c 15 ; echo`.csv
DiskInQuestion=/apps/data01

cd $DiskInQuestion
DISKSPACE_KB=`du . -sk | awk {'print $1'} | /usr/bin/tr -d '[:alpha:]' | /bin/sed 's/[<>]//g'`
DISKSPACE_MB=`echo ${DISKSPACE_KB}/1024 | bc`

DISKINFO="$RECORD_DATE,$MYIP,<diskinfo><diskusage>$DISKSPACE_MB</diskusage><billable>1</billable></diskinfo>"
/bin/echo "$DISKINFO" > $OUTGOING_TMPFILE
/bin/chmod 444 $OUTGOING_TMPFILE
/bin/su - $DEPLOYMGR -c "/usr/bin/scp -P $SSHPORT $INCOMING_TMPFILE $OUTGOING_TMPFILE $DBUSER@$DBSERVER:$SHELLSCRIPT_DB_PLAYAREA"
if [ "$?" -eq "0" ]; then
	echo "Disk usage data has been scp'ed."
else
	echo "Bandwidth data could not be transferred."
	/bin/mail -s "Disk usage data could not be trasferred!" $NOTIFYLIST < /dev/null
fi
/bin/rm -rf $OUTGOING_TMPFILE
