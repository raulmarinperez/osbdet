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

create_data_folder(){
  debug "minio.create_data_folder DEBUG [`date +"%Y-%m-%d %T"`] Creating the folder where the files will live"
  mkdir -p /data/s3
  chmod -R 775 /data/s3
  chown osbdet:osbdet /data/s3
  debug "minio.create_data_folder DEBUG [`date +"%Y-%m-%d %T"`] Folder where files will create created"
}
remove_data_folder(){
  debug "minio.remove_data_folder DEBUG [`date +"%Y-%m-%d %T"`] Removing the folder where the files live"
  rm -rf /data/s3
  debug "minio.remove_data_folder DEBUG [`date +"%Y-%m-%d %T"`] Folder where the files live removed"
}

install_minio(){
  debug "minio.install_minio DEBUG [`date +"%Y-%m-%d %T"`] Installing minio server and client"
  # 1. Download the server and client to /tmp
  wget -P /tmp/ https://dl.min.io/server/minio/release/linux-arm64/minio_20220401034139.0.0_arm64.deb
  wget -P /tmp/ https://dl.min.io/client/mc/release/linux-arm64/mcli_20220407214327.0.0_arm64.deb
  # 2. Install both packages
  dpkg -i /tmp/minio_20220401034139.0.0_arm64.deb
  dpkg -i /tmp/mcli_20220407214327.0.0_arm64.deb
  # 3. Remove the packages
  rm /tmp/minio_20220401034139.0.0_arm64.deb /tmp/mcli_20220407214327.0.0_arm64.deb
  debug "minio.install_minio DEBUG [`date +"%Y-%m-%d %T"`] Minio server and client installed"
}
uninstall_minio(){
  debug "minio.uninstall_minio DEBUG [`date +"%Y-%m-%d %T"`] Uninstalling minio server and client"
  # 1. Remove packages
  dpkg -P minio mcli
  debug "minio.uninstall_minio DEBUG [`date +"%Y-%m-%d %T"`] Minio server and client uninstalled"
}

serviceinstall(){
  debug "minio.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_HOME/minio.service /lib/systemd/system/minio.service
  chmod 644 /lib/systemd/system/minio.service
  systemctl daemon-reload
  debug "minio.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "minio.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  service minio stop
  rm /etc/systemd/system/minio.service
  rm /lib/systemd/system/minio.service
  systemctl daemon-reload
  systemctl reset-failed
  debug "minio.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

# Primary functions
#
module_install(){
  debug "minio.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Create the folder that will hold the files
  #   2. Install MinIO server and client
  #   3. Systemd script installation
  printf "  Installing module 'minio' ... "
  create_data_folder >>$OSBDET_LOGFILE 2>&1
  install_minio >>$OSBDET_LOGFILE 2>&1
  serviceinstall >>$OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "minio.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/data/s3" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "minio.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Systemd script removel
  #   2. MinIO server and client uninstallation
  #   3. Data folder deletion
  printf "  Uninstalling module 'minio' ... "
  remove_serviceinstall >>$OSBDET_LOGFILE 2>&1
  uninstall_minio >>$OSBDET_LOGFILE 2>&1
  remove_data_folder >>$OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "minio.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'minio\' module
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
  debug "minio DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the minio module" >> $OSBDET_LOGFILE
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
  debug "minio DEBUG [`date +"%Y-%m-%d %T"`] Activity with the minio module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
