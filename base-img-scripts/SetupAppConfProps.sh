#!/bin/bash
JASYPT_HOME=/apps/.Support/jasypt
APPCONFPROPHOME=/apps/.Support/AppProperties
CONFPROP=config.properties
ID=$ID
CLIENTINFO=.clientinfo
[ -f /root/$CLIENTINFO ] && FILESIZE=`stat -c%s /root/$CLIENTINFO` || FILESIZE=0
CLIENT=nullclient
REPO=nullrepo
TYPE=nulltype
EZMGMTDB=ezmgmtdb
EZCHATDB=ezchatdb
DBPORT=37637
DBIP=$1
COMMPUBLICIP=$2
COMMPRIVATEIP=$3
EZMGMTDBUSER=$4
EZMGMTDBPASS=$5
EZCHATDBUSER=$6
EZCHATDBPASS=$7
DOMAINAME=$8
IMPERSEMAIL=$9
IMPERSPASS=$10
AMAZONSES-AKEY=$11
AMAZONSES-SKEY=$12

function GET_CLIENT_DETAILS()
{
echo -n "Please enter client name (E.g eusiness), followed by [ENTER]:"
read CLIENT
echo -n "Please enter client repo (E.g. ezmgmt), followed by [ENTER]:"
read REPO
echo -n "Please enter client repo type (E.g. prod), followed by [ENTER]:"
read TYPE
if [ -z "$CLIENT" -o -z "$REPO" -o -z "$TYPE" ]; then
/bin/echo "I can not configure this server without requested information!"
exit 1
fi
}

function ENCRYPT_DEFAULTS()
{
# Default Values
formatusername=`$JASYPT_HOME/bin/encrypt.sh input="(firstname).(lastname)" password=$ID verbose=false`
formatdisplayname=`$JASYPT_HOME/bin/encrypt.sh input="(firstname) (lastname)" password=$ID verbose=false`
openfireport=`$JASYPT_HOME/bin/encrypt.sh input="5280" password=$ID verbose=false`
openfireadminport=`$JASYPT_HOME/bin/encrypt.sh input="2428" password=$ID verbose=false`
openfirekey=`$JASYPT_HOME/bin/encrypt.sh input="6d7KY0pV" password=$ID verbose=false`
exchangehost=`$JASYPT_HOME/bin/encrypt.sh input="pod51010.outlook.com" password=$ID verbose=false`
exchangeprefix=`$JASYPT_HOME/bin/encrypt.sh input="Exchange" password=$ID verbose=false`
exchangeusessl=`$JASYPT_HOME/bin/encrypt.sh input="true" password=$ID verbose=false`
authenticationtype=`$JASYPT_HOME/bin/encrypt.sh input="daoAuthenticationProvider" password=$ID verbose=false`
hibernatedialect=`$JASYPT_HOME/bin/encrypt.sh input="org.hibernate.dialect.MySQLDialect" password=$ID verbose=false`
jdbcdriverClass=`$JASYPT_HOME/bin/encrypt.sh input="com.mysql.jdbc.Driver" password=$ID verbose=false`
meetingminattendance=`$JASYPT_HOME/bin/encrypt.sh input="50.0" password=$ID verbose=false`
docroot=`$JASYPT_HOME/bin/encrypt.sh input="/apps/data01/" password=$ID verbose=false`
twilio.smsStatusCallback=`$JASYPT_HOME/bin/encrypt.sh input="https://myfirm.yonnor.com/rest/twiml/smsStatusCallback" password=$ID verbose=false`
}

function ASSIGN_DEFAULT_APP_PROPERTIES_FILE()
{
[ ! -d $APPCONFPROPHOME ] && /bin/mkdir -p $APPCONFPROPHOME
/bin/chmod 775 $APPCONFPROPHOME
/bin/cat > $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP << EOF
format.username=ENC($formatusername)
format.displayname=ENC($formatdisplayname)
openfire.port=ENC($openfireport)
openfire.admin.port=ENC($openfireadminport)
openfire.key=ENC($openfirekey)
exchange.host=ENC($exchangehost)
exchange.prefix=ENC($exchangeprefix)
exchange.usessl=ENC($exchangeusessl)
authentication.type=ENC($authenticationtype)
hibernate.dialect=ENC($hibernatedialect)
jdbc.driverClass=ENC($jdbcdriverClass)
meeting.minattendance=ENC($meetingminattendance)
doc.root=ENC($docroot)
c3p0.acquireIncrement=2
c3p0.initialPoolSize=10
c3p0.maxPoolSize=30
c3p0.maxIdleTime=300
c3p0.minPoolSize=5
c3p0.maxIdleTimeExcessConnections=300
c3p0.acquireRetryAttempts=0
c3p0.acquireRetryDelay=3000
c3p0.breakAfterAcquireFailure=false
c3p0.maxConnectionAge=6000
c3p0.idleConnectionTestPeriod=3600
EOF
/bin/chmod 444 $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
}

function GET_ADDITIONAL_INFO()
{
echo -n "Please enter database server's PRIVATE IP, followed by [ENTER]:"
read DBIP
IP1=`echo $DBIP | cut -d '.' -f1,1`
if [ $IP1 -eq "10" -o $IP1 -eq "172" -o $IP1 -eq "192" -o $IP1 -eq "169" -o $IP1 -eq "127" ]; then
/bin/ping -c 2 $DBIP > /dev/null 2>&1
if [ $? -ne 0 ]; then
echo "$DBIP is not reachable! I can not setup config.properties for ezManagement at this time!!"
exit 1
else
echo -n "Please enter communication server's PRIVATE IP, followed by [ENTER]:"
read COMMPRIVATEIP
IP1=`echo $COMMPRIVATEIP | cut -d '.' -f1,1`
if [ $IP1 -eq "10" -o $IP1 -eq "172" -o $IP1 -eq "192" -o $IP1 -eq "169" -o $IP1 -eq "127" ]; then
/bin/ping -c 2 $COMMPRIVATEIP > /dev/null 2>&1
if [ $? -ne 0 ]; then
echo "$COMMPRIVATEIP is not reachable! I can not setup config.properties for ezManagement at this time!!"
exit 1
else
echo -n "Please enter communication server's PUBLIC IP, followed by [ENTER]:"
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
else
echo -n "Please enter ezmgmtdb username, followed by [ENTER]:"
read EZMGMTDBUSER
echo -n "Please enter ezmgmtdb password, followed by [ENTER]:"
read EZMGMTDBPASS
echo -n "Please enter ezchatdb username, followed by [ENTER]:"
read EZCHATDBUSER
echo -n "Please enter ezchatdb password, followed by [ENTER]:"
read EZCHATDBPASS
echo -n "Please enter office 365 domain name, followed by [ENTER]:"
read DOMAINAME
echo -n "Please enter office 365 impersonation user email, followed by [ENTER]:"
read IMPERSEMAIL
echo -n "Please enter office 365 impersonation user password, followed by [ENTER]:"
read IMPERSPASS
echo -e -n "Please enter Amazon SES access key, followed by [ENTER]: \n"
read AMAZONSES-AKEY
echo -e -n "Please enter Amazon SES secret key, followed by [ENTER]: \n"
read AMAZONSES-SKEY
if [ -z "$EZMGMTDBUSER" -o -z "$EZMGMTDBPASS" -o -z "$EZCHATDBUSER" -o -z "$EZCHATDBPASS" -o -z "$DOMAINAME" -o -z "$IMPERSEMAIL" -o -z "$IMPERSPASS" -o -z "$AMAZONSES-AKEY" -o -z "$AMAZONSES-SKEY" ]; then
/bin/echo "I can not configure ezManagement config file without requested information!"
exit 1
fi
SETUP_CONFIG_PROPERTIES
fi
fi
fi
fi
fi
fi
}

function SETUP_CONFIG_PROPERTIES()
{
if [ -z "$DBIP" -o -z "$COMMPRIVATEIP" -o -z "$EZMGMTDBUSER" -o -z "$EZMGMTDBPASS" -o -z "$DOMAINAME" -o -z "$IMPERSEMAIL" -o -z "$IMPERSPASS" -o -z "$AMAZONSES-AKEY" -o -z "$AMAZONSES-SKEY" ]; then
GET_ADDITIONAL_INFO
else
jdbcurl_app=`$JASYPT_HOME/bin/encrypt.sh input="jdbc:mysql://$DBIP:$DBPORT/$EZMGMTDB?useUnicode=true&connectionCollation=utf8_general_ci&characterSetResults=utf8&characterEncoding=utf8" password=$ID verbose=false`
jdbcusername_app=`$JASYPT_HOME/bin/encrypt.sh input="$EZMGMTDBUSER" password=$ID verbose=false`
jdbcpassword_app=`$JASYPT_HOME/bin/encrypt.sh input="$EZMGMTDBPASS" password=$ID verbose=false`
jdbcurl_chat=`$JASYPT_HOME/bin/encrypt.sh input="jdbc:mysql://$DBIP:$DBPORT/$EZCHATDB" password=$ID verbose=false`
jdbcusername_chat=`$JASYPT_HOME/bin/encrypt.sh input="$EZCHATDBUSER" password=$ID verbose=false`
jdbcpassword_chat=`$JASYPT_HOME/bin/encrypt.sh input="$EZCHATDBPASS" password=$ID verbose=false`
openfireserver=`$JASYPT_HOME/bin/encrypt.sh input="chatmaster" password=$ID verbose=false`
exchangedomain=`$JASYPT_HOME/bin/encrypt.sh input="$DOMAINAME" password=$ID verbose=false`
impersemail=`$JASYPT_HOME/bin/encrypt.sh input="$IMPERSEMAIL" password=$ID verbose=false`
imperspass=`$JASYPT_HOME/bin/encrypt.sh input="$IMPERSPASS" password=$ID verbose=false`
twilioincoming=`$JASYPT_HOME/bin/encrypt.sh input="https://$COMMPUBLICIP/ezVoice/Incoming.php" password=$ID verbose=false`
twiliosms=`$JASYPT_HOME/bin/encrypt.sh input="https://$COMMPUBLICIP/ezVoice/IncomingSMSApp.php" password=$ID verbose=false`
amazonses-akey=`$JASYPT_HOME/bin/encrypt.sh input="$AMAZONSES-AKEY" password=$ID verbose=false`
amazonses-skey=`$JASYPT_HOME/bin/encrypt.sh input="$AMAZONSES-SKEY" password=$ID verbose=false`
ENCRYPT_DEFAULTS
ASSIGN_DEFAULT_APP_PROPERTIES_FILE
/bin/echo "jdbc.url=ENC($jdbcurl_app)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "jdbc.username=ENC($jdbcusername_app)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "jdbc.password=ENC($jdbcpassword_app)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "openfire.url=ENC($jdbcurl_chat)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "openfire.dbusername=ENC($jdbcusername_chat)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "openfire.dbpassword=ENC($jdbcpassword_chat)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "openfire.server=ENC($openfireserver)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "exchange.domain=ENC($exchangedomain)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "exchange.impers.id=ENC($impersemail)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "exchange.impers.pass=ENC($imperspass)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "twilio.incoming=ENC($twilioincoming)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "twilio.sms=ENC($twiliosms)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "amazon-ses.accesskey=ENC($amazonses-akey)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
/bin/echo "amazon-ses.secretekey=ENC($amazonses-skey)" >> $APPCONFPROPHOME/.$CLIENT-$REPO-$TYPE.$CONFPROP
fi
}

function GATHER_CLIENT_DETAILS()
{
if [ -f /root/$CLIENTINFO -a $FILESIZE -ne 0 ]; then
CLIENT=`grep "CLIENT" /root/$CLIENTINFO | cut -d '=' -f2,2`
REPO=`grep "REPO" /root/$CLIENTINFO | cut -d '=' -f2,2`
TYPE=`grep "TYPE" /root/$CLIENTINFO | cut -d '=' -f2,2`
else
GET_CLIENT_DETAILS
fi
}

if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
else
	GATHER_CLIENT_DETAILS
	SETUP_CONFIG_PROPERTIES
fi
