#!/bin/bash
NOW=`date +%d-%b-%Y-%H%M%S`
INCLUDELIST=/tmp/$NOW.list
LOGFILE=/tmp/$NOW.log
ARCHIVES_HOME=/ServerReplicationArchive
ARCHIVE_TYPE="DONTKNOW" # Comm, DB, App
RSCLOUDACTIVE=1 # cloud backups inactive when 0
CONTAINER=ServerReplicationArchive
GLOBALSCRIPTSLOC=/usr/local/scripts
ADDTOCLOUD=$GLOBALSCRIPTSLOC/AddAFileToRSCloud.sh
# Encryption
Encryption=/usr/bin/gpg2

function GPGENCRYPT()
{
fname=$1
if [ -f "/root/.gnupg/.gpg-agent-info" ]; then
. "/root/.gnupg/.gpg-agent-info"
export GPG_AGENT_INFO
export SSH_AUTH_SOCK
. "/root/.bash_profile"
$Encryption --batch --passphrase $ID -c $fname
/bin/rm -rf $fname
fi
}

function SETUPINCLUDELIST_COMM()
{
/bin/echo "Setting up include list $INCLUDELIST ..." >> $LOGFILE
/bin/cat > $INCLUDELIST << EOF
/etc/passwd
/etc/group
/etc/shadow
/etc/pam.d/su
/etc/pam.d/system-auth
/etc/pam.d/system-auth-ac
/etc/pam.d/system-auth-local
/etc/profile
/etc/login.defs
/etc/skel/.bashrc
/etc/skel/.bash_profile
/etc/default/useradd
/etc/postfix/generic
/etc/postfix/main.cf
/etc/aliases
/var/spool/cron/root
/etc/hosts
/etc/nslcd.conf
/etc/system-aide.conf
/etc/nsswitch.conf
/etc/sysctl.conf
/etc/support-aide.conf
/etc/pam_ldap.conf
/etc/yum.conf
/etc/sudoers
/etc/sysconfig/authconfig
/etc/sysconfig/iptables
/etc/sysconfig/openfire
/etc/xinetd.d/nrpe
/etc/logrotate.d/openfire
/etc/logrotate.d/httpd
/etc/init.d/openfire
/etc/init.d/httpd
/etc/init.d/System-Start-Stop-Notification
/root/.bash_profile
/etc/ld.so.conf
/etc/ssh/sshd_config
/etc/openldap/
/apps/
/usr/local/scripts/
EOF
}

function SETUPINCLUDELIST_APP()
{
/bin/echo "Setting up include list $INCLUDELIST ..." >> $LOGFILE
/bin/cat > $INCLUDELIST << EOF
/etc/passwd
/etc/group
/etc/shadow
/etc/pam.d/su
/etc/pam.d/system-auth
/etc/pam.d/system-auth-ac
/etc/pam.d/system-auth-local
/etc/profile
/etc/login.defs
/etc/skel/.bashrc
/etc/skel/.bash_profile
/etc/default/useradd
/etc/postfix/generic
/etc/postfix/main.cf
/etc/aliases
/var/spool/cron/root
/etc/hosts
/etc/nslcd.conf
/etc/system-aide.conf
/etc/nsswitch.conf
/etc/sysctl.conf
/etc/support-aide.conf
/etc/pam_ldap.conf
/etc/yum.conf
/etc/sudoers
/etc/sysconfig/authconfig
/etc/sysconfig/iptables
/etc/xinetd.d/nrpe
/etc/logrotate.d/tomcat
/etc/logrotate.d/httpd
/etc/init.d/tomcat
/etc/init.d/httpd
/etc/init.d/System-Start-Stop-Notification
/etc/init.d/ezscheduler
/root/.bash_profile
/etc/ssh/sshd_config
/etc/openldap/
/apps/
/usr/local/scripts/
EOF
}

function SETUPINCLUDELIST_DB()
{
/bin/echo "Setting up include list $INCLUDELIST ..." >> $LOGFILE
/bin/cat > $INCLUDELIST << EOF
/etc/passwd
/etc/group
/etc/shadow
/etc/pam.d/su
/etc/pam.d/system-auth
/etc/pam.d/system-auth-ac
/etc/pam.d/system-auth-local
/etc/profile
/etc/login.defs
/etc/skel/.bashrc
/etc/skel/.bash_profile
/etc/default/useradd
/etc/postfix/generic
/etc/postfix/main.cf
/etc/aliases
/var/spool/cron/root
/etc/hosts
/etc/nslcd.conf
/etc/system-aide.conf
/etc/nsswitch.conf
/etc/sysctl.conf
/etc/support-aide.conf
/etc/pam_ldap.conf
/etc/yum.conf
/etc/sudoers
/etc/sysconfig/authconfig
/etc/sysconfig/iptables
/etc/xinetd.d/nrpe
/etc/logrotate.d/mysqld
/etc/init.d/mysqld
/etc/init.d/System-Start-Stop-Notification
/root/.bash_profile
/etc/ssh/sshd_config
/etc/openldap/
/apps/
/usr/local/scripts/
EOF
}

function SETUPINCLUDELIST_BASE()
{
/bin/echo "Setting up include list $INCLUDELIST ..." >> $LOGFILE
/bin/cat > $INCLUDELIST << EOF
/etc/passwd
/etc/group
/etc/shadow
/etc/pam.d/su
/etc/pam.d/system-auth
/etc/pam.d/system-auth-ac
/etc/pam.d/system-auth-local
/etc/profile
/etc/login.defs
/etc/skel/.bashrc
/etc/skel/.bash_profile
/etc/default/useradd
/etc/postfix/generic
/etc/postfix/main.cf
/etc/aliases
/var/spool/cron/root
/etc/hosts
/etc/nslcd.conf
/etc/system-aide.conf
/etc/nsswitch.conf
/etc/sysctl.conf
/etc/support-aide.conf
/etc/pam_ldap.conf
/etc/yum.conf
/etc/sudoers
/etc/sysconfig/authconfig
/etc/sysconfig/iptables
/etc/xinetd.d/nrpe
/etc/init.d/System-Start-Stop-Notification
/root/.bash_profile
/etc/ssh/sshd_config
/etc/openldap/
EOF
}

function SERVER_BUNDLE()
{
/bin/echo "Creating server bundle per your request..this may take a while..."  >> $LOGFILE
/bin/echo "Creating server bundle per your request..this may take a while..."
/bin/mkdir -p $ARCHIVES_HOME/$ARCHIVE_TYPE
cd $ARCHIVES_HOME/$ARCHIVE_TYPE
/bin/cat $INCLUDELIST | xargs /bin/tar zvcf $ARCHIVE_TYPE-$NOW.tar.gz >> $LOGFILE 2>&1
[ $? -ne 0 ] && /bin/echo "Error occured while bundling your files. Please make sure that all files that you intend to bundle exist and try again!!" && /bin/rm -rf $ARCHIVE_TYPE-$NOW.tar.gz && exit 1
GPGENCRYPT $ARCHIVE_TYPE-$NOW.tar.gz
FILEMD5=`/usr/bin/md5sum $ARCHIVE_TYPE-$NOW.tar.gz.gpg | awk {'print $1'} | tr -d ' '`
if [ "$RSCLOUDACTIVE" -eq "1" ]; then
$ADDTOCLOUD -c $CONTAINER $ARCHIVE_TYPE-$NOW.tar.gz.gpg
/bin/rm -rf $ARCHIVE_TYPE-$NOW.tar.gz.gpg
/bin/echo "Woohhooo, I got it done for you and stored on rackspace cloud as $ARCHIVE_TYPE-$NOW.tar.gz.gpg [md5sum is $FILEMD5] ..." >> $LOGFILE
/bin/echo "Woohhooo, I got it done for you and stored on rackspace cloud as $ARCHIVE_TYPE-$NOW.tar.gz.gpg [md5sum is $FILEMD5] ..." 
else
echo "Woohhooo, I got it done for you and stored it under $ARCHIVES_HOME/$ARCHIVE_TYPE as $ARCHIVE_TYPE-$NOW.tar.gz.gpg [md5sum is $FILEMD5] ..." >> $LOGFILE
echo "Woohhooo, I got it done for you and stored it under $ARCHIVES_HOME/$ARCHIVE_TYPE as $ARCHIVE_TYPE-$NOW.tar.gz.gpg [md5sum is $FILEMD5] ..."
fi
/bin/rm -rf $INCLUDELIST
}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
else
	/bin/echo "I believe, you already have configured/tested server you are trying to bundle..." > $LOGFILE
	/bin/echo "I believe, you already have configured/tested server you are trying to bundle..."
	/bin/echo "the reason I say that is because, I am dumb, I just bundle your server, nothing else..." >> $LOGFILE
	/bin/echo "the reason I say that is because, I am dumb, I just bundle your server, nothing else..."
	/bin/echo  "What type (comm,app,db,base) of server is this ? " >> $LOGFILE
	/bin/echo  -e -n "What type (comm,app,db,base) of server is this ? \n"
        read ARCHIVE_TYPE
	if [ -z "$ARCHIVE_TYPE" ]; then
		echo "You've got to tell me what type of server is this, else I can not help you!" >> $LOGFILE
	else
		/bin/echo "Okay, I am going to create a $ARCHIVE_TYPE bundle for you..." >> $LOGFILE
		/bin/echo "Okay, I am going to create a $ARCHIVE_TYPE bundle for you..."
		if [ "$ARCHIVE_TYPE" == "comm" -o "$ARCHIVE_TYPE" == "app" -o "$ARCHIVE_TYPE" == "db" -o "$ARCHIVE_TYPE" == "base" ]; then
			[ "$ARCHIVE_TYPE" == "comm" ] && SETUPINCLUDELIST_COMM
			[ "$ARCHIVE_TYPE" == "app" ] && SETUPINCLUDELIST_APP
			[ "$ARCHIVE_TYPE" == "db" ] && SETUPINCLUDELIST_DB
			[ "$ARCHIVE_TYPE" == "base" ] && SETUPINCLUDELIST_BASE
			SERVER_BUNDLE
		else
			echo "Invalid input, please try again!"	
			exit 1
		fi
	fi
fi
