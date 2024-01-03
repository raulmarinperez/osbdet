#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
HADOOP_BINARY_URL=https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
HADOOP_TGZ_FILE=hadoop-3.3.6.tar.gz
HADOOP_DEFAULT_DIR=hadoop-3.3.6

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

getandextract(){
  debug "hadoop3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Hadoop 3"
  wget $HADOOP_BINARY_URL -O /opt/$HADOOP_TGZ_FILE
  if [[ $? -ne 0 ]]; then
    echo "[Error]"
    exit 1
  fi
      
  tar zxf /opt/$HADOOP_TGZ_FILE -C /opt
  rm /opt/$HADOOP_TGZ_FILE 
  mv /opt/$HADOOP_DEFAULT_DIR /opt/hadoop3
  chown -R osbdet:osbdet /opt/hadoop3
  chmod +x /opt/hadoop3/etc/hadoop/*-env.sh
  debug "hadoop3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 downloading and extracting process done"
}
binaries_removal(){
  debug "hadoop3.binaries_removal DEBUG [`date +"%Y-%m-%d %T"`] Removing Hadoop 3 files"
  rm -rf /opt/hadoop3
  debug "hadoop3.binaries_removal DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 files removed"
}

setenvvars(){
  debug "hadoop3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Setting the environment variables for the installation process"
  export HADOOP_HOME=/opt/hadoop3
  export HADOOP_COMMON_HOME=/opt/hadoop3
  export HADOOP_HDFS_HOME=/opt/hadoop3
  export HADOOP_MAPRED_HOME=/opt/hadoop3
  export HADOOP_YARN_HOME=/opt/hadoop3
  export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop3
  export HDFS_DATANODE_USER=osbdet
  export HDFS_NAMENODE_USER=osbdet
  export HDFS_SECONDARYNAMENODE_USER=osbdet
  export YARN_RESOURCEMANAGER_USER=osbdet
  export YARN_NODEMANAGER_USER=osbdet
  export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
  export JAVA_HOME=/usr/lib/jvm/temurin-11-jdk-amd64
  export PATH=$PATH:$JAVA_HOME/bin
  debug "hadoop3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Environment variables already defined"
}

configfilessetup(){
  debug "hadoop3.configfilessetup DEBUG [`date +"%Y-%m-%d %T"`] Copying Hadoop 3 configuration files"
  sed -i '/^# export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/temurin-11-jdk-amd64\nexport HADOOP_HOME=/opt/hadoop3\n:' \
         $HADOOP_HOME/etc/hadoop/hadoop-env.sh
  sed -i '/^# export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
  cp $SCRIPT_HOME/core-site.xml.template $HADOOP_HOME/etc/hadoop/core-site.xml.template
  cp $SCRIPT_HOME/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
  cp $SCRIPT_HOME/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
  cp $SCRIPT_HOME/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
  chown osbdet:osbdet $HADOOP_HOME/etc/hadoop/core-site.xml.template $HADOOP_HOME/etc/hadoop/hdfs-site.xml \
                      $HADOOP_HOME/etc/hadoop/mapred-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
  debug "hadoop3.configfilessetup DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 configuration files copied"
}

sshsetup(){
  debug "hadoop3.sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Passwordless SSH access setup"
  echo -e 'y\n' | ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key > /dev/null
  echo -e 'y\n' | ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key > /dev/null
  su - osbdet -c 'echo -e "y\n" | ssh-keygen -q -N "" -t rsa -f /home/osbdet/.ssh/id_rsa'
  su - osbdet -c 'cp /home/osbdet/.ssh/id_rsa.pub /home/osbdet/.ssh/authorized_keys'
  cp $SCRIPT_HOME/ssh_config /home/osbdet/.ssh/config
  chmod 600 /home/osbdet/.ssh/config
  chown osbdet:osbdet /home/osbdet/.ssh/config
  debug "hadoop3.sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Passwordless SSH access setup done"
}
remove_sshsetup(){
  debug "hadoop3.remove_sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Removing password-less SSH access setup"
  rm /etc/ssh/ssh_host_dsa_key*
  rm /etc/ssh/ssh_host_rsa_key*
  rm -rf /home/osbdet/.ssh
  debug "hadoop3.remove_sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Password-less SSH access setup removed"
}

hdfsinit(){
  debug "hadoop3.hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] HDFS initialization"
  mkdir -p /data/hdfs/namenode
  mkdir -p /data/hdfs/datanode
  chown osbdet:osbdet -R /data
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs namenode -format"
  sed s/HOSTNAME/localhost/ $HADOOP_HOME/etc/hadoop/core-site.xml.template > $HADOOP_HOME/etc/hadoop/core-site.xml
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/start-dfs.sh"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 755 /"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/osbdet"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /user"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 755 /user"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 777 /tmp"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /tmp"
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/stop-dfs.sh"
  debug "hadoop3.hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] HDFS initialization done"
}
remove_hdfsinit(){
  debug "hadoop3.remove_hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] Removing HDFS initialization (data folder)"
  rm -rf /data
  debug "hadoop3.remove_hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] HDFS initialization removed"
}

serviceinstall(){
  debug "hadoop3.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation"
  cp $SCRIPT_PATH/hadoop3.service /lib/systemd/system/hadoop3.service
  chmod 644 /lib/systemd/system/hadoop3.service
  systemctl daemon-reload
  debug "hadoop3.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done"
}
remove_serviceinstall(){
  debug "hadoop3.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation"
  systemctl stop hadoop3.service
  rm /lib/systemd/system/hadoop3.service 
  systemctl daemon-reload
  debug "hadoop3.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done"
}

userprofile(){
  debug "hadoop3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Setting up user profile to run Hadoop 3"
  echo >> /home/osbdet/.profile
  echo '# set HADOOP_HOME and add its bin folder to the PATH' >> /home/osbdet/.profile
  echo 'export HADOOP_HOME=/opt/hadoop3' >> /home/osbdet/.profile
  echo 'PATH="$PATH:$HADOOP_HOME/bin"' >> /home/osbdet/.profile
  debug "hadoop3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to run Hadoop 3 setup"
}
remove_userprofile(){
  debug "hadoop3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Remove user profile settings to run Hadoop 3"
  # remove the break line before the user profile setup for Hadoop
  #   - https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern
  #   - https://unix.stackexchange.com/questions/29906/delete-range-of-lines-above-pattern-with-sed-or-awk
  tac /home/osbdet/.profile > /home/osbdet/.eliforp
  sed -i '/^# set HADOOP.*/{n;d}' /home/osbdet/.eliforp

  rm /home/osbdet/.profile
  tac /home/osbdet/.eliforp > /home/osbdet/.profile
  chown osbdet:osbdet /home/osbdet/.profile

  # remove user profile setup for Hadoop
  sed -i '/^# set HADOOP.*/,+3d' /home/osbdet/.profile
  rm -f /home/osbdet/.eliforp
  debug "hadoop3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile settings to run Hadoop 3 removed"
}

# Primary functions
#
module_install(){
  debug "hadoop3.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Get Hadoop3 and extract it
  #   2. Set up environment variables for the rest of the installation process
  #   3. Copy Hadoop 3 configuration files
  #   4. Password-less ssh connections setup
  #   5. HDFS initialization
  #   6. Hadoop 3 service installation (start and stop)
  #   7. Update of osdbet user profile to have access to Hadoop 3 binaries
  printf "  Installing module 'hadoop3' ... "
  getandextract >> $OSBDET_LOGFILE 2>&1
  setenvvars >> $OSBDET_LOGFILE 2>&1
  configfilessetup >> $OSBDET_LOGFILE 2>&1
  sshsetup >> $OSBDET_LOGFILE 2>&1
  hdfsinit >> $OSBDET_LOGFILE 2>&1
  serviceinstall >> $OSBDET_LOGFILE 2>&1
  userprofile >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "hadoop3.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/hadoop3" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "hadoop3.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Remove references to Hadoop 3 binaries from osbdet's profile
  #   2. Remove the Hadoop 3 service
  #   3. Remove HDFS initialization (data folder)
  #   4. Remove password-less ssh access setup
  #   5. Remove Hadoop 3 binaries
  #
  printf "  Uninstalling module 'hadoop3' ... "
  remove_userprofile >> $OSBDET_LOGFILE 2>&1
  remove_serviceinstall >> $OSBDET_LOGFILE 2>&1
  remove_hdfsinit >> $OSBDET_LOGFILE 2>&1
  remove_sshsetup >> $OSBDET_LOGFILE 2>&1
  binaries_removal >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "hadoop3.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'hadoop3\' module
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
  debug "hadoop3 DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the hadoop3 module" >> $OSBDET_LOGFILE
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
  debug "hadoop3 DEBUG [`date +"%Y-%m-%d %T"`] Activity with the hadoop3 module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
