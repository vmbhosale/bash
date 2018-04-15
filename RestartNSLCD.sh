#!/bin/bash
# /usr/bin/yum -y downgrade nss nss-softokn* nss-sysinit openldap* pam*
/etc/rc.d/init.d/nslcd restart
