#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""
NIFI_BINARY_URL=https://ftp.cixug.es/apache/nifi/1.13.2/nifi-1.13.2-bin.tar.gz
NIFI_TGZ_FILE=nifi-1.13.2-bin.tar.gz
NIFI_DEFAULT_DIR=nifi-1.13.2

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

getandextract(){
  debug "nifi.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting NiFi" >> $OSBDET_LOGFILE
  wget $NIFI_BINARY_URL -O /opt/$NIFI_TGZ_FILE >> $OSBDET_LOGFILE 2>&1
  if [[ $? -ne 0 ]]; then
    echo "[Error]"
    exit 1
  fi
  
  tar zxf /opt/$NIFI_TGZ_FILE -C /opt >> $OSBDET_LOGFILE 2>&1
  rm /opt/$NIFI_TGZ_FILE
  mv /opt/$NIFI_DEFAULT_DIR /opt/nifi
  chown -R osbdet:osbdet /opt/nifi
  debug "nifi.getandextract DEBUG [`date +"%Y-%m-%d %T"`] NiFi downloading and extracting process done" >> $OSBDET_LOGFILE
}
remove(){
  debug "nifi.remove DEBUG [`date +"%Y-%m-%d %T"`] Removing NiFi binaries" >> $OSBDET_LOGFILE
  rm -rf /opt/nifi
  debug "nifi.remove DEBUG [`date +"%Y-%m-%d %T"`] NiFi binaries removed" >> $OSBDET_LOGFILE
}

nifisetup(){
  debug "nifi.nifisetup DEBUG [`date +"%Y-%m-%d %T"`] Setting up NiFi" >> $OSBDET_LOGFILE
  # From https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/
  sed -i 's+^#export JAVA_HOME.*+export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64/+' \
         /opt/nifi/bin/nifi-env.sh
  sed -i 's+^nifi\.web\.http\.host.*+nifi.web.http.host=0\.0\.0\.0+' \
         /opt/nifi/conf/nifi.properties
  debug "nifi.nifisetup DEBUG [`date +"%Y-%m-%d %T"`] NiFi properly setup" >> $OSBDET_LOGFILE
}

userprofile(){
  debug "nifi.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Setting up user profile to run NiFi" >> $OSBDET_LOGFILE
  echo >> /home/osbdet/.profile
  echo '# Add NiFi''s bin folder to the PATH' >> /home/osbdet/.profile
  echo 'PATH="$PATH:/opt/nifi/bin"' >> /home/osbdet/.profile
  debug "nifi.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to run NiFi setup" >> $OSBDET_LOGFILE
}
remove_userprofile(){
  debug "nifi.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Removing references to NiFi from user profile" >> $OSBDET_LOGFILE
  # remove the break line before the user profile setup for NiFi
  #   - https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern                                     
  #   - https://unix.stackexchange.com/questions/29906/delete-range-of-lines-above-pattern-with-sed-or-awk                            
  tac /home/osbdet/.profile > /home/osbdet/.eliforp
  sed -i '/^# Add NiFi.*/{n;d}' /home/osbdet/.eliforp

  rm /home/osbdet/.profile
  tac /home/osbdet/.eliforp > /home/osbdet/.profile
  chown osbdet:osbdet /home/osbdet/.profile

  # remove user profile setup for NiFi
  sed -i '/^# Add NiFi.*/,+2d' /home/osbdet/.profile
  rm -f /home/osbdet/.eliforp
  debug "nifi.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] References to NiFi removed from user profile" >> $OSBDET_LOGFILE
}

removehiveprocs() {
  debug "nifi.removehiveprocs DEBUG [`date +"%Y-%m-%d %T"`] Removing Hive related processors" >> $OSBDET_LOGFILE
  rm /opt/nifi/lib/nifi-hive*
  debug "nifi.removehiveprocs DEBUG [`date +"%Y-%m-%d %T"`] Hive related processors removed" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "nifi.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get NiFi 3 and extract it
  #   2. Set up NiFi
  #   3. Set up userprofile to get binaries accessible
  #   4. Remove Hive related processors to avoid the error with the Snappy library.
  printf "  Installing module 'nifi' ... "
  getandextract
  nifisetup
  userprofile
  removehiveprocs
  printf "[Done]\n"
  debug "nifi.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/nifi" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "nifi.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Remove references to NiFi from user profile
  #   2. Remove NiFi binaries from the system
  printf "  Uninstalling module 'nifi' ... "
  remove_userprofile
  remove
  printf "[Done]\n"
  debug "nifi.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
  
}

usage() {
  echo Starting \'nifi\' module
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
  debug "nifi DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the nifi module" >> $OSBDET_LOGFILE
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
  debug "nifi DEBUG [`date +"%Y-%m-%d %T"`] Activity with the nifi module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
