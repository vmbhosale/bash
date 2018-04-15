#!/bin/bash
SCHED_SENTRY=ScD0NzRlODQ
APP_SENTRY=YjU5OWIyNzE
# DB_SENTRY=DBRiYTA5ZTF
NOW=`date +%d-%b-%Y-%H%M`

MYUID=`grep root /etc/passwd | cut -d ':' -f3,3`

if [ "$(id -u)" != "$MYUID" ]; then
    echo "This script must be run as root !" 1>&2
    exit 0
fi

function SCHED_PASS()
{
echo -n "Please enter scheduler user's public key, followed by [ENTER]:"
read key
if [ -n "$key" ]; then
[ ! -d /home/$SCHED_SENTRY/.ssh ] && /bin/mkdir /home/$SCHED_SENTRY/.ssh && /bin/chown -R $SCHED_SENTRY.$SCHED_SENTRY /home/$SCHED_SENTRY/.ssh && touch /home/$SCHED_SENTRY/.ssh/authorized_keys && /bin/chown -R $SCHED_SENTRY.$SCHED_SENTRY /home/$SCHED_SENTRY/.ssh/authorized_keys && /bin/chmod 644 /home/$SCHED_SENTRY/.ssh/authorized_keys
cd /home/$SCHED_SENTRY/.ssh
/bin/rm -rf `ls -t | tail -n +6`
[ -f authorized_keys ] && /bin/cp -p authorized_keys authorized_keys.$NOW
echo $key >> authorized_keys
else
echo "public key can not be empty!!"
fi
}

function APP_PASS()
{
echo -n "Please enter application user's public key, followed by [ENTER]:"
read key
if [ -n "$key" ]; then
[ ! -d /home/$SCHED_SENTRY/.ssh ] && /bin/mkdir /home/$SCHED_SENTRY/.ssh && /bin/chown -R $SCHED_SENTRY.$SCHED_SENTRY /home/$SCHED_SENTRY/.ssh && touch /home/$SCHED_SENTRY/.ssh/authorized_keys && /bin/chown -R $SCHED_SENTRY.$SCHED_SENTRY /home/$SCHED_SENTRY/.ssh/authorized_keys && /bin/chmod 644 /home/$SCHED_SENTRY/.ssh/authorized_keys
cd /home/$APP_SENTRY/.ssh
/bin/rm -rf `ls -t | tail -n +6`
[ -f authorized_keys ] && /bin/cp -p authorized_keys authorized_keys.$NOW
echo $key >> authorized_keys
else
echo "public key can not be empty!!"
fi
}

function DB_PASS()
{
echo -n "Please enter DB user's public key, followed by [ENTER]:"
read key
if [ -n "$key" ]; then
[ ! -d /home/$SCHED_SENTRY/.ssh ] && /bin/mkdir /home/$SCHED_SENTRY/.ssh && /bin/chown -R $SCHED_SENTRY.$SCHED_SENTRY /home/$SCHED_SENTRY/.ssh && touch /home/$SCHED_SENTRY/.ssh/authorized_keys && /bin/chown -R $SCHED_SENTRY.$SCHED_SENTRY /home/$SCHED_SENTRY/.ssh/authorized_keys && /bin/chmod 644 /home/$SCHED_SENTRY/.ssh/authorized_keys
cd /home/$DB_SENTRY/.ssh
/bin/rm -rf `ls -t | tail -n +6`
[ -f authorized_keys ] && /bin/cp -p authorized_keys authorized_keys.$NOW
echo $key >> authorized_keys
else
echo "public key can not be empty!!"
fi
}

case "$1" in
        app)
            APP_PASS
            ;;
# While deploying DB, it is expected that you enter a password
# In short, no ssh-key exchange is expected for DB operation
#        db)
#            DB_PASS
#            ;;
        sched)
            SCHED_PASS
            ;;
        *)
            echo $"Usage: $0 {app|sched}"
            exit 1
esac
