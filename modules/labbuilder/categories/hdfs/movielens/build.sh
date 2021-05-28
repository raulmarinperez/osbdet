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
  debug "hdfs/movielens.prechecks DEBUG [`date +"%Y-%m-%d %T"`] Doing some checks before the execution" >> $LABBUILDER_LOGFILE
  # TBD - Basically it's all about checking the Hadoop is up and running.
  debug "hdfs/movielens.prechecks DEBUG [`date +"%Y-%m-%d %T"`] Pre-execution checks done" >> $LABBUILDER_LOGFILE
}

download_dataset_locally() {  
  debug "hdfs/movielens.download_dataset_locally DEBUG [`date +"%Y-%m-%d %T"`] Downloading Movielens small dataset"
  wget http://files.grouplens.org/datasets/movielens/ml-latest-small.zip -O /tmp/ml-latest-small.zip
  unzip -d /tmp -o /tmp/ml-latest-small.zip
  debug "hdfs/movielens.download_dataset_locally DEBUG [`date +"%Y-%m-%d %T"`] Movielens small dataset downloaded"
}

upload_dataset_HDFS() {
  debug "hdfs/movielens.upload_dataset_HDFS DEBUG [`date +"%Y-%m-%d %T"`] Uploading Movielens dataset to HDFS"
  hdfs dfs -mkdir -p /user/osbdet/datalake/raw/movielens
  hdfs dfs -mkdir /user/osbdet/datalake/raw/movielens/ratings
  hdfs dfs -mkdir /user/osbdet/datalake/raw/movielens/links
  hdfs dfs -mkdir /user/osbdet/datalake/raw/movielens/movies
  hdfs dfs -mkdir /user/osbdet/datalake/raw/movielens/tags
  hdfs dfs -put /tmp/ml-latest-small/ratings.csv /user/osbdet/datalake/raw/movielens/ratings
  hdfs dfs -put /tmp/ml-latest-small/links.csv /user/osbdet/datalake/raw/movielens/links
  hdfs dfs -put /tmp/ml-latest-small/movies.csv /user/osbdet/datalake/raw/movielens/movies
  hdfs dfs -put /tmp/ml-latest-small/tags.csv /user/osbdet/datalake/raw/movielens/tags
  debug "hdfs/movielens.upload_dataset_HDFS DEBUG [`date +"%Y-%m-%d %T"`] Movielens dataset moved to HDFS"
}
remove_dataset_HDFS() {
  debug "hdfs/movielens.remove_dataset_HDFS DEBUG [`date +"%Y-%m-%d %T"`] Removing Movielens dataset from HDFS"
  hdfs dfs -rm -r /user/osbdet/datalake/raw/movielens
  debug "hdfs/movielens.remove_dataset_HDFS DEBUG [`date +"%Y-%m-%d %T"`] Movielens dataset removed from HDFS"
}

delete_dataset_locally() {  
  debug "hdfs/movielens.delete_dataset_locally DEBUG [`date +"%Y-%m-%d %T"`] Deleting Movielens small dataset locally"
  rm -rf /tmp/ml-latest-small
  debug "hdfs/movielens.delete_dataset_locally DEBUG [`date +"%Y-%m-%d %T"`] Movielens small dataset deleted locally"
}

# Primary functions
#

lab_deploy(){
  debug "hdfs/movielens.lab_deploy DEBUG [`date +"%Y-%m-%d %T"`] Starting lab deployment" >> $LABBUILDER_LOGFILE
  # The deployment of this module consists on:
  #   1. Pre-execution checkings to verify that is all ready for execution.
  #   2. Download the MovieLens data set locally
  #   3. Upload the MovieLens data set to HDFS (folder structure creation)
  #   4. Delete the MovieLens data set locally
  printf "  Deploying lab 'hdfs/movielens' ... "
  prechecks
  download_dataset_locally >> $LABBUILDER_LOGFILE 2>&1
  upload_dataset_HDFS >> $LABBUILDER_LOGFILE 2>&1
  delete_dataset_locally >> $LABBUILDER_LOGFILE 2>&1
  touch $SCRIPT_PATH/.installed
  printf "[Done]\n"
  debug "hdfs/movielens.lab_deploy DEBUG [`date +"%Y-%m-%d %T"`] Lab deployment done" >> $LABBUILDER_LOGFILE
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
  debug "hdfs/movielens.lab_remove DEBUG [`date +"%Y-%m-%d %T"`] Starting lab removal" >> $LABBUILDER_LOGFILE
  # The removal of this module consists on:
  #   1. Pre-execution checkings to verify that is all ready for removal.
  #   2. Remove the MovieLens data set from HDFS
  printf "  Removing lab 'hdfs/movielens' ... "
  prechecks
  remove_dataset_HDFS >> $LABBUILDER_LOGFILE 2>&1
  rm $SCRIPT_PATH/.installed >> $LABBUILDER_LOGFILE 2>&1
  printf "[Done]\n"
  debug "hdfs/movielens.lab_remove DEBUG [`date +"%Y-%m-%d %T"`] Lab removal done" >> $LABBUILDER_LOGFILE
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
  debug "hdfs/movielens DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the movielens lab" >> $LABBUILDER_LOGFILE
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
  debug "hdfs/movielens DEBUG [`date +"%Y-%m-%d %T"`] Activity with the movielens lab is done" >> $LABBUILDER_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
