#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""
SPARK_BINARY_URL=https://ftp.cixug.es/apache/spark/spark-3.1.1/spark-3.1.1-bin-hadoop3.2.tgz
SPARK_TGZ_FILE=spark-3.1.1-bin-hadoop3.2.tgz
SPARK_DEFAULT_DIR=spark-3.1.1-bin-hadoop3.2

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
  debug "spark3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Spark 3" >> $OSBDET_LOGFILE
  wget $SPARK_BINARY_URL -O /opt/$SPARK_TGZ_FILE >> $OSBDET_LOGFILE 2>&1
  tar zxf /opt/$SPARK_TGZ_FILE -C /opt >> $OSBDET_LOGFILE 2>&1
  rm /opt/$SPARK_TGZ_FILE
  mv /opt/$SPARK_DEFAULT_DIR /opt/spark3
  chown -R osbdet:osbdet /opt/spark3
  pip3 install findspark >> $OSBDET_LOGFILE 2>&1
  debug "spark3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Spark 3 downloading and extracting process done" >> $OSBDET_LOGFILE
}
removal(){
  debug "spark3.removal DEBUG [`date +"%Y-%m-%d %T"`] Removing Spark 3 from the system" >> $OSBDET_LOGFILE
  rm -rf /opt/spark3
  pip3 uninstall -y findspark >> $OSBDET_LOGFILE 2>&1
  debug "spark3.removal DEBUG [`date +"%Y-%m-%d %T"`] Spark 3 removed from the system" >> $OSBDET_LOGFILE
}

jupyterspark(){
  debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] If Jupyter is installed, the service is updated to consider Spark 3" >> $OSBDET_LOGFILE
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop >> $OSBDET_LOGFILE 2>&1
     cp $SCRIPT_PATH/jupyter.service /lib/systemd/system/jupyter.service
     chmod 644 /lib/systemd/system/jupyter.service
     rm -f /etc/systemd/system/jupyter.service
     ln -s /lib/systemd/system/jupyter.service /etc/systemd/system/jupyter.service
     systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
     systemctl enable jupyter.service >> $OSBDET_LOGFILE 2>&1
     service jupyter start >> $OSBDET_LOGFILE 2>&1
     debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script updated" >> $OSBDET_LOGFILE
  else
     debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script update skipped as Jupyter was not found" >> $OSBDET_LOGFILE
  fi
  debug "spark3.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter and Spark 3 integration done" >> $OSBDET_LOGFILE
}
remove_jupyterspark(){
  debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] If Jupyter is installed, the service is updated to remove the reference to Spark 3" >> $OSBDET_LOGFILE
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop >> $OSBDET_LOGFILE 2>&1
     cp $SCRIPT_PATH/jupyter_nospark3.service /lib/systemd/system/jupyter.service
     chmod 644 /lib/systemd/system/jupyter.service
     rm -f /etc/systemd/system/jupyter.service
     ln -s /lib/systemd/system/jupyter.service /etc/systemd/system/jupyter.service
     systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
     systemctl enable jupyter.service >> $OSBDET_LOGFILE 2>&1
     service jupyter start >> $OSBDET_LOGFILE 2>&1
     debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script updated" >> $OSBDET_LOGFILE
  else
     debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script update skipped as Jupyter was not found" >> $OSBDET_LOGFILE
  fi
  debug "spark3.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter and Spark 3 integration removed" >> $OSBDET_LOGFILE
}

userprofile(){
  debug "spark3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Update user profile to find Spark 3 binaries" >> $OSBDET_LOGFILE
  echo '# set SPARK_HOME and its bin folder to the PATH' >> /home/osbdet/.profile                                                   
  echo 'SPARK_HOME=/opt/spark3/' >> /home/osbdet/.profile                                                 
  echo 'HADOOP_HOME=${HADOOP_HOME:-/opt/spark3}' >> /home/osbdet/.profile                                                
  echo 'PATH="$PATH:$SPARK_HOME/bin"' >> /home/osbdet/.profile
  debug "spark3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to find Spark 3 binaries updated" >> $OSBDET_LOGFILE
}
remove_userprofile(){
  debug "spark3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Update user profile to remove Spark 3 binaries access" >> $OSBDET_LOGFILE
  sed -i '/^# set SPARK.*/,+3d' ~osbdet/.profile
  debug "spark3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile updated" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "spark3.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get Spark 3 and extract it
  #   2. Update jupyter systemd script if Jupyter is installed
  #   3. Update userprofile to get access to Spark 3 binaries
  printf "  Installing module 'spark3' ... "
  getandextract
  jupyterspark
  userprofile
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
  remove_userprofile
  remove_jupyterspark
  removal
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
  main $*
fi
