#!/bin/bash

echo "CPU warning limit set to '$1'"

while true; do
  sleep 1
  cpuPerc=`grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' | cut -d'.' -f1`
  if [ "$cpuPerc" -ge "$1" ]; then
    currentDate=`date "+%x %H:%M:%S"`
    echo "CPU LIMIT REACHED at $currentDate : $cpuPerc"
  fi
done
