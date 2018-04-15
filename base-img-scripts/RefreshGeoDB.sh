#!/bin/bash
MONTHYEAR=`date +%b-%Y`
GEO_DATA_HOME=/apps/nginx/GeoData
GEO_DATA=GeoLiteCity.dat.gz
GEO_DATA_FILE=GeoLiteCity.dat
GEO_DATA_DOWNLOAD_LINK=http://geolite.maxmind.com/download/geoip/database
GEO_DATA_LICENSE=LICENSE.txt
GEO_DATA_LICENSE_LOG=GeoDataLicense.log
GEO_DATA_LOG=GeoData.log
ARCHIVES=archives

if [ -d $GEO_DATA_HOME ]; then
/usr/bin/wget --spider $GEO_DATA_DOWNLOAD_LINK/$GEO_DATA
if [ "$?" -eq "0" ]; then
# Checking to see if GeoData license file exists
/usr/bin/wget --spider $GEO_DATA_DOWNLOAD_LINK/$GEO_DATA_LICENSE
if [ "$?" -eq "0" ]; then
# Backing up old database,license and log files
[ -f $GEO_DATA_HOME/$GEO_DATA_FILE ] && /bin/mkdir -p $GEO_DATA_HOME/$ARCHIVES/$MONTHYEAR && /bin/mv $GEO_DATA_HOME/$GEO_DATA_FILE $GEO_DATA_HOME/$ARCHIVES/$MONTHYEAR
[ -f $GEO_DATA_HOME/$GEO_DATA_LICENSE ] && /bin/mv $GEO_DATA_HOME/$GEO_DATA_LICENSE $GEO_DATA_HOME/$ARCHIVES/$MONTHYEAR
[ -f $GEO_DATA_HOME/$GEO_DATA_LICENSE_LOG ] && /bin/mv $GEO_DATA_HOME/$GEO_DATA_LICENSE_LOG $GEO_DATA_HOME/$ARCHIVES/$MONTHYEAR
[ -f $GEO_DATA_HOME/$GEO_DATA_LOG ] && /bin/mv $GEO_DATA_HOME/$GEO_DATA_LOG $GEO_DATA_HOME/$ARCHIVES/$MONTHYEAR
/usr/bin/wget -O $GEO_DATA_HOME/$GEO_DATA_LICENSE $GEO_DATA_DOWNLOAD_LINK/$GEO_DATA_LICENSE -o $GEO_DATA_HOME/$GEO_DATA_LICENSE_LOG
if [ "$?" -eq "0" ]; then
/usr/bin/wget -O $GEO_DATA_HOME/$GEO_DATA $GEO_DATA_DOWNLOAD_LINK/$GEO_DATA -o $GEO_DATA_HOME/$GEO_DATA_LOG || echo "Could not download $GEO_DATA_DOWNLOAD_LINK/$GEO_DATA"
/bin/chown root.apache $GEO_DATA_HOME/*
/bin/rm -rf $GEO_DATA_HOME/$GEO_DATA_FILE
/bin/gunzip $GEO_DATA_HOME/$GEO_DATA
/bin/chmod 440 $GEO_DATA_HOME/*
/bin/chmod 550 $GEO_DATA_HOME/$ARCHIVES/$MONTHYEAR
# Remove all but last 5 archives
for d in `cd $GEO_DATA_HOME/$ARCHIVES ; ls -t | tail -n +6`; do /bin/rm -rf $d ; done
else
echo "Could not download $GEO_DATA_DOWNLOAD_LINK/$GEO_DATA_LICENSE"
fi
else
echo "$GEO_DATA_DOWNLOAD_LINK/$GEO_DATA_LICENSE is inaccesible!"
fi
else
echo "$GEO_DATA_DOWNLOAD_LINK/$GEO_DATA is inaccesible!"
fi
fi
