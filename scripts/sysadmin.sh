#!/bin/bash

########################
# Parse option program #
########################

CPU_LIMIT="80"
EDITOR="${EDITOR:-vim}"

usage() {
echo """usage: $(basename $BASH_SOURCE) [-a | -st | -s <service_name>] [-c] [-l <limit>] [-h]

Options (only choose one):
  -s / --service <service_name>   Permet to check a service existance, and / or
                                  configure it
  -st / --stats                   Show some system stats, and start cpu warning
                                  monitoring
  -a / --all                      Show all services, and their characteristics

Other options:
  -c / --cpu-monitoring           Launch the CPU monitoring daemon
  -l / --cpu-limit <limit>        Set the CPU limit for warn of load (1-99). Set
                                  this setting enable cpu monitoring
  -h / --help                     Display this message"""
}

action=""
cpu_mon="false"

while true ; do
    case "$1" in
         -a|--all) action="all";
                shift;;
         -st|--stats) action="stats";
                shift;;
         -c|--cpu-monitoring) cpu_mon="yes";
                shift;;
         -s|--service) action="service"
                service="${2}"
                shift 1;
                shift 1;;
         -l|--cpu-limit) cpu_mon="yes";
                CPU_LIMIT="${2}"
                shift 1;
                shift 1;;
         *) shift; break;;
    esac
done

if [ -z "${action}" ] || [[ $action == "service" && -z "${service}" ]] && [[ $cpu_mon == "false" || -z "$CPU_LIMIT" ]]; then
   usage
   exit 0
fi


####################################
# Set up some colors and constants #
####################################

RED='\033[0;91m'
GREEN='\033[0;92m'
MAGENTA='\033[0;95m'
BLUE='\033[0;94m'
NC='\033[0m' # No Color

COLOR_EMPHASIS="$BLUE"

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

# Install ifstat network monitoring
if ! command -v ifstat > /dev/null; then
  echo "Installing ifstat"
  sudo apt-get install ifstat -y > /dev/null
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
    read -p "> $1" yn
    case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
}

network_monitoring () {
  ifstat &
  pid=$!
  sleep 1
  disown
  sudo kill -9 $pid 2> /dev/null
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
  printf "${1}${COLOR_EMPHASIS}"
  echo -e "${@:2}"
  printf "${NC}"
}

# Display informations about a service

getServiceFacts() {
  daemon=$1
  if sudo apt-cache show $daemon &> /dev/null; then
    type=`sudo apt-cache show $daemon | grep '^Section' | cut -d ' ' -f 2 | head -n 1`
    echo $type
  else
    echo "?"
  fi

  ports=""

  if ps -eaf | grep "$daemon" | grep -vq grep; then
    pids_list=`ps -eaf | grep "$daemon" | grep -v grep | tr -s " " | cut -d " " -f 2 | tr '\n' ' '`
    pids=$(echo $pids_list | tr ";" "\n")
    pids_list="${GREEN}${pids_list}${NC}"
    for pid in $pids
    do
      ports="$ports"`sudo netstat -peanut | grep -F "$pid" | tr -s " " | cut -d " " -f 1,4 | sed 's/^/    /'`
    done
  else
    pid="${RED}non launched${NC}"
  fi

  if [ -z "$ports" ];then
    ports="    none"
  fi

  disp "  name: " "$daemon"
  printf "  pid(s): $pids_list\n"
  echo "  IP/ports linked:"


  [ "$ports" == "    none" ] || printf "$MAGENTA"
  echo "$ports"
  [ "$ports" == "    none" ] || printf "$NC"
}

proceed_service() {

    service="$1"
    skip_install="${2:-false}"

    skip="false"

    if [ $skip_install == "false" ] && ! which "$service" > /dev/null ; then
      echo "Package '$service' not found! Install? (y/n)"
      if to_install; then
        if ! sudo apt-get install "$service" -y &> /dev/null; then
          printf "${RED}Failed to install package $service ${NC}\n"
          skip="true"
        else
          printf "${GREEN}Package sucessfully installed${NC}\n"
        fi
      else
        skip="true"
      fi
    fi

    if service_exists "$service"; then
      echo "Here is some facts about this service :"
      getServiceFacts "$service"
    else
      printf "${RED}No service found with this name ..${NC}\n"
    fi

    if [ ! $skip == "true" ]; then

      if [ -f "/var/lib/dpkg/info/$service.conffiles" ]; then
        echo "Do you want to edit it's confs files ? (y/n)"
        if to_install; then
          $EDITOR `cat /var/lib/dpkg/info/$service.conffiles`
        fi
      else
        printf "${RED}No configurations files found for this package ..${NC}\n"
      fi

    fi

}

################################
################################
### Real start of the script ###
################################
################################

title "Beginning of the script"

####################
# Service specific #
####################

if [[ ! -z "$action" ]] && [ $action == "service" ] && [ ! -z $service ]; then

  proceed_service "$service"

###################
# Service listing #
###################

elif [[ ! -z "$action" ]] && [ $action == "all" ]; then

  title "Daemons presents"

  service --status-all | cut -d ' ' -f 6 | while read -r daemon; do

    getServiceFacts "$daemon"

  done

  echo ""
  echo "Do you want to configure one service ? (empty is none)"
  read -p "> $1" service_name

  if [ -z "$service_name" ]; then
    echo "Nothing entered - Skipped"
  else
    proceed_service "$service_name" "yes"
  fi

#################
# System config #
#################

elif [ ! -z "$action" ] && [ $action == "stats" ]; then

  title "Machine informations"

  disp "Distribution : " `cat /etc/*-release | grep "DISTRIB_ID=" | cut -d"=" -f2`
  disp "Distribution version : " `cat /etc/*-release | grep "DISTRIB_RELEASE=" | cut -d"=" -f2`
  disp "Distribution codename : " `cat /etc/*-release | grep "DISTRIB_CODENAME=" | cut -d"=" -f2`
  disp "Kernel version : " `uname -r`
  disp "Architecture : " `uname -m`
  echo "Hardware"
  disp "  - CPU number : " `nproc`
  disp "  - Total ram : " `cat /proc/meminfo | grep "MemTotal:" | tr -s " " | cut -d" " -f2,3`

  title "Machine current state"

  disp "Current cpu usage: " `grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'`
  disp "Load average: " `uptime | cut -d ',' -f3-8 | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//'`
  disp "Memory free: " `free | grep Mem | awk '{print $3/$2 * 100.0}'`"%"
  echo "Disk information: "
  disp " - write : " `sudo iotop -b --iter=1 | grep "Actual DISK READ" | grep -v grep | tr "|" "\n" | sed -e 's/^[[:space:]]*//' | grep READ | tr -s " " | cut -d" " -f 4-`
  disp " - read : " `sudo iotop -b --iter=1 | grep "Actual DISK READ" | grep -v grep | tr "|" "\n" | sed -e 's/^[[:space:]]*//' | grep READ | tr -s " " | cut -d" " -f 4-`

  title "Network informations"

  network_monitoring

fi

###############
# Cpu warning #
###############

if [ ! -z $CPU_LIMIT ] && [ $cpu_mon == "yes" ]; then

  title "CPU monitoring"

  disp "CPU limit is set to " "${CPU_LIMIT}%"
  disp "To rattach the cpu monitoring process, do : " "screen -r cpuwarning"
  disp "To quit the session without killing it : " "CTRL+A then CTRL+D"

  # Kill previous cpu warning task if exists
  screen -S cpuwarning -X quit > /dev/null

  # Restart one
  screen -S cpuwarning -dm ./cpuwarning.sh $CPU_LIMIT

fi

#########################
#########################
### End of the script ###
#########################
#########################

title "End of program"
