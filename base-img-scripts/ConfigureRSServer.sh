#!/bin/bash
NEWHOSTNAME=`hostname`
HTTPD_HOME=/apps/httpd
HTTPDCF=$HTTPD_HOME/conf/httpd.conf
CLOUDCRED=.Cloud
clouduser=""
cloudpass=""
GLOBALSCRIPTSLOC=/usr/local/scripts
CLOUD_LOC_FILES="/usr/local/scripts/AddAFileToRSCloud.sh /usr/local/scripts/GetAFileFromRSCloud.sh /usr/local/scripts/ImageServer.sh /usr/local/scripts/RemoveAFileFromRSCloud.sh /usr/local/scripts/AddContainer.sh"
ADDCONTAINER=AddContainer.sh
BWREPORTERSCRIPT=BandwidthReporter.sh
APPDEPLOYSCRIPT2_2=AppDeployCode-2-2.sh
NOTIFYLIST=sysadmins
# Nagios Client
MYIP=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2`
NAGIOSSETUPMGR=Nag1ZjBlMWR
NAGIOSMASTER=nagiosmaster
NAGIOS_HOME=/apps/.Support/nagios
REMOTENAGIOSCLIENTSETUPSCRIPT=/usr/local/scripts/NagiosNewClientSetup.sh
SSHPORT=422
SETUPAPPCNFSCRPT=SetupAppConfProps.sh
CLIENTINFO=.clientinfo
CLIENT=nullclient
REPO=nullrepo
TYPE=nulltype
# App Conf Prop
COMMPUBLICIP=commpublicip
COMMPRIVATEIP=commprivateip
# Sched Conf Prop
IMPERSEMAIL=impersemail
IMPERSPASS=imperspass
AMAZONSES-AKEY=amazonses-akey
AMAZONSES-SKEY=amazonses-skey
# Common to App Conf Prop and Sched Conf Prop
DBIP=dbip
EZMGMTDBUSER=yoezmgmtdbuser
EZMGMTDBPASS=yoezmgmtdbpass
EZCHATDBUSER=yoezchatdbuser
EZCHATDBPASS=yoezchatdbpass
SERVDOMAIN=eusiness.com

if [ -f ~/$CLIENTINFO ]; then
FILESIZE=`stat -c%s ~/$CLIENTINFO`
if [ $FILESIZE -eq 0 ]
then
echo "I don't think you've initialized this server, please check and try again!"
exit
else
echo "Sweet, it looks like server has been initialized...I think I am good to move forward..."
fi
else
echo "I don't think you've initialized this server, please check and try again!"
exit 1
fi

function ADD_RS_BACKUP_CONTAINER()
{
$GLOBALSCRIPTSLOC/$ADDCONTAINER -m $NEWHOSTNAME-backup
}

function CONFIGURE_CLOUD_LOCATION()
{
files=$CLOUD_LOC_FILES
echo -e -n "Where is this server located (us/uk/other) ? \n"
read loc
if [ ! -z "$loc" -a "$loc" == "us" ]; then
for f in $files ; do sed -i '/DEFAULT_AUTH_SERVER=/ c\DEFAULT_AUTH_SERVER=${AUTH_SERVER_US}' $f ; done
echo "This server will be backed up at US rackspace cloud!"
elif [ ! -z "$loc" -a "$loc" == "uk" ]; then
for f in $files ; do sed -i '/DEFAULT_AUTH_SERVER=/ c\DEFAULT_AUTH_SERVER=${AUTH_SERVER_LON}' $f ; done
echo "This server will be backed up at UK rackspace cloud!"
else
for f in $files ; do sed -i '/DEFAULT_AUTH_SERVER=/ c\DEFAULT_AUTH_SERVER=${AUTH_SERVER_LON}' $f ; done
echo "This server will be backed up at UK rackspace cloud!"
fi
}

function CONFIGURE_HTTPD_SSL_CERTS()
{
# If you generate new self-signed SSL certs, it will need to be imported in cacerts on Application Server's JRE.
# Also, you will need to manually modify httpd.conf for relative entries.
/bin/rm -rf $HTTPD_HOME/conf/mycerts/*
[ -f $GLOBALSCRIPTSLOC/GenerateSSLCert.sh ] && $GLOBALSCRIPTSLOC/GenerateSSLCert.sh
SSLCERTFILENAME=$NEWHOSTNAME.crt
SSLCERTKEYNAME=$NEWHOSTNAME.key
[ -f $HTTPD_HOME/conf/mycerts/$SSLCERTFILENAME ] && /bin/sed -i 's/SSLCERTFILE/'$SSLCERTFILENAME'/g' $HTTPDCF
[ -f $HTTPD_HOME/conf/mycerts/$SSLCERTKEYNAME ] && /bin/sed -i 's/SSLCERTKEY/'$SSLCERTKEYNAME'/g' $HTTPDCF
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

function GET_CLIENT_DETAILS()
{
echo -e -n "Please enter client name (E.g eusiness), followed by [ENTER]: \n"
read CLIENT
echo -e -n "Please enter client repo (E.g. ezmgmt), followed by [ENTER]: \n"
read REPO
echo -e -n "Please enter client repo type (E.g. prod), followed by [ENTER]: \n"
read TYPE
echo -e -n "Please enter client main service domain (E.g. eusiness.com), followed by [ENTER]: \n"
read SERVDOMAIN
if [ -z "$CLIENT" -o -z "$REPO" -o -z "$TYPE" -o -z "$SERVDOMAIN" ]; then
/bin/echo "I can not configure this server without requested information!"
exit 1
else
echo "CLIENT=$CLIENT" > ~/$CLIENTINFO
echo "REPO=$REPO" >> ~/$CLIENTINFO
echo "TYPE=$TYPE" >> ~/$CLIENTINFO
echo "DOMAIN=$SERVDOMAIN" >> ~/$CLIENTINFO
/bin/chmod 444 ~/$CLIENTINFO
fi
}

function GATHER_CLIENT_DETAILS()
{
if [ -f ~/$CLIENTINFO -a $FILESIZE -ne 0 ]; then
CLIENT=`grep "CLIENT" ~/$CLIENTINFO | cut -d '=' -f2,2`
REPO=`grep "REPO" ~/$CLIENTINFO | cut -d '=' -f2,2`
TYPE=`grep "TYPE" ~/$CLIENTINFO | cut -d '=' -f2,2`
SERVDOMAIN=`grep "DOMAIN" ~/$CLIENTINFO | cut -d '=' -f2,2`
else
GET_CLIENT_DETAILS
fi
}

function CONFIGURE_CLOUD_CREDS()
{
CONFIGURE_CLOUD_LOCATION
echo -e -n "Please enter cloud's exact username, followed by [ENTER]: \n"
read clouduser
echo -e -n "Please enter cloud's exact api-key, followed by [ENTER]: \n"
read cloudpass
if [ -z "$clouduser" -o -z "$cloudpass" ]; then
/bin/echo "Your cloud operations will not work as you've not provided both the cloud user and api-key!"
/bin/echo "You will need to manuall add cloud credentials now!!"
else
USER=`$JASYPT_HOME/bin/encrypt.sh input="$clouduser" password="$ID" verbose=false`
PASS=`$JASYPT_HOME/bin/encrypt.sh input="$cloudpass" password="$ID" verbose=false`
echo "CLOUDMGR=$USER" > ~/$CLOUDCRED
echo "CLOUDKEY=$PASS" >> ~/$CLOUDCRED
fi
}

function NAGIOS_CLIENT_SETUP()
{
echo -e -n "Please enter $NAGIOSSETUPMGR password, followed by [ENTER]: \n"
read NAGPASS
/bin/sed -i 's/HOSTNAME/'$NEWHOSTNAME'/g' $NAGIOS_HOME/appservertemplate.cfg
/bin/sed -i 's/IPADD/'$MYIP'/g' $NAGIOS_HOME/appservertemplate.cfg
/bin/mv $NAGIOS_HOME/appservertemplate.cfg $NAGIOS_HOME/$NEWHOSTNAME.cfg
/usr/bin/sshpass -p $NAGPASS /usr/bin/scp -o UserKnownHostsFile=/root/.ssh/known_hosts -o StrictHostKeyChecking=no -P $SSHPORT $NAGIOS_HOME/$NEWHOSTNAME.cfg $NAGIOSSETUPMGR@$NAGIOSMASTER:/tmp/$NEWHOSTNAME.cfg
echo "Restarting nagios server services on $NAGIOSMASTER ..."
/usr/bin/sshpass -p $NAGPASS /usr/bin/ssh -p $SSHPORT $NAGIOSSETUPMGR@$NAGIOSMASTER sudo $REMOTENAGIOSCLIENTSETUPSCRIPT $NEWHOSTNAME.cfg
/bin/rm -rf $NAGIOS_HOME/$NEWHOSTNAME.cfg
echo "nrpe            5666/tcp                        # Nagios Monitoring" >> /etc/services
# Restart xinetd
/sbin/service xinetd restart
}

function CONFIGURE_DB_CONDUIT_USER()
{
echo -e -n "Please enter database server's PRIVATE IP, followed by [ENTER]: \n"
read DBIP
IP1=`echo $DBIP | cut -d '.' -f1,1`
if [ $IP1 -eq "10" -o $IP1 -eq "172" -o $IP1 -eq "192" -o $IP1 -eq "169" -o $IP1 -eq "127" ]; then
echo -e -n "Please enter DB conduit username on database, followed by [ENTER]: \n"
read DBCONDUITUSER
if [ ! -z "$DBCONDUITUSER" ]
then
/bin/sed -i 's/DBIP/'$DBIP'/g' $GLOBALSCRIPTSLOC/$BWREPORTERSCRIPT
/bin/sed -i 's/DBPASSUSER/'$DBCONDUITUSER'/g' $GLOBALSCRIPTSLOC/$BWREPORTERSCRIPT
/bin/sed -i 's/DBIP/'$DBIP'/g' $GLOBALSCRIPTSLOC/$APPDEPLOYSCRIPT2_2
/bin/sed -i 's/DBPASSUSER/'$DBCONDUITUSER'/g' $GLOBALSCRIPTSLOC/$APPDEPLOYSCRIPT2_2
else
echo "DB Conduit username can not be left empty! You'll need to reconfigure DB conduit user!!"
fi
else
echo "Entered IP does not look like PRIVATE!"
echo "You had one small job and you mess up!!"
fi
}

function GATHER_COMMON_CONF_PROPS_INFO()
{
echo -e -n "Please enter yoezmgmtdb username, followed by [ENTER]: \n"
read EZMGMTDBUSER
echo -e -n "Please enter yoezmgmtdb password, followed by [ENTER]: \n"
read EZMGMTDBPASS
echo -e -n "Please enter yoezchatdb username, followed by [ENTER]: \n"
read EZCHATDBUSER
echo -e -n "Please enter yoezchatdb password, followed by [ENTER]: \n"
read EZCHATDBPASS
echo -e -n "Please enter office 365 domain name, followed by [ENTER]: \n"
read SERVDOMAIN
echo -e -n "Please enter office 365 impersonation user email, followed by [ENTER]: \n"
read IMPERSEMAIL
echo -e -n "Please enter office 365 impersonation user password, followed by [ENTER]: \n"
read IMPERSPASS
echo -e -n "Please enter Amazon SES access key, followed by [ENTER]: \n"
read AMAZONSES-AKEY
echo -e -n "Please enter Amazon SES secret key, followed by [ENTER]: \n"
read AMAZONSES-SKEY
if [ -z "$EZMGMTDBUSER" -o -z "$EZMGMTDBPASS" -o -z "$EZCHATDBUSER" -o -z "$EZCHATDBPASS" -o -z "$SERVDOMAIN" -o -z "$IMPERSEMAIL" -o -z "$IMPERSPASS" -z "$AMAZONSES-AKEY" -o -z "$AMAZONSES-SKEY" ]; then
/bin/echo "I can not configure ezManagement config files without requested information!"
exit 1
fi
}

function GET_ADDITIONAL_INFO_FOR_APPPROPS()
{
echo -e -n "Please enter communication server's PRIVATE IP, followed by [ENTER]: \n"
read COMMPRIVATEIP
IP1=`echo $COMMPRIVATEIP | cut -d '.' -f1,1`
if [ $IP1 -eq "10" -o $IP1 -eq "172" -o $IP1 -eq "192" -o $IP1 -eq "169" -o $IP1 -eq "127" ]; then
/bin/ping -c 2 $COMMPRIVATEIP > /dev/null 2>&1
if [ $? -ne 0 ]; then
echo "$COMMPRIVATEIP is not reachable! I can not setup config.properties for ezManagement at this time!!"
exit 1
else
echo -e -n "Please enter communication server's PUBLIC IP, followed by [ENTER]: \n"
read COMMPUBLICIP
IP1=`echo $COMMPUBLICIP | cut -d '.' -f1,1`
if [ $IP1 -eq "10" -o $IP1 -eq "172" -o $IP1 -eq "192" -o $IP1 -eq "169" -o $IP1 -eq "127" ]; then
/bin/echo "$COMMPUBLICIP does not look like its public. I can not setup config.properties for ezManagement at this time."
exit 1
else
/bin/ping -c 2 $COMMPUBLICIP > /dev/null 2>&1
if [ $? -ne 0 ]; then
echo "$COMMPUBLICIP is not reachable! I can not setup config.properties for ezManagement at this time!!"
exit 1
fi
fi
fi
fi
}

function SETUP_APP_CONF_PROPS()
{
# function GATHER_COMMON_CONF_PROPS_INFO must be run before this step
GET_ADDITIONAL_INFO_FOR_APPPROPS
[ -f $GLOBALSCRIPTSLOC/$SETUPAPPCNFSCRPT ] && $GLOBALSCRIPTSLOC/$SETUPAPPCNFSCRPT $DBIP $COMMPUBLICIP $COMMPRIVATEIP $EZMGMTDBUSER $EZMGMTDBPASS $EZCHATDBUSER $EZCHATDBPASS $SERVDOMAIN $IMPERSEMAIL $IMPERSPASS $AMAZONSES-AKEY $AMAZONSES-SKEY
}

function CHECK_IF_DBIP_VALID()
{
IP1=`echo $DBIP | cut -d '.' -f1,1`
if [ $IP1 -eq "10" -o $IP1 -eq "172" -o $IP1 -eq "192" -o $IP1 -eq "169" -o $IP1 -eq "127" ]; then
/bin/ping -c 2 $DBIP > /dev/null 2>&1
if [ $? -ne 0 ]; then
echo "$DBIP is not reachable! I can not setup config.properties for scheduler at this time!!"
exit 1
fi
fi
}

function RESET_ROOT_PASSWORD()
{
PASS=`date +%s | sha256sum | base64 | head -c 11 ; echo`
/bin/echo $PASS | passwd --stdin root
/bin/echo "Changing root password..."
}

function UPDATE_ETCHOSTS()
{
echo "$COMMPRIVATEIP chatmaster" >> /etc/hosts
}

function CONFIGURE_PUPPET_CLIENT()
{
OS=`cat /etc/redhat-release | awk {'print $1'}`
RUNINT=`shuf -i 70000-86400 -n 1`
if [ "$OS" == "CentOS" -a "$TYPE" == "prod" ]
then
ENV=CentOSProduction
/bin/sed -i 's/ENVIRONMENT/'$ENV'/g' /etc/puppet/puppet.conf
/bin/sed -i 's/RUNINTERVAL/'$RUNINT'/g' /etc/puppet/puppet.conf
elif [ "$OS" == "CentOS" -a "$TYPE" == "testing" ]
then
ENV=CentOSTesting
/bin/sed -i 's/ENVIRONMENT/'$ENV'/g' /etc/puppet/puppet.conf
/bin/sed -i 's/RUNINTERVAL/'$RUNINT'/g' /etc/puppet/puppet.conf
elif [ "$OS" == "CentOS" -a "$TYPE" == "staging" ]
then
ENV=CentOSStaging
/bin/sed -i 's/ENVIRONMENT/'$ENV'/g' /etc/puppet/puppet.conf
/bin/sed -i 's/RUNINTERVAL/'$RUNINT'/g' /etc/puppet/puppet.conf
elif [ "$OS" == "Red" -a "$TYPE" == "prod" ]
then
ENV=RHELProduction
/bin/sed -i 's/ENVIRONMENT/'$ENV'/g' /etc/puppet/puppet.conf
/bin/sed -i 's/RUNINTERVAL/'$RUNINT'/g' /etc/puppet/puppet.conf
elif [ "$OS" == "Red" -a "$TYPE" == "testing" ]
then
ENV=RHELTesting
/bin/sed -i 's/ENVIRONMENT/'$ENV'/g' /etc/puppet/puppet.conf
/bin/sed -i 's/RUNINTERVAL/'$RUNINT'/g' /etc/puppet/puppet.conf
elif [ "$OS" == "Red" -a "$TYPE" == "staging" ]
then
ENV=RHELStaging
/bin/sed -i 's/ENVIRONMENT/'$ENV'/g' /etc/puppet/puppet.conf
/bin/sed -i 's/RUNINTERVAL/'$RUNINT'/g' /etc/puppet/puppet.conf
else
echo "Such scenario has not been designed!"
fi
}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
else
	GATHER_CLIENT_DETAILS
        echo "=================================================================="
        echo "**** PLEASE DON'T RUN THIS SCRIPT FOR MORE THAN ONCE TIME!! ****"
        echo "You will need following information for $CLIENT to proceed:"
	echo "1. Client's Cloud Username"
	echo "2. Client's Cloud API Key"
        echo "3. Database Server's PRIVATE IP address"
        echo "4. Database Server's conduit username (bandwidth reporter)"
        echo "5. yoezmgmtdb database user's username and password"
        echo "6. yoezchatdb database user's username and password"
        echo "7. Office 365's domain name"
        echo "8. Office 365's impersonation username"
        echo "9. Office 365's impersonation user's password"
        echo "10. Amazon SES access key"
        echo "11. Amazon SES secret key"
        echo "12. Communication Server's PRIVATE,PUBLIC IP address"
        echo "13. Head Office Location/service URL details for SSL configuration"
        echo    "E.g. Country Name, State or Province Name, Locality Name,"
	echo 	 "Organization Name, Service URL."
        echo "14. Nagios Client Setup user's password," [ $NAGIOSSETUPMGR ]
        echo "=================================================================="
        echo -e -n "Proceed (y/n) ? \n"
        read ans
        if [ $ans == "y" ]; then
		READY_SSHPASS_SOURCE
		CONFIGURE_CLOUD_CREDS
		# CONFIGURE_DB_CONDUIT_USER
		GATHER_COMMON_CONF_PROPS_INFO
		CONFIGURE_HTTPD_SSL_CERTS
		# CONFIGURE_HTTPD_SSL_CERTS must be above SETUP_APP_CONF_PROPS
		# SETUP_APP_CONF_PROPS
		# NAGIOS_CLIENT_SETUP
		ADD_RS_BACKUP_CONTAINER
		# CONFIGURE_PUPPET_CLIENT
		UPDATE_ETCHOSTS
		# RESET_ROOT_PASSWORD
		/bin/mail -s "$NEWHOSTNAME [APP] has been configured and should be ready for use!" $NOTIFYLIST < /dev/null
        else
                echo "Please run this script when you are ready!"
        fi
fi
