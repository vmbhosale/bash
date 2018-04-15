#!/bin/bash
NOTIFYLIST=sysadmins
CLOUDINFO=.Cloud
CLOUDMGR=dummy
CLOUDKEY=dummy

[ -f /root/$CLOUDINFO ] && FILESIZE=`stat -c%s /root/$CLOUDINFO` || FILESIZE=0
if [ -f /root/$CLOUDINFO -a $FILESIZE -ne 0 ]; then
. /root/.bash_profile
CLOUDMGR=`cat /root/$CLOUDINFO | grep CLOUDMGR | cut -d '=' -f2,2`
CLOUDKEY=`cat /root/$CLOUDINFO | grep CLOUDKEY | cut -d '=' -f2,2`
else
echo "$0, I dont see master user/password file."
/bin/mail -s "$0, I dont see master cloud file." $NOTIFYLIST < /dev/null
exit 1
fi

# Auth Server (change it if you have a custom swift install)
AUTH_SERVER_LON=https://lon.auth.api.rackspacecloud.com/v1.0
AUTH_SERVER_US=https://auth.api.rackspacecloud.com/v1.0
DEFAULT_AUTH_SERVER=${AUTH_SERVER_US}

# Set it to true if you want to use servicenet to upload.
SERVICENET=false

# Make it quiet or not
QUIET=false

function msg {
    echo $1
}

function check_api_key {
    temp_file=$(mktemp /tmp/.rackspace-cloud.XXXXXX)
    local good_key=
    [[ -z ${AUTH_SERVER} ]] && AUTH_SERVER=${DEFAULT_AUTH_SERVER}

    curl -k -s -f -D -         -H "X-Auth-Key: ${RCLOUD_API_KEY}"         -H "X-Auth-User: ${RCLOUD_API_USER}"         ${AUTH_SERVER} >${temp_file} && good_key=1

    if [[ -z $good_key ]];then
msg "You have a bad username or api/key." "Bad Username/API Key" 200 25
        exit 1;
    fi
while read line;do
        [[ $line != X-* ]] && continue
line=${line#X-}
        key=${line%: *};key=${key//-/}
        value=${line#*: }
        value=$(echo ${value}|tr -d '\r')
        eval "export $key=$value"
    done < ${temp_file}

    if [[ -z ${StorageUrl} ]];then
echo "Invalid auth url."
        exit 1
    fi

if [[ ${SERVICENET} == true || ${SERVICENET} == True || ${SERVICENET} == TRUE ]];then
StorageUrl=${StorageUrl/https:\/\//https://snet-}
        StorageUrl=${StorageUrl/http:\/\//http://snet-}
    fi

rm -f ${temp_file}
}

function download_object {
    local container=$1
object=$2

uploaded=

    [[ $QUIET != "true" ]] && echo "Downloading ${file}"
    curl -k -o ${object} -f -X GET -H "X-Auth-Token: ${StorageToken}" ${StorageUrl}/${container}/${object}
    [[ $QUIET != "true" ]] && echo
}

function container_cname {
    local cont=$@
    curl -s -f -k -I -H "X-Auth-Token: ${AuthToken}" $StorageUrl/$cont|grep "X-Container-Meta-Cname"|sed -e 's/\r$//;s/X-Container-Meta-Cname: //'|tr -d '\r'
}
set -e

RCLOUD_API_USER=`$JASYPT_HOME/bin/decrypt.sh input="$CLOUDMGR" password="$ID" verbose=false`
RCLOUD_API_KEY=`$JASYPT_HOME/bin/decrypt.sh input="$CLOUDKEY" password="$ID" verbose=false`
AUTH_SERVER=$DEFAULT_AUTH_SERVER

while getopts ":c:dxsu:k:a:C:qm:" opt; do
case $opt in
    q)
    QUIET=true
    ;;
    s)
    SERVICENET=true
    ;;
    u)
    RCLOUD_API_USER=$OPTARG
    ;;
    k)
    RCLOUD_API_KEY=$OPTARG
    ;;
    a)
    AUTH_SERVER=$OPTARG
    ;;
    c)
    container=$OPTARG
    ;;
    x)
    set -x
exit 0
    ;;
    \?)
    echo "Invalid option: -$OPTARG" >&2
    help
exit 1
    ;;
  esac
done
shift $((OPTIND-1))

[[ -n ${RCLOUD_API_KEY} && -n ${RCLOUD_API_USER} ]] && check_api_key

ARGS=$@
if [[ -z ${ARGS} ]];then
msg "No files specified." "No files specified." 200 50
    exit 1
fi

[[ -z ${container} ]] && exit 1

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for arg in $ARGS;do

file=${arg}
download_object ${container} ${file}
done
