#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
HADOOP_BINARY_URL=https://ftp.cixug.es/apache/hadoop/common/hadoop-3.3.0/hadoop-3.3.0-aarch64.tar.gz
HADOOP_TGZ_FILE=hadoop-3.3.0-aarch64.tar.gz
HADOOP_DEFAULT_DIR=hadoop-3.3.0

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
  debug "hadoop3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Hadoop 3" >> $OSBDET_LOGFILE
  wget $HADOOP_BINARY_URL -O /opt/$HADOOP_TGZ_FILE >> $OSBDET_LOGFILE 2>&1
  if [[ $? -ne 0 ]]; then
    echo "[Error]"
    exit 1
  fi
      
  tar zxf /opt/$HADOOP_TGZ_FILE -C /opt >> $OSBDET_LOGFILE 2>&1
  rm /opt/$HADOOP_TGZ_FILE 
  mv /opt/$HADOOP_DEFAULT_DIR /opt/hadoop3
  chown -R osbdet:osbdet /opt/hadoop3
  chmod +x /opt/hadoop3/etc/hadoop/*-env.sh
  debug "hadoop3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 downloading and extracting process done" >> $OSBDET_LOGFILE
}
binaries_removal(){
  debug "hadoop3.binaries_removal DEBUG [`date +"%Y-%m-%d %T"`] Removing Hadoop 3 files" >> $OSBDET_LOGFILE
  rm -rf /opt/hadoop3
  debug "hadoop3.binaries_removal DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 files removed" >> $OSBDET_LOGFILE
}

setenvvars(){
  debug "hadoop3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Setting the environment variables for the installation process" >> $OSBDET_LOGFILE
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
  export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64/
  export PATH=$PATH:$JAVA_HOME/bin
  debug "hadoop3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Environment variables already defined" >> $OSBDET_LOGFILE
}

configfilessetup(){
  debug "hadoop3.configfilessetup DEBUG [`date +"%Y-%m-%d %T"`] Copying Hadoop 3 configuration files" >> $OSBDET_LOGFILE
  sed -i '/^# export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64/\nexport HADOOP_HOME=/opt/hadoop3\n:' \
         $HADOOP_HOME/etc/hadoop/hadoop-env.sh
  sed -i '/^# export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
  cp $SCRIPT_HOME/core-site.xml.template $HADOOP_HOME/etc/hadoop/core-site.xml.template
  cp $SCRIPT_HOME/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
  cp $SCRIPT_HOME/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
  cp $SCRIPT_HOME/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
  chown osbdet:osbdet $HADOOP_HOME/etc/hadoop/core-site.xml.template $HADOOP_HOME/etc/hadoop/hdfs-site.xml \
                      $HADOOP_HOME/etc/hadoop/mapred-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
  debug "hadoop3.configfilessetup DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 configuration files copied" >> $OSBDET_LOGFILE
}

sshsetup(){
  debug "hadoop3.sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Passwordless SSH access setup" >> $OSBDET_LOGFILE
  echo -e 'y\n' | ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key > /dev/null
  echo -e 'y\n' | ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key > /dev/null
  su - osbdet -c 'echo -e "y\n" | ssh-keygen -q -N "" -t rsa -f /home/osbdet/.ssh/id_rsa' >> $OSBDET_LOGFILE
  su - osbdet -c 'cp /home/osbdet/.ssh/id_rsa.pub /home/osbdet/.ssh/authorized_keys' >> $OSBDET_LOGFILE
  cp $SCRIPT_HOME/ssh_config /home/osbdet/.ssh/config
  chmod 600 /home/osbdet/.ssh/config
  chown osbdet:osbdet /home/osbdet/.ssh/config
  debug "hadoop3.sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Passwordless SSH access setup done" >> $OSBDET_LOGFILE
}
remove_sshsetup(){
  debug "hadoop3.remove_sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Removing password-less SSH access setup" >> $OSBDET_LOGFILE
  rm /etc/ssh/ssh_host_dsa_key*
  rm /etc/ssh/ssh_host_rsa_key*
  rm -rf /home/osbdet/.ssh
  debug "hadoop3.remove_sshsetup DEBUG [`date +"%Y-%m-%d %T"`] Password-less SSH access setup removed" >> $OSBDET_LOGFILE
}

hdfsinit(){
  debug "hadoop3.hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] HDFS initialization" >> $OSBDET_LOGFILE
  mkdir -p /data/hdfs/namenode
  mkdir -p /data/hdfs/datanode
  chown osbdet:osbdet -R /data
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs namenode -format" >> $OSBDET_LOGFILE 2>&1
  sed s/HOSTNAME/localhost/ $HADOOP_HOME/etc/hadoop/core-site.xml.template > $HADOOP_HOME/etc/hadoop/core-site.xml
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/start-dfs.sh" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 755 /" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/osbdet" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /user" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 755 /user" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 777 /tmp" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /tmp" >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/stop-dfs.sh" >> $OSBDET_LOGFILE 2>&1
  debug "hadoop3.hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] HDFS initialization done" >> $OSBDET_LOGFILE
}
remove_hdfsinit(){
  debug "hadoop3.remove_hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] Removing HDFS initialization (data folder)" >> $OSBDET_LOGFILE
  rm -rf /data
  debug "hadoop3.remove_hdfsinit DEBUG [`date +"%Y-%m-%d %T"`] HDFS initialization removed" >> $OSBDET_LOGFILE
}

scriptscopy(){
  debug "hadoop3.scriptscopy DEBUG [`date +"%Y-%m-%d %T"`] Copying scripts to operate the pseudo-cluster" >> $OSBDET_LOGFILE
  cp $SCRIPT_PATH/hadoop-start.sh /home/osbdet/bin
  cp $SCRIPT_PATH/hadoop-stop.sh /home/osbdet/bin
  chown -R osbdet:osbdet /home/osbdet/bin
  debug "hadoop3.scriptscopy DEBUG [`date +"%Y-%m-%d %T"`] Scripts to operate the pseudo-cluster copied" >> $OSBDET_LOGFILE
}
remove_scriptscopy(){
  debug "hadoop3.remove_scriptscopy DEBUG [`date +"%Y-%m-%d %T"`] Removing scripts to operate the pseudo-cluster" >> $OSBDET_LOGFILE
  rm /home/osbdet/bin/hadoop-start.sh
  rm /home/osbdet/bin/hadoop-stop.sh
  # rmdir only removes empty folders (hide stderr output)
  rmdir /home/osbdet/bin 2> /dev/null
  debug "hadoop3.remove_scriptscopy DEBUG [`date +"%Y-%m-%d %T"`] Scripts to operate the pseudo-cluster removed" >> $OSBDET_LOGFILE
}

userprofile(){
  debug "hadoop3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Setting up user profile to run Hadoop 3" >> $OSBDET_LOGFILE
  echo >> /home/osbdet/.profile
  echo '# set HADOOP_HOME and add its bin folder to the PATH' >> /home/osbdet/.profile
  echo 'export HADOOP_HOME=/opt/hadoop3' >> /home/osbdet/.profile
  echo 'PATH="$PATH:$HADOOP_HOME/bin"' >> /home/osbdet/.profile
  debug "hadoop3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to run Hadoop 3 setup" >> $OSBDET_LOGFILE
}
remove_userprofile(){
  debug "hadoop3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Remove user profile settings to run Hadoop 3" >> $OSBDET_LOGFILE
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
  debug "hadoop3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile settings to run Hadoop 3 removed" >> $OSBDET_LOGFILE
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
  #   6. Copy of scripts to operate Hadoop 3 (start and stop)
  #   7. Update of osdbet user profile to have access to Hadoop 3 binaries
  printf "  Installing module 'hadoop3' ... "
  getandextract
  setenvvars
  configfilessetup
  sshsetup
  hdfsinit
  scriptscopy
  userprofile
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
  #   2. Remove scripts to operate the Hadoop 3 pseudo-cluster
  #   3. Remove HDFS initialization (data folder)
  #   4. Remove password-less ssh access setup
  #   5. Remove Hadoop 3 binaries
  #
  printf "  Uninstalling module 'hadoop3' ... "
  remove_userprofile
  remove_scriptscopy
  remove_hdfsinit
  remove_sshsetup
  binaries_removal
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
