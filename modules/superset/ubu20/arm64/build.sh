#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

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

# Primary functions
#
module_install(){
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] This module is not supported for ARM64" >> $OSBDET_LOGFILE
  printf "This module is NOT supported for ARM64 [Unsupported]\n"
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  echo "Unsupported module [KO]"
  exit 1
}

module_uninstall(){
  debug "superset.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] This module is not supported for ARM64" >> $OSBDET_LOGFILE
  printf "This module is NOT supported for ARM64 [Unsupported]\n"
  debug "superset.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'superset\' unit
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
  debug "superset DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the superset module" >> $OSBDET_LOGFILE
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
  debug "superset DEBUG [`date +"%Y-%m-%d %T"`] Activity with the superset module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
