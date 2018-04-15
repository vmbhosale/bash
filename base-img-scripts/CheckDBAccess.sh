#!/bin/bash
DB_HOME=/apps/mariadb
if [ ! -d $DB_HOME ]; then
/bin/echo "Oops, I don't see $DB_HOME, without this I can not proceed!"
exit 1
else
if [ ! -f $DB_HOME/bin/mysql ]; then
/bin/echo "I don't see $DB_HOME/bin/mysql, cant proceed without it!!"
exit 1
else
/bin/echo -e -n "Please enter database server ip, followed by [ENTER]: \n"
read DBIP
/bin/echo -e -n "Please enter database server user under investigation, followed by [ENTER]: \n"
read DBUSER
$DB_HOME/bin/mysql -u $DBUSER -P 37637 -h $DBIP -p
fi
fi
