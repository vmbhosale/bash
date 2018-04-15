#!/bin/bash
fss="/apps"
for fs in $fss
do
du -xB M --max-depth=2 $fs | sort -rn | head -n 10
done
