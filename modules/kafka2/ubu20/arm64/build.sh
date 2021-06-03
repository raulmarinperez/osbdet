#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
KAFKA_BINARY_URL=https://ftp.cixug.es/apache/kafka/2.7.0/kafka_2.13-2.7.0.tgz
KAFKA_TGZ_FILE=kafka_2.13-2.7.0.tgz
KAFKA_DEFAULT_DIR=kafka_2.13-2.7.0

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
  debug "kafka.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Kafka" >> $OSBDET_LOGFILE
  wget $KAFKA_BINARY_URL -O /opt/$KAFKA_TGZ_FILE >> $OSBDET_LOGFILE 2>&1
  tar zxf /opt/$KAFKA_TGZ_FILE -C /opt >> $OSBDET_LOGFILE 2>&1
  rm /opt/$KAFKA_TGZ_FILE
  mv /opt/$KAFKA_DEFAULT_DIR /opt/kafka
  chown -R osbdet:osbdet /opt/kafka
  debug "kafka.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Kafka downloading and extracting process done" >> $OSBDET_LOGFILE
}
remove(){
  debug "kafka.remove DEBUG [`date +"%Y-%m-%d %T"`] Removing Kafka binaries" >> $OSBDET_LOGFILE
  rm -rf /opt/kafka
  debug "kafka.remove DEBUG [`date +"%Y-%m-%d %T"`] Kafka binaries removed" >> $OSBDET_LOGFILE
}

libraries(){
  debug "kafka.libraries DEBUG [`date +"%Y-%m-%d %T"`] Installing additional libraries" >> $OSBDET_LOGFILE
  # pip installation not supported due to old librdkafka library version.
  #python3 -m pip install --upgrade pip >> $OSBDET_LOGFILE 2>&1
  #python3 -m pip install confluent-kafka >> $OSBDET_LOGFILE 2>&1
  apt update >> $OSBDET_LOGFILE 2>&1
  apt install -y python3-confluent-kafka >> $OSBDET_LOGFILE 2>&1
  debug "kafka.libraries DEBUG [`date +"%Y-%m-%d %T"`] Additional libraries installed" >> $OSBDET_LOGFILE
}
remove_libraries(){
  debug "kafka.remove_libraries DEBUG [`date +"%Y-%m-%d %T"`] Removing additional libraries" >> $OSBDET_LOGFILE
  # pip installation not supported due to old librdkafka library version.
  #python3 -m pip uninstall -y confluent-kafka >> $OSBDET_LOGFILE 2>&1
  apt remove -y python3-confluent-kafka --purge >>$OSBDET_LOGFILE 2>&1
  debug "kafka.libraries DEBUG [`date +"%Y-%m-%d %T"`] Additional libraries removed" >> $OSBDET_LOGFILE
}

userprofile(){
  debug "kafka.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Setting up user profile to run Kafka" >> $OSBDET_LOGFILE
  echo >> /home/osbdet/.profile
  echo '# Add Kafka''s bin folder to the PATH' >> /home/osbdet/.profile
  echo 'PATH="$PATH:/opt/kafka/bin"' >> /home/osbdet/.profile
  debug "kafka.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to run Kafka setup" >> $OSBDET_LOGFILE
}
remove_userprofile(){
  debug "kafka.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Removing references to Kafka from user profile" >> $OSBDET_LOGFILE
  # remove the break line before the user profile setup for NiFi
  #   - https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern                                     
  #   - https://unix.stackexchange.com/questions/29906/delete-range-of-lines-above-pattern-with-sed-or-awk                            
  tac /home/osbdet/.profile > /home/osbdet/.eliforp
  sed -i '/^# Add Kafka.*/{n;d}' /home/osbdet/.eliforp

  rm /home/osbdet/.profile
  tac /home/osbdet/.eliforp > /home/osbdet/.profile
  chown osbdet:osbdet /home/osbdet/.profile

  # remove user profile setup for Kafka
  sed -i '/^# Add Kafka.*/,+2d' /home/osbdet/.profile
  rm -f /home/osbdet/.eliforp
  debug "kafka.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] References to Kafka removed from user profile" >> $OSBDET_LOGFILE
}

initscript() {
  debug "kafka.initscript DEBUG [`date +"%Y-%m-%d %T"`] Installing Kafka systemd script" >> $OSBDET_LOGFILE
  cp $SCRIPT_HOME/zookeeper.service /lib/systemd/system/zookeeper.service
  cp $SCRIPT_HOME/kafka.service /lib/systemd/system/kafka.service
  chmod 644 /lib/systemd/system/zookeeper.service
  chmod 644 /lib/systemd/system/kafka.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "kafka.initscript DEBUG [`date +"%Y-%m-%d %T"`] Kafka systemd script installed" >> $OSBDET_LOGFILE
}
remove_initscript() {
  debug "kafka.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Removing the Kafka systemd script" >> $OSBDET_LOGFILE
  rm /lib/systemd/system/zookeeper.service
  rm /lib/systemd/system/kafka.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "hive3.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Hive 3 systemd script removed" >> $OSBDET_LOGFILE
}


# Primary functions
#
module_install(){
  debug "kafka.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get Kafka 2 and extract it
  #   2. Install additional libraries
  #   3. Setup osbdet user profile to find Kafka binaries
  #   4. Install systemd init script
  printf "  Installing module 'kafka' ... "
  getandextract
  libraries
  userprofile
  initscript
  printf "[Done]\n"
  debug "kafka.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/kafka" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "kafka.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Remove systemd init script
  #   2. Remove references to Kafka from user profile
  #   3. Remove libraries
  #   4. Remove Kafka binaries from the system
  printf "  Uninstalling module 'kafka' ... "
  remove_initscript
  remove_userprofile
  remove_libraries
  remove
  printf "[Done]\n"
  debug "kafka.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'kafka\' module
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
  debug "kafka DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the kafka module" >> $OSBDET_LOGFILE
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
  debug "kafka DEBUG [`date +"%Y-%m-%d %T"`] Activity with the kafka module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
