#!/bin/bash
NEWHOSTNAME=`hostname`
DOMAIN=eusiness.com
LDAPMASTER=108.166.91.217
NAGIOSMASTER=108.171.184.72
MYIP=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2`
MYPRIVATEIP=`/sbin/ifconfig eth1 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2`
GLOBALSCRIPTSLOC=/usr/local/scripts
NOTIFYLIST=sysadmins
CLIENT=nullclient
REPO=nullrepo
TYPE=nulltype
CLIENTINFO=.clientinfo

function GET_CLIENT_DETAILS()
{
echo -n "Please enter client name (E.g eusiness), followed by [ENTER]:"
read CLIENT
echo -n "Please enter client repo (E.g. ezmgmt), followed by [ENTER]:"
read REPO
echo -n "Please enter client repo type (E.g. prod), followed by [ENTER]:"
read TYPE
if [ -z "$CLIENT" -o -z "$REPO" -o -z "$TYPE" ]; then
/bin/echo "I can not initialize this server without requested information!"
exit 1
else
echo "CLIENT=$CLIENT" > ~/$CLIENTINFO
echo "REPO=$REPO" >> ~/$CLIENTINFO
echo "TYPE=$TYPE" >> ~/$CLIENTINFO
/bin/chmod 444 ~/$CLIENTINFO
fi
}

function RESET_ROOT_PASSWORD()
{
PASS=`date +%s | sha256sum | base64 | head -c 11 ; echo`
/bin/echo $PASS | passwd --stdin root
/bin/echo "Reset root password..."
}

function GET_NEWHOSTNAME()
{
IP1=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f1,1`
IP2=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f2,2`
IP3=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f3,3`
IP4=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f4,4`
NEWHOSTNAME=e$IP1$IP2$IP3$IP4
}

function SET_NEWHOSTNAME()
{
GET_NEWHOSTNAME
/bin/hostname -v $NEWHOSTNAME
}

function ETCHOSTS()
{
/bin/echo "Updating /etc/hosts..."
/bin/cat > /etc/hosts << EOF
127.0.0.1  $NEWHOSTNAME localhost localhost.localdomain
$LDAPMASTER ldapmaster.$DOMAIN ldapmaster
$NAGIOSMASTER nagiosmaster.$DOMAIN nagiosmaster
$MYPRIVATEIP $NEWHOSTNAME.$DOMAIN $NEWHOSTNAME
$MYIP $NEWHOSTNAME.$DOMAIN $NEWHOSTNAME
EOF
}

function CONFIGURE_POSTFIX()
{
/bin/echo "Updating postfix..."
/bin/sed -i 's/HOSTNAME/'$NEWHOSTNAME'/g' /etc/postfix/main.cf
/bin/sed -i 's/HOSTNAME/'$NEWHOSTNAME'/g' /etc/postfix/generic
/usr/sbin/postmap /etc/postfix/generic
/sbin/service postfix restart
}

function CONFIGURE_ROOTID()
{
/bin/echo "Updating ROOT ID..."
ROOTPROFCF=/root/.bash_profile
IP1=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f1,1`
IP2=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f2,2`
IP3=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f3,3`
IP4=`/sbin/ifconfig eth0 | grep -i 'Bcast' | awk {'print $2'} | cut -d ':' -f2,2 | cut -d '.' -f4,4`
EUSINESS=38746377
ROOTIDVAL=$(($IP1*$IP2*$IP3*$IP4*$EUSINESS))
/bin/sed -i '/'ID'/ d' $ROOTPROFCF
echo "ID=$ROOTIDVAL" >> $ROOTPROFCF
echo "export ID" >> $ROOTPROFCF

}

# This function updates the system and reboots it
function UPDATESYSTEM()
{
/bin/echo "Updating system..."
/usr/bin/yum -y update
}

function REBOOTSYSTEM()
{
/bin/mail -s "$NEWHOSTNAME [APP] has been initialized but needs to be configured!" $NOTIFYLIST < /dev/null
/sbin/shutdown -r now
}

function CONFIGURE_NETWORK_HOSTNAME()
{
/bin/sed -i '/HOSTNAME/ d' /etc/sysconfig/network
echo "HOSTNAME=$NEWHOSTNAME" >> /etc/sysconfig/network
}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
else
	GET_CLIENT_DETAILS
        SET_NEWHOSTNAME
        ETCHOSTS
        CONFIGURE_NETWORK_HOSTNAME
        CONFIGURE_ROOTID
        CONFIGURE_POSTFIX
fi
