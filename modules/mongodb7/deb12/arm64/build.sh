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
  debug "mongodb44.addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] Adding MongoDB 4.4 CE repo and install MongoDB"
  # Procedure as it's documented at https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/
  apt-get install -y gnupg
  wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
  echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
  apt-get update
  apt-get install -y mongodb-mongosh
  debug "mongodb44.addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 4.4 CE repo and MongoDB added and installed"
}
remove_addrepoandinstall(){
  debug "mongodb44.remove_addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] Removing MongoDB 4.4 CE repo and MongoDB"
  apt remove -y mongodb-mongosh --purge
  apt autoremove -y
  apt-key del "`apt-key list | $OSBDET_HOME/shared/givemekey.awk -v pattern=MongoDB`"
  rm /etc/apt/sources.list.d/mongodb-org-4.4.list
  apt-get update
  debug "mongodb44.remove_addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 4.4 CE repo and MongoDB removed"
}

containerdeploy(){
  debug "mongodb44.containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] Deploy a MongoDB 4.4 CE container"
  # There is no official MongoDB server packages for Debian arm64 -> I'll rely on Docker

  # Create a docker volume to persist data across restarts
  docker volume create mongodb-vol
  
  # Run the docker container for the first time to have the image locally
  docker run --rm --name mongo -p 27017:27017/tcp --mount source=mongodb-vol,target=/data/db -d arm64v8/mongo:4.4

  # Kill it to stop it
  docker kill mongo
  debug "mongodb44.containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 4.4 CE container deployed"
}
remove_containerdeploy(){
  debug "mongodb44.remove_containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] Removing MongoDB 4.4 CE container"
  # Only the volume needs to be removed
  docker volume remove mongodb-vol
  debug "mongodb44.remove_containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 4.4 CE container removed"
}

serviceinstall(){
  debug "mongodb44.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_PATH/mongodb.service /lib/systemd/system/mongodb.service
  chmod 644 /lib/systemd/system/mongodb.service
  systemctl daemon-reload
  systemctl disable mongodb.service
  debug "mongodb44.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "mongodb44.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service mongodb stop
  systemctl disable mongodb.service
  rm /lib/systemd/system/mongodb.service
  systemctl daemon-reload
  debug "mongodb44.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

# Primary functions
#
module_install(){
  debug "mongodb44.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Removing MongoDB 4.4 CE repo and MongoDB
  #   2. Deploy a MongoDB 4.4 CE container
  #   3. Systemd script installation
  printf "  Installing module 'mongodb44' ... "
  addrepoandinstall >> $OSBDET_LOGFILE 2>&1
  containerdeploy >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "mongodb44.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

}

module_status() {
  if [ -f "/usr/bin/mongosh" ]
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
  #   1. Systemd script removal
  #   2. Removing MongoDB 4.4 CE repo and MongoDB
  #   3. Removing MongoDB 4.4 CE container
  printf "  Uninstalling module 'mongodb44' ... "
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  remove_addrepoandinstall >> $OSBDET_LOGFILE 2>&1
  remove_containerdeploy >> $OSBDET_LOGFILE 2>&1
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
