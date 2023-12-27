#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic

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

dsenv_install(){
  debug "jupyter.dsenv_install DEBUG [`date +"%Y-%m-%d %T"`] Installing all the software for the data science environment"
  apt-get install -y pandoc texlive-xetex texlive-fonts-recommended python3-venv
  su osbdet -c "mkdir /home/osbdet/.jupyter_venv"
  su osbdet -c "python3 -m venv /home/osbdet/.jupyter_venv"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install --upgrade pip"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip install jupyter numpy pandas seaborn statsmodels"
  debug "jupyter.dsenv_install DEBUG [`date +"%Y-%m-%d %T"`] Software for the data science environment installed"
}
remove_dsenv(){
  debug "jupyter.remove_dsenv DEBUG [`date +"%Y-%m-%d %T"`] Removing data science environment software"
  apt-get remove -y pandoc texlive-xetex texlive-fonts-recommended python3-venv --purge
  apt autoremove -y
  rm -rf /home/osbdet/.jupyter_venv
  debug "jupyter.remove_dsenv DEBUG [`date +"%Y-%m-%d %T"`] Data science environment software removed"
}

initialsetup(){
  debug "jupyter.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Jupyter"
  su osbdet -c "mkdir /home/osbdet/notebooks"
  su osbdet -c "/home/osbdet/.jupyter_venv/bin/jupyter notebook --generate-config"
  sed -i "s/^# c\.ServerApp\.ip = 'localhost'/c\.ServerApp\.ip = '\*'/" /home/osbdet/.jupyter/jupyter_notebook_config.py
  sed -i "s/^# c\.ServerApp\.password = ''/c\.ServerApp\.password = 'sha1:51a108786a75:0798779c484abd8a6218db7d4e9d3370ffbcd9c8'/"\
         /home/osbdet/.jupyter/jupyter_notebook_config.py
  sed -i "s/^# c\.ServerApp\.notebook\_dir = ''/c\.ServerApp\.notebook\_dir = '\/home\/osbdet\/notebooks'/"\
         /home/osbdet/.jupyter/jupyter_notebook_config.py
  debug "jupyter.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Jupyter done"
}
remove_initialsetup(){
  debug "jupyter.remove_initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Removing initial setup of Jupyter"
  rm -rf /home/osbdet/.jupyter /home/osbdet/notebooks
  debug "jupyter.remove_initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Removing initial setup of Jupyter"
}

serviceinstall(){
  debug "jupyter.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_HOME/jupyter.service /lib/systemd/system/jupyter.service
  chmod 644 /lib/systemd/system/jupyter.service
  systemctl daemon-reload
  systemctl enable jupyter.service
  debug "jupyter.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "jupyter.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  systemctl stop jupyter.service
  systemctl disable jupyter.service
  rm /lib/systemd/system/jupyter.service 
  systemctl daemon-reload
  debug "jupyter.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

# Primary functions
#
module_install(){
  debug "jupyter.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Data Science environment installation
  #   2. Initial setup of Jupyter
  #   3. Systemd script installation
  printf "  Installing module 'jupyter' ... "
  dsenv_install >> $OSBDET_LOGFILE 2>&1
  initialsetup >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "jupyter.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/home/osbdet/.jupyter" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "jupyter.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Systemd script removal
  #   2. Undoing setup of Jupyter
  #   3. Data Science environment removal
  printf "  Uninstalling module 'jupyter' ... "
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  remove_initialsetup >> $OSBDET_LOGFILE 2>&1
  remove_dsenv >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "jupyter.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'jupyter\' module
  echo Usage: script.sh [OPTION]
  echo 
  echo Available options for this module:
  echo "  install             module installation"
  echo "  status              module installation status check"
  echo "  uninstall           module uninstallation"
}

main(){
  # 1. Set logfile to /dev/null if it doesn't exist
  if [ -z "$OSBDET_LOGFILE" ] ; then
    export OSBDET_LOGFILE=/dev/null
  fi
  # 2. Main function
  debug "jupyter DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the jupyter module" >> $OSBDET_LOGFILE
  if [ $# -eq 1 ]
  then
    if [ "$1" == "install" ]
    then
      module_install
    elif [ "$1" == "status" ]
    then
      module_status
    elif [ "$1" == "uninstall" ]
    then
      module_uninstall
    else
      usage
      exit -1
    fi
  else
    usage
    exit -1
  fi
  debug "jupyter DEBUG [`date +"%Y-%m-%d %T"`] Activity with the jupyter module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..  
  main $*
fi
