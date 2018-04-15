#!/bin/bash
/usr/bin/top -b -n 1 | sed -e "1,6d" | head -11
