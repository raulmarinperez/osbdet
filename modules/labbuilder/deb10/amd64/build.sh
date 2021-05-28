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

deployment(){
  debug "labbuilder.deployment DEBUG [`date +"%Y-%m-%d %T"`] Starting lab builder deployment"

  debug "Creating the folder structure..."
  mkdir -p /home/osbdet/bin /home/osbdet/etc/labbuilder /home/osbdet/log/ /home/osbdet/lib/labbuilder/categories/

  debug "Copying files..."
  cp $SCRIPT_PATH/../../lab-builder.sh /home/osbdet/bin
  cp $SCRIPT_PATH/../../*.conf /home/osbdet/etc/labbuilder
  cp -r $SCRIPT_PATH/../../categories /home/osbdet/lib/labbuilder

  debug "Changing ownership to osbdet:osbdet and execution permissions where needed..."
  chown -R osbdet:osbdet /home/osbdet/bin /home/osbdet/etc /home/osbdet/log /home/osbdet/lib
  chmod 755 /home/osbdet/bin/lab-builder.sh
  debug "labbuilder.deployment DEBUG [`date +"%Y-%m-%d %T"`] lab builder deployment process done"
}
removal(){
  debug "labbuilder.removal DEBUG [`date +"%Y-%m-%d %T"`] Starting lab builder deletion"

  debug "Removing files..."
  rm -f /home/osbdet/bin/lab-builder.sh 
  rm -f /home/osbdet/log/labbuilder.log
  rm -rf /home/osbdet/etc/labbuilder
  rm -rf /home/osbdet/lib/labbuilder

  debug "labbuilder.removal DEBUG [`date +"%Y-%m-%d %T"`] lab builder deletion done"
}

# Primary functions
#
module_install(){
  debug "labbuilder.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Creating folder structure and copying files.
  printf "  Installing module 'labbuilder' ... "
  deployment >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "labbuilder.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -f "/home/osbdet/bin/lab-builder.sh" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "labbuilder.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Removing copied files and unnecessary folders...
  #   
  printf "  Uninstalling module 'labbuilder' ... "
  removal >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "labbuilder.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'labbuilder\' module
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
  debug "labbuilder DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the labbuilder module" >> $OSBDET_LOGFILE
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
  debug "labbuilder DEBUG [`date +"%Y-%m-%d %T"`] Activity with the labbuilder module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
