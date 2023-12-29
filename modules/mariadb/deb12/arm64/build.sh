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
  debug "mariadb.install DEBUG [`date +"%Y-%m-%d %T"`] Install MariaDB"
  apt-get update
  apt-get install -y mariadb-server default-libmysqlclient-dev libmariadb-java
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install --upgrade pip"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install mysqlclient"
  debug "mariadb.install DEBUG [`date +"%Y-%m-%d %T"`] MariaDB installed"
}
remove_install(){
  debug "mariadb.remove_install DEBUG [`date +"%Y-%m-%d %T"`] Removing MariaDB"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip uninstall -y mysqlclient"
  apt remove -y mariadb-server libmariadbclient-dev --purge
  rm -rf /var/lib/mysql /var/log/mysql
  rm /etc/mysql/mariadb.conf.d/50-sqlmode.cnf
  apt autoremove -y
  apt clean
  debug "mariadb.remove_install DEBUG [`date +"%Y-%m-%d %T"`] MariaDB removed"
}

initialsetup(){
  debug "mariadb.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of MariaDB"
  systemctl disable mariadb
  systemctl disable mysql
  cp $SCRIPT_HOME/50-sqlmode.cnf /etc/mysql/mariadb.conf.d
  service mariadb start
  mariadb < $SCRIPT_HOME/init.sql
  service mariadb stop
  debug "mariadb.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of MariaDB done"
}

# Primary functions
#
module_install(){
  debug "mariadb.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Install the mariadb-server package
  #   2. Initial setup
  printf "  Installing module 'mariadb' ... "
  install >> $OSBDET_LOGFILE 2>&1
  initialsetup >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "mariadb.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

}

module_status() {
  if [ -f "/usr/bin/mariadb" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "mariadb.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Removing MariaDB
  printf "  Uninstalling module 'mariadb' ... "
  remove_install >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "mariadb.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'mariadb\' module
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
  debug "mariadb DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the mariadb module" >> $OSBDET_LOGFILE
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
  debug "mariadb DEBUG [`date +"%Y-%m-%d %T"`] Activity with the mariadb module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
