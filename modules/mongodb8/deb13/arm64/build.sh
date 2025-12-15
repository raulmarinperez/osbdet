#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic

MONGODB_VERSION=8.0.16

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
  debug "mongodb8.installation DEBUG [`date +"%Y-%m-%d %T"`] Adding MongoDB 8 OSS repo and install MongoDB 8"
  # Procedure as it's documented at https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-debian/#install-mongodb-community-edition
  apt-get install gnupg curl
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
  echo "deb [ arch=arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list
  apt-get update
  apt-get install -y mongodb-org=$MONGODB_VERSION mongodb-org-database=$MONGODB_VERSION mongodb-org-server=$MONGODB_VERSION mongodb-mongosh mongodb-org-mongos=$MONGODB_VERSION mongodb-org-tools=$MONGODB_VERSION
  systemctl daemon-reload
  systemctl disable mongod
  debug "mongodb8.installation DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 8 OSS repo and MongoDB 8 added and installed" 
}
remove_installation(){
  debug "mongodb8.remove_installation DEBUG [`date +"%Y-%m-%d %T"`] Removing MongoDB 8 OSS repo and MongoDB 8"
  service mongod stop
  apt remove -y mongodb-org mongodb-org-database mongodb-org-server mongodb-mongosh mongodb-org-mongos mongodb-org-tools --purge 
  apt autoremove -y 
  rm /usr/share/keyrings/mongodb-server-8.0.gpg
  rm /etc/apt/sources.list.d/mongodb-org-8.0.list
  apt-get update 
  debug "mongodb8.remove_installation DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 8 OSS repo and MongoDB 8 removed"
}

# Primary functions
#
module_install(){
  debug "mongodb8.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Add MongoDB 8 OSS repo and install MongoDB 8
  printf "  Installing module 'mongodb8' ... "
  installation >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "mongodb8.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -f "/usr/bin/mongod" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "mongodb8.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Removing MongoDB 8 OSS repo and MongoDB 8
  printf "  Uninstalling module 'mongodb8' ... "
  remove_installation>> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "mongodb8.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'mongodb8\' module
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
  debug "mongodb8 DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the mongodb8 module" >> $OSBDET_LOGFILE
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
  debug "mongodb8 DEBUG [`date +"%Y-%m-%d %T"`] Activity with the mongodb8 module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
