#!/bin/bash
TOTMEMINKB=`cat /proc/meminfo  | grep -i MemTotal | awk {'print $2'} | sed -e 's/^[ \t]*//'`
TOTMEMINMB=`echo 'scale=2;'$TOTMEMINKB'/(1024)' | bc`
TOTMEMINGB=`echo 'scale=2;'$TOTMEMINKB'/(1024*1024)' | bc`
PIDS=`ps -A --sort -rss -o pid,comm,pmem,rss,etime | head -11 | grep -v PID | awk {'print $1'}`
PROCPERC=`ps -A --sort -rss -o pid,comm,pmem,rss,etime | head -11 | grep -v PID | awk {'print $3'}`
PIDSARRAY=( $PIDS )
PROCPERCARRAY=( $PROCPERC )
i=0
for PID in $PIDS
do
echo ---------------------Top process# `expr $i +  1`-----------------------------
echo "`ps hp $PID`"
echo "Process memory footprint : ${PROCPERCARRAY[i]}% (of total $TOTMEMINMB MB/$TOTMEMINGB GB)"
i=`expr $i +  1`
done
