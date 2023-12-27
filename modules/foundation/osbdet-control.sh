#!/bin/bash

# Global variables definition
#
OSBDET_VER=24r1

# module_status
#   desc: Display if the specified module is running or is stopped
#   params:
#     $1 - module to check
#   return (status code/stdout):
#     0/ok message - module specified correctly
#     1/ko message - module doesn't exists
module_status() {
    # TBD - check module name
    if [ ! -f "/tmp/$1" ]; then
      echo "down"
    else
      cat /tmp/$1
    fi

    return 0
}

# start_module
#   desc: Start the specified module if it wasn't running already
#   params:
#     $1 - module to start
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_module() {
    # TBD - check module name and if it's already running
    echo "Starting module '$1'"
    sleep 5
    echo "up" > /tmp/$1

    return 0
}

# stop_module
#   desc: Stop the specified module if it wasn't stopped already
#   params:
#     $1 - module to stop
#   return (status code/stdout):
#     0/ok message - module stopped correctly
#     1/ko message - module doesn't exists or it was already stopped
stop_module() {
    # TBD - check module name and if it's already stopped
    echo "Stopping module '$1'"
    sleep 5
    echo "down" > /tmp/$1

    return 0
}

# usage
#   desc: display script's syntax
#   params: None
#   return (status code/stdout): None
usage() {
  echo "Usage: osbdet_control.sh [command] [module name]"
  echo 
  echo "Available options for 'commands' and 'modules names' in osbdet_control:"
  echo "  ## commands ##"
  echo "  status              display the current status of the selected module"
  echo "  start               start the specified module if it's not running (no effect otherwise)"
  echo "  stop                stop the specified module if it's running (no effect otherwise)"
  echo
  echo "  ## modules names ##"
  echo "  hadoop              Storage and processing at scale"
  echo "  nifi                Data ingestion"
  echo "  spark               Unified processing framework for Big Data projects"
}

# eval_args
#   desc: evaluate the arguments provided to the script
#   params:
#     $1 - command to execute
#   return (status code/stdout):
#     0/ok message - the option is executed properly
#     1/ko message - display usage due to a syntax error
eval_args(){
  if [ $# -eq 2 ]
  then
    if [ "$1" == "status" ]
    then
      module_status $2
    elif [ "$1" == "start" ]
    then
      start_module $2
    elif [ "$1" == "stop" ]
    then
      stop_module $2
    else
      echo "Error: bad command specified"
      usage
      exit 1
    fi
  else
    echo "Error: bad number of arguments"
    usage
    exit 1
  fi
}

# OSBDET control's entry point
#

if ! [ -z "$*" ]
then
  eval_args $*
  exit 0
fi

usage
exit 1
