#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
KESTRA_BINARY_URL=https://repo.maven.apache.org/maven2/io/kestra/kestra/0.20.7/kestra-0.20.7.zip
KESTRA_ZIP_FILE=kestra-0.20.7.zip
KESTRA_DEFAULT_BIN=kestra-0.20.7

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

getandextract(){
  debug "kestra.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Kestra"
  # Download and extract
  wget $KESTRA_BINARY_URL -O /opt/$KESTRA_ZIP_FILE
  mkdir /opt/kestra
  unzip /opt/$KESTRA_ZIP_FILE -d /opt/kestra
  # Reorganization, setup and cleaning
  mv /opt/kestra/$KESTRA_DEFAULT_BIN /opt/kestra/kestra
  chown -R osbdet:osbdet /opt/kestra
  chmod 755 /opt/kestra/kestra
  rm /opt/$KESTRA_ZIP_FILE
  debug "kestra.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Kestra downloading and extracting process done"
}
remove(){
  debug "kestra.remove DEBUG [`date +"%Y-%m-%d %T"`] Removing Kestra binaries"
  rm -rf /opt/kestra
  debug "kestra.remove DEBUG [`date +"%Y-%m-%d %T"`] Kestra binaries removed"
}

initscript() {
  debug "kestra.initscript DEBUG [`date +"%Y-%m-%d %T"`] Installing Kestra systemd script"
  cp $SCRIPT_HOME/kestra.service /lib/systemd/system/kestra.service
  chmod 644 /lib/systemd/system/kestra.service
  systemctl daemon-reload 
  debug "kestra.initscript DEBUG [`date +"%Y-%m-%d %T"`] Kestra systemd script installed"
}
remove_initscript() {
  debug "kestra.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Removing the Kestra systemd script"
  rm /lib/systemd/system/kestra.service
  systemctl daemon-reload
  debug "kestra.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Kestra systemd script removed"
}

# Primary functions
#
module_install(){
  debug "kestra.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get Kestra and extract it
  #   2. Systemd script installation
  printf "  Installing module 'kestra' ... "
  #getandextract >> $OSBDET_LOGFILE 2>&1
  initscript >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "kestra.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/kestra" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "kestra.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Remove systemd init script
  #   2. Remove binaries from the system
  printf "  Uninstalling module 'kestra' ... "
  remove_initscript >> $OSBDET_LOGFILE 2>&1
  #remove >>$OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "kestra.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'kestra\' module
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
  debug "kestra DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the kestra module" >> $OSBDET_LOGFILE
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
  debug "kestra DEBUG [`date +"%Y-%m-%d %T"`] Activity with the kestra module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi