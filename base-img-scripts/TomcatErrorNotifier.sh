#!/bin/bash
TOMCAT_HOME="/apps/tomcat"
NOTIFYLIST=sysadmins
IDENTIFIER1="ERROR"
IDENTIFIER2="NullPointerException"
LOGFILE=ezmgmt.log
TMP_FILE01=/tmp/`tr -cd '[:alnum:]' < /dev/urandom | fold -w15 | head -n1`.tmp
NEWTOKEN=`tr -cd '[:alnum:]' < /dev/urandom | fold -w50 | head -n1`
TOKENHOLDER=/tmp/.tomcat_monitor.token
[ -f $TOKENHOLDER ] && SEARCH_TOKEN=`cat $TOKENHOLDER`

if [ -f $TOMCAT_HOME/logs/$LOGFILE ]; then
        ERRORS=`/bin/sed '1,/'$SEARCH_TOKEN'/d' $TOMCAT_HOME/logs/$LOGFILE | egrep "$IDENTIFIER1|$IDENTIFIER2" | wc -l`
                if [ $ERRORS -gt 0 ]; then
                        /bin/sed '1,/'$SEARCH_TOKEN'/d' $TOMCAT_HOME/logs/$LOGFILE > $TMP_FILE01
                        /bin/mail -s "[Yonnor] ezManagement Error Notification Service" $NOTIFYLIST < $TMP_FILE01
                else
                        echo "I don't see any error's in Tomcat log!"
                fi
/bin/echo "$NEWTOKEN" >> $TOMCAT_HOME/logs/$LOGFILE
/bin/echo "$NEWTOKEN" > $TOKENHOLDER
/bin/rm -rf $TMP_FILE01
fi
