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

install_nodejs20(){
  debug "osbdetweb.addcontent DEBUG [`date +"%Y-%m-%d %T"`] Installing NodeJS 20"
  # Installation instructions documented at https://github.com/nodesource/distributions#debinstall
  # The "chromium" package will be needed if decktape (PDF printing) is needed (ex. slides)
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install -y nodejs chromium
  debug "osbdetweb.addcontent DEBUG [`date +"%Y-%m-%d %T"`] NodeJS 20 installed"
}
remove_nodejs20(){
  debug "osbdetweb.addcontent DEBUG [`date +"%Y-%m-%d %T"`] Removing NodeJS 20"
  apt remove -y nodejs chromium
  apt autoremove -y 
  rm /etc/apt/keyrings/nodesource.gpg
  rm /etc/apt/sources.list.d/nodesource.list
  apt-get update 
  debug "osbdetweb.addcontent DEBUG [`date +"%Y-%m-%d %T"`] NodeJS 20 removed"
}

addcontent(){
  debug "osbdetweb.addcontent DEBUG [`date +"%Y-%m-%d %T"`] Adding content to destination folder"
  # Copy content
  cp -r $SCRIPT_HOME/content /opt/osbdetweb
  chown -R osbdet:osbdet /opt/osbdetweb
  # Build content
  cd /opt/osbdetweb && npm install && npm run build
  # Copy the OSBDET control script
  cp $SCRIPT_HOME/osbdet-control.sh /home/osbdet/bin
  chmod 755 /home/osbdet/bin/osbdet-control.sh
  chown osbdet:osbdet /home/osbdet/bin/osbdet-control.sh
  debug "osbdetweb.addcontent DEBUG [`date +"%Y-%m-%d %T"`] Content added"
}
removecontent(){
  debug "osbdetweb.removecontent DEBUG [`date +"%Y-%m-%d %T"`] Removing content"
  rm -rf /opt/osbdetweb
  rm /home/osbdet/bin/osbdet-control.sh
  debug "osbdetweb.removecontent DEBUG [`date +"%Y-%m-%d %T"`] Content removed"
}

serviceinstall(){
  debug "osbdetweb.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_HOME/osbdetweb.service /lib/systemd/system/osbdetweb.service
  chmod 644 /lib/systemd/system/osbdetweb.service
  systemctl daemon-reload
  systemctl disable osbdetweb.service
  debug "osbdetweb.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "osbdetweb.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service osbdetweb stop
  systemctl disable osbdetweb.service
  rm /lib/systemd/system/osbdetweb.service
  systemctl daemon-reload
  debug "osbdetweb.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

# Primary functions
#
module_install(){
  debug "osbdetweb.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation"
  # The installation of this module consists on:
  #   1. Add NodeJS repo and install NodeJS and Chromium
  #   2. Add and build content
  #   3. Add systemd service
  printf "  Installing module 'osbdetweb' ... "
  install_nodejs20 >> $OSBDET_LOGFILE 2>&1
  addcontent >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "osbdetweb.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done"
}

module_status() {
  if [ -d "/opt/osbdetweb" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "osbdetweb.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Remove systemd service
  #   2. Remove content
  #   3. Remove NodeJS and Chromium and NodeJS repo
  printf "  Uninstalling module 'osbdetweb' ... "
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  removecontent >> $OSBDET_LOGFILE 2>&1
  remove_nodejs20 >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "osbdetweb.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'osbdetweb\' module
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
  debug "osbdetweb DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the osbdetweb module" >> $OSBDET_LOGFILE
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
  debug "osbdetweb DEBUG [`date +"%Y-%m-%d %T"`] Activity with the osbdetweb module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi