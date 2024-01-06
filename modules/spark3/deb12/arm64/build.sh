#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
SPARK_BINARY_URL=https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
SPARK_TGZ_FILE=spark-3.5.0-bin-hadoop3.tgz
SPARK_DEFAULT_DIR=spark-3.5.0-bin-hadoop3

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
  debug "spark3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Spark 3"
  wget $SPARK_BINARY_URL -O /opt/$SPARK_TGZ_FILE
  if [[ $? -ne 0 ]]; then
    echo "[Error]"
    exit 1
  fi
  
  tar zxf /opt/$SPARK_TGZ_FILE -C /opt
  rm /opt/$SPARK_TGZ_FILE
  mv /opt/$SPARK_DEFAULT_DIR /opt/spark3
  chown -R osbdet:osbdet /opt/spark3
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install findspark"  
  debug "spark3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Spark 3 downloading and extracting process done"
}
removal(){
  debug "spark3.removal DEBUG [`date +"%Y-%m-%d %T"`] Removing Spark 3 from the system"
  rm -rf /opt/spark3
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip uninstall -y findspark"  
  debug "spark3.removal DEBUG [`date +"%Y-%m-%d %T"`] Spark 3 removed from the system"
}

setenvvars(){
  debug "spark3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Setting the environment variables for the installation process"
  export SPARK_HOME=/opt/spark3
  debug "spark3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Environment variables already defined"
}

configfilessetup(){
  debug "spark3.configfilessetup DEBUG [`date +"%Y-%m-%d %T"`] Copying Spark 3 configuration files"

  cp $SCRIPT_HOME/log4j.properties $SPARK_HOME/conf
  chown osbdet:osbdet $SPARK_HOME/conf/log4j.properties

  debug "spark3.configfilessetup DEBUG [`date +"%Y-%m-%d %T"`] Spark 3 configuration files copied"
}

jupyterspark(){
  debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] If Jupyter is installed, the service is updated to consider Spark 3"
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop
     cp $SCRIPT_HOME/jupyter.service /lib/systemd/system/jupyter.service
     chmod 644 /lib/systemd/system/jupyter.service
     systemctl daemon-reload
     systemctl enable jupyter.service
     service jupyter start
     debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script updated"
  else
     debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script update skipped as Jupyter was not found"
  fi
  debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter and Spark 3 integration done"
}
remove_jupyterspark(){
  debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] If Jupyter is installed, the service is updated to remove the reference to Spark 3"
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop
     cp $SCRIPT_HOME/jupyter_nospark3.service /lib/systemd/system/jupyter.service
     chmod 644 /lib/systemd/system/jupyter.service
     systemctl daemon-reload
     systemctl enable jupyter.service
     service jupyter start
     debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script updated"
  else
     debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script update skipped as Jupyter was not found"
  fi
  debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter and Spark 3 integration removed"
}

userprofile(){
  debug "spark3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Update user profile to find Spark 3 binaries"
  echo '# set SPARK_HOME and its bin folder to the PATH' >> /home/osbdet/.profile                                                   
  echo 'SPARK_HOME=/opt/spark3/' >> /home/osbdet/.profile                                                 
  echo 'HADOOP_HOME=${HADOOP_HOME:-/opt/spark3}' >> /home/osbdet/.profile                                                
  echo 'PATH="$PATH:$SPARK_HOME/bin"' >> /home/osbdet/.profile
  debug "spark3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to find Spark 3 binaries updated"
}
remove_userprofile(){
  debug "spark3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Update user profile to remove Spark 3 binaries access"
  sed -i '/^# set SPARK.*/,+3d' ~osbdet/.profile
  debug "spark3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile updated"
}

# Primary functions
#
module_install(){
  debug "spark3.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get Spark 3 and extract it
  #   2. Set up environment variables for the rest of the installation process                                           
  #   3. Copy Spark 3 configuration files    
  #   4. Update jupyter systemd script if Jupyter is installed
  #   5. Update userprofile to get access to Spark 3 binaries
  printf "  Installing module 'spark3' ... "
  getandextract >> $OSBDET_LOGFILE 2>&1
  setenvvars >> $OSBDET_LOGFILE 2>&1
  configfilessetup >> $OSBDET_LOGFILE 2>&1
  jupyterspark >> $OSBDET_LOGFILE 2>&1
  userprofile >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "spark3.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/spark3" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "spark3.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Update userprofile to remove access to Spark 3 binaries
  #   2. Update jupyter systemd script to remove Spark 3 dependencies if Jupyter is installed
  #   3. Remove Spark 3 binaries
  printf "  Uninstalling module 'spark3' ... "
  remove_userprofile >> $OSBDET_LOGFILE 2>&1
  remove_jupyterspark >> $OSBDET_LOGFILE 2>&1
  removal >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "spark3.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'spark3\' module
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
  debug "spark3 DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the spark3 module" >> $OSBDET_LOGFILE

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
  debug "spark3 DEBUG [`date +"%Y-%m-%d %T"`] Activity with the spark3 module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
