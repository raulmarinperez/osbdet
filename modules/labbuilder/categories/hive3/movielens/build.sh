#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

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

prechecks() {
  debug "hive3/movielens.prechecks DEBUG [`date +"%Y-%m-%d %T"`] Doing some checks before the execution" >> $LABBUILDER_LOGFILE
  # TBD - Basically it's all about checking that Hadoop and Hive are up and running.
  debug "hive3/movielens.prechecks DEBUG [`date +"%Y-%m-%d %T"`] Pre-execution checks done" >> $LABBUILDER_LOGFILE
}

execute_deploy_sql() {  
  debug "hive3/movielens.execute_deploy_sql DEBUG [`date +"%Y-%m-%d %T"`] Executing the deploy SQL script"
  beeline -u jdbc:hive2://localhost:10000 -n osbdet -p osbdet -f $SCRIPT_PATH/deploy.sql
  debug "hive3/movielens.execute_deploy_sql DEBUG [`date +"%Y-%m-%d %T"`] Deploy SQL script executed"
}
execute_removal_sql() {  
  debug "hive3/movielens.execute_removal_sql DEBUG [`date +"%Y-%m-%d %T"`] Executing the removal SQL script"
  beeline -u jdbc:hive2://localhost:10000 -n osbdet -p osbdet -f $SCRIPT_PATH/removal.sql
  debug "hive3/movielens.execute_deploy_sql DEBUG [`date +"%Y-%m-%d %T"`] Removal SQL script executed"
}

remove_files_HDFS() {
  debug "hive3/movielens.remove_dataset_HDFS DEBUG [`date +"%Y-%m-%d %T"`] Removing Movielens dataset from HDFS"
  hdfs dfs -rm -r /user/osbdet/datalake/std/movielens
  debug "hive3/movielens.remove_dataset_HDFS DEBUG [`date +"%Y-%m-%d %T"`] Movielens dataset removed from HDFS"
}

# Primary functions
#

lab_deploy(){
  debug "hive3/movielens.lab_deploy DEBUG [`date +"%Y-%m-%d %T"`] Starting lab deployment" >> $LABBUILDER_LOGFILE
  # The deployment of this module consists on:
  #   1. Pre-execution checkings to verify that is all ready for execution.
  #   2. Execute deploy SQL script
  printf "  Deploying lab 'hive3/movielens' ... "
  prechecks
  execute_deploy_sql >> $LABBUILDER_LOGFILE 2>&1
  touch $SCRIPT_PATH/.installed
  printf "[Done]\n"
  debug "hive3/movielens.lab_deploy DEBUG [`date +"%Y-%m-%d %T"`] Lab deployment done" >> $LABBUILDER_LOGFILE
}

lab_status() {
  if [ -f "$SCRIPT_PATH/.installed" ]
  then
    echo "Lab is installed [OK]"
    exit 0
  else
    echo "Lab is not installed [KO]"
    exit 1  
  fi
}

lab_remove(){
  debug "hive3/movielens.lab_remove DEBUG [`date +"%Y-%m-%d %T"`] Starting lab removal" >> $LABBUILDER_LOGFILE
  # The removal of this module consists on:
  #   1. Pre-execution checkings to verify that is all ready for removal.
  #   2. Execute removal SQL script
  #   3. Remove files created in HDFS
  printf "  Removing lab 'hive3/movielens' ... "
  prechecks
  execute_removal_sql >> $LABBUILDER_LOGFILE 2>&1
  remove_files_HDFS >> $LABBUILDER_LOGFILE 2>&1
  rm $SCRIPT_PATH/.installed >> $LABBUILDER_LOGFILE 2>&1
  printf "[Done]\n"
  debug "hive3/movielens.lab_remove DEBUG [`date +"%Y-%m-%d %T"`] Lab removal done" >> $LABBUILDER_LOGFILE
}

usage() {
  echo Starting \'movielens\' lab
  echo Usage: script.sh [OPTION]
  echo
  echo Available options for this lab:
  echo "  deploy              lab deployment"
  echo "  status              lab deployment status check"
  echo "  remove              lab removal"
}

main(){
  # 1. Set logfile to /dev/null if it doesn't exist
  if [ -z "$LABBUILDER_LOGFILE" ] ; then
    export LABBUILDER_LOGFILE=/dev/null
  fi
  # 2. Main function
  debug "hive3/movielens DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the movielens lab" >> $LABBUILDER_LOGFILE
  if [ $# -eq 1 ]
  then
    if [ "$1" == "deploy" ]
    then
      lab_deploy
    elif [ "$1" == "status" ]
    then
      lab_status
    elif [ "$1" == "remove" ]
    then
      lab_remove
    else
      usage
      exit 1
    fi
  else
    usage
    exit 1
  fi
  debug "hive3/movielens DEBUG [`date +"%Y-%m-%d %T"`] Activity with the movielens lab is done" >> $LABBUILDER_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
