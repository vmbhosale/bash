#!/bin/bash
# Shutdown Applications
/sbin/service tomcat stop
/sbin/service httpd stop
# Wait for gracefull App exists
sleep 5
# Update System
/usr/bin/yum -y update > /tmp/UpdateSystem.log.`date +%d-%b-%Y-%H%M`
# Reboot System
/sbin/shutdown -r now
