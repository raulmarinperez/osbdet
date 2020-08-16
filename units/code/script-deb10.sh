#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions
_code_dependencies(){
  pip3 install python-telegram-bot
}
_code_remove_dependencies(){
  pip3 uninstall -y python-telegram-bot
}

_code_copycode(){
  mkdir /opt/code
  chown osbdet:osbdet /opt/code
}
_code_remove_copycode(){
  rm -rf /opt/code
}

# Primary functions
#
unit_install(){
  echo Starting code_install...

  _code_dependencies
  echo "    Code dependencies installation [Done]"
  _code_copycode
  echo "    Code copy [Done]"
}

unit_status() {
  echo Checking code unit installation status...
  if [ -d "/opt/code" ]
  then
    echo "    Code unit is installed [OK]"
    exit 0
  else
    echo "    Code unit is not installed [KO]"
    exit -1
  fi
}

unit_uninstall(){
  echo Starting code_uninstall...

  _code_remove_copycode
  echo "    Code removal [Done]"
  _code_remove_dependencies
  echo "    Code dependencies installation removal [Done]"
}

usage() {
  echo Starting \'code\' unit
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
