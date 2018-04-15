#!/bin/bash
TMPDIR=`date +%d-%b-%Y-%H%M%S`
CONTAINER=ServerReplicationArchive
GLOBALSCRIPTSLOC=/usr/local/scripts
ADDTOCLOUD=$GLOBALSCRIPTSLOC/AddAFileToRSCloud.sh
GETAFILEFROMCLOUD=$GLOBALSCRIPTSLOC/GetAFileFromRSCloud.sh
# Encryption
Encryption=/usr/bin/gpg2

function GET()
{
echo -e -n "Please enter archive name as it is...\n"
read ARCHIVE
[ ! -d /tmp/$TMPDIR ] && mkdir -p /tmp/$TMPDIR
cd /tmp/$TMPDIR
$GETAFILEFROMCLOUD -c $CONTAINER $ARCHIVE
$Encryption --batch --passphrase $ID $ARCHIVE
/bin/rm -rf $ARCHIVE
TARCHIVE=`find . -type f | xargs basename`
/bin/tar -zxf $TARCHIVE
/bin/rm -rf $TARCHIVE
echo "All you need it at /tmp/$TMPDIR"
exit 1
}

function PUT()
{
echo -e -n "Where is temp folder location?  E.g. /tmp/27-Oct-2012-001034/ \n"
read ARCHIVELOC
if [ ! -d $ARCHIVELOC ] 
then
echo "I don't see it, typo? or you have lost your mind :) ?? Check again!!"
exit 1
else
echo -e -n "What is the archive type ? (comm,app,db,base) \n"
read ARCHIVE_TYPE
cd $ARCHIVELOC
# Below is needed else OpenLDAP breaks!
/bin/chmod 755 *
DATETIME=`date +%d-%b-%Y-%H%M%S`
/bin/tar -zcf $ARCHIVE_TYPE-$DATETIME.tar.gz *
if [ "$ARCHIVE_TYPE" == "comm" -o "$ARCHIVE_TYPE" == "app" -o "$ARCHIVE_TYPE" == "db" -o "$ARCHIVE_TYPE" == "base" ]; then
if [ -f "/root/.gnupg/.gpg-agent-info" ]; then
. "/root/.gnupg/.gpg-agent-info"
export GPG_AGENT_INFO
export SSH_AUTH_SOCK
. "/root/.bash_profile"
sleep 1
$Encryption --batch --passphrase $ID -c $ARCHIVE_TYPE-$DATETIME.tar.gz
$ADDTOCLOUD -c $CONTAINER $ARCHIVE_TYPE-$DATETIME.tar.gz.gpg
MD5=`/usr/bin/md5sum $ARCHIVE_TYPE-$DATETIME.tar.gz.gpg | awk {'print $1'}`
cd -
echo "I would have deleted unloaded archive here...."
# /bin/rm -rf $ARCHIVELOC
echo "I have put $ARCHIVE_TYPE-$DATETIME.tar.gz.gpg [$MD5] in $CONTAINER container...."
fi
else
echo "You messed it up, please try again!"
exit 1
fi
fi
}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
else
echo -e -n "So what do you want to do today (get/put) ? \n"
read ans
if [ $ans == "get" ]; then
	GET
elif [ $ans == "put" ]; then
	PUT
else
	echo "Please enter valid entry!"
	exit 1
fi
fi
