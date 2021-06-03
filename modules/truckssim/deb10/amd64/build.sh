#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
TRUCKSSIM_URL=https://github.com/raulmarinperez/collaterals/raw/master/knowledge/data_generation/trucking_data_sim/Data-Loader.zip
TRUCKSSIM_ZIP_FILE=Data-Loader.zip

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
  debug "truckssim.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting the trucks simulator" >> $OSBDET_LOGFILE
  apt-get install unzip >> $OSBDET_LOGFILE 2>&1
  wget $TRUCKSSIM_URL -O /opt/$TRUCKSSIM_ZIP_FILE >> $OSBDET_LOGFILE 2>&1
  cd /opt
  unzip $TRUCKSSIM_ZIP_FILE >> $OSBDET_LOGFILE 2>&1
  cd Data-Loader
  mkdir /opt/Data-Loader/truck-sensor-data
  tar zxf routes.tar.gz >> $OSBDET_LOGFILE 2>&1
  rm routes.tar.gz
  rm ../$TRUCKSSIM_ZIP_FILE
  chown -R osbdet:osbdet /opt/Data-Loader
  debug "truckssim.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator downloaded and extracted" >> $OSBDET_LOGFILE
}
remove(){
  debug "truckssim.remove DEBUG [`date +"%Y-%m-%d %T"`] Removing the trucks simulator" >> $OSBDET_LOGFILE
  rm -rf /opt/Data-Loader
  debug "truckssim.remove DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator removed" >> $OSBDET_LOGFILE
}

initscript(){
  debug "truckssim.initscript DEBUG [`date +"%Y-%m-%d %T"`] Installing the trucks simulator systemd script" >> $OSBDET_LOGFILE
  cp $SCRIPT_PATH/data-loader.service /lib/systemd/system/data-loader.service
  chmod 644 /lib/systemd/system/data-loader.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "truckssim.initscript DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator systemd script installed" >> $OSBDET_LOGFILE
}
remove_initscript(){
  debug "truckssim.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Removing the trucks simulator systemd script" >> $OSBDET_LOGFILE
  service data-loader stop >> $OSBDET_LOGFILE 2>&1
  rm /lib/systemd/system/data-loader.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "truckssim.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Trucks simulator systemd script removed" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "truckssim.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get the trucks simulator binaries and extract them
  #   2. Install the systemd init script
  printf "  Installing module 'truckssim' ... "
  getandextract
  initscript
  printf "[Done]\n"
  debug "truckssim.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/Data-Loader/truck-sensor-data" ]
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
  remove_initscript
  remove
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
