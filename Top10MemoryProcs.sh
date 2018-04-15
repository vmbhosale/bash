#!/bin/bash
ps -A --sort -rss -o pid,comm,pmem,rss | head -11
