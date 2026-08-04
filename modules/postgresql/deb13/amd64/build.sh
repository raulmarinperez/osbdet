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

install(){
  debug "postgresql.install DEBUG [`date +"%Y-%m-%d %T"`] Install PostgreSQL"
  apt update
  apt install -y postgresql libpq-dev libpostgresql-jdbc-java
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install --upgrade pip setuptools wheel"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install pkgconfig"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install psycopg2"
  debug "postgresql.install DEBUG [`date +"%Y-%m-%d %T"`] PostgreSQL installed"
}
remove_install(){
  debug "postgresql.remove_install DEBUG [`date +"%Y-%m-%d %T"`] Removing PostgreSQL"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip uninstall -y psycopg2"
  apt remove -y postgresql libpq-dev libpostgresql-jdbc-java --purge
  apt autoremove -y
  apt clean
  rm -rf /var/lib/postgresql /var/log/postgresql /etc/postgresql  
  debug "mariadb.remove_install DEBUG [`date +"%Y-%m-%d %T"`] MariaDB removed"
}

initialsetup(){
  debug "postgresql.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of PostgreSQL"
  systemctl disable postgresql
  service postgresql start
  su postgres -c "psql < $SCRIPT_HOME/init.sql"
  service postgresql stop
  debug "postgresql.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of PostgreSQL done"
}

# Primary functions
#
module_install(){
  debug "postgresql.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Install the PostgreSQL package
  #   2. Initial setup
  printf "  Installing module 'postgresql' ... "
  install >> $OSBDET_LOGFILE 2>&1
  initialsetup >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "postgresql.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

}

module_status() {
  if [ -f "/usr/bin/psql" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "postgresql.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Removing PostgreSQL
  printf "  Uninstalling module 'postgresql' ... "
  remove_install >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "postgresql.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'postgresql\' module
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
  debug "postgresql DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the postgresql module" >> $OSBDET_LOGFILE
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
  debug "postgresql DEBUG [`date +"%Y-%m-%d %T"`] Activity with the postgresql module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
