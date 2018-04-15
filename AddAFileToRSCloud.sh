#!/bin/bash
NOTIFYLIST=sysadmins
CLOUDINFO=.Cloud

[ -f /root/$CLOUDINFO ] && FILESIZE=`stat -c%s /root/$CLOUDINFO` || FILESIZE=0
if [ -f /root/$CLOUDINFO -a $FILESIZE -ne 0 ]; then
. /root/$CLOUDINFO
. /root/.bash_profile
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

function put_object {
    local container=$1
    local file=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $2)
    local dest_name=$3
    if [[ -n $3 ]];then
object=$3
    else
object=${file}
    fi
object=$(basename ${object})
    #url encode in sed yeah i am not insane i have googled that
object=$(echo $object|sed -e 's/%/%25/g;s/ /%20/g;s/ /%09/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/\*/%2a/g;s/+/%2b/g; s/,/%2c/g; s/-/%2d/g; s/\./%2e/g; s/:/%3a/g; s/;/%3b/g; s//%3e/g; s/?/%3f/g; s/@/%40/g; s/\[/%5b/g; s/\\/%5c/g; s/\]/%5d/g; s/\^/%5e/g; s/_/%5f/g; s/`/%60/g; s/{/%7b/g; s/|/%7c/g; s/}/%7d/g; s/~/%7e/g; s/ /%09/g;')

    if [[ ! -e ${file} ]];then
msg "Cannot find file ${file}" "Cannot find file" 200 25
        exit 1
    fi
    #MaxOSX
    if file -I 2>&1 | grep -q "invalid option" ;then
local ctype=$(file -bi ${file});ctype=${ctype%%;*}
    else
local ctype=$(file -bI ${file});ctype=${ctype%%;*}
    fi
if [[ -e /sbin/md5 ]];then
local etag=$(md5 ${file});etag=${etag##* }
    else
local etag=$(md5sum ${file});etag=${etag%% *} #TODO progress
    fi
if [[ -z ${ctype} || ${ctype} == *corrupt* ]];then
ctype="application/octet-stream"
    fi
if [[ -n ${content_type} ]];then
ctype=${content_type}
    fi
uploaded=

    options=""
    if [[ $QUIET == "true" ]];then
options="-s"
    fi

if [[ ${container} == */* ]];then
object="${container#*/}/${object}"
        container=${container%%/*}
    fi

    [[ $QUIET != "true" ]] && echo "Uploading ${file}"
    curl ${options} -k -o/dev/null -f -X PUT -T ${file} -H "ETag: ${etag}" -H "Content-type: ${ctype}" -H "X-Auth-Token: ${StorageToken}" ${StorageUrl}/${container}/${object}
    [[ $QUIET != "true" ]] && echo

}

set -e

RCLOUD_API_USER=`$JASYPT_HOME/bin/decrypt.sh input="$CLOUDMGR" password="$ID" verbose=false`
RCLOUD_API_KEY=`$JASYPT_HOME/bin/decrypt.sh input="$CLOUDKEY" password="$ID" verbose=false`
AUTH_SERVER=$DEFAULT_AUTH_SERVER


content_type=

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
    C)
    content_type=$OPTARG
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
tarname=

    #MacOsX
    if readlink -f 2>&1 | grep -q illegal;then
        file=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' ${arg})
    else
file=$(readlink -f ${arg})
    fi
dest_name=

    [[ -e ${file} ]] || {
        echo "$file does not seem to exist."
        continue
    }
    [[ -f ${file} || -d ${file} ]] || {
        echo "$file does not seem a file or directory."
        continue
    }
    if [[ -d ${file} ]];then
if [[ -w ./ ]];then
tardir="."
        else
tardir=/tmp
        fi
tarname=${tardir}/${arg}-cf-tarball.tar.gz #in case if already exist we don't destruct it
        dest_name=${arg}.tar.gz
        tar cvzf $tarname ${arg}
        file=${tarname}
    fi
put_object ${container} ${file} ${dest_name}
    [[ -n ${tarname} ]] && rm -f ${tarname}
done
