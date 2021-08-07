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

create_lab_folder() {
  debug "ingestion/lab01_mandatory_tfl.create_lab_folder DEBUG [`date +"%Y-%m-%d %T"`] Create lab folder"
  mkdir -p /home/osbdet/notebooks/labs/ingestion/lab01_mandatory_tfl
  debug "ingestion/lab01_mandatory_tfl.create_lab_folder DEBUG [`date +"%Y-%m-%d %T"`] Lab folder created"
}

cloning_tfl_repo() {  
  debug "ingestion/lab01_mandatory_tfl.cloning_tfl_repo DEBUG [`date +"%Y-%m-%d %T"`] Cloning the TfL repo"
  cd /home/osbdet/notebooks/labs/ingestion/lab01_mandatory_tfl
  git clone https://github.com/raulmarinperez/transportforlondon.git
  debug "ingestion/lab01_mandatory_tfl.cloning_tfl_repo DEBUG [`date +"%Y-%m-%d %T"`] TfL repo cloned"
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
  debug "ingestion/lab01_mandatory_tfl.lab_deploy DEBUG [`date +"%Y-%m-%d %T"`] Starting lab deployment" >> $LABBUILDER_LOGFILE
  # The deployment of this module consists on:
  #   1. Create lab folder.
  #   2. Cloning TfL repo.
  printf "  Deploying lab 'ingestion/lab01_mandatory_tfl' ... "
  create_lab_folder >> $LABBUILDER_LOGFILE 2>&1
  cloning_tfl_repo >> $LABBUILDER_LOGFILE 2>&1
  #touch $SCRIPT_PATH/.installed
  printf "[Done]\n"
  debug "ingestion/lab01_mandatory_tfl.lab_deploy DEBUG [`date +"%Y-%m-%d %T"`] Lab deployment done" >> $LABBUILDER_LOGFILE
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
  debug "ingestion/lab01_mandatory_tfl.lab_remove DEBUG [`date +"%Y-%m-%d %T"`] Starting lab removal" >> $LABBUILDER_LOGFILE
  # The removal of this module consists on:
  #   1. Pre-execution checkings to verify that is all ready for removal.
  #   2. Remove the MovieLens data set from HDFS
  printf "  Removing lab 'hdfs/movielens' ... "
  prechecks
  remove_dataset_HDFS >> $LABBUILDER_LOGFILE 2>&1
  rm $SCRIPT_PATH/.installed >> $LABBUILDER_LOGFILE 2>&1
  printf "[Done]\n"
  debug "ingestion/lab01_mandatory_tfl.lab_remove DEBUG [`date +"%Y-%m-%d %T"`] Lab removal done" >> $LABBUILDER_LOGFILE
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
  debug "ingestion/lab01_mandatory_tfl DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the tfl lab" >> $LABBUILDER_LOGFILE
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
  debug "ingestion/lab01_mandatory_tfl DEBUG [`date +"%Y-%m-%d %T"`] Activity with the tfl lab is done" >> $LABBUILDER_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
