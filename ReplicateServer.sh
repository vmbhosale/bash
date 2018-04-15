#!/bin/bash
NOW=`date +%d-%b-%Y-%H%M%S`
LOGFILE=/tmp/$NOW.log
STARTTIME=`date`
ROOTPASS="blah"
DESTLOC="DONTKNOW" # us,uk, other
RSCLOUDACTIVE=1 # cloud backups inactive when 0
CONTAINER=ServerReplicationArchive
GLOBALSCRIPTSLOC=/usr/local/scripts
GETAFILEFROMCLOUD=$GLOBALSCRIPTSLOC/GetAFileFromRSCloud.sh
ARCHIVES_HOME=ServerReplicationArchive
COMMARCHIVE="comm-29-Oct-2012-131134.tar.gz.gpg"
COMMARCHIVEMD5="9998e2d505e32649ef481bc5b36aebe9"
APPARCHIVE="app-29-Oct-2012-142009.tar.gz.gpg"
APPARCHIVEMD5="72e51ceec793de5a637617ab7f7b3338"
DBARCHIVE="db-28-Oct-2012-184717.tar.gz.gpg"
DBARCHIVEMD5="eabb64bfe8adadbdf074bab80a04ed97"
BASEARCHIVE="base-10-Sep-2012-155800.tar.gz.gpg"
BASEARCHIVEMD5="397e920a4b0a5b84b6a46f9a00ca7cb2"
ARCHIVE_TYPE="DONTKNOW" # Comm, DB, App
TMPDIR=`date +%s | sha256sum | base64 | head -c 11 ; echo`
# Encryption
Encryption=/usr/bin/gpg2

function GPGDECRYPT()
{
fname=$1
if [ -f "/root/.gnupg/.gpg-agent-info" ]; then
. "/root/.gnupg/.gpg-agent-info"
export GPG_AGENT_INFO
export SSH_AUTH_SOCK
. "/root/.bash_profile"
$Encryption --batch --passphrase $ID $fname
/bin/rm -rf $fname
fi
}

function PRE_OPS()
{
echo "Performing pre-migration work on $DESTIP..."
echo "Performing pre-migration work on $DESTIP..." >> $LOGFILE
/usr/bin/sshpass -p $ROOTPASS ssh -t root@$DESTIP <<EOF
/usr/bin/wget -O /etc/yum.repos.d/drivesrvr.repo "http://agentrepo.drivesrvr.com/redhat/drivesrvr.repo"
/usr/bin/yum -y install mailx nscd nss-pam-ldapd pam_ldap openldap-clients gd.x86_64 xinetd openssl098e-0.9.8e-17.el6.centos.2.x86_64 driveclient
/bin/rpm -i http://dl.fedoraproject.org/pub/epel/6/x86_64/vnstat-1.11-1.el6.x86_64.rpm
/usr/bin/yum -y update
/bin/rpm -e tmpwatch ed traceroute lftp ftp telnet ntp ntpdate dhcp-common dhclient vim-enhanced parted vim-common at
/usr/bin/yum -y dos2unix
/bin/echo "108.166.91.217 ldapmaster.eusiness.com ldapmaster" >> /etc/hosts
/bin/echo "108.171.184.72 nagiosmaster.eusiness.com nagiosmaster" >> /etc/hosts
EOF
}

function GETARCHIVE()
{
/bin/mkdir -p /tmp/$TMPDIR
cd /tmp/$TMPDIR
if [ "$RSCLOUDACTIVE" -eq "1" ]; then
if [ "$ARCHIVE_TYPE" == "comm" ]; then
$GETAFILEFROMCLOUD -c $CONTAINER $COMMARCHIVE
FILEMD5=`/usr/bin/md5sum $COMMARCHIVE | awk {'print $1'} | tr -d ' '`
[ "$FILEMD5" != "$COMMARCHIVEMD5" ] && /bin/echo "MD5 failed, $COMMARCHIVE has been tampered, you shall not pass!!" && exit 1
GPGDECRYPT $COMMARCHIVE
/bin/echo "Woohhooo, I found it on rackspace cloud and checked it for MD5 integrity..."
elif [ "$ARCHIVE_TYPE" == "app" ]; then
$GETAFILEFROMCLOUD -c $CONTAINER $APPARCHIVE
FILEMD5=`/usr/bin/md5sum $APPARCHIVE | awk {'print $1'} | tr -d ' '`
[ "$FILEMD5" != "$APPARCHIVEMD5" ] && /bin/echo "MD5 failed, $APPARCHIVE has been tampered, you shall not pass!!" && exit 1
GPGDECRYPT $APPARCHIVE
/bin/echo "Woohhooo, I found it on rackspace cloud and checked it for integrity..."
elif [ "$ARCHIVE_TYPE" == "db" ]; then
$GETAFILEFROMCLOUD -c $CONTAINER $DBARCHIVE
FILEMD5=`/usr/bin/md5sum $DBARCHIVE | awk {'print $1'} | tr -d ' '`
[ "$FILEMD5" != "$DBARCHIVEMD5" ] && /bin/echo "MD5 failed, $DBARCHIVE has been tampered, you shall not pass!!" && exit 1
GPGDECRYPT $DBARCHIVE
/bin/echo "Woohhooo, I found it on rackspace cloud and checked it for integrity..."
elif [ "$ARCHIVE_TYPE" == "base" ]; then
$GETAFILEFROMCLOUD -c $CONTAINER $BASEARCHIVE
FILEMD5=`/usr/bin/md5sum $BASEARCHIVE | awk {'print $1'} | tr -d ' '`
[ "$FILEMD5" != "$BASEARCHIVEMD5" ] && /bin/echo "MD5 failed, $BASEARCHIVE has been tampered, you shall not pass!!" && exit 1
GPGDECRYPT $BASEARCHIVE
/bin/echo "Woohhooo, I found it on rackspace cloud and checked it for integrity..."
else
/bin/echo "This scenario is not possible! Something is seriously wrong!!"
exit 1
fi
fi
}

function MAIN_OP_COMM()
{
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? "
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? " >> $LOGFILE
if [ "$RSCLOUDACTIVE" -eq "1" ];then
GETARCHIVE
COMMARCHIVE=`echo ${COMMARCHIVE%.*}`
/usr/bin/sshpass -p $ROOTPASS scp -P 22 /tmp/$TMPDIR/$COMMARCHIVE root@$DESTIP:/ 
if [ $? -eq 0 ];then
/bin/rm -rf /tmp/$TMPDIR
else
echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..."
exit 1
fi
else
[ ! -f $ARCHIVES_HOME/$ARCHIVE_TYPE/$COMMARCHIVE.gpg ] && /bin/echo "I don't see $ARCHIVES_HOME/$ARCHIVE_TYPE/$COMMARCHIVE.gpg , please try again!!"
GPGDECRYPT $COMMARCHIVE
COMMARCHIVE=`echo ${COMMARCHIVE%.*}`
/usr/bin/sshpass -p $ROOTPASS scp -P 22 $ARCHIVES_HOME/$ARCHIVE_TYPE/$COMMARCHIVE root@$DESTIP:/
[ $? -ne 0 ] && echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..." && exit 1
fi
/usr/bin/sshpass -p $ROOTPASS ssh -t root@$DESTIP <<EOF
cd /
/bin/tar -zxvf $COMMARCHIVE
if [ $? -eq 0 ]; then 
/bin/rm -rf $COMMARCHIVE
/usr/sbin/authconfig --enableldap --enablemd5 --enableshadow --enableldapauth --enablemkhomedir --enablelocauthorize --ldapserver=ldaps://ldapmaster.eusiness.com/ --ldapbasedn="dc=eusiness,dc=com" --updateall
/usr/sbin/postmap /etc/postfix/generic
/usr/bin/newaliases
/sbin/chkconfig --level 234 httpd on
/sbin/chkconfig --level 234 openfire on
/sbin/chkconfig --level 234 System-Start-Stop-Notification on
/sbin/chkconfig --level 234 vnstat on
/sbin/ldconfig
/sbin/init 6
fi
EOF
}

function MAIN_OP_APP()
{
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? "
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? " >> $LOGFILE
if [ "$RSCLOUDACTIVE" -eq "1" ];then
GETARCHIVE
APPARCHIVE=`echo ${APPARCHIVE%.*}`
/usr/bin/sshpass -p $ROOTPASS scp -P 22 /tmp/$TMPDIR/$APPARCHIVE root@$DESTIP:/ 
if [ $? -eq 0 ];then
/bin/rm -rf /tmp/$TMPDIR
else
echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..."
exit 1
fi
else
[ ! -f $ARCHIVES_HOME/$ARCHIVE_TYPE/$APPARCHIVE.gpg ] && /bin/echo "I don't see $ARCHIVES_HOME/$ARCHIVE_TYPE/$APPARCHIVE.gpg , please try again!!"
GPGDECRYPT $APPARCHIVE
APPARCHIVE=`echo ${APPARCHIVE%.*}`
exit 1
/usr/bin/sshpass -p $ROOTPASS scp -P 22 $ARCHIVES_HOME/$ARCHIVE_TYPE/$APPARCHIVE root@$DESTIP:/
[ $? -ne 0 ] && echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..." && exit 1
fi
/usr/bin/sshpass -p $ROOTPASS ssh -t root@$DESTIP <<EOF
cd /
/bin/tar -zxvf $APPARCHIVE
if [ $? -eq 0 ]; then 
/bin/rm -rf $APPARCHIVE
/usr/sbin/authconfig --enableldap --enablemd5 --enableshadow --enableldapauth --enablemkhomedir --enablelocauthorize --ldapserver=ldaps://ldapmaster.eusiness.com/ --ldapbasedn="dc=eusiness,dc=com" --updateall
/usr/sbin/postmap /etc/postfix/generic
/usr/bin/newaliases
/sbin/chkconfig --level 234 httpd on
/sbin/chkconfig --level 234 tomcat on
/sbin/chkconfig --level 234 System-Start-Stop-Notification on
/sbin/chkconfig --level 234 ezscheduler on
/sbin/chkconfig --level 234 vnstat on
/sbin/init 6
fi
EOF
}

function MAIN_OP_DB()
{
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? "
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? " >> $LOGFILE
if [ "$RSCLOUDACTIVE" -eq "1" ];then
GETARCHIVE
DBARCHIVE=`echo ${DBARCHIVE%.*}`
/usr/bin/sshpass -p $ROOTPASS scp -P 22 /tmp/$TMPDIR/$DBARCHIVE root@$DESTIP:/ 
if [ $? -eq 0 ];then
/bin/rm -rf /tmp/$TMPDIR
else
echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..."
exit 1
fi
else
[ ! -f $ARCHIVES_HOME/$ARCHIVE_TYPE/$DBARCHIVE.gpg ] && /bin/echo "I don't see $ARCHIVES_HOME/$ARCHIVE_TYPE/$DBARCHIVE.gpg , please try again!!"
GPGDECRYPT $DBARCHIVE
DBARCHIVE=`echo ${DBARCHIVE%.*}`
/usr/bin/sshpass -p $ROOTPASS scp -P 22 $ARCHIVES_HOME/$ARCHIVE_TYPE/$DBARCHIVE root@$DESTIP:/
[ $? -ne 0 ] && echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..." && exit 1
fi
/usr/bin/sshpass -p $ROOTPASS ssh -t root@$DESTIP <<EOF
cd /
/bin/tar -zxvf $DBARCHIVE
if [ $? -eq 0 ]; then 
/bin/rm -rf $DBARCHIVE
/usr/sbin/authconfig --enableldap --enablemd5 --enableshadow --enableldapauth --enablemkhomedir --enablelocauthorize --ldapserver=ldaps://ldapmaster.eusiness.com/ --ldapbasedn="dc=eusiness,dc=com" --updateall
/usr/sbin/postmap /etc/postfix/generic
/usr/bin/newaliases
/sbin/chkconfig --level 234 mysqld on
/sbin/chkconfig --level 234 System-Start-Stop-Notification on
/sbin/chkconfig --level 234 vnstat on
/sbin/init 6
fi
EOF
}

function MAIN_OP_BASE()
{
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? "
echo "Performing migration, this is going to take a while...why don't you grab a cup of coffee? " >> $LOGFILE
if [ "$RSCLOUDACTIVE" -eq "1" ];then
GETARCHIVE
BASEARCHIVE=`echo ${BASEARCHIVE%.*}`
/usr/bin/sshpass -p $ROOTPASS scp -P 22 /tmp/$TMPDIR/$BASEARCHIVE root@$DESTIP:/ 
if [ $? -eq 0 ];then
/bin/rm -rf /tmp/$TMPDIR
else
echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..."
exit 1
fi
else
[ ! -f $ARCHIVES_HOME/$ARCHIVE_TYPE/$BASEARCHIVE.gpg ] && /bin/echo "I don't see $ARCHIVES_HOME/$ARCHIVE_TYPE/$BASEARCHIVE.gpg , please try again!!"
GPGDECRYPT $BASEARCHIVE
BASEARCHIVE=`echo ${BASEARCHIVE%.*}`
/usr/bin/sshpass -p $ROOTPASS scp -P 22 $ARCHIVES_HOME/$ARCHIVE_TYPE/$BASEARCHIVE root@$DESTIP:/
[ $? -ne 0 ] && echo "It looks like secure transfer to $DESTIP failed, I am helpless...I need an expert to take a look...you know I am dumb..." && exit 1
fi
/usr/bin/sshpass -p $ROOTPASS ssh -t root@$DESTIP <<EOF
cd /
/bin/tar -zxvf $BASEARCHIVE
if [ $? -eq 0 ]; then
/bin/rm -rf $BASEARCHIVE
/usr/sbin/authconfig --enableldap --enablemd5 --enableshadow --enableldapauth --enablemkhomedir --enablelocauthorize --ldapserver=ldaps://ldapmaster.eusiness.com/ --ldapbasedn="dc=eusiness,dc=com" --updateall
/usr/sbin/postmap /etc/postfix/generic
/usr/bin/newaliases
/sbin/chkconfig --level 234 System-Start-Stop-Notification on
/sbin/chkconfig --level 234 vnstat on
/sbin/init 6
fi
EOF
}

function READY_SSHPASS_SOURCE()
{
#Check for sshpass on source
/usr/bin/which sshpass > /dev/null
if [ $? -ne 0 ]; then
/bin/rpm -i http://dl.fedoraproject.org/pub/epel/6/x86_64/sshpass-1.05-1.el6.x86_64.rpm
else
echo "Good, sshpass is already installed on source."
fi
}

function SSH_STRICTCHECK_HANDLE()
{
# Clean up known_hosts
echo "" > /root/.ssh/known_hosts
echo "Handling ssh strict checking before starting my work..."
echo "Handling ssh strict checking before starting my work..." >> $LOGFILE
/usr/bin/sshpass -p "$ROOTPASS" /usr/bin/ssh -t -o UserKnownHostsFile=/root/.ssh/known_hosts -o StrictHostKeyChecking=no root@$DESTIP <<EOF
exit
EOF
}

function F_CONFIRM() {
echo -e -n "$1 \n"
read ans
case "$ans" in
y|Y|yes|YES|Yes) return 1 ;;
*) echo "Thanks for cancelling it before starting it..." ; return 0 ;;
esac
}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
else
	/bin/echo "NOTE: If interrupted, destination server may need to be built from scratch!" > $LOGFILE
	/bin/echo "NOTE: If interrupted, destination server may need to be built from scratch!"
	F_CONFIRM "Do you still want to proceed (y|Y|yes|YES|Yes)?" && exit 1
	READY_SSHPASS_SOURCE
	/bin/echo "Please enter destination server's IP, followed by [ENTER]:" >> $LOGFILE
	/bin/echo -e -n "Please enter destination server's IP, followed by [ENTER]: \n"
	read DESTIP
	/bin/ping -c 2 $DESTIP
	if [ $? -ne 0 ]; then
		echo "$DESTIP is not reachable. I can not duplicate `hostname` at this time." >> $LOGFILE
		echo "$DESTIP is not reachable. I can not duplicate `hostname` at this time."
		echo "Please run $0 when you've valid/correct IP."
		echo "Please run $0 when you've valid/correct IP." >> $LOGFILE
		exit 1
	else
        	/bin/echo  "What type (comm,app,db,base) of server is this ? " > $LOGFILE
        	/bin/echo  -e -n "What type (comm,app,db,base) of server is this ? \n"
	        read ARCHIVE_TYPE
       		if [ -z "$ARCHIVE_TYPE" ]; then
                	echo "You've got to tell me what type of server is this, else I can not help you!" >> $LOGFILE
	        else
                		if [ "$ARCHIVE_TYPE" == "comm" -o "$ARCHIVE_TYPE" == "app" -o "$ARCHIVE_TYPE" == "db" -o "$ARCHIVE_TYPE" == "base" ]; then
					echo "Please enter destination server's location (us,uk,other), followed by [ENTER]:" >> $LOGFILE
					echo "Please enter destination server's location (us,uk,other), followed by [ENTER]:" >> $LOGFILE
					echo -e -n "Please enter destination server's location (us,uk,other), followed by [ENTER]: \n"
					read DESTLOC
					[ -z "$DESTLOC" ] && echo "You have to tell me where destination server is located...else you shall not pass!" && exit 1
					# [ "$DESTLOC" != "us" -o "$DESTLOC" != "uk" -o "$DESTLOC" != "other" ] && /bin/echo "Please enter correct destination location...else you shall not pass!" && exit 1
					if [ "$DESTLOC" != "us" -a "$DESTLOC" != "uk" -a "$DESTLOC" != "other" ]; then
                                        /bin/echo "Please enter correct destination location..."
                                        exit 1
                                        fi
					echo "Please enter destination server's root password, followed by [ENTER]:" >> $LOGFILE
					echo -e -n "Please enter destination server's root password, followed by [ENTER]: \n"
					read ROOTPASS
					SSH_STRICTCHECK_HANDLE
					PRE_OPS
					[ "$ARCHIVE_TYPE" == "comm" ] && MAIN_OP_COMM
					[ "$ARCHIVE_TYPE" == "app" ] && MAIN_OP_APP
					[ "$ARCHIVE_TYPE" == "db" ] && MAIN_OP_DB
					[ "$ARCHIVE_TYPE" == "base" ] && MAIN_OP_BASE
					echo "I started at $STARTTIME and finished at `date`."
                		else
                        		echo "Invalid input, please try again!"
                        		exit 1
                		fi
		fi
	fi
fi
