#!/bin/bash

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
else
echo -n "Please enter exact path of ssl certificate,E.g. /tmp/server.crt ,followed by [ENTER]:"
read CRT
[ ! -f $CRT ] && echo "I don't see your certificate, make sure path is correct !" && exit 1
/usr/bin/openssl x509 -in $CRT -text -noout | egrep "Issuer|Not Before|Not After"
fi
