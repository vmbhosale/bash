#!/bin/bash
NOTIFYLIST=sysadmins

if [ -f ~/.Cloud ];then
. ~/.Cloud
else
echo "I dont see master user/password file!"
/bin/mail -s "I dont see master cloud file [`hostname`]!" $NOTIFYLIST < /dev/null
exit 1
fi

# Pass in the server name to backup (the name in the control panel), and
# optionally a base name for the backup image
if [[ -z $1 ]]; then
    echo "usage: $0 server_name [base_name]"
    exit 1
else
    servername=$1
fi

if [[ -n $2 ]]; then
    imagename=$2;
else
    imagename=$servername;
fi

# Auth Server (change it if you have a custom swift install)
AUTH_SERVER_LON=https://lon.auth.api.rackspacecloud.com/v1.0
AUTH_SERVER_US=https://auth.api.rackspacecloud.com/v1.0
DEFAULT_AUTH_SERVER=${AUTH_SERVER_US}

RCLOUD_API_USER=`$JASYPT_HOME/bin/decrypt.sh input="$CLOUDMGR" password="$ID" verbose=false`
RCLOUD_API_KEY=`$JASYPT_HOME/bin/decrypt.sh input="$CLOUDKEY" password="$ID" verbose=false`

# Specify Username and API Key Here
username=$RCLOUD_API_USER
apikey=$RCLOUD_API_KEY

# Helper functions
function die() { echo "[`timestamp`] $*"; exit 1; }
function timestamp() { echo "`date +%Y-%b-%d"-"%H"-"%M"-"%S"-"%Z`"; }
function strip() { echo $1 | tr -d "\r"; }

# Authenticate and make sure it logs in.
# Additionally get the Auth Token and Server URL
while read -r key value rest ; do
    if [[ $key = "X-Server-Management-Url:" ]]; then
        url=`strip $value`
    elif [[ $key = "X-Auth-Token:" ]]; then
        token=`strip $value`
    elif [[ $key = "HTTP/1.1" ]]; then
        status=`strip $value`
    fi
done <<< "`curl -s -i -H "X-Auth-User: $username" -H "X-Auth-Key: $apikey" \
           ${DEFAULT_AUTH_SERVER}`"

# We should get a 204, but that could change, so we accept any 200 status
if [[ ! $status =~ 20. ]]; then
    die "Failed to Auth, check the username and apikey variables. " \
        "Currently they are set to $username and $apikey"
fi

shopt -s nocasematch
serverlist=`curl -s -H "X-Auth-Token: $token" $url/servers`

# nb: set our field seperator to "\n" for the "for" loop below
OLDIFS=$IFS
IFS=`echo -en "\n"`

# Find our server id...this is magical...don't edit it
for server in `echo $serverlist | \
               awk -F':\\\\[' '{gsub("},{", "\n", $2); \
                                gsub(/\{|\}|\[|\]|\"/, "", $2); \
                                print $2}'`
do
    id=`echo $server | awk -F: '{if ($3 == "'$servername'") { \
                                     split($2, a, ","); print a[1]}}'`
    if [[ -n $id ]]; then break; fi
done

IFS=$OLDIFS

if [[ -z $id ]]; then
    die "Server not found, check the server name. " \
        "Currently it is set to $servername"
fi

# Create the server image
time=`timestamp`
tmp=`curl -s -X POST -H "X-Auth-Token: $token" \
                     -H "Content-type: application/json" \
     -d '{ "image" : {"serverId": '$id', \
                      "name": "'$imagename'-'$time'"}}' $url/images`

if [[ ! $tmp =~ "QUEUED" ]]; then
    die $tmp
fi
shopt -u nocasematch
echo "`hostname` imaging has been initiated: $imagename-$time"
