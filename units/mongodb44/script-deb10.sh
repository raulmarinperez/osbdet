#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions
_mongodb44_addrepoandinstall(){
  # Procedure as it's documented at https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/
  apt-get install gnupg
  wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
  echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
  apt-get update
  apt-get install -y mongodb-org
}
_mongodb44_remove_addrepoandinstall(){
  apt remove -y mongodb-org --purge
  apt autoremove -y
  apt-key del "`apt-key list | $SCRIPT_PATH/../../shared/givemekey.awk -v pattern=MongoDB`"
  rm /etc/apt/sources.list.d/mongodb-org-4.4.list
  apt-get update
}

# Primary functions
#
unit_install(){
  echo Starting mongodb44_install...

  _mongodb44_addrepoandinstall
  echo "    MongoDB 4.4 CE repo addition and installation [Done]"
}

unit_status() {
  echo Checking mongodb44 unit installation status...
  if [ -f "/usr/bin/mongo" ]
  then
    echo "    MongoDB44 unit is installed [OK]"
    exit 0
  else
    echo "    MongoDB44 unit is not installed [KO]"
    exit -1
  fi
}

unit_uninstall(){
  echo Starting mongodb44_uninstall...

  _mongodb44_remove_addrepoandinstall
  echo "    MongoDB 4.4 CE repo and installation removal [Done]"
}

usage() {
  echo Starting \'mongodb44\' unit
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
