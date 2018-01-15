#!/bin/bash

######################
# Set up some colors #
######################

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Install some softwares prerequisits

# Install iotop for IO disk checking
if ! command -v iotop > /dev/null; then
  sudo apt-get install iotop -y
fi

# Install iotop for IO disk checking
if ! command -v screen > /dev/null; then
  sudo apt-get install screen -y
fi

echo "Beginning of the script !"

service_exists () {
  if service --status-all | grep -Fq "$1"; then
    return 0
  else
    return 1
  fi
}

to_install () {
  while true; do
    read -p "$1" yn
    case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
}

if service_exists 'bind9'; then
  echo "- DNS server is installed"
elif to_install "-> Do you wish to install a DNS server ? "; then
  sudo apt-get install bind9 bind9utils bind9-doc -y > /dev/null
fi

if service_exists 'isc-dhcp-server'; then
  echo "- DHCP Server is installed"
elif to_install "-> Do you wish to install a DHCP server ? "; then
  sudo apt-get install isc-dhcp-server -y
fi

if service_exists 'slapd'; then
  echo "- LDAP Server is installed"
elif to_install "-> Do you wish to install a LDAP server ? "; then
  sudo apt-get install slapd ldap-utils -y > /dev/null
fi


# Service listing :

echo "Daemons presents"

service --status-all | cut -d ' ' -f 6 | while read -r daemon; do
  #echo ">$daemon<"
  if sudo apt-cache show $daemon 2&>1; then
    type=`sudo apt-cache show $daemon | grep '^Section' | cut -d ' ' -f 2`
    echo $type
  else
    echo "?"
  fi

  if ps -eaf | grep $daemon | grep -vq grep; then
    pid=`ps -eaf | grep $daemon | grep -v grep | tr -s " " | cut -d " " -f 2 | tr '\n' ' '`
    pid="${GREEN}${pid}${NC}"
    ports=`sudo netstat -peanut | grep "$pid" | tr -s " " | cut -d " " -f 1,4 | sed 's/^/    /'`
  else
    pid="${RED}non launched${NC}"
    ports="    none"
  fi

  echo "  name: $daemon"
  printf "  pid: $pid\n"
  echo "  IP/ports linked:"
  echo "$ports"

done

# System config

echo "------------------------"
echo "| Machine informations |"
echo "------------------------"

echo "Distribution : "`cat /etc/*-release | grep "DISTRIB_ID=" | cut -d"=" -f2`
echo "Distribution version : "`cat /etc/*-release | grep "DISTRIB_RELEASE=" | cut -d"=" -f2`
echo "Distribution codename : "`cat /etc/*-release | grep "DISTRIB_CODENAME=" | cut -d"=" -f2`
echo "Kernel version : "`uname -r`
echo "Architecture : "`uname -m`
echo "Hardware"
echo "  - CPU number : "`nproc`
echo "  - Total ram : "`cat /proc/meminfo | grep "MemTotal:" | tr -s " " | cut -d" " -f2,3`


# Current machine state

echo "-------------------------"
echo "| Machine current state |"
echo "-------------------------"

echo "Current cpu usage: "`grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'`
echo "Load average: "`uptime | cut -d ',' -f3-8 | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//'`
echo "Memory free: "`free | grep Mem | awk '{print $3/$2 * 100.0}'`"%"
echo "Disk information: "
sudo iotop -b --iter=1 | grep "Actual DISK READ" | grep -v grep | tr "|" "\n" | sed -e 's/^[[:space:]]*//' | sed 's/.*/ - &/'

###############
# Cpu warning #
###############

# Kill previous cpu warning task if exists
screen -S cpuwarning -X quit > /dev/null

# Restart one
screen -S cpuwarning -dm ./cpuwarning.sh 80
