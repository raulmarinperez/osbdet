#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic
OTELCOLCONTRIB_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.116.1/otelcol-contrib_0.116.1_linux_amd64.deb"
OTELCOLCONTRIB_LOCAL="/tmp/otelcol-contrib_0.116.1_linux_amd64.deb"

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

miscinstall(){
  debug "foundation.miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous software installation"
  apt update
  apt install -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common \
                 tmux python3-pip emacs unzip ca-certificates-java default-jdk
  debug "foundation.miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous software installation done"
}
remove_miscinstall(){
  debug "foundation.remove_miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous software uninstallation"
  apt remove -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common \
                tmux python3-pip emacs unzip ca-certificates-java default-jdk --purge
  apt autoremove -y
  debug "foundation.remove_miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous software uninstallation done" 
}

miscsetup() {
  debug "foundation.miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous setup"
  # Adapting /etc/hosts
  sed -i "s/^127.0.0.1\tlocalhost/127.0.0.1\tlocalhost\tosbdet/" /etc/hosts
  sed -i "s/^127.0.1.1\tosbdet/#127.0.1.1\tosbdet/" /etc/hosts
  # Adding some tools to the osbdet user
  su osbdet -c "mkdir -p /home/osbdet/bin"
  cp $SCRIPT_HOME/osbdet-update.sh /home/osbdet/bin
  cp $SCRIPT_HOME/osbdet-recipes.sh /home/osbdet/bin
  cp $SCRIPT_HOME/osbdet-cook.sh /home/osbdet/bin
  chown -R osbdet:osbdet /home/osbdet/bin
  # Removing the need of typing a password when sudoing a command
  echo "osbdet ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/osbdet
  debug "foundation.miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous setup done"
}
remove_miscsetup() {
  debug "foundation.remove_miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous setup removal"
  sed -i "s/^127.0.0.1\tlocalhost\tosbdet/127.0.0.1\tlocalhost/" /etc/hosts
  sed -i "s/^#127.0.1.1\tosbdet/127.0.1.1\tosbdet/" /etc/hosts
  # Remove tools from the osbdet user
  su osbdet -c "rm -rf /home/osbdet/bin"
  # Enabling the need of typing a password when sudoing a command
  rm -f /etc/sudoers.d/osbdet
  debug "foundation.remove_miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous setup removal done"
}

add_adoptiumopenjdkrepo(){
  debug "foundation.add_adoptiumopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] Adding AdoptiumOpenJDK repo"
  wget -O - https://packages.adoptium.net/artifactory/api/security/keypair/default-gpg-key/public | tee /etc/apt/keyrings/adoptium.asc
  echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
  apt update
  debug "foundation.add_adoptiumopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] AdoptiumOpenJDK repo added"
}
remove_adoptiumopenjdkrepo(){
  debug "foundation.remove_adoptiumopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] Removing AdoptiumOpenJDK repo"
  rm /etc/apt/keyrings/adoptium.asc
  rm /etc/apt/sources.list.d/adoptium.list
  apt update
  debug "foundation.remove_adoptiumopen_jdkrepo DEBUG [`date +"%Y-%m-%d %T"`] AdoptiumOpenJDK repo removed"
}

install_jdk11_21(){
  debug "foundation.install_jdk11_21 DEBUG [`date +"%Y-%m-%d %T"`] Installing JDK 11 and 21"
  # JDK 11 needed by Hadoop, JDK 21 needed by NiFi
  apt install -y temurin-11-jdk temurin-21-jdk
  # Removes platform dependency while using JDK 21 CACERTS (NiFi's Binance Lab)
  sudo ln -s /usr/lib/jvm/temurin-21-jdk-amd64/lib/security/cacerts /opt/jdk-21-cacerts
  debug "foundation.install_jdk11_21 DEBUG [`date +"%Y-%m-%d %T"`] JDK 11 and 21 installation done"
}
remove_jdk11_21(){
  debug "foundation.remove_jdk11_21 DEBUG [`date +"%Y-%m-%d %T"`] Removing JDK 11 and 21"
  rm /opt/jdk-21-cacerts
  apt remove -y temurin-11-jdk temurin-21-jdk
  debug "foundation.remove_jdk11_21 DEBUG [`date +"%Y-%m-%d %T"`] JDK 11 and 21 removed"
}

install_docker(){
  debug "foundation.install_docker DEBUG [`date +"%Y-%m-%d %T"`] Installing Docker"
  apt-get remove -y docker docker-engine docker.io containerd runc
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  usermod -aG docker osbdet
  debug "foundation.install_docker DEBUG [`date +"%Y-%m-%d %T"`] Docker installed"
}
remove_docker(){
  debug "foundation.remove_docker DEBUG [`date +"%Y-%m-%d %T"`] Removing Docker"
  gpasswd -d osbdet docker
  apt-get remove -y docker-ce docker-ce-cli containerd.io --purge
  rm /etc/apt/sources.list.d/docker.list
  rm /usr/share/keyrings/docker-archive-keyring.gpg
  apt-get update
  debug "foundation.remove_docker DEBUG [`date +"%Y-%m-%d %T"`] Docker removed"
}

install_cloudproviders_clis(){
  debug "foundation.install_cloudproviders_clis DEBUG [`date +"%Y-%m-%d %T"`] Installing cloud providers clis"
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
  debug "foundation.install_cloudproviders_clis DEBUG [`date +"%Y-%m-%d %T"`] Cloud providers clis installation done"
}
remove_cloudproviders_clis(){
  debug "foundation.remove_cloudproviders_cli DEBUG [`date +"%Y-%m-%d %T"`] Removing cloud providers clis"
  rm /usr/local/bin/aws
  rm /usr/local/bin/aws_completer
  rm -rf /usr/local/aws-cli
  debug "foundation.remove_cloudproviders_cli DEBUG [`date +"%Y-%m-%d %T"`] Cloud providers clis removed"
}

install_otel_collector(){
  debug "foundation.install_otel_collector DEBUG [`date +"%Y-%m-%d %T"`] Installing OpenTelemetry collector"
  # Download from the official repo
  wget -O $OTELCOLCONTRIB_LOCAL $OTELCOLCONTRIB_URL
  dpkg -i $OTELCOLCONTRIB_LOCAL
  rm $OTELCOLCONTRIB_LOCAL
  # Disable service autostart
  systemctl stop otelcol-contrib
  systemctl disable otelcol-contrib
  debug "foundation.install_otel_collector DEBUG [`date +"%Y-%m-%d %T"`] OpenTelemetry collector installation done"
}
remove_otel_collector(){
  debug "foundation.remove_otel_collector DEBUG [`date +"%Y-%m-%d %T"`] Removing OpenTelemetry collector"
  dpkg --purge otelcol-contrib
  debug "foundation.remove_otel_collector DEBUG [`date +"%Y-%m-%d %T"`] OpenTelemetry collector removed"
}

# Primary functions
#
module_install(){
  debug "foundation.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Installation miscellaneous software
  #   2. Miscellaneous setup
  #   3. Adding AdoptiumOpenJDK repo
  #   4. Installing JDK 11 and 21
  #   5. Docker installation
  #   6. Install cloud providers CLIs
  #   7. Install the OpenTelemetry collector
  printf "  Installing module 'foundation' ... "
  miscinstall >> $OSBDET_LOGFILE 2>&1
  miscsetup >> $OSBDET_LOGFILE 2>&1
  add_adoptiumopenjdkrepo >> $OSBDET_LOGFILE 2>&1
  install_jdk11_21 >> $OSBDET_LOGFILE 2>&1
  install_docker >> $OSBDET_LOGFILE 2>&1
  install_cloudproviders_clis >> $OSBDET_LOGFILE 2>&1
  install_otel_collector >> $OSBDET_LOGFILE 2>&1
  mkdir -p /home/osbdet/.osbdet/ && touch /home/osbdet/.osbdet/foundation >> $OSBDET_LOGFILE 2>&1
  printf "[Done]\n"
  debug "foundation.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -f "/home/osbdet/.osbdet/foundation" ]
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
  #   1. Remove the OpenTelemetry collector
  #   2. Remove cloud providers CLIs
  #   3. Remove Docker
  #   4. Uninstall JDK 11 and 21
  #   5. Remove AdoptiumOpenJDK repo
  #   6. Miscellaneous setup
  #   7. Uninstallation miscellaneous software
  #   
  printf "  Uninstalling module 'foundation' ... "
  remove_otel_collector >> $OSBDET_LOGFILE 2>&1
  remove_cloudproviders_clis >> $OSBDET_LOGFILE 2>&1
  remove_docker >> $OSBDET_LOGFILE 2>&1
  remove_jdk11_21 >> $OSBDET_LOGFILE 2>&1
  remove_adoptiumopenjdkrepo >> $OSBDET_LOGFILE 2>&1
  remove_miscsetup >> $OSBDET_LOGFILE 2>&1
  remove_miscinstall >> $OSBDET_LOGFILE 2>&1
  rm /home/osbdet/.osbdet/foundation >> $OSBDET_LOGFILE 2>&1
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
