#!/usr/bin/bash

# Global variables definition
#
OSBDET_VER=vS21R1
OSBDET_USERPASS=osbdet123$
OSBDET_MODULESLIST=shared/modules_list.conf
OSBDET_MODULESDIR=modules
OSBDET_TARGETOS=deb10

declare -A MODULESMAP

# Auxiliary functions
#

# load_modules
#   desc: load modules from a file into an associative array
#   params:
#     $1 - file containing available modules
#   return (status code/stdout):
load_modules() {
  while IFS=\| read -r field1 field2 field3 field4; do
    if [[ ! $field1 =~ ^# && ! $field1 =~ ^" "+ && $field1 != "" ]]; then
      MODULESMAP[$field1]="$field2|$field3|$field4"
    fi
  done < "$1"
}

# get_module_version
#   desc: 
#   params:
#     $1 - module name
#   return (status code/stdout):
#     0/module_version - module version if exists
#     -1/no_version    - no_version string if there is no version available
#     -2/no_module     - module not found
get_module_version() {
  module_info=${MODULESMAP[$1]}
  if [[ $module_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3  <<< "$module_info"
    if [[ $field1 != "" ]]; then
      echo $field1
      return 0
    else
      echo "no_version"
      return -1
    fi
  else
    echo "no_module"
    return -2
  fi
}

# get_module_description
#   desc: 
#   params:
#     $1 - module name
#   return (status code/stdout):
#     0/module description - module description if exists
#     -1/no_description    - no_description string if there is no description available
#     -2/no_module         - module not found
get_module_description() {
  module_info=${MODULESMAP[$1]}
  if [[ $module_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3  <<< "$module_info"
    if [[ $field2 != "" ]]; then
      echo $field2
      return 0
    else
      echo "no_description"
      return -1
    fi
  else
    echo "no_module"
    return -2
  fi
}

# get_module_dependencies
#   desc: 
#   params:
#     $1 - module name
#   return (status code/stdout):
#     0/module dependencies - module dependencies if exists
#     -1/no_dependencies    - no_dependencies string if there is no dependencies available
#     -2/no_module          - module not found
get_module_dependencies() {
  module_info=${MODULESMAP[$1]}
  if [[ $module_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3  <<< "$module_info"
    if [[ $field3 != "" ]]; then
      echo $field3
      return 0
    else
      echo "no_dependencies"
      return -1
    fi
  else
    echo "no_module"
    return -2
  fi
}

# show_status
#   desc: 
#   params:
#   return (status code/stdout):
show_status() {
  echo "The folowing list shows the status of all available modules:"
  for module_name in "${!MODULESMAP[@]}"; do 
    module_status=`$OSBDET_MODULESDIR/$module_name/script-$OSBDET_TARGETOS.sh status`
    echo "  - $module_name: $module_status"
  done
}
 
# list_modules
#   desc: 
#   params:
#   return (status code/stdout):
list_modules() {
  echo "These are the modules available in OSBDET $OSBDET_VER:"
  for module_name in "${!MODULESMAP[@]}"; do 
    module_description=$(get_module_description $module_name)
    module_dependencies=$(get_module_dependencies $module_name)
    echo "  - $module_name: $module_description, depends on: $module_dependencies"
  done
}

# build_modules
#   desc: 
#   params:
#     $1 - modules to build
#   return (status code/stdout):
#     0/ok message - modules installed correctly
#     -1/ko message - not all modules were installed
build_modules() {

  IFS=','
  read -a lmodules <<< "$1"

  for module in "${lmodules[@]}";
  do
    printf "$module\n"
  done
}

# usage
#   desc: display script's syntax
#   params:
#   return (status code/stdout):
usage() {
  echo "Usage: osbdet_builder.sh [OPTION] [comma separated list of modules]"
  echo 
  echo "Available options for mounter:"
  echo "  status              display the current status of OSBDET's modules"
  echo "  modules             list available modules"
  echo "  build               build modules specified in config_file"
  echo "  remove              remove modules specified in config_file"
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
      show_status
    elif [ "$1" == "modules" ]
    then
      list_modules
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
      build_modules $2
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
  load_modules ./shared/modules_list.conf
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
