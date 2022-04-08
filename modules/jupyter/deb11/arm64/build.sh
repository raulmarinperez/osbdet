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
  debug "jupyter.dsenv_install DEBUG [`date +"%Y-%m-%d %T"`] Installing all the software for the data science environment" >> $OSBDET_LOGFILE
  apt-get install -y pandoc texlive-xetex texlive-fonts-recommended texlive-generic-recommended >> $OSBDET_LOGFILE 2>&1
  python3 -m pip install --upgrade pip >> $OSBDET_LOGFILE 2>&1
  python3 -m pip install jupyter numpy pandas seaborn statsmodels >> $OSBDET_LOGFILE 2>&1
  debug "jupyter.dsenv_install DEBUG [`date +"%Y-%m-%d %T"`] Software for the data science environment installed" >> $OSBDET_LOGFILE
}
remove_dsenv(){
  debug "jupyter.remove_dsenv DEBUG [`date +"%Y-%m-%d %T"`] Removing data science environment software" >> $OSBDET_LOGFILE
  python3 -m pip uninstall -y jupyter numpy pandas seaborn statsmodels >> $OSBDET_LOGFILE 2>&1
  apt-get remove -y pandoc texlive-xetex texlive-fonts-recommended texlive-generic-recommended --purge >> $OSBDET_LOGFILE 2>&1
  apt autoremove -y >>$OSBDET_LOGFILE 2>&1
  debug "jupyter.remove_dsenv DEBUG [`date +"%Y-%m-%d %T"`] Data science environment software removed" >> $OSBDET_LOGFILE
}

initialsetup(){
  debug "jupyter.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Jupyter" >> $OSBDET_LOGFILE
  su osbdet -c "mkdir /home/osbdet/notebooks" >> $OSBDET_LOGFILE 2>&1
  su osbdet -c "jupyter notebook --generate-config" >> $OSBDET_LOGFILE 2>&1
  sed -i "s/^# c\.NotebookApp\.ip = 'localhost'/c\.NotebookApp\.ip = '\*'/" /home/osbdet/.jupyter/jupyter_notebook_config.py
  sed -i "s/^# c\.NotebookApp\.password = ''/c\.NotebookApp\.password = 'sha1:51a108786a75:0798779c484abd8a6218db7d4e9d3370ffbcd9c8'/"\
         /home/osbdet/.jupyter/jupyter_notebook_config.py
  sed -i "s/^# c\.NotebookApp\.notebook\_dir = ''/c\.NotebookApp\.notebook\_dir = '\/home\/osbdet\/notebooks'/"\
         /home/osbdet/.jupyter/jupyter_notebook_config.py
  debug "jupyter.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Jupyter done" >> $OSBDET_LOGFILE
}
remove_initialsetup(){
  debug "jupyter.remove_initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Removing initial setup of Jupyter" >> $OSBDET_LOGFILE
  rm -rf /home/osbdet/.jupyter /home/osbdet/notebooks >> $OSBDET_LOGFILE 2>&1
  debug "jupyter.remove_initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Removing initial setup of Jupyter" >> $OSBDET_LOGFILE
}

serviceinstall(){
  debug "jupyter.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation" >> $OSBDET_LOGFILE
  cp $SCRIPT_HOME/jupyter.service /lib/systemd/system/jupyter.service
  chmod 644 /lib/systemd/system/jupyter.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  systemctl enable jupyter.service >> $OSBDET_LOGFILE 2>&1
  debug "jupyter.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done" >> $OSBDET_LOGFILE
}
remove_serviceinstall(){
  debug "jupyter.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation" >> $OSBDET_LOGFILE
  service jupyter stop >> $OSBDET_LOGFILE 2>&1
  systemctl disable jupyter.service >> $OSBDET_LOGFILE 2>&1
  rm /lib/systemd/system/jupyter.service 
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "jupyter.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done" >> $OSBDET_LOGFILE
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
  dsenv_install
  initialsetup
  serviceinstall
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
  remove_serviceinstall
  remove_initialsetup
  remove_dsenv
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
