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

create_osbdetuser(){
  debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] Starting osbdet user creation" >> $OSBDET_LOGFILE
  if [ ! -d "/home/osbdet" ]
  then
    useradd -m -s /bin/bash osbdet
    echo osbdet:osbdet123$ | chpasswd 2> /dev/null
    debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet user created" >> $OSBDET_LOGFILE
  else
    debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet already existed and wasn't created" >> $OSBDET_LOGFILE
  fi
  debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet user creation process done" >> $OSBDET_LOGFILE
}
remove_osbdetuser(){
  debug "foundation.remove_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] Starting osbdet user deletion" >> $OSBDET_LOGFILE
  deluser --remove-home osbdet >> $OSBDET_LOGFILE
  debug "foundation.remove_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet user deletion done" >> $OSBDET_LOGFILE
}

miscinstall(){
  debug "foundation.miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous software installation" >> $OSBDET_LOGFILE
  apt update >> $OSBDET_LOGFILE 2>&1
  apt install -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common \
                 tmux python3-pip sudo git emacs unzip nginx >> $OSBDET_LOGFILE 2>&1
  debug "foundation.miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous software installation done" >> $OSBDET_LOGFILE
}
remove_miscinstall(){
  debug "foundation.remove_miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous software uninstallation" >> $OSBDET_LOGFILE
  apt remove -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common \
                tmux python3-pip sudo git unzip nginx --purge >>$OSBDET_LOGFILE 2>&1
  apt autoremove -y >>$OSBDET_LOGFILE 2>&1
  debug "foundation.remove_miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous software uninstallation done" >> $OSBDET_LOGFILE
}

miscsetup() {
  debug "foundation.miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous setup" >> $OSBDET_LOGFILE
  usermod -aG sudo osbdet
  sed -i "s/^127.0.0.1\tlocalhost/127.0.0.1\tlocalhost\tosbdet/" /etc/hosts
  sed -i "s/^127.0.1.1\tosbdet/#127.0.1.1\tosbdet/" /etc/hosts
  su osbdet -c "mkdir -p /home/osbdet/bin" >> $OSBDET_LOGFILE 2>&1
  cp $SCRIPT_HOME/osbdet-update.sh /home/osbdet/bin
  cp $SCRIPT_HOME/osbdet-recipes.sh /home/osbdet/bin
  cp $SCRIPT_HOME/osbdet-cook.sh /home/osbdet/bin
  chown -R osbdet:osbdet /home/osbdet/bin
  debug "foundation.miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous setup done" >> $OSBDET_LOGFILE
}
remove_miscsetup() {
  debug "foundation.remove_miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous setup removal" >> $OSBDET_LOGFILE
  deluser osbdet sudo >> $OSBDET_LOGFILE
  sed -i "s/^127.0.0.1\tlocalhost\tosbdet/127.0.0.1\tlocalhost/" /etc/hosts
  sed -i "s/^#127.0.1.1\tosbdet/127.0.1.1\tosbdet/" /etc/hosts
  debug "foundation.remove_miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous setup removal done" >> $OSBDET_LOGFILE
}

add_adoptopenjdkrepo(){
  debug "foundation.add_adoptopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] Adding AdoptOpenJDK repo" >> $OSBDET_LOGFILE
  wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - >> $OSBDET_LOGFILE 2>&1
  add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ >> $OSBDET_LOGFILE 2>&1
  apt update >> $OSBDET_LOGFILE 2>&1
  debug "foundation.add_adoptopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] AdoptOpenJDK repo added" >> $OSBDET_LOGFILE
}
remove_adoptopenjdkrepo(){
  debug "foundation.remove_adoptopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] Removing AdoptOpenJDK repo" >> $OSBDET_LOGFILE
  apt-key del `apt-key list | $OSBDET_HOME/shared/givemekey.awk -v pattern=AdoptOpenJDK` >> $OSBDET_LOGFILE 2>&1
  add-apt-repository --yes -r https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ >> $OSBDET_LOGFILE 2>&1
  apt update >> $OSBDET_LOGFILE 2>&1
  debug "foundation.remove_adoptopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] AdoptOpenJDK repo removed" >> $OSBDET_LOGFILE
}

install_jdk8_11(){
  debug "foundation.install_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] Installing JDK 8 and 11" >> $OSBDET_LOGFILE
  apt install -y adoptopenjdk-8-hotspot adoptopenjdk-11-hotspot >> $OSBDET_LOGFILE 2>&1
  debug "foundation.install_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] JDK 8 and 11 installation done" >> $OSBDET_LOGFILE
}
remove_jdk8_11(){
  debug "foundation.remove_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] Removing JDK 8 and 11" >> $OSBDET_LOGFILE
  apt remove -y adoptopenjdk-8-hotspot adoptopenjdk-11-hotspot >> $OSBDET_LOGFILE 2>&1
  debug "foundation.remove_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] JDK 8 and 11 removed" >> $OSBDET_LOGFILE
}

install_docker(){
  debug "foundation.install_docker DEBUG [`date +"%Y-%m-%d %T"`] Installing Docker" >> $OSBDET_LOGFILE
  apt-get remove -y docker docker-engine docker.io containerd runc >> $OSBDET_LOGFILE 2>&1
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release >> $OSBDET_LOGFILE 2>&1
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >> $OSBDET_LOGFILE 2>&1
  echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list >> $OSBDET_LOGFILE 2>&1
  apt-get update >> $OSBDET_LOGFILE 2>&1
  apt-get install -y docker-ce docker-ce-cli containerd.io >> $OSBDET_LOGFILE 2>&1
  debug "foundation.install_docker DEBUG [`date +"%Y-%m-%d %T"`] Docker installed" >> $OSBDET_LOGFILE
}
remove_docker(){
  debug "foundation.remove_docker DEBUG [`date +"%Y-%m-%d %T"`] Removing Docker" >> $OSBDET_LOGFILE
  apt-get update >> $OSBDET_LOGFILE 2>&1
  apt-get remove -y docker-ce docker-ce-cli containerd.io --purge >> $OSBDET_LOGFILE 2>&1
  rm /etc/apt/sources.list.d/docker.list >> $OSBDET_LOGFILE 2>&1
  rm /usr/share/keyrings/docker-archive-keyring.gpg >> $OSBDET_LOGFILE 2>&1
  apt-get remove -y apt-transport-https ca-certificates curl gnupg lsb-release --purge >> $OSBDET_LOGFILE 2>&1
  debug "foundation.remove_docker DEBUG [`date +"%Y-%m-%d %T"`] Docker removed" >> $OSBDET_LOGFILE
}

install_cloudproviders_clis(){
  debug "foundation.install_cloudproviders_clis DEBUG [`date +"%Y-%m-%d %T"`] Installing cloud providers clis" >> $OSBDET_LOGFILE
  curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "/tmp/awscliv2.zip" >> $OSBDET_LOGFILE 2>&1
  unzip /tmp/awscliv2.zip -d /tmp >> $OSBDET_LOGFILE 2>&1
  /tmp/aws/install >> $OSBDET_LOGFILE 2>&1
  rm -rf /tmp/aws /tmp/awscliv2.zip >> $OSBDET_LOGFILE 2>&1
  debug "foundation.install_cloudproviders_clis DEBUG [`date +"%Y-%m-%d %T"`] Cloud providers clis installation done" >> $OSBDET_LOGFILE
}
remove_cloudproviders_clis(){
  debug "foundation.remove_cloudproviders_cli DEBUG [`date +"%Y-%m-%d %T"`] Removing cloud providers clis" >> $OSBDET_LOGFILE
  rm /usr/local/bin/aws >> $OSBDET_LOGFILE 2>&1
  rm /usr/local/bin/aws_completer >> $OSBDET_LOGFILE 2>&1
  rm -rf /usr/local/aws-cli >> $OSBDET_LOGFILE 2>&1
  debug "foundation.remove_cloudproviders_cli DEBUG [`date +"%Y-%m-%d %T"`] Cloud providers clis removed" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "foundation.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Creating the osbdet system user
  #   2. Installation miscellaneous software
  #   3. Miscellaneous setup
  #   4. Adding AdoptOpenJDK repo
  #   5. Installing JDK 8 and 11
  #   6. Docker installation
  #   7. Install cloud providers CLIs
  printf "  Installing module 'foundation' ... "
  create_osbdetuser
  miscinstall
  miscsetup
  add_adoptopenjdkrepo
  install_jdk8_11
  install_docker
  install_cloudproviders_clis
  printf "[Done]\n"
  debug "foundation.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/home/osbdet" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "foundation.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Remove cloud providers CLIs
  #   2. Remove Docker
  #   3. Uninstall JDK 8 and 11
  #   4. Remove AdoptOpenJDK repo
  #   5. Miscellaneous setup
  #   6. Uninstallation miscellaneous software
  #   7. Remove the osbdet system user
  #   
  printf "  Uninstalling module 'foundation' ... "
  remove_cloudproviders_clis
  remove_docker
  remove_jdk8_11
  remove_adoptopenjdkrepo
  remove_miscsetup
  remove_miscinstall
  remove_osbdetuser
  printf "[Done]\n"
  debug "foundation.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'foundation\' module
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
  debug "foundation DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the foundation module" >> $OSBDET_LOGFILE
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
  debug "foundation DEBUG [`date +"%Y-%m-%d %T"`] Activity with the foundation module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
