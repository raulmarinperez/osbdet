#!/bin/bash

# Global variables definition
#

declare -A LABSMAP
declare -A CATEGORIESMAP

# Auxiliary functions
#

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

# load_categories
#   desc: load categories from a file into an associative array
#   params:
#     $1 - file containing available categories
#   return (status code/stdout):
load_categories() {
  while IFS=\| read -r field1 field2; do
    if [[ ! $field1 =~ ^# && ! $field1 =~ ^" "+ && $field1 != "" ]]; then
      CATEGORIESMAP[$field1]="$field2"
    fi
  done < "$1"
}

# load_labs
#   desc: load labs from a file into an associative array
#   params:
#     $1 - file containing available labs
#   return (status code/stdout):
load_labs() {
  while IFS=\| read -r field1 field2 field3 field4 field5; do
    if [[ ! $field1 =~ ^# && ! $field1 =~ ^" "+ && $field1 != "" ]]; then
      LABSMAP[$field1]="$field2|$field3|$field4|$field5"
    fi
  done < "$1"
}

# get_lab_category
#   desc:
#   params:
#     $1 - lab extended name
#   return (status code/stdout):
#     0/lab_category - input is properly formatted
#     1/no_category  - input is not properly formatted and no category can be extracted
get_lab_category() {
  IFS=/
  read -r field1 field2  <<< "$1"
  if [[ $field1 != "" ]]; then
    echo $field1
    return 0
  else
    echo "no_category"
    return 1
  fi
}

# get_lab_name
#   desc:
#   params:
#     $1 - lab extended name
#   return (status code/stdout):
#     0/lab_name - lab name if exists
#     1/no_name     - no_name string if there is no name available
#     2/no_lab   - lab not found
get_lab_name() {
  lab_info=${LABSMAP[$1]}
  if [[ $lab_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$lab_info"
    if [[ $field1 != "" ]]; then
      echo $field1
      return 0
    else
      echo "no_name"
      return 1
    fi
  else
    echo "no_lab"
    return -2
  fi
}

# get_lab_version
#   desc:
#   params:
#     $1 - lab extended name
#   return (status code/stdout):
#     0/lab_version - lab version if exists
#     1/no_version     - no_version string if there is no version available
#     2/no_lab      - lab not found
get_lab_version() {
  lab_info=${LABSMAP[$1]}
  if [[ $lab_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$lab_info"
    if [[ $field2 != "" ]]; then
      echo $field2
      return 0
    else
      echo "no_version"
      return 1
    fi
  else
    echo "no_lab"
    return 2
  fi
}

# get_lab_description
#   desc:
#   params:
#     $1 - lab extended name
#   return (status code/stdout):
#     0/lab description - lab description if exists
#     1/no_description  - no_description string if there is no description available
#     -2/no_lab         - lab not found
get_lab_description() {
  lab_info=${LABSMAP[$1]}
  if [[ $lab_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$lab_info"
    if [[ $field3 != "" ]]; then
      echo $field3
      return 0
    else
      echo "no_description"
      return 1
    fi
  else
    echo "no_lab"
    return -2
  fi
}

# get_lab_dependencies
#   desc:
#   params:
#     $1 - lab extended name
#   return (status code/stdout):
#     0/lab dependencies - lab dependencies if exists
#     1/no_dependencies  - no_dependencies string if there is no dependencies available
#     -2/no_lab          - lab not found
get_lab_dependencies() {
  lab_info=${LABSMAP[$1]}
  if [[ $lab_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$lab_info"
    if [[ $field4 != "" ]]; then
      echo $field4
      return 0
    else
      echo "no_dependencies"
      return 1
    fi
  else
    echo "no_lab"
    return 2
  fi
}

# list_categories
#   desc:
#   params:
#   return (status code/stdout):
list_categories() {
  echo "These are the categories available for OSBDET v$OSBDET_VER:"
  for category_name in "${!CATEGORIESMAP[@]}"; do
    echo "  - $category_name: ${CATEGORIESMAP[$category_name]}"
  done
}

# list_labs
#   desc:
#   params:
#     $1 - category name
#   return (status code/stdout):
list_labs() {
  echo "These are the labs for "category" $1 available in OSBDET v$OSBDET_VER:"
  for lab_name_ext in "${!LABSMAP[@]}"; do
    lab_name=$(get_lab_name $lab_name_ext)
    if [ "$1/$lab_name" == "$lab_name_ext" ]
    then
      lab_version=$(get_lab_version $lab_name_ext)
      lab_description=$(get_lab_description $lab_name_ext)
      lab_dependencies=$(get_lab_dependencies $lab_name_ext)
      echo "  - $lab_name[$lab_version]: $lab_description, depends on: $lab_dependencies"
    fi
  done
}

# deploy_lab_and_deps
#   desc:
#   params:
#     $1 - category the labs belong to
#     $2 - lab name to deploy
#   return (status code/stdout):
#     0/ok message - labs deployed correctly
#     1/ko message - not all labs were deployed
deploy_lab_and_deps() {
  # 1. Check if it's installed
  $LABBUILDER_LABS/categories/$1/$2/build.sh status > /dev/null
  lab_status=$?
  if [[ $lab_status -eq 0 ]]; then
    debug "[deploy_lab_and_dep] Skipping '$1', lab is already installed"
    return 1
  else
    IFS=','
    dependencies=$(get_lab_dependencies $1/$2)
    read -a llabs <<< "$dependencies"
    # 2. Go over dependencies and install them before installing this module
    for lab_name_ext in "${llabs[@]}";
    do
      if [[ $lab_name_ext != "no_dependencies" ]]
      then
        lab_category=$(get_lab_category $lab_name_ext)
        lab_name=$(get_lab_name $lab_name_ext)
        deploy_lab_and_deps $lab_category $lab_name
      fi
    done
    # 3. Lab installation
    $LABBUILDER_LABS/categories/$1/$2/build.sh deploy
    if [ $? -ne 0 ]
    then
      debug "Fatal error: lab '$1' cannot be installed. See log messages for more information."
      exit 1
    fi
  fi
}

# deploy
#   desc:
#   params:
#     $1 - category the labs belong to
#     $2 - comma separated list of labs
#   return (status code/stdout):
#     0/ok message - labs deployed correctly
#     1/ko message - not all labs were deployed
deploy() {
  IFS=','
  read -a llabs <<< "$2"

  # 1. Iterate over labs
  for lab_name in "${llabs[@]}";
  do
    # 2. Check if it's a valid lab
    if [ ${LABSMAP[$1/$lab_name]+_} ]
    then
      # 3. Lab and dependencies installation
      deploy_lab_and_deps $1 $lab_name
    else
      echo "  Skipping '$lab_name', lab is NOT a valid lab"
      exit
    fi
  done
}

# remove
#   desc:
#   params:
#     $1 - category the labs belong to
#     $2 - name of the lab to remove
#   return (status code/stdout):
#     0/ok message - module uninstalled correctly
#     1/ko message - module was not uninstalled
remove() {
  # 1. Check if the module is already installed
  $LABBUILDER_LABS/categories/$1/$2/build.sh status > /dev/null
  lab_status=$?
  if [[ $lab_status -eq 0 ]]
  then
    # 2. Check if there is a dependency before removing (TBD)
    # 3. Remove the module
    $LABBUILDER_LABS/categories/$1/$2/build.sh remove
  else
    echo "  Skipping '$1/$2', lab is NOT actually installed"
  fi
}

# usage
#   desc: display script's syntax
#   params:
#   return (status code/stdout):
usage() {
  echo "Usage: lab_builder.sh OPTION [category] [comma separated list of labs]"
  echo
  echo "Available options for lab_builder:"
  echo "  status              display the current status of available labs"
  echo "  categories          list available categories"
  echo "  labs                list available labs for a given category"
  echo "  deploy              deploy a list of labs from a specific category"
  echo "  remove              remove a list of labs from a specific category"
}

# eval_args
#   desc: evaluate the arguments provided to the script
#   params:
#     $1 - option to execute
#   return (status code/stdout):
#     0/ok message - the option is executed properly
#     1/ko message - display usage due to a syntax error
eval_args(){
  if [ $# -eq 1 ]
  then
    if [ "$1" == "status" ]
    then
      echo "showing status"
    elif [ "$1" == "categories" ]
    then
      list_categories
    else
      echo "Error: bad option or bad number of arguments"
      usage
      exit 1
    fi
  elif [ $# -eq 2 ]
  then
    if [ "$1" == "labs" ]
    then
      list_labs $2
    fi
  elif [ $# -eq 3 ]
  then
    if [ "$1" == "deploy" ]
    then
      deploy $2 $3
    elif [ "$1" == "remove" ]
    then
      remove $2 $3
    else
      echo "Error: bad option or bad number of arguments"
      usage
      exit 1
    fi
  else
    echo "Error: bad option or bad number of arguments"
    usage
    exit 1
  fi
}

# Lab builder's entry point
#
if ! [ -z "$*" ]
then
  LABBUILDER_HOME=$(dirname $(realpath $0))
  source $LABBUILDER_HOME/../etc/labbuilder/lab_builder.conf

  load_categories $LABBUILDER_CATEGORIESLIST
  load_labs $LABBUILDER_LABSLIST
  eval_args $*
  exit 0
fi

usage
