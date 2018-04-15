#!/bin/bash
NOTIFYLIST=sysadmins
PROCESS="tomcat"
NOW=`date +%d-%b-%Y-%H%M`
LOGFILE=/tmp/$NOW.log
TOMCAT_HOME=/apps/tomcat
if [ -d $TOMCAT_HOME ]
then
TomcatProcExists=`/bin/ps -ef | grep $PROCESS | grep -v "grep" | wc -l`
if [ $TomcatProcExists -gt 0 ]; then
echo "[Yonnor] Tomcat is online."
else
/bin/echo "===========================" > $LOGFILE
/bin/echo "=== TOMCAT CRASH REPORT ===" >> $LOGFILE
/bin/echo "===========================" >> $LOGFILE
/bin/echo "CATALINA LOG:" >> $LOGFILE
/bin/echo "===========================" >> $LOGFILE
/usr/bin/tail -200 $TOMCAT_HOME/logs/catalina.out >> $LOGFILE
/bin/echo "" >> $LOGFILE
/bin/echo "" >> $LOGFILE
/bin/echo "===========================" >> $LOGFILE
/bin/echo "SYSTEM LOG:" >> $LOGFILE
/bin/echo "===========================" >> $LOGFILE
/usr/bin/tail -100 /var/log/messages >> $LOGFILE
/bin/echo "[Yonnor] Tomcat seems to be offline, I am going to try and start it now!"
/bin/mail -s "[Yonnor] Tomcat crash incidence report. [FYI, restart has been attempted]" $NOTIFYLIST < $LOGFILE
/sbin/service tomcat start
/bin/rm -rf $LOGFILE
fi
else
echo "[Yonnor] Tomcat may not have been setup on this system!"
fi
