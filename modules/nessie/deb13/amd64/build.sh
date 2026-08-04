#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
DOCKER_IMAGE="ghcr.io/projectnessie/nessie:0.108.2-java"

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

create_postgres_user() {
  debug "nessie.create_postgres_user DEBUG [`date +"%Y-%m-%d %T"`] Creating a postgres user for Nessie"
  service postgresql start
  sudo -u postgres psql -c "CREATE USER nessie WITH PASSWORD 'osbdet123$' SUPERUSER;"
  sudo -u postgres PGPASSWORD='osbdet123$' psql -h localhost -U nessie -d postgres -c "CREATE DATABASE nessie_catalog;"
  service postgresql stop  
  debug "nessie.create_postgres_user DEBUG [`date +"%Y-%m-%d %T"`] Postgres user created"
}
remove_postgres_user() {
  debug "nessie.remove_postgres_user DEBUG [`date +"%Y-%m-%d %T"`] Removing the postgres user for Nessie"
  service postgresql start
  sudo -u postgres PGPASSWORD='osbdet123$' psql -h localhost -U nessie -d postgres -c "DROP DATABASE nessie_catalog;"
  sudo -u postgres psql -c "DROP USER nessie;"
  service postgresql stop  
  debug "nessie.remove_postgres_user DEBUG [`date +"%Y-%m-%d %T"`] Postgres user removed"
}

pull_docker_image(){
  debug "nessie.pull_docker_image DEBUG [`date +"%Y-%m-%d %T"`] Pulling Nessie's Docker image"
  docker pull $DOCKER_IMAGE
  debug "nessie.pull_docker_image DEBUG [`date +"%Y-%m-%d %T"`] Nessie's Docker image pulled"
}
remove_docker_image(){
  debug "nessie.remove_docker_image DEBUG [`date +"%Y-%m-%d %T"`] Removing Docker image"
  docker rmi -f $DOCKER_IMAGE
  debug "nessie.remove_docker_image DEBUG [`date +"%Y-%m-%d %T"`] Docker image removed"
}

serviceinstall(){
  debug "nessie.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_HOME/nessie.service /lib/systemd/system/nessie.service
  chmod 644 /lib/systemd/system/nessie.service
  systemctl daemon-reload
  systemctl disable nessie.service
  debug "nessie.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "nessie.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service nessie stop
  systemctl disable nessie.service
  rm /lib/systemd/system/nessie.service
  systemctl daemon-reload
  debug "nessie.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

# Primary functions
#
module_install(){
  debug "nessie.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Create a postgres user to persist the catalog
  #   2. Pull the Docker image
  #   3. Systemd script installation
  printf "  Installing module 'nessie' ... "
  create_postgres_user >> $OSBDET_LOGFILE 2>&1
  pull_docker_image >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "nessie.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -f "/lib/systemd/system/nessie.service" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "nessie.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Remove the created postgresql user
  #   2. Remove Docker image
  #   3. Remove Nessie service
  printf "  Uninstalling module 'nessie' ... "
  remove_postgres_user >> $OSBDET_LOGFILE 2>&1
  remove_docker_image >> $OSBDET_LOGFILE 2>&1
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "nessie.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE

}

usage() {
  echo Starting \'nessie\' module
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
  debug "nessie DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the nessie module" >> $OSBDET_LOGFILE
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
  debug "nessie DEBUG [`date +"%Y-%m-%d %T"`] Activity with the nessie module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
