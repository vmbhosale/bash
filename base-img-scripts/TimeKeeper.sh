#!/bin/bash
# Author: Vikram Bhosale
# Date: Oct 3, 2013
# Goal: If the time is between START_HOUR and END_HOUR (work hours for a given timezone) and you are doing an operation that might interrupt users, you need to notify (via email) all client employees of a possible interruption automatically. This is expected work in conjunction with AppDeployCode (or likewise) scripts and send out an email to make sure that users are in loop. Yes, ideally you should not do anything during day in production but you know how it goes!

# Temp files
TMP_FILE01=`/usr/bin/openssl rand -base64 32 | sha256sum | base64 | head -c 15 ; echo`
# Please don't change below name to something else. It HAS TO BE time.txt. If you change it, you will need to modify a lot of other deploy related scripts
TZ_FILE=/tmp/time.txt

# STARTIME and ENDTIME have to be integers
# E.g. 6AM EST to 6AM PST is United States work hours in this case
START_HOUR=6
END_HOUR=21

# Finding hour of the day
TZ=":US/Eastern" date +%H > $TMP_FILE01
HOUR=`cat $TMP_FILE01`

if [[ ${HOUR} -ge ${START_HOUR} && ${HOUR} -lt ${END_HOUR} ]]; then
	echo "office time"
	echo "1" > $TZ_FILE
else
	echo "off hours"
	echo "0" > $TZ_FILE
fi
/bin/rm -rf $TMP_FILE01
