#!/bin/bash

# usage
#   desc: display script's syntax
#   params:
#   return (status code/stdout):
usage() {
  echo "Usage: osbdet_cook.sh recipe_name"
  echo
  echo "Available arguments for osbdet_cook:"
  echo "  recipe_name              name of the recipe to 'cook'"
}

# eval_args
#   desc: evaluate the arguments provided to the script
#   params:
#     $1 - name of recipe to cook
#   return (status code/stdout):
#     0/ok message - the recipe is cooked properly
#     1/ko message - display usage due to a syntax error
eval_args(){
  if [ $# -eq 1 ]
  then
    echo "Starting the recipe cooking process."
    sudo bash -c "cd /home/osbdet/repos/osbdet; ./osbdet_builder.sh cook $1"
  else
    echo "Error: you must provide the name of the recipe as the only argument"
    usage
    exit 1
  fi
}

# OSBDET recipe cooking entry point
#
if ! [ -z "$*" ]
then
  eval_args $*
  exit 0
fi

usage
exit 1
