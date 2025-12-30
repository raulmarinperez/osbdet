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
  debug "clickhouse.installation DEBUG [`date +"%Y-%m-%d %T"`] Adding ClickHouse OSS repo and install ClickHouse"
  # Procedure as it's documented at https://clickhouse.com/docs/install/debian_ubuntu
  apt-get install -y apt-transport-https ca-certificates curl gnupg
  # Download the ClickHouse GPG key and store it in the keyring
  curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
  # Get the system architecture
  ARCH=$(dpkg --print-architecture)
  # Add the ClickHouse repository to apt sources
  echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" | tee /etc/apt/sources.list.d/clickhouse.list
  # Update apt package lists
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client
  # Disable service
  systemctl disable clickhouse-server
  debug "clickhouse.installation DEBUG [`date +"%Y-%m-%d %T"`] ClickHouse OSS repo and ClickHouse added and installed" 
}
remove_installation(){
  debug "clickhouse.remove_installation DEBUG [`date +"%Y-%m-%d %T"`] Removing ClickHouse OSS repo and ClickHouse"
  apt remove -y clickhouse-server clickhouse-client --purge 
  apt autoremove -y 
  apt-key del "`apt-key list | $OSBDET_HOME/shared/givemekey.awk -v pattern=ClickHouse`" 
  rm /usr/share/keyrings/clickhouse-keyring.gpg /etc/apt/sources.list.d/clickhouse.list
  apt-get update 
  debug "clickhouse.remove_installation DEBUG [`date +"%Y-%m-%d %T"`] ClickHouse OSS repo and ClickHouse removed"
}

# Primary functions
#
module_install(){
  debug "clickhouse.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Add ClickHouse OSS repo and install ClickHouse
  printf "  Installing module 'clickhouse' ... "
  installation >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "clickhouse.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -f "/usr/bin/clickhouse-server" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "clickhouse.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Removing Grafana OSS repo and Grafana
  printf "  Uninstalling module 'clickhouse' ... "
  remove_installation >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "clickhouse.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'clickhouse\' module
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
  debug "clickhouse DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the clickhouse module" >> $OSBDET_LOGFILE
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
  debug "clickhouse DEBUG [`date +"%Y-%m-%d %T"`] Activity with the clickhouse module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
