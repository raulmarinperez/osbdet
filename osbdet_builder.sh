#!/bin/bash

# Global variables definition
#
export OSBDET_VER=s21r2
export OSBDET_TARGETOS=deb10
export OSBDET_USERPASS=osbdet123$
export OSBDET_HOME=/root/osbdet
export OSBDETRECIPES_HOME=/root/osbdet-recipes
export OSBDET_MODULESLIST=$OSBDET_HOME/shared/modules_list.conf
export OSBDET_MODULESDIR=$OSBDET_HOME/modules
export OSBDET_RECIPESLIST=$OSBDET_HOME/shared/recipes_list.conf
export OSBDET_LOGFILE=$OSBDET_HOME/osbdet.log

export LOGLEVEL=DEBUG

declare -A MODULESMAP
declare -A RECIPESMAP

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

# load_recipes
#   desc: load recipes from a file into an associative array
#   params:
#     $1 - file containing available recipes
#   return (status code/stdout):
load_recipes() {
  while IFS=\| read -r field1 field2 field3 field4; do
    if [[ ! $field1 =~ ^# && ! $field1 =~ ^" "+ && $field1 != "" ]]; then
      RECIPESMAP["$field1-$field2"]="$field1|$field2|$field3|$field4"
    fi
  done < "$1"
}

# get_recipe_name
#   desc: 
#   params:
#     $1 - recipe extended name
#   return (status code/stdout):
#     0/recipe_name - recipe name if exists
#     1/no_name     - no_name string if there is no name available
#     2/no_recipe   - recipe not found
get_recipe_name() {
  recipe_info=${RECIPESMAP[$1]}
  if [[ $recipe_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$recipe_info"
    if [[ $field1 != "" ]]; then
      echo $field1
      return 0
    else
      echo "no_name"
      return 1
    fi
  else
    echo "no_recipe"
    return -2
  fi
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

# get_recipe_version
#   desc: 
#   params:
#     $1 - recipe extended name
#   return (status code/stdout):
#     0/recipe_version - recipe version if exists
#     1/no_version     - no_version string if there is no version available
#     2/no_recipe      - recipe not found
get_recipe_version() {
  recipe_info=${RECIPESMAP[$1]}
  if [[ $recipe_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$recipe_info"
    if [[ $field2 != "" ]]; then
      echo $field2
      return 0
    else
      echo "no_version"
      return 1
    fi
  else
    echo "no_recipe"
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

# get_recipe_description
#   desc: 
#   params:
#     $1 - recipe extended name
#   return (status code/stdout):
#     0/recipe description - recipe description if exists
#     1/no_description     - no_description string if there is no description available
#     -2/no_recipe         - recipe not found
get_recipe_description() {
  recipe_info=${RECIPESMAP[$1]}
  if [[ $recipe_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$recipe_info"
    if [[ $field3 != "" ]]; then
      echo $field3
      return 0
    else
      echo "no_description"
      return 1
    fi
  else
    echo "no_recipe"
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

# get_recipe_dependencies
#   desc: 
#   params:
#     $1 - recipe extended name
#   return (status code/stdout):
#     0/recipe dependencies - recipe dependencies if exists
#     1/no_dependencies     - no_dependencies string if there is no dependencies available
#     -2/no_recipe          - recipe not found
get_recipe_dependencies() {
  recipe_info=${RECIPESMAP[$1]}
  if [[ $recipe_info != "" ]]; then
    IFS=\|
    read -r field1 field2 field3 field4 <<< "$module_info"
    if [[ $field4 != "" ]]; then
      echo $field4
      return 0
    else
      echo "no_dependencies"
      return 1
    fi
  else
    echo "no_recipe"
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
  echo "These are the modules available in OSBDET v$OSBDET_VER:"
  for module_name in "${!MODULESMAP[@]}"; do 
    module_description=$(get_module_description $module_name)
    module_dependencies=$(get_module_dependencies $module_name)
    echo "  - $module_name: $module_description, depends on: $module_dependencies"
  done
}
# list_recipes
#   desc: 
#   params:
#   return (status code/stdout):
list_recipes() {
  echo "These are the recipes available for OSBDET v$OSBDET_VER:"
  for recipe_name_ext in "${!RECIPESMAP[@]}"; do 
    recipe_name=$(get_recipe_name $recipe_name_ext)
    recipe_version=$(get_recipe_version $recipe_name_ext)
    recipe_description=$(get_recipe_description $recipe_name_ext)
    recipe_dependencies=$(get_recipe_dependencies $recipe_name_ext)
    echo "  - $recipe_name[$recipe_version]: $recipe_description, depends on: $recipe_dependencies"
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
    if [ $? -ne 0 ]
    then
      debug "Fatal error: module '$1' cannot be installed. See log messages for more information."
      exit 1
    fi
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

# cook_recipes
#   desc: 
#   params:
#     $1 - list of recipes to cook for this OSBDET environment
#   return (status code/stdout):
#     0/ok message - recipes were cooked correctly
#     1/ko message - not all recipes were cooked
cook_recipes() {
  IFS=','
  read -a lrecipes <<< "$1"

  # 1. Update the repo with the recipes
  cd $OSBDETRECIPES_HOME && git reset --hard HEAD > /dev/null && git pull > /dev/null
  # 2. Iterate over recipes
  for recipe_name in "${lrecipes[@]}";
  do
    # 3. Check if it's a valid recipe
    recipe_name_ext="$recipe_name-$OSBDET_VER"  
    if [ ${RECIPESMAP[$recipe_name_ext]+_} ]; then	
      cd recipes/$OSBDET_VER/$recipe_name
      /bin/bash ./run.sh
    else
      echo "  Skipping '$recipe_name', recipe is NOT a valid recipe"
      exit
    fi
  done
}

# usage
#   desc: display script's syntax
#   params:
#   return (status code/stdout):
usage() {
  echo "Usage: osbdet_builder.sh [OPTION] [comma separated list of modules/recipes]"
  echo 
  echo "Available options for osbdet_builder:"
  echo "  status              display the current status of OSBDET's modules"
  echo "  modules             list available modules"
  echo "  recipes             list available recipes"
  echo "  build               build environment by installing available modules"
  echo "  remove              remove installed modules from current environment"
  echo "  cook                'cook' all the recipes passed as an argument"
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
    elif [ "$1" == "recipes" ]
    then
      list_recipes
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
    elif [ "$1" == "cook" ]
    then
      echo  "Cooking some recipes for OSBDET:"
      cook_recipes $2
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
  load_modules $OSBDET_MODULESLIST
  load_recipes $OSBDET_RECIPESLIST
  eval_args $*
  exit 0
fi

usage
exit 1
