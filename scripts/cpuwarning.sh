#!/bin/bash

if [ -z "$1" ];then
  cpu_limit="80"
else
  cpu_limit="$1"
fi

echo "CPU warning limit set to '$cpu_limit'"

while true; do
  sleep 1
  cpuPerc=`grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' | cut -d'.' -f1`
  if [ "$cpuPerc" -ge "$cpu_limit" ]; then
    currentDate=`date "+%x %H:%M:%S"`
    echo "CPU LIMIT REACHED at $currentDate : $cpuPerc"
  fi
done
