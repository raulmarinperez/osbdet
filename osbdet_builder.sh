#!/bin/bash

# Global variables definition
#
OSBDET_VER=24r1
export OSBDET_HOME=$(dirname $(realpath $0))
export OSBDET_MODULESLIST=$OSBDET_HOME/shared/modules_list.conf
export OSBDET_MODULESDIR=$OSBDET_HOME/modules
export OSBDET_RECIPESLIST=$OSBDET_HOME/shared/recipes_list.conf
export OSBDET_LOGFILE=$OSBDET_HOME/osbdet.log

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

# load_configuration
#   desc: Load the configuration file if exists
#   params:
#   return (status code/stdout):
load_configuration() {
  if [ -f $OSBDET_HOME/shared/osbdet_builder.conf ]
  then
    source $OSBDET_HOME/shared/osbdet_builder.conf
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
  # 1. Create the recipes folder if it didn't exist (first run)
  if [ ! -d "$OSBDETRECIPES_HOME" ] && [ "$OSBDETRECIPES_HOME" != "" ]
  then
    debug "osbdet_builder.load_recipes DEBUG [`date +"%Y-%m-%d %T"`] $OSBDETRECIPES_HOME doesn't exit and it'll be created" >> $OSBDET_LOGFILE
    mkdir -p $OSBDETRECIPES_HOME 
    cd $OSBDETRECIPES_HOME/..
    git clone https://github.com/raulmarinperez/osbdet-recipes.git >> $OSBDET_LOGFILE 2>&1
  fi
  # 2. Update the repo with the recipes
  if [ "$OSBDETRECIPES_HOME" != "" ] && [ -d $OSBDETRECIPES_HOME ] && [ "$OSBDETRECIPES_REPO" != "" ]
  then
    cd $OSBDETRECIPES_HOME
    git reset --hard HEAD >> $OSBDET_LOGFILE 2>&1 
    git pull >> $OSBDET_LOGFILE 2>&1
  fi
  # 3. Load the list of recipes into memory
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
    module_status=`$OSBDET_MODULESDIR/$module_name/$OSBDET_TARGETOS/$OSBDET_ARCHITECTURE/build.sh status`
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
    if [ "$OSBDET_VER" == "$recipe_version" ]
    then
      echo "  - $recipe_name[$recipe_version]: $recipe_description, depends on: $recipe_dependencies"
    fi
  done
}

# current_conf
#   desc: 
#   params:
#   return (status code/stdout):
current_conf() {
  echo "This is the current configuration of OSBDET $OSBDET_VER:"
  echo "  OSBDET_HOME: $OSBDET_HOME"
  echo "  LOGLEVEL: $LOGLEVEL"
  echo "  OSBDET_TARGETOS: $OSBDET_TARGETOS"
  echo "  OSBDET_ARCHITECTURE: $OSBDET_ARCHITECTURE"
  echo "  OSBDETRECIPES_HOME: $OSBDETRECIPES_HOME"
  echo "  OSBDETRECIPES_REPO: $OSBDETRECIPES_REPO"
}

# check_conf
#   desc: check a configuration variable
#   params:
#     $1 - Configuration variable
#     $2 - Value to check against
#   return (conf value/VALUE global var):
#     Value - Confirmed or default value if it's all good
#     1     - The checking was not successful
check_conf() {
  # 1. Checking values of the LOGLEVEL configuration variable
  if [ "$1" == "LOGLEVEL" ]
  then
    if [ "$2" == "" ] || [ "$2" == "DEBUG" ]
    then
      VALUE="DEBUG"
    else
      VALUE=1
    fi
  # 2. Checking values of the OSBDET_TARGETOS configuration variable
  elif [ "$1" == "OSBDET_TARGETOS" ]
  then
    if [ "$2" == "" ] || [ "$2" == "deb12" ]
    then
      VALUE="deb12"
    elif  [ "$2" == "ubu20" ]
    then
      VALUE=$2
    else
      VALUE=1
    fi
  # 3. Checking values of the OSBDET_ARCHITECTURE configuration variable
  elif [ "$1" == "OSBDET_ARCHITECTURE" ]
  then
    if [ "$2" == "" ] || [ "$2" == "amd64" ]
    then
      VALUE="amd64"
    elif  [ "$2" == "arm64" ]
    then
      VALUE=$2
    else
      VALUE=1
    fi
  # 4. Checking values of the OSBDETRECIPES_HOME configuration variable
  elif [ "$1" == "OSBDETRECIPES_HOME" ]
  then
    if [ "$2" == "" ]
    then
      VALUE="/root/osbdet-recipes"
    else
      VALUE=$2
    fi
  # 5. Checking values of the OSBDETRECIPES_REPO configuration variable
  elif [ "$1" == "OSBDETRECIPES_REPO" ]
  then
    if [ "$2" == "" ]
    then
      VALUE="https://github.com/raulmarinperez/osbdet-recipes.git"
    else
      VALUE=$2
    fi
  else
    VALUE=1
  fi
}

# persist_setup
#   desc: 
#   params:
#   return:
persist_setup() {
  printf "Persisting changes in $OSBDET_HOME/shared/osbdet_builder.conf... "
  echo "export LOGLEVEL=$LOGLEVEL" > $OSBDET_HOME/shared/osbdet_builder.conf
  echo "OSBDET_VER=$OSBDET_VER" >> $OSBDET_HOME/shared/osbdet_builder.conf
  echo "OSBDET_TARGETOS=$OSBDET_TARGETOS" >> $OSBDET_HOME/shared/osbdet_builder.conf
  echo "OSBDET_ARCHITECTURE=$OSBDET_ARCHITECTURE" >> $OSBDET_HOME/shared/osbdet_builder.conf
  echo >> $OSBDET_HOME/shared/osbdet_builder.conf
  echo "OSBDETRECIPES_HOME=$OSBDETRECIPES_HOME" >> $OSBDET_HOME/shared/osbdet_builder.conf
  echo "OSBDETRECIPES_REPO=$OSBDETRECIPES_REPO" >> $OSBDET_HOME/shared/osbdet_builder.conf
  printf "[Done]\n"
}

# read_valid_conf
#   desc: read a valid configuration parameter from the keyboard
#   params:
#     $1 - Configuration variable
#     $2 - Message with the valid options
#   return (conf value/VALUE global var):
#     Value - Confirmed or default value if it's all good
read_valid_conf() {
  VALUE=1
  while [ "$VALUE" == "1" ]
  do
    # 1. Ask the user for a value
    read VALUE
    # 2. Check the value introduced
    check_conf $1 $VALUE
    if [ "$VALUE" == "1" ]
    then
      echo "WRONG VALUE! Please, provide a valid value: '$2'"
    fi
  done
}

# setup
#   desc: ask some questions to the user to set the environment up
#   params:
#   return (status code/stdout):
setup() {
  echo "Let's setup your OSBDET $OSBDET_VER builder:"
  printf "  Log level (DEBUG*): "
  read_valid_conf LOGLEVEL "DEBUG*"
  LOGLEVEL=$VALUE
  printf "  Target Operating System (deb12*): "
  read_valid_conf OSBDET_TARGETOS "deb12*|ubu20"
  OSBDET_TARGETOS=$VALUE
  printf "  Target Architecture (amd64*|arm64): "
  read_valid_conf OSBDET_ARCHITECTURE "amd64*|arm64"
  OSBDET_ARCHITECTURE=$VALUE
  printf "  OSBDET recipes home (/root/osbdet-recipes*): "
  read_valid_conf OSBDETRECIPES_HOME "/root/osbdet-recipes*"
  OSBDETRECIPES_HOME=$VALUE
  printf "  OSBDET repository (https://github.com/raulmarinperez/osbdet-recipes.git*): "
  read_valid_conf OSBDETRECIPES_REPO "https://github.com/raulmarinperez/osbdet-recipes.git*"
  OSBDETRECIPES_REPO=$VALUE

  persist_setup
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
  $OSBDET_MODULESDIR/$1/$OSBDET_TARGETOS/$OSBDET_ARCHITECTURE/build.sh status > /dev/null
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
    $OSBDET_MODULESDIR/$1/$OSBDET_TARGETOS/$OSBDET_ARCHITECTURE/build.sh install
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
  $OSBDET_MODULESDIR/$1/$OSBDET_TARGETOS/$OSBDET_ARCHITECTURE/build.sh status > /dev/null
  module_status=$?
  if [[ $module_status -eq 0 ]]; then
    # 2. Check if there is a dependency before removing (TBD)
    # 3. Remove the module
    $OSBDET_MODULESDIR/$1/$OSBDET_TARGETOS/$OSBDET_ARCHITECTURE/build.sh uninstall
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

  # 1. Iterate over recipes
  for recipe_name in "${lrecipes[@]}";
  do
    # 2. Check if it's a valid recipe
    recipe_name_ext="$recipe_name-$OSBDET_VER"  
    if [ ${RECIPESMAP[$recipe_name_ext]+_} ]
    then
      cd $OSBDETRECIPES_HOME/recipes/$OSBDET_VER/$recipe_name
      /bin/bash ./run.sh
    else
      echo "  Skipping '$recipe_name', recipe is NOT a valid recipe"
      exit
    fi
  done
}

# is_setup
#   desc: checking if OSBDET is properly configured
#   params:
#   return (status code/stdout):
is_setup() {
  if [ "$OSBDET_TARGETOS" == "" ] || [ "$OSBDET_ARCHITECTURE" == "" ]
  then
    echo "WATCH OUT: before you can work with your environment, you have to set it up:"
    echo
    echo "   osbdet_builder.sh setup" 
    exit 1
  fi
}

# usage
#   desc: display script's syntax
#   params:
#   return (status code/stdout):
usage() {
  echo "Usage: osbdet_builder.sh [OPTION] [comma separated list of modules/recipes]"
  echo 
  echo "Available options for osbdet_builder:"
  echo "  ## environment related options ##"
  echo "  status              display the current status of OSBDET's modules"
  echo "  modules             list available modules"
  echo "  recipes             list available recipes"
  echo "  currentconf         display the current configuration of osbdet_builder"
  echo "  setup               change the current configuration of osbdet_builder"
  echo
  echo "  ## operational options ##"
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
      is_setup
      show_status
    elif [ "$1" == "modules" ]
    then
      is_setup
      list_modules
    elif [ "$1" == "recipes" ]
    then
      is_setup
      list_recipes
    elif [ "$1" == "currentconf" ]
    then
      is_setup
      current_conf
    elif [ "$1" == "setup" ]
    then
      setup
    else
      echo "Error: bad option or bad number of arguments"
      usage
      exit 1
    fi
  elif [ $# -eq 2 ]
  then
    if [ "$1" == "build" ]
    then
      is_setup
      echo  "Building some modules into OSBDET:"
      build_environment $2
    elif [ "$1" == "remove" ]
    then
      is_setup
      echo  "Removing modules from OSBDET:"
      remove_modules $2
    elif [ "$1" == "cook" ]
    then
      is_setup
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
load_configuration

if ! [ -z "$*" ]
then
  load_modules $OSBDET_MODULESLIST
  load_recipes $OSBDET_RECIPESLIST
  eval_args $*
  exit 0
fi

usage
echo && is_setup
exit 1
