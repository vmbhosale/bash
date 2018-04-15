#!/bin/bash
NOW=`date +%d-%b-%Y-%H%M`
NOTIFYLIST=sysadmins
AIDECNF=/etc/system-aide.conf
AIDE=/usr/sbin/aide
CHANGEDFILES=/tmp/$NOW.txt
Encryption=/usr/bin/gpg2
CONTAINER=`hostname`-backup
GLOBALSCRIPTSLOC=/usr/local/scripts

function RECONFIGUREAIDE()
{
AIDE_DB_HOME=`/bin/cat $AIDECNF | grep "@@define DBDIR" | cut -d ' ' -f3,3`
DB_OUT=`/bin/cat $AIDECNF | grep database_out= | cut -d '/' -f2,2`
DB=`/bin/cat $AIDECNF | grep database= | cut -d '/' -f2,2`
$AIDE -c $AIDECNF --update
/bin/cp -f -p $AIDE_DB_HOME/$DB_OUT $AIDE_DB_HOME/$DB
}

$AIDE -c $AIDECNF --check | egrep -i 'removed:|added:|changed:' > $CHANGEDFILES
if [ -s "$CHANGEDFILES" ]
then
	echo "$CHANGEDFILES has some data."
	RECONFIGUREAIDE
	/bin/mail -s "AIDE Report" $NOTIFYLIST < $CHANGEDFILES
	/bin/rm -rf $CHANGEDFILES
else
	echo "$CHANGEDFILES is empty."
	/bin/rm -rf $CHANGEDFILES
fi
