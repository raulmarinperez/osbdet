#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
KAFKA_BINARY_URL=https://downloads.apache.org/kafka/3.9.0/kafka_2.13-3.9.0.tgz
KAFKA_TGZ_FILE=kafka_2.13-3.9.0.tgz
KAFKA_DEFAULT_DIR=kafka_2.13-3.9.0

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
  debug "kafka.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Kafka"
  wget $KAFKA_BINARY_URL -O /opt/$KAFKA_TGZ_FILE
  tar zxf /opt/$KAFKA_TGZ_FILE -C /opt
  rm /opt/$KAFKA_TGZ_FILE
  mv /opt/$KAFKA_DEFAULT_DIR /opt/kafka
  chown -R osbdet:osbdet /opt/kafka
  debug "kafka.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Kafka downloading and extracting process done"
}
remove(){
  debug "kafka.remove DEBUG [`date +"%Y-%m-%d %T"`] Removing Kafka binaries"
  rm -rf /opt/kafka
  debug "kafka.remove DEBUG [`date +"%Y-%m-%d %T"`] Kafka binaries removed"
}

libraries(){
  debug "kafka.libraries DEBUG [`date +"%Y-%m-%d %T"`] Installing additional libraries"
  apt update
  apt install -y librdkafka-dev
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install confluent-kafka"
  debug "kafka.libraries DEBUG [`date +"%Y-%m-%d %T"`] Additional libraries installed"
}
remove_libraries(){
  debug "kafka.remove_libraries DEBUG [`date +"%Y-%m-%d %T"`] Removing additional libraries"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip uninstall -y confluent-kafka"
  debug "kafka.libraries DEBUG [`date +"%Y-%m-%d %T"`] Additional libraries removed"
}

userprofile(){
  debug "kafka.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Setting up user profile to run Kafka"
  echo >> /home/osbdet/.profile
  echo '# Add Kafka''s bin folder to the PATH' >> /home/osbdet/.profile
  echo 'PATH="$PATH:/opt/kafka/bin"' >> /home/osbdet/.profile
  debug "kafka.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to run Kafka setup"
}
remove_userprofile(){
  debug "kafka.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Removing references to Kafka from user profile"
  # remove the break line before the user profile setup for Kafka
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
  debug "kafka.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] References to Kafka removed from user profile"
}

initwithkraft() {
  debug "kafka.initwithkraft DEBUG [`date +"%Y-%m-%d %T"`] Initializing server properties with KRaft"
  KAFKA_CLUSTER_ID="$(/opt/kafka/bin/kafka-storage.sh random-uuid)"
  su - osbdet -c 'sed -i s/"tmp\/kraft-combined-logs"/"data\/kraft-combined-logs"/ /opt/kafka/config/kraft/server.properties'
  su - osbdet -c "/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server.properties"
  debug "kafka.initwithkraft DEBUG [`date +"%Y-%m-%d %T"`] Server properties with KRaft initialized"
}
remove_kraftlogs() {
  debug "kafka.kraftlogs DEBUG [`date +"%Y-%m-%d %T"`] Removing KRaft logs"
  rm -rf /data/kraft-combined-logs
  debug "kafka.kraftlogs DEBUG [`date +"%Y-%m-%d %T"`] KRaft logs removed"
}

initscript() {
  debug "kafka.initscript DEBUG [`date +"%Y-%m-%d %T"`] Installing Kafka systemd script"
  cp $SCRIPT_HOME/kafka.service /lib/systemd/system/kafka.service
  chmod 644 /lib/systemd/system/kafka.service
  systemctl daemon-reload 
  debug "kafka.initscript DEBUG [`date +"%Y-%m-%d %T"`] Kafka systemd script installed"
}
remove_initscript() {
  debug "kafka.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Removing the Kafka systemd script"
  rm /lib/systemd/system/kafka.service
  systemctl daemon-reload
  debug "kafka.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Kafka systemd script removed"
}

# Primary functions
#
module_install(){
  debug "kafka.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get Kafka 3 and extract it
  #   2. Install additional libraries
  #   3. Setup osbdet user profile to find Kafka binaries
  #   4. Initialize Kafka with KRaft to remove Zookeeper dependency
  #   5. Install systemd init script
  printf "  Installing module 'kafka' ... "
  getandextract >> $OSBDET_LOGFILE 2>&1
  libraries >> $OSBDET_LOGFILE 2>&1
  userprofile >> $OSBDET_LOGFILE 2>&1
  initwithkraft >> $OSBDET_LOGFILE 2>&1
  initscript >> $OSBDET_LOGFILE 2>&1
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
  #   2. Remove KRaft logs
  #   3. Remove references to Kafka from user profile  
  #   4. Remove libraries
  #   5. Remove Kafka binaries from the system
  printf "  Uninstalling module 'kafka' ... "  
  remove_initscript >> $OSBDET_LOGFILE 2>&1
  remove_kraftlogs >> $OSBDET_LOGFILE 2>&1
  remove_userprofile >> $OSBDET_LOGFILE 2>&1
  remove_libraries >> $OSBDET_LOGFILE 2>&1
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
