#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic

AIRFLOW_HOME=/opt/airflow
AIRFLOW_VERSION=2.5.0
PYTHON_VERSION="$(python3 --version | cut -d " " -f 2 | cut -d "." -f 1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

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

create_folder(){
  debug "airflow.create_folder DEBUG [`date +"%Y-%m-%d %T"`] Creating the folder where the files will live"
  mkdir -p $AIRFLOW_HOME
  chown osbdet:osbdet $AIRFLOW_HOME
  debug "airflow.create_folder DEBUG [`date +"%Y-%m-%d %T"`] Folder where files will create created"
}
remove_folder(){
  debug "airflow.remove_folder DEBUG [`date +"%Y-%m-%d %T"`] Removing the folder where the files live"
  rm -rf $AIRFLOW_HOME
  debug "airflow.remove_folder DEBUG [`date +"%Y-%m-%d %T"`] Folder where the files live removed"
}

install_airflow(){
  debug "airflow.install_airflow DEBUG [`date +"%Y-%m-%d %T"`] Installing airflow"
  # 1. Installation as detailed at https://airflow.apache.org/docs/apache-airflow/stable/start/local.html
  python3 -m venv $AIRFLOW_HOME 
  . $AIRFLOW_HOME/bin/activate
  python -m pip install --upgrade pip
  python -m pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"  
  deactivate
  debug "airflow.install_airflow DEBUG [`date +"%Y-%m-%d %T"`] Airflow installed"
}
uninstall_airflow(){
  debug "airflow.uninstall_airflow DEBUG [`date +"%Y-%m-%d %T"`] Uninstalling airflow"
  # 1. Remove packages
  rm -rf $AIRFLOW_HOME
  debug "airflow.uninstall_airflow DEBUG [`date +"%Y-%m-%d %T"`] Airflow uninstalled"
}

airflow_initialization(){
  debug "airflow.airflow_initialization DEBUG [`date +"%Y-%m-%d %T"`] Initializing airflow"
  . $AIRFLOW_HOME/bin/activate
  export AIRFLOW_HOME
  # 1. Airflow's db initialization
  airflow db init
  # 2. osbdet user creation (Admin role)
  airflow users create \
            --username osbdet \
            --password osbdet123$ \
            --firstname osbdet \
            --lastname osbdet \
            --role Admin \
            --email osbdet@osbdet.com
  # 3. Set user and group to osbdet
  chown -R osbdet:osbdet $AIRFLOW_HOME
  deactivate
  
  debug "airflow.airflow_initialization DEBUG [`date +"%Y-%m-%d %T"`] Airflow initialized"
}

serviceinstall() {
  debug "airflow.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Installing Airflow systemd script" >> $OSBDET_LOGFILE
  cp $SCRIPT_HOME/af_webserver.service /lib/systemd/system/af_webserver.service
  cp $SCRIPT_HOME/airflow.service /lib/systemd/system/airflow.service
  chmod 644 /lib/systemd/system/af_webserver.service
  chmod 644 /lib/systemd/system/airflow.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "airflow.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Airflow systemd script installed" >> $OSBDET_LOGFILE
}
remove_serviceinstall() {
  debug "airflow.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Removing the Airflow systemd script" >> $OSBDET_LOGFILE
  rm /lib/systemd/system/af_webserver.service
  rm /lib/systemd/system/airflow.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "airflow.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Airflow systemd script removed" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "airflow.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Create the folder that will hold the files
  #   2. Install airflow
  #   3. Airflow initialization
  #   4. Systemd script installation
  printf "  Installing module 'airflow' ... "
  create_folder >>$OSBDET_LOGFILE 2>&1
  install_airflow >>$OSBDET_LOGFILE 2>&1
  airflow_initialization >>$OSBDET_LOGFILE 2>&1
  serviceinstall >>$OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "airflow.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "$AIRFLOW_HOME" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "airflow.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Systemd script removel
  #   2. MinIO server and client uninstallation
  #   3. Folder deletion
  printf "  Uninstalling module 'airflow' ... "
  remove_serviceinstall >>$OSBDET_LOGFILE 2>&1
  uninstall_airflow >>$OSBDET_LOGFILE 2>&1
  remove_folder >>$OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "airflow.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'airflow\' module
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
  debug "airflow DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the airflow module" >> $OSBDET_LOGFILE
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
  debug "airflow DEBUG [`date +"%Y-%m-%d %T"`] Activity with the airflow module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
