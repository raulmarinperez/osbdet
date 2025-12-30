#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic

SPARK_VERSION=3.5.7
SPARK_JARS_DIR=/home/osbdet/.jupyter_venv/lib/python3.13/site-packages/pyspark/jars
HADOOP_AWS_JAR_URL=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
HADOOP_AWS_JAR_NAME=hadoop-aws-3.3.4.jar
AWS_JAVA_SDK_JAR_URL=https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.780/aws-java-sdk-bundle-1.12.780.jar
AWS_JAVA_SDK_JAR_NAME=aws-java-sdk-bundle-1.12.780.jar
NVM_INSTALL_SCRIPT=https://raw.githubusercontent.com/nvm-sh/nvm/refs/tags/v0.40.3/install.sh
NVM_DIR=/home/osbdet/.nvm

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

install_dependencies(){
  debug "spark.install_dependencies DEBUG [`date +"%Y-%m-%d %T"`] Installing dependencies to make Spark work"

  su osbdet -c "curl -o- $NVM_INSTALL_SCRIPT | bash"
  su osbdet -c ". $NVM_DIR/nvm.sh && . $NVM_DIR/bash_completion && nvm install --lts"

  debug "spark.install_dependencies DEBUG [`date +"%Y-%m-%d %T"`] Dependencies to make Spark work installed"
}
remove_dependencies(){
  debug "spark.remove_dependencies DEBUG [`date +"%Y-%m-%d %T"`] Removing dependencies to make Spark work"

  su osbdet -c "rm -rf /home/osbdet/.nvm"

  debug "spark.remove_dependencies DEBUG [`date +"%Y-%m-%d %T"`] Dependencies to make Spark work removed"
}

install_pyspark(){
  debug "spark.install_pyspark DEBUG [`date +"%Y-%m-%d %T"`] Installing pyspark, jupyterlab-sql-editor and others"

  su osbdet -c "export TMPDIR=/var/tmp;/home/osbdet/.jupyter_venv/bin/python3 -m pip install bokeh jupyterlab-lsp jupyterlab-sql-editor pyspark==$SPARK_VERSION"
  # the following file makes the sparksql magic available in Jupyter
  su osbdet -c "mkdir -p /home/osbdet/.ipython/profile_default/"
  su osbdet -c "cp -f $SCRIPT_HOME/ipython_config.py /home/osbdet/.ipython/profile_default/ipython_config.py"

  debug "spark.install_pyspark DEBUG [`date +"%Y-%m-%d %T"`] pyspark, jupyterlab-sql-editor and others installed"
}
remove_pyspark(){
  debug "spark.remove_pyspark DEBUG [`date +"%Y-%m-%d %T"`] Removing pyspark, jupyterlab-sql-editor and others"

  su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip uninstall -y bokeh jupyterlab-lsp jupyterlab-sql-editor pyspark"

  debug "spark.remove_pyspark DEBUG [`date +"%Y-%m-%d %T"`] pyspark, jupyterlab-sql-editor and others removed"
}

deploy_jars(){
  debug "spark.deploy_jars DEBUG [`date +"%Y-%m-%d %T"`] Deploying JARs to make S3-compatible storage accessible from Spark"

  su osbdet -c "wget -O $SPARK_JARS_DIR/$AWS_JAVA_SDK_JAR_NAME $AWS_JAVA_SDK_JAR_URL"
  su osbdet -c "wget -O $SPARK_JARS_DIR/$HADOOP_AWS_JAR_NAME $HADOOP_AWS_JAR_URL"

  debug "spark.deploy_jars DEBUG [`date +"%Y-%m-%d %T"`] JARs to make S3-compatible storage accessible from Spark deployed"
}

jupyterspark(){
  debug "spark.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] If Jupyter is installed, the service is updated to consider Spark"
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop
     sed -i '/User=osbdet/a Environment="NVM_DIR=/home/osbdet/.nvm"' /lib/systemd/system/jupyter.service 
     sed -i '/User=osbdet/a Environment="AWS_JAVA_V1_DISABLE_DEPRECATION_ANNOUNCEMENT=true"' /lib/systemd/system/jupyter.service 
     systemctl daemon-reload
     service jupyter start
     debug "spark.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script updated"
  else
     debug "spark.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script update skipped as Jupyter was not found"
  fi
  debug "spark.jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter and Spark integration done"
}
remove_jupyterspark(){
  debug "spark.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] If Jupyter is installed, the service is updated to remove the reference to Spark" >> $OSBDET_LOGFILE
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop
     sed -i '/Environment="NVM_DIR=\/home\/osbdet\/.nvm"/d' /lib/systemd/system/jupyter.service
     sed -i '/Environment="AWS_JAVA_V1_DISABLE_DEPRECATION_ANNOUNCEMENT=true"/d' /lib/systemd/system/jupyter.service 
     systemctl daemon-reload
     service jupyter start
     debug "spark.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script updated"
  else
     debug "spark.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter systemd script update skipped as Jupyter was not found"
  fi
  debug "spark.remove_jupyterspark DEBUG [`date +"%Y-%m-%d %T"`] Jupyter and Spark integration removed"
}

# Primary functions
#
module_install(){
  debug "spark.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Install dependencies, NVM, to make jupyterlab-lsp work
  #   2. Install PySpark module, jupyterlab-sql-editor and others
  #   3. Deploy jars to connect Spark with S3 compatible object storage (ex. MinIO)
  #   4. Update jupyter systemd script accordingly
  printf "  Installing module 'spark' ... "
  install_dependencies >> $OSBDET_LOGFILE 2>&1
  install_pyspark >> $OSBDET_LOGFILE 2>&1
  deploy_jars >> $OSBDET_LOGFILE 2>&1
  jupyterspark >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "spark.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  # Does Jupyter venv, where PySpark will live, exist?
  if [ -f "/home/osbdet/.jupyter_venv/bin/python3" ]
  then
    # is the pyspark module installed?
    su osbdet -c "/home/osbdet/.jupyter_venv/bin/python3 -m pip list | grep pyspark > /dev/null"
    if [ $? -eq 0 ]
    then
      echo "Module is installed [OK]"
      exit 0
    fi
  fi
  # No Jupyter venv or no PySpark module in it.
  echo "Module is not installed [KO]"
  exit 1
}

module_uninstall(){
  debug "spark.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Update jupyter systemd script to remove Spark dependencies if Jupyter is installed
  #   2. Remove pyspark module, jupyterlab-sql-editor and others
  #   3. Remove dependencies, NVM, to make jupyterlab-lsp work
  printf "  Uninstalling module 'spark' ... "
  remove_jupyterspark >> $OSBDET_LOGFILE 2>&1
  remove_pyspark >> $OSBDET_LOGFILE 2>&1
  remove_dependencies >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "spark.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'spark\' module
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
  debug "spark DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the spark module" >> $OSBDET_LOGFILE

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
  debug "spark DEBUG [`date +"%Y-%m-%d %T"`] Activity with the spark module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
