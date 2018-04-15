#!/bin/bash
NOW=`date +%d-%b-%Y-%H%M`
NOTIFYLIST=sysadmins
AIDECNF=/etc/support-aide.conf
AIDE=/usr/sbin/aide
AIDE_DB_HOME=`/bin/cat $AIDECNF | grep "@@define DBDIR" | cut -d ' ' -f3,3`
DB_OUT=`/bin/cat $AIDECNF | grep database_out= | cut -d '/' -f2,2`
DB=`/bin/cat $AIDECNF | grep database= | cut -d '/' -f2,2`
CHANGEDFILES=/tmp/$NOW.txt
# Encryption
Encryption=/usr/bin/gpg2
# Cloud Backup Config
RSCLOUDACTIVE=1 # cloud backups inactive when 0
CONTAINER=`hostname`-backup
GLOBALSCRIPTSLOC=/usr/local/scripts
ADDTOCLOUD=$GLOBALSCRIPTSLOC/AddAFileToRSCloud.sh
REMOVEFROMCLOUD=$GLOBALSCRIPTSLOC/RemoveAFileFromRSCloud.sh

function RECONFIGUREAIDE()
{
$AIDE -c $AIDECNF --update
/bin/cp -f -p $AIDE_DB_HOME/$DB_OUT $AIDE_DB_HOME/$DB
}

function GPGENCRYPT()
{
dname=$1
fname=$2
cd $dname
if [ -f "/root/.gnupg/.gpg-agent-info" ]; then
. "/root/.gnupg/.gpg-agent-info"
export GPG_AGENT_INFO
export SSH_AUTH_SOCK
. "/root/.bash_profile"
$Encryption --batch --passphrase $ID -c $fname
/bin/rm -rf $fname
fi
}

function CLOUDPLUS()
{
fname=$(basename $1)
dname=$(dirname $1)
extension=${fname##*.}
if [ ! $extension == "gpg" ]
then
GPGENCRYPT $dname $fname
cd $dname
$ADDTOCLOUD -c $CONTAINER $fname.gpg
fi
}

function CLOUDMINUS()
{
fname=$(basename $1)
dname=$(dirname $1)
cd $dname
$REMOVEFROMCLOUD -c $CONTAINER $fname
}

function AIDEINIT()
{
echo "Initializing init....it may take several minutes, please be patient."
$AIDE -c $AIDECNF --init 
/bin/cp -f -p $AIDE_DB_HOME/$DB_OUT $AIDE_DB_HOME/$DB

}

[ ! -f $AIDE_DB_HOME/$DB ] && AIDEINIT
$AIDE -c $AIDECNF --check | egrep -i 'removed:|added:|changed:' > $CHANGEDFILES
while read line
do
OP=$(echo $line | awk -F':' '{print $1}' | tr -d ' ')
FILE=$(echo $line | awk -F':' '{print $2}' | tr -d ' ')
ISFILE=`file $FILE | grep -c -v ": directory"`
if [ $ISFILE -eq 0 ]
then
echo "I don't deal with directories BUT only files!"
else
if [ "$OP" == "removed" ]
then
CLOUDMINUS $FILE
elif [ "$OP" == "added" ]
then
CLOUDPLUS $FILE
elif [ "$OP" == "changed" ]
then
CLOUDMINUS $FILE
CLOUDPLUS $FILE
else
echo "I dont recognize this operation! Sorry!!"
fi
fi
done < $CHANGEDFILES
if [ -s "$CHANGEDFILES" ]
then
	echo "$CHANGEDFILES has some data."
	RECONFIGUREAIDE
	/bin/mail -s "Backup Report" $NOTIFYLIST < $CHANGEDFILES
	/bin/rm -rf $CHANGEDFILES
else
	echo "$CHANGEDFILES is empty."
	/bin/rm -rf $CHANGEDFILES
fi
