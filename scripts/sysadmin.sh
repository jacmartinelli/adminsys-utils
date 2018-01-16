#!/bin/bash

########################
# Parse option program #
########################

usage() {
echo """usage: $(basename $BASH_SOURCE) [-a | -st | -s <service_name>] [-h]

Options (only choose one):
  -s / --service <service_name>   Permet to check a service existance, and / or
                                  configure it
  -st / --stats                   Show some system stats, and start cpu warning
                                  monitoring
  -a / --all                      Show all services, and permit to configure
                                  them

Other options:
  -h / --help                     Display this message"""
}

action=""

while true ; do
    case "$1" in
        -h) usage;
            exit 0;;
         -a|--all) action="all";
                shift;;
         -st|--stats) action="stats";
                shift;;
         -s|--service) action="service"
                service="${2}"
                shift 1;
                shift 1;;
         *) shift; break;;
    esac
done

if [ -z "${action}" ] || [[ $action == "service" && -z "${service}" ]]; then
   usage
   exit 0
fi


####################################
# Set up some colors and constants #
####################################

RED='\033[0;91m'
GREEN='\033[0;92m'
BLUE='\033[0;94m'
NC='\033[0m' # No Color

VALUE="$BLUE"

CPU_LIMIT="80"

#######################################
# Install some softwares prerequisits #
#######################################

# Install iotop for IO disk checking
if ! command -v iotop > /dev/null; then
  echo "Installing htop"
  sudo apt-get install iotop -y > /dev/null
fi

# Install iotop for background launch of process
if ! command -v screen > /dev/null; then
  echo "Installing screen"
  sudo apt-get install screen -y > /dev/null
fi

#########################
# Define some functions #
#########################

# Check if a service exists

service_exists () {
  if service --status-all | grep -Fq "$1"; then
    return 0
  else
    return 1
  fi
}

# Ask to a program installation

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

# Display a title framed

title () {
  letter_number=${#1}
  new_size=$((letter_number + 4))
  echo ""
  printf '%'$new_size's\n' | tr ' ' -
  echo "| $1 |"
  printf '%'$new_size's\n' | tr ' ' -
  echo ""
}

# Display key - value with colors

disp() {
  printf "${1}${VALUE}"
  echo -e "${@:2}"
  printf "${NC}"
}

############################
# Real start of the script #
############################

title "Beginning of the script"

if [ $action == "all" ]; then

  ###################
  # Service listing #
  ###################

  title "Daemons presents"

  service --status-all | cut -d ' ' -f 6 | while read -r daemon; do
    if sudo apt-cache show $daemon 2&>1; then
      type=`sudo apt-cache show $daemon | grep '^Section' | cut -d ' ' -f 2`
      echo $type
    else
      echo "?"
    fi

    ports=""

    if ps -eaf | grep "$daemon" | grep -vq grep; then
      pid=`ps -eaf | grep "$daemon" | grep -v grep | tr -s " " | cut -d " " -f 2 | tr '\n' ' '`
      pid="${GREEN}${pid}${NC}"
      ports=`sudo netstat -peanut | grep -F "$pid" | tr -s " " | cut -d " " -f 1,4 | sed 's/^/    /'`
    else
      pid="${RED}non launched${NC}"
    fi

    if [ -z "$ports" ];then
      ports="    none"
    fi

    disp "  name: " "$daemon"
    printf "  pid: $pid\n"
    echo "  IP/ports linked:"
    echo "$ports"

  done

elif [ $action == "stats" ]; then

  #################
  # System config #
  #################

  title "Machine informations"

  disp "Distribution : " `cat /etc/*-release | grep "DISTRIB_ID=" | cut -d"=" -f2`
  disp "Distribution version : " `cat /etc/*-release | grep "DISTRIB_RELEASE=" | cut -d"=" -f2`
  disp "Distribution codename : " `cat /etc/*-release | grep "DISTRIB_CODENAME=" | cut -d"=" -f2`
  disp "Kernel version : " `uname -r`
  disp "Architecture : " `uname -m`
  echo "Hardware"
  disp "  - CPU number : " `nproc`
  disp "  - Total ram : " `cat /proc/meminfo | grep "MemTotal:" | tr -s " " | cut -d" " -f2,3`

  #########################
  # Current machine state #
  #########################

  title "Machine current state"

  disp "Current cpu usage: " `grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'`
  disp "Load average: " `uptime | cut -d ',' -f3-8 | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//'`
  disp "Memory free: " `free | grep Mem | awk '{print $3/$2 * 100.0}'`"%"
  echo "Disk information: "
  disp " - write : " `sudo iotop -b --iter=1 | grep "Actual DISK READ" | grep -v grep | tr "|" "\n" | sed -e 's/^[[:space:]]*//' | grep READ | tr -s " " | cut -d" " -f 4-`
  disp " - read : " `sudo iotop -b --iter=1 | grep "Actual DISK READ" | grep -v grep | tr "|" "\n" | sed -e 's/^[[:space:]]*//' | grep READ | tr -s " " | cut -d" " -f 4-`

  ###############
  # Cpu warning #
  ###############

  title "CPU monitoring"

  disp "CPU limit is set to " "${CPU_LIMIT}%"
  disp "To rattach the cpu monitoring process, do : " "screen -r cpuwarning"
  disp "To quit the session without killing it : " "CTRL+A then CTRL+D"

  # Kill previous cpu warning task if exists
  screen -S cpuwarning -X quit > /dev/null

  # Restart one
  screen -S cpuwarning -dm ./cpuwarning.sh $CPU_LIMIT

fi

##################
# End of program #
##################

title "End of program"
