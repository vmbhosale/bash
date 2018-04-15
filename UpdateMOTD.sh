#!/bin/bash
TOTMEMINKB=`cat /proc/meminfo  | grep -i MemTotal | awk {'print $2'} | sed -e 's/^[ \t]*//'`
TOTMEMINMB=`echo 'scale=2;'$TOTMEMINKB'/(1024)' | bc`
TOTMEMINGB=`echo 'scale=2;'$TOTMEMINKB'/(1024*1024)' | bc`
MOTDCF=/etc/motd
/bin/cat > $MOTDCF << EOF
****************
NOTICE TO USERS
****************
This computer system is the private property of Eusiness Management Solutions LLC. [http://www.eusiness.com] and/or Eusiness Management Solutions LLC's client(s), whether individual, corporate or government.  It is for authorized use only. Users (authorized or unauthorized) have no explicit or implicit expectation of privacy.

Any or all uses of this system and all files on this system may be intercepted, monitored, recorded, copied, audited, inspected, and disclosed to your employer, to authorized site, government, and law enforcement personnel, as well as authorized officials of government agencies, both domestic and foreign.

By using this system, the user consents to such interception, monitoring, recording, copying, auditing, inspection, and disclosure at the discretion of such personnel or officials.  Unauthorized or improper use of this system may result in civil and criminal penalties and administrative or disciplinary action, as appropriate. By continuing to use this system you indicate your awareness of and consent to these terms and conditions of use. LOG OFF IMMEDIATELY if you do not agree to the conditions stated in this warning.
EOF
/bin/echo "" >> $MOTDCF
/bin/echo "MACHINE SPECS" >> $MOTDCF
/bin/echo "*************" >> $MOTDCF
/bin/echo "OS: `cat /etc/redhat-release`" >> $MOTDCF
/bin/echo "Kernel: `uname -r`" >> $MOTDCF
/bin/echo "Processor(s): `cat  /proc/cpuinfo | grep "processor" | wc -l`" >> $MOTDCF
/bin/echo "Processor(s) Model:  `cat /proc/cpuinfo | grep "model name" | head -1 | cut -d ':' -f2,2 | sed -e 's/^[ \t]*//'`" >> $MOTDCF
/bin/echo "Memory:  $TOTMEMINMB MB [ $TOTMEMINGB GB] " >> $MOTDCF
/bin/echo "Last Patched: `/bin/rpm -qa --last | head -1 | awk {'print $2" "$3" "$4" "$5" "$6" "$7'}`" >> $MOTDCF
