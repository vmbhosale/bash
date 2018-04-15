#!/bin/bash
/bin/echo "You will need to overwrite agent configuration. Make sure that you have client rackspace userid and corresponding API key!"
/bin/echo -n "Proceed (y/n) ?"
read ans
if [ $ans == "y" ]; then
/usr/local/bin/driveclient --configure
/bin/sleep 2
/bin/echo "Please make sure that driveclient is started, run /sbin/service driveclient start "
else
/bin/echo "Agent configuration was not touched."
fi
