#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
TRUCKFLEETSIM_ZIPFILE=/opt/Data-Loader.zip
TRUCKFLEETSIM_HOME=/opt/truckfleet-sim

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
  debug "truckssim.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting the trucks simulator"
  apt-get install unzip
  cp $SCRIPT_HOME/Data-Loader.zip $TRUCKFLEETSIM_ZIPFILE
  cd /opt
  unzip $TRUCKFLEETSIM_ZIPFILE
  mv /opt/Data-Loader $TRUCKFLEETSIM_HOME
  cd $TRUCKFLEETSIM_HOME
  mkdir $TRUCKFLEETSIM_HOME/truck-sensor-data
  tar zxf routes.tar.gz
  rm routes.tar.gz
  rm $TRUCKFLEETSIM_ZIPFILE
  chown -R osbdet:osbdet $TRUCKFLEETSIM_HOME
  debug "truckssim.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator downloaded and extracted"
}
remove(){
  debug "truckssim.remove DEBUG [`date +"%Y-%m-%d %T"`] Removing the trucks simulator"
  rm -rf $TRUCKFLEETSIM_HOME
  debug "truckssim.remove DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator removed"
}

install_jdk8(){
  debug "truckssim.install_jdk8 DEBUG [`date +"%Y-%m-%d %T"`] Installing JDK 8"
  debig "IMPORTANT: The Temurin APT source has to be already installed; this should happen withint the Foundation module installation"
  apt install -y temurin-8-jdk
  debug "truckssim.install_jdk8 DEBUG [`date +"%Y-%m-%d %T"`] JDK 11 installation done"
}
remove_jdk8(){
  debug "truckssim.remove_jdk8 DEBUG [`date +"%Y-%m-%d %T"`] Removing JDK 8"
  apt remove -y temurin-8-jdk
  debug "truckssim.remove_jdk8 DEBUG [`date +"%Y-%m-%d %T"`] JDK 8 removed"
}

initscript(){
  debug "truckssim.initscript DEBUG [`date +"%Y-%m-%d %T"`] Installing the trucks simulator systemd script"
  cp $SCRIPT_PATH/truckfleet-sim.service /lib/systemd/system/truckfleet-sim.service
  chmod 644 /lib/systemd/system/truckfleet-sim.service
  systemctl daemon-reload
  debug "truckssim.initscript DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator systemd script installed"
}
remove_initscript(){
  debug "truckssim.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Removing the trucks simulator systemd script"
  service truckfleet-sim stop
  rm /lib/systemd/system/truckfleet-sim.service
  systemctl daemon-reload
  debug "truckssim.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator systemd script removed"
}

# Primary functions
#
module_install(){
  debug "truckssim.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get the trucks simulator binaries and extract them
  #   2. Install the systemd init script
  printf "  Installing module 'truckssim' ... "
  getandextract >> $OSBDET_LOGFILE 2>&1
  install_jdk8 >> $OSBDET_LOGFILE 2>&1
  initscript >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "truckssim.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "$TRUCKFLEETSIM_HOME" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "truckssim.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get the trucks simulator binaries and extract them
  #   2. Install the systemd init script
  printf "  Uninstalling module 'truckssim' ... "
  remove_initscript >> $OSBDET_LOGFILE 2>&1
  remove_jdk8 >> $OSBDET_LOGFILE 2>&1
  remove >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "truckssim.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'truckssim\' module
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
  debug "truckssim DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the truckssim module" >> $OSBDET_LOGFILE
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
  debug "truckssim DEBUG [`date +"%Y-%m-%d %T"`] Activity with the truckssim module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
