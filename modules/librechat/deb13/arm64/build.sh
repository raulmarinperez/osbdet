#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
LIBRECHAT_GITHUB_REPO="https://github.com/danny-avila/LibreChat.git"
LIBRECHAT_HOME='/opt/LibreChat'
OLLAMA_USER=ollama

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

repo_clone() {
  debug "LibreChat.repo_clone DEBUG [`date +"%Y-%m-%d %T"`] Cloning LibreChat's github repository"
  git clone $LIBRECHAT_GITHUB_REPO $LIBRECHAT_HOME
  chown $OLLAMA_USER:$OLLAMA_USER $LIBRECHAT_HOME
  debug "LibreChat.repo_clone DEBUG [`date +"%Y-%m-%d %T"`] LibreChat's github repository cloned"
}
remove_repo() {
  debug "LibreChat.remove_repo DEBUG [`date +"%Y-%m-%d %T"`] Removing LibreChat's local github repository"
  rm -rf $LIBRECHAT_HOME 
  debug "LibreChat.remove_repo DEBUG [`date +"%Y-%m-%d %T"`] LibreChat's local github repository removed"
}

docker_images_pulling() {
  debug "LibreChat.docker_images_pulling DEBUG [`date +"%Y-%m-%d %T"`] Pulling Docker images to speed first run up"
  # In Debian 13, these two missing env var turn into an "Invalid Proto:" error
  export PORT=3080
  export RAG_PORT=8000
  docker compose -f $LIBRECHAT_HOME/docker-compose.yml pull 
  debug "LibreChat.docker_images_pulling DEBUG [`date +"%Y-%m-%d %T"`] Docker images pulled"
}
remove_docker_images(){
  debug "nessie.remove_docker_image DEBUG [`date +"%Y-%m-%d %T"`] Removing Docker image"
  cd $LIBRECHAT_HOME
  docker compose down --rmi all
  cd $OLDPWD
  debug "nessie.remove_docker_image DEBUG [`date +"%Y-%m-%d %T"`] Docker image removed"
}

librechat_setup() {
  debug "LibreChat.env_setup DEBUG [`date +"%Y-%m-%d %T"`] Create an out of the box environment file"
  cp $SCRIPT_HOME/env $LIBRECHAT_HOME/.env
  cp $SCRIPT_HOME/librechat.yaml $LIBRECHAT_HOME
  sed -i '/^    volumes:/a \      - type: bind\n        source: .\/librechat.yaml\n        target: \/app\/librechat.yaml' $LIBRECHAT_HOME/docker-compose.yml

  debug "LibreChat.env_setup DEBUG [`date +"%Y-%m-%d %T"`] Out of the box environment file created"
}

systemd_service(){
  debug "LibreChat.systemd_service DEBUG [`date +"%Y-%m-%d %T"`] Deploy, install and disable the SystemD service"
  cp $SCRIPT_HOME/librechat.service /lib/systemd/system/librechat.service
  chmod 644 /lib/systemd/system/librechat.service
  systemctl daemon-reload
  debug "LibreChat.systemd_service DEBUG [`date +"%Y-%m-%d %T"`] SystemD service deployed and installed"
}
remove_serviceinstall(){
  debug "LibreChat.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service librechat stop
  systemctl disable librechat.service
  rm /lib/systemd/system/librechat.service
  systemctl daemon-reload
  debug "LibreChat.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

create_user() {
  debug "LibreChat.create_user DEBUG [`date +"%Y-%m-%d %T"`] Creating a LiberChat user"
  service librechat start
  cd $LIBRECHAT_HOME
  echo "Waiting for LibreChat API to accept connections..."
  until [ "$(/usr/bin/curl -s -o /dev/null -w "%{http_code}" http://localhost:3080/health)" -eq 200 ]; do
    echo "API is initializing... retrying in 3 seconds."
    sleep 3
  done  
  docker compose exec -T api npm run create-user -- --email-verified=true admin@osbdet.edu osbdet osbdet osbdet123\$
  cd $OLDPWD
  service librechat stop  
  debug "LibreChat.create_user DEBUG [`date +"%Y-%m-%d %T"`] LiberChat user created"
}

install_ollama() {
  debug "LibreChat.install_ollama DEBUG [`date +"%Y-%m-%d %T"`] Installing ollama to work with openweight models"
  curl -fsSL https://ollama.com/install.sh | sh
  # As we'll run LibreChat as ollama user, it needs to be able to run docker containers
  usermod -aG docker ollama
  systemctl disable ollama
  service ollama stop
  debug "LibreChat.install_ollama DEBUG [`date +"%Y-%m-%d %T"`] Ollama installed"
}
uninstall_ollama() {
  debug "LibreChat.uninstall_ollama DEBUG [`date +"%Y-%m-%d %T"`] Uninstalling ollama"
  systemctl stop ollama
  systemctl disable ollama
  rm /etc/systemd/system/ollama.service
  systemctl daemon-reload
  rm $(which ollama)
  gpasswd -d ollama docker
  userdel ollama
  groupdel ollama
  rm -rf /usr/share/ollama
  rm -rf ~/.ollama ~osbdet/.ollama
  debug "LibreChat.uninstall_ollama DEBUG [`date +"%Y-%m-%d %T"`] Ollama uninstalled"
}

ollama_bound_to_all_interfaces() {
  debug "LibreChat.ollama_bound_to_all_interfaces DEBUG [`date +"%Y-%m-%d %T"`] Binding ollama service to all interfaces"
  # 1. Create the systemd override directory for Ollama
  mkdir -p /etc/systemd/system/ollama.service.d

  # 2. Write the configuration directly to the override file
  tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_ORIGINS=*"
EOF

  # 3. Reload systemd configurations to apply the changes
  systemctl daemon-reload
  debug "LibreChat.ollama_bound_to_all_interfaces DEBUG [`date +"%Y-%m-%d %T"`] Ollama service bound to all interfaces"
}

deploy_qwen() {
  debug "LibreChat.deploy_qwen DEBUG [`date +"%Y-%m-%d %T"`] Deploying qwen2.5 coder on Ollama"
  service ollama start
  # Wait until Ollama responds to api ping requests
  until curl -s http://localhost:11434/api/tags > /dev/null; do
    echo "Waiting for Ollama service to start..."
    sleep 2
  done  
  ollama pull qwen2.5-coder:7b
  service ollama stop
  debug "LibreChat.deploy_qwen DEBUG [`date +"%Y-%m-%d %T"`] Qwen2.5 coder deployed on Ollama"
}
undeploy_qwen() {
  debug "LibreChat.undeploy_qwen DEBUG [`date +"%Y-%m-%d %T"`] Undeploying qwen2.5 coder on Ollama"
  service ollama start
  # Wait until Ollama responds to api ping requests
  until curl -s http://localhost:11434/api/tags > /dev/null; do
    echo "Waiting for Ollama service to start..."
    sleep 2
  done
  ollama rm qwen2.5-coder:7b
  service ollama stop
  debug "LibreChat.undeploy_qwen DEBUG [`date +"%Y-%m-%d %T"`] Qwen2.5 coder undeployed from Ollama"
}

# Primary functions
#
module_install(){
  debug "LibreChat.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Install Ollama service
  #   2. Bound Ollama service to all interfaces
  #   3. Deploy qwen on Ollama
  #   4. Clone the librechat repo to /opt
  #   5. Pull images to speed up first execution
  #   6. Create the LibreChat configuration
  #   7. Install and enable a LibreChat Systemd service
  #   8. Create the user to avoid registering a user
  printf "  Installing module 'LibreChat' ... "
  install_ollama >> $OSBDET_LOGFILE 2>&1
  ollama_bound_to_all_interfaces >> $OSBDET_LOGFILE 2>&1
  deploy_qwen >> $OSBDET_LOGFILE 2>&1
  repo_clone >> $OSBDET_LOGFILE 2>&1
  docker_images_pulling >> $OSBDET_LOGFILE 2>&1
  librechat_setup >> $OSBDET_LOGFILE 2>&1
  systemd_service >> $OSBDET_LOGFILE 2>&1
  create_user >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "LibreChat.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  # While building the module
  #echo "Module is not installed [KO]"
  #echo "Module is installed [OK]"  
  #exit 0
    
  if [ -f "/lib/systemd/system/librechat.service" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "LibreChat.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Remove Librechat service
  #   2. Remove Docker images
  #   3. Remove the repo locally
  #   4. Undeploy Qwen model
  #   5. Uninstall Ollama
  printf "  Uninstalling module 'LibreChat' ... "
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  remove_docker_images >> $OSBDET_LOGFILE 2>&1
  remove_repo >> $OSBDET_LOGFILE 2>&1
  undeploy_qwen >> $OSBDET_LOGFILE 2>&1
  uninstall_ollama >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "LibreChat.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE

}

usage() {
  echo Starting \'LibreChat\' module
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
  debug "LibreChat DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the LibreChat module" >> $OSBDET_LOGFILE
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
  debug "LibreChat DEBUG [`date +"%Y-%m-%d %T"`] Activity with the LibreChat module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
