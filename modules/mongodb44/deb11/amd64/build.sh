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

addrepoandinstall(){
  debug "mongodb44.addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] Adding MongoDB 4.4 CE repo and install MongoDB" >> $OSBDET_LOGFILE
  # Procedure as it's documented at https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/
  apt-get install gnupg >> $OSBDET_LOGFILE 2>&1
  wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - >> $OSBDET_LOGFILE 2>&1
  echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list >> $OSBDET_LOGFILE 2>&1
  apt-get update >> $OSBDET_LOGFILE 2>&1
  apt-get install -y mongodb-org >> $OSBDET_LOGFILE 2>&1
  debug "mongodb44.addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 4.4 CE repo and MongoDB added and installed" >> $OSBDET_LOGFILE
}
remove_addrepoandinstall(){
  debug "mongodb44.remove_addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] Removing MongoDB 4.4 CE repo and MongoDB" >> $OSBDET_LOGFILE
  apt remove -y mongodb-org --purge >> $OSBDET_LOGFILE 2>&1
  apt autoremove -y >> $OSBDET_LOGFILE 2>&1
  apt-key del "`apt-key list | $OSBDET_HOME/shared/givemekey.awk -v pattern=MongoDB`" >> $OSBDET_LOGFILE 2>&1
  rm /etc/apt/sources.list.d/mongodb-org-4.4.list
  apt-get update >> $OSBDET_LOGFILE 2>&1
  debug "mongodb44.remove_addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 4.4 CE repo and MongoDB removed" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "mongodb44.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Add MongoDB 4.4 CE repo and install MongoDB
  printf "  Installing module 'mongodb44' ... "
  addrepoandinstall
  printf "[Done]\n"
  debug "mongodb44.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

}

module_status() {
  if [ -f "/usr/bin/mongo" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "mongodb44.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Removing MongoDB 4.4 CE repo and MongoDB
  printf "  Uninstalling module 'mongodb44' ... "
  remove_addrepoandinstall
  printf "[Done]\n"
  debug "mongodb44.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE

}

usage() {
  echo Starting \'mongodb44\' module
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
  debug "mongodb44 DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the mongodb44 module" >> $OSBDET_LOGFILE
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
  debug "mongodb44 DEBUG [`date +"%Y-%m-%d %T"`] Activity with the mongodb44 module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
