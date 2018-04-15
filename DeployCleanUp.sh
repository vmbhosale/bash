#!/bin/bash
# Goal is to delete residues of deploy process
# This script is expected to delete all files and folders under /apps/DeployStaging that are 12 hours old
DEPLOYPLAYAREA=/apps/DeployStaging
GITOLITEADMIN=gitolite
cd $DEPLOYPLAYAREA
for client in `ls -d *`
do
cd $DEPLOYPLAYAREA/$client
for directory in `find . -type d -user gitolite -mmin -720`
do
/bin/rm -rf $directory
done
for f in `find . -type f -user gitolite -mmin -720`
do
/bin/rm -rf $f
done
done
