#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
DOCKER_COMPOSE_FILE_URL="https://github.com/open-metadata/OpenMetadata/releases/download/1.11.0-release/docker-compose-postgres.yml"
DOCKER_COMPOSE_FILENAME="docker-compose-postgres.yml" 
REPOSITORIES=(
    "docker.getcollate.io/openmetadata/ingestion"
    "docker.getcollate.io/openmetadata/server"
    "docker.getcollate.io/openmetadata/postgresql"
    "docker.elastic.co/elasticsearch/elasticsearch"
)

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

folderanddockercompose(){
  debug "openmetadata.folderanddockercompose DEBUG [`date +"%Y-%m-%d %T"`] Creating folder and downloading Docker Compose file"
  # Procedure as it's documented at https://docs.open-metadata.org/latest/quick-start/local-docker-deployment
  mkdir -p /opt/openmetadata
  curl -sL -o /opt/openmetadata/$DOCKER_COMPOSE_FILENAME $DOCKER_COMPOSE_FILE_URL
  chown -R osbdet:osbdet /opt/openmetadata
  debug "openmetadata.folderanddockercompose DEBUG [`date +"%Y-%m-%d %T"`] Folder created and Docker Compose file downloaded"
}
remove_folderanddockercompose(){
  debug "openmetadata.remove_folderanddockercompose DEBUG [`date +"%Y-%m-%d %T"`] Removing folder"
  rm -rf /opt/openmetadata
  debug "openmetadata.remove_folderanddockercompose DEBUG [`date +"%Y-%m-%d %T"`] Folder removed"
}

serviceinstall(){
  debug "openmetadata.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_HOME/openmetadata.service /lib/systemd/system/openmetadata.service
  chmod 644 /lib/systemd/system/openmetadata.service
  systemctl daemon-reload
  systemctl disable openmetadata.service
  debug "openmetadata.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "openmetadata.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service openmetadata stop
  systemctl disable openmetadata.service
  rm /lib/systemd/system/openmetadata.service
  systemctl daemon-reload
  debug "openmetadata.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

remove_dockerartifacts(){
  debug "openmetadata.remove_dockerartifacts DEBUG [`date +"%Y-%m-%d %T"`] Removing Docker artifacts such as images and volumes"
  # Stop containers (if running) and remove volumes
  docker compose -f /opt/openmetadata/$DOCKER_COMPOSE_FILENAME down --volumes
  # Remove images
  for REPO in "${REPOSITORIES[@]}"; do
    # Get the image ID for the current repository
    IMAGE_ID=$(docker image ls --format "{{.Repository}} {{.ID}}" | grep "^$REPO" | awk '{print $2}')    
    # Check if IMAGE_ID is not empty
    if [ -n "$IMAGE_ID" ]; then
        debug "  Removing image for repository: $REPO (Image ID: $IMAGE_ID)"
        docker rmi "$IMAGE_ID"
    else
        debug "  No image found for repository: $REPO"
    fi
  done
  debug "openmetadata.remove_dockerartifacts DEBUG [`date +"%Y-%m-%d %T"`] Docker artifacts removed"
}

# Primary functions
#
module_install(){
  debug "openmetadata.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Create folder and download docker compose file
  #   2. Systemd script installation
  printf "  Installing module 'openmetadata' ... "
  folderanddockercompose >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "openmetadata.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

}

module_status() {
  if [ -d "/opt/openmetadata" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "openmetadata.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Systemd script removal
  #   2. Remove all created Docker containers
  #   3. Remove Docker artifacts
  printf "  Uninstalling module 'openmetadata' ... "
  #remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  remove_dockerartifacts >> $OSBDET_LOGFILE 2>&1
  remove_folderanddockercompose >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "openmetadata.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE

}

usage() {
  echo Starting \'openmetadata\' module
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
  debug "openmetadata DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the openmetadata module" >> $OSBDET_LOGFILE
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
  debug "openmetadata DEBUG [`date +"%Y-%m-%d %T"`] Activity with the openmetadata module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
