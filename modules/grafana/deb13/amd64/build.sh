#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic

# Aux functions

# debug
#   desc: Display a debug message if LOGLEVEL is DEBUG
#   params:
#     $1 - Debug message
#   return (status code/stdout):
debug() {
  if [[ "$LOGLEVEL" == "DEBUG" ]]; then
    echo $1
  fi
}

installation(){
  debug "grafana.installation DEBUG [`date +"%Y-%m-%d %T"`] Adding Grafana OSS repo and install Grafana"
  # Procedure as it's documented at https://grafana.com/docs/grafana/latest/installation/debian/
  apt-get install -y apt-transport-https software-properties-common wget
  mkdir -p /etc/apt/keyrings/
  wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list
  apt-get update 
  apt-get install -y grafana
  debug "grafana.installation DEBUG [`date +"%Y-%m-%d %T"`] Grafana OSS repo and Grafana added and installed" 
}
remove_installation(){
  debug "grafana.remove_installation DEBUG [`date +"%Y-%m-%d %T"`] Removing Grafana OSS repo and Grafana"
  apt remove -y grafana --purge 
  apt autoremove -y 
  apt-key del "`apt-key list | $OSBDET_HOME/shared/givemekey.awk -v pattern=Grafana`" 
  rm /etc/apt/keyrings/grafana.gpg /etc/apt/sources.list.d/grafana.list
  apt-get update 
  debug "grafana.remove_installation DEBUG [`date +"%Y-%m-%d %T"`] Grafana OSS repo and Grafana removed"
}

set_default_pass(){
  debug "grafana.set_default_pass DEBUG [`date +"%Y-%m-%d %T"`] Setting up default password to admin user"
  service grafana-server start
  grafana-cli admin reset-admin-password 'osbdet123$'
  service grafana-server stop
  debug "grafana.set_default_pass DEBUG [`date +"%Y-%m-%d %T"`] Default password setup"
}

# Primary functions
#
module_install(){
  debug "grafana.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Add Grafana OSS repo and install Grafana
  #   2. Setup admin default password
  printf "  Installing module 'grafana' ... "
  installation >> $OSBDET_LOGFILE 2>&1
  set_default_pass >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "grafana.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

}

module_status() {
  if [ -f "/usr/sbin/grafana-server" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "grafana.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Removing Grafana OSS repo and Grafana
  printf "  Uninstalling module 'grafana' ... "
  remove_installation>> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "grafana.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'grafana\' module
  echo Usage: script.sh [OPTION]
  echo 
  echo Available options for this module:
  echo "  install             module installation"
  echo "  status              module installation status check"
  echo "  uninstall           module uninstallation"
}

main(){
  # 1. Set logfile to /dev/null if it doesn't exist
  if [ -z "$OSBDET_LOGFILE" ] ; then
    export OSBDET_LOGFILE=/dev/null
  fi
  # 2. Main function
  debug "grafana DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the grafana module" >> $OSBDET_LOGFILE
  if [ $# -eq 1 ]
  then
    if [ "$1" == "install" ]
    then
      module_install
    elif [ "$1" == "status" ]
    then
      module_status
    elif [ "$1" == "uninstall" ]
    then
      module_uninstall
    else
      usage
      exit -1
    fi
  else
    usage
    exit -1
  fi
  debug "grafana DEBUG [`date +"%Y-%m-%d %T"`] Activity with the grafana module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
