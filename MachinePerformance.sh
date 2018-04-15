#!/bin/bash
echo "Please type control+c once you are done...."
echo ""
/usr/bin/vmstat 1 1;for ((;;));do date; vmstat 10 2 | tail -n1;done
