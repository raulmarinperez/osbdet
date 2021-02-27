#!/usr/bin/bash

# Global variables definition
#
OSBDET_VER=vs21r1
OSBDET_USERPASS=osbdet123$
OSBDET_UNITSLIST=shared/units_list.conf

SPARK_HOME=/opt/spark-3.0.0-preview2-bin-hadoop3.2/

# Auxiliary functions
#

# usage
#   desc: display script's syntax
#   params:
#   return (status code/stdout):
usage() {
  echo "Usage: osbdet_builder.sh [OPTION] [comma separated list of units]"
  echo 
  echo "Available options for mounter:"
  echo "  build               build modules specified in config_file"
  echo "  remove              remove modules specified in config_file"
  echo "  status              display the current status of OSBDET"
}

# eval_args
#   desc: evaluate the arguments provided to the script
#   params:
#     $1 - option to execute
#   return (status code/stdout):
#     0/ok message - the option is executed properly
#     -1/ko message - display usage due to a syntax error
eval_args(){
  if [ $# -eq 1 ]
  then
    if [ "$1" == "status" ]
    then
      echo "Showing status of OSBDET"
    else
      echo "Error: bad option or bad number of arguments"
      usage
      exit -1
    fi
  elif [ $# -eq 2 ]
  then
    if [ "$1" == "build" ]
    then
      echo  "Building some modules into OSBDET"
    elif [ "$1" == "remove" ]
    then
      echo  "Removing modules from OSBDET"
    else
      echo "Error: bad option or bad number of arguments"
      usage
      exit -1
    fi
  else
    echo "Error: bad option or bad number of arguments"
    usage
    exit -1
  fi
}

pause() {
  read -p "$*"
}

install_foundation(){
  units/foundation/script-deb10.sh install
}

install_jupyter(){
  units/jupyter/script-deb10.sh install
}

install_spark3(){
  units/spark3/script-deb10.sh install
}

install_hadoop3(){
  units/hadoop3/script-deb10.sh install
}

install_hive3(){
  units/hive3/script-deb10.sh install
}

# OSBDET builder's entry point
#
if ! [ -z "$*" ]
then
  eval_args $*
  exit 0
fi

usage
exit -1


#clear
#echo Welcome to the OSBDET installer...
#echo You\'re about to deploy OSBDET $OSBDET_VER in this machine.
#pause Press any key to start

# 1. Setting up the foundations
#install_foundation

# 2. Deploying Jupyter
#install_jupyter

# 3. Deploying Spark 3
#install_spark3

# 4. Deploying Hadoop 3
#install_hadoop3

# 5. Deploying Hive 3
#install_hive3
