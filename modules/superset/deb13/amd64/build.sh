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

bienv_install(){
  debug "superset.bienv_install DEBUG [`date +"%Y-%m-%d %T"`] Installing all the software for the BI environment"
  mkdir /opt/superset && chown osbdet:osbdet /opt/superset
  # As Debian ships Python 3.13 and it's not a superset compatible, version
  # we'll rely on uv to create a 3.11 Python Virtual Environment
  su - osbdet -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
  su - osbdet -c '/home/osbdet/.local/bin/uv venv /opt/superset/ --python 3.11'
  su - osbdet -c 'VIRTUAL_ENV=/opt/superset /home/osbdet/.local/bin/uv pip install apache-superset==5.0.0 mysqlclient marshmallow==3.26.1'
  debug "superset.bienv_install DEBUG [`date +"%Y-%m-%d %T"`] Software for the BI environment installed"
}
remove_bienv(){
  debug "superset.remove_bienv DEBUG [`date +"%Y-%m-%d %T"`] Removing BI environment software"
  rm -rf /opt/superset
  rm -rf /home/osbdet/.superset
  rm /home/osbdet/.local/bin/env /home/osbdet/.local/bin/env.fish /home/osbdet/.local/bin/uv /home/osbdet/.local/bin/uvx
  rmdir /home/osbdet/.local/bin/
  sed -i '/\. "\$HOME\/\.local\/bin\/env"/d' .bashrc .profile
  debug "superset.remove_bienv DEBUG [`date +"%Y-%m-%d %T"`] BI environment software removed"
}

initialsetup(){
  debug "superset.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Superset"
  # 2024R1: A secret key needs to be created - https://superset.apache.org/docs/installation/installing-superset-from-scratch/#python-virtual-environment
  cp $SCRIPT_HOME/superset_config.py /opt/superset
  sed -i 's@YOUR_OWN_RANDOM_GENERATED_SECRET_KEY@'`openssl rand -base64 42`'@' /opt/superset/superset_config.py
  # All set to do the initial configuration
  su - osbdet -c 'SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py FLASK_APP=superset /opt/superset/bin/superset db upgrade'
  su - osbdet -c 'SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py FLASK_APP=superset /opt/superset/bin/superset fab create-admin --username osbdet --firstname osb --lastname bdet \
                                            --email osbdet@osbdet.com --password osbdet123\$'
  su - osbdet -c 'SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py FLASK_APP=superset /opt/superset/bin/superset init'
  chown -R osbdet:osbdet /opt/superset
  debug "superset.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Superset done"
}

serviceinstall(){
  debug "superset.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_HOME/superset.service /lib/systemd/system/superset.service
  chmod 644 /lib/systemd/system/superset.service
  systemctl daemon-reload
  debug "superset.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "superset.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service superset stop
  systemctl disable superset.service
  rm /lib/systemd/system/superset.service 
  systemctl daemon-reload
  debug "jupyter.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

# Primary functions
#
module_install(){
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Install 
  #   1. BI environment installation
  #   2. Initial setup of Superset
  #   3. Systemd script installation
  printf "  Installing module 'superset' ... "
  bienv_install >> $OSBDET_LOGFILE 2>&1
  initialsetup >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/superset" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "superset.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Systemd script removel
  #   2. Undoing setup of Superset
  #   3. BI environment removal
  printf "  Uninstalling module 'superset' ... "
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  remove_bienv >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "jupyter.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'superset\' unit
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
  debug "superset DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the superset module" >> $OSBDET_LOGFILE
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
  debug "superset DEBUG [`date +"%Y-%m-%d %T"`] Activity with the superset module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
