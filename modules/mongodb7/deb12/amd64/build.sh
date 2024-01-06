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
  debug "mongodb7.addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] Adding MongoDB 7 CE repo and install MongoDB"
  # Procedure as it's documented at https://www.mongodb.com/docs/current/tutorial/install-mongodb-on-debian/
  apt-get install -y gnupg
  curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
       sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
       --dearmor
  echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
  apt-get update
  apt-get install -y mongodb-mongosh
  debug "mongodb7.addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 7 CE repo and MongoDB added and installed"
}
remove_addrepoandinstall(){
  debug "mongodb7.remove_addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] Removing MongoDB 7 CE repo and MongoDB"
  apt remove -y mongodb-mongosh --purge
  apt autoremove -y
  apt-key del "`apt-key list | $OSBDET_HOME/shared/givemekey.awk -v pattern=MongoDB`"
  rm /etc/apt/sources.list.d/mongodb-org-7.0.list
  apt-get update
  debug "mongodb7.remove_addrepoandinstall DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 7 CE repo and MongoDB removed"
}

containerdeploy(){
  debug "mongodb7.containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] Deploy a MongoDB 7 CE container"
  # There is no official MongoDB server packages for Debian arm64 -> I'll rely on Docker

  # Create a docker volume to persist data across restarts
  docker volume create mongodb-vol
  
  # Run the docker container for the first time to have the image locally
  docker run --rm --name mongo -p 27017:27017/tcp --mount source=mongodb-vol,target=/data/db -d amd64/mongo:7.0.4-jammy

  # Kill it to stop it
  docker kill mongo
  debug "mongodb7.containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 7 CE container deployed"
}
remove_containerdeploy(){
  debug "mongodb7.remove_containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] Removing MongoDB 7 CE container"
  # Only the volume needs to be removed
  docker volume remove mongodb-vol
  debug "mongodb7.remove_containerdeploy DEBUG [`date +"%Y-%m-%d %T"`] MongoDB 7 CE container removed"
}

serviceinstall(){
  debug "mongodb7.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_PATH/mongodb.service /lib/systemd/system/mongodb.service
  chmod 644 /lib/systemd/system/mongodb.service
  systemctl daemon-reload
  systemctl disable mongodb.service
  debug "mongodb7.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "mongodb7.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service mongodb stop
  systemctl disable mongodb.service
  rm /lib/systemd/system/mongodb.service
  systemctl daemon-reload
  debug "mongodb7.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

# Primary functions
#
module_install(){
  debug "mongodb7.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Removing MongoDB 7 CE repo and MongoDB
  #   2. Deploy a MongoDB 7 CE container
  #   3. Systemd script installation
  printf "  Installing module 'mongodb7' ... "
  addrepoandinstall >> $OSBDET_LOGFILE 2>&1
  containerdeploy >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "mongodb7.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

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
  debug "mongodb7.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Systemd script removal
  #   2. Removing MongoDB 7 CE repo and MongoDB
  #   3. Removing MongoDB 7 CE container
  printf "  Uninstalling module 'mongodb7' ... "
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  remove_addrepoandinstall >> $OSBDET_LOGFILE 2>&1
  remove_containerdeploy >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "mongodb7.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE

}

usage() {
  echo Starting \'mongodb7\' module
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
  debug "mongodb7 DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the mongodb7 module" >> $OSBDET_LOGFILE
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
  debug "mongodb7 DEBUG [`date +"%Y-%m-%d %T"`] Activity with the mongodb7 module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
