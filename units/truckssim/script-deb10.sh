#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions
_truckssim_getandextract(){
  apt-get install unzip
  wget https://github.com/raulmarinperez/collaterals/raw/master/knowledge/data_generation/trucking_data_sim/Data-Loader.zip \
       -O /opt/Data-Loader.zip
  cd /opt
  unzip Data-Loader.zip
  cd Data-Loader
  mkdir /opt/Data-Loader/truck-sensor-data
  tar zxf routes.tar.gz
  rm routes.tar.gz
  rm ../Data-Loader.zip
  chown -R osbdet:osbdet /opt/Data-Loader
}
_truckssim_remove(){
  rm -rf /opt/Data-Loader
}

_truckssim_serviceinstall(){
  cp $SCRIPT_PATH/data-loader.service /lib/systemd/system/data-loader.service
  chmod 644 /lib/systemd/system/data-loader.service
  systemctl daemon-reload
}
_truckssim_remove_serviceinstall(){
  service data-loader stop
  rm /lib/systemd/system/data-loader.service 
  systemctl daemon-reload
}

# Primary functions
#
unit_install(){
  echo Starting truckssim_install...

  _truckssim_getandextract
  echo "    Trucks Simulator downloading and extraction [Done]"
  _truckssim_serviceinstall
  echo "    Init script creation [Done]"
}

unit_status() {
  echo Checking truckssim unit installation status...
  if [ -d "/opt/Data-Loader/truck-sensor-data" ]
  then
    echo "    Trucks simulator unit is installed [OK]"
    exit 0
  else
    echo "    Trucks simulator unit is not installed [KO]"
    exit -1
  fi
}

unit_uninstall(){
  echo Starting truckssim_uninstall...

  _truckssim_remove_serviceinstall
  echo "    Init script removal [Done]"
  _truckssim_remove
  echo "    Trucks Simulator removal [Done]"
}

usage() {
  echo Starting \'truckssim\' unit
  echo Usage: script.sh [OPTION]
  echo 
  echo Available options for this unit:
  echo "  install             unit installation"
  echo "  status              unit installation status check"
  echo "  uninstall           unit uninstallation"
}

main(){
  if [ $# -eq 1 ]
  then
    if [ "$1" == "install" ]
    then
      unit_install
    elif [ "$1" == "status" ]
    then
      unit_status
    elif [ "$1" == "uninstall" ]
    then
      unit_uninstall
    else
      usage
      exit -1
    fi
  else
    usage
    exit -1
  fi
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
