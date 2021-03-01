#!/bin/bash

# Global variables definition
#
export OSBDET_VER=vS21R1
export OSBDET_TARGETOS=deb10
export OSBDET_USERPASS=osbdet123$
export OSBDET_HOME=/root/osbdet
export OSBDET_MODULESLIST=$OSBDET_HOME/shared/modules_list.conf
export OSBDET_MODULESDIR=$OSBDET_HOME/modules
export OSBDET_LOGFILE=$OSBDET_HOME/osbdet.log

export LOGLEVEL=DEBUG

declare -A MODULESMAP

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
#     1/no_version    - no_version string if there is no version available
#     2/no_module     - module not found
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
      return 1
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
#     1/no_description    - no_description string if there is no description available
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
      return 1
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
#     1/no_dependencies    - no_dependencies string if there is no dependencies available
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
      return 1
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

# install_module
#   desc: 
#   params:
#     $1 - module to install
#   return (status code/stdout):
#     0/ok message - module installed correctly
#     1/ko message - module was not installed
install_module() {
  # 1. Check if it's installed
  $OSBDET_MODULESDIR/$1/script-$OSBDET_TARGETOS.sh status > /dev/null
  module_status=$?
  if [[ $module_status -eq 0 ]]; then
    debug "[install_module] Skipping '$1', module is already installed"
    return 1
  else
    IFS=','
    dependencies=$(get_module_dependencies $1)
    read -a lmodules <<< "$dependencies"
    # 2. Go over dependencies and install them before installing this module
    for module_name in "${lmodules[@]}";
    do
      if [[ $module_name != "no_dependencies" ]]; then
        install_module $module_name
      fi
    done
    # 3. Module installation
    $OSBDET_MODULESDIR/$1/script-$OSBDET_TARGETOS.sh install
  fi
}

# build_environment
#   desc: 
#   params:
#     $1 - list of modules to build the environment
#   return (status code/stdout):
#     0/ok message - modules installed correctly
#     1/ko message - not all modules were installed
build_environment() {
  IFS=','
  read -a lmodules <<< "$1"

  # 1. Iterate over modules
  for module_name in "${lmodules[@]}";
  do
    # 2. Check if it's a valid module
    if [ ${MODULESMAP[$1]+_} ]; then
      # 3. Module and dependencies installation
      install_module $module_name
     else
      echo "  Skipping '$module_name', module is NOT a valid module"
      exit
    fi
   done
}

# uninstall_module
#   desc: 
#   params:
#     $1 - module to uninstall
#   return (status code/stdout):
#     0/ok message - module uninstalled correctly
#     1/ko message - module was not uninstalled
uninstall_module() {
  # 1. Check if the module is already installed
  $OSBDET_MODULESDIR/$1/script-$OSBDET_TARGETOS.sh status > /dev/null
  module_status=$?
  if [[ $module_status -eq 0 ]]; then
    # 2. Check if there is a dependency before removing (TBD)
    # 3. Remove the module
    $OSBDET_MODULESDIR/$1/script-$OSBDET_TARGETOS.sh uninstall
  else
    echo "  Skipping '$module_name', module is NOT actually installed"
  fi
}
 
# remove_modules
#   desc: 
#   params:
#     $1 - list of modules to remove from the current environment
#   return (status code/stdout):
#     0/ok message - modules removed correctly
#     1/ko message - not all modules were removed
remove_modules() {
  IFS=','
  read -a lmodules <<< "$1"

  # 1. Iterate over modules
  for module_name in "${lmodules[@]}";
  do
    # 2. Check if it's a valid module
    if [ ${MODULESMAP[$1]+_} ]; then
      uninstall_module $module_name
    else
      echo "  Skipping '$module_name', module is NOT a valid module"
      exit
    fi
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
  echo "  build               build environment by installing available modules"
  echo "  remove              remove installed modules from current environment"
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
      show_status
    elif [ "$1" == "modules" ]
    then
      list_modules
    else
      echo "Error: bad option or bad number of arguments"
      usage
      exit 1
    fi
  elif [ $# -eq 2 ]
  then
    if [ "$1" == "build" ]
    then
      echo  "Building some modules into OSBDET:"
      build_environment $2
    elif [ "$1" == "remove" ]
    then
      echo  "Removing modules from OSBDET:"
      remove_modules $2
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

# OSBDET builder's entry point
#
if ! [ -z "$*" ]
then
  load_modules ./shared/modules_list.conf
  eval_args $*
  exit 0
fi

usage
exit 1
