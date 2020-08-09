#!/bin/sh
OSBDET_VER=vf20r1
OSBDET_USERPASS=osbdet123$

SPARK_HOME=/opt/spark-3.0.0-preview2-bin-hadoop3.2/

pause() {
  read -p "$*"
}

install_foundation(){
  units/foundation/script-deb10.sh install
}

install_jupyter(){
  units/jupyter/script-deb10.sh install
}

install_spark3(){
  units/spark3/script-deb10.sh install
}

install_hadoop3(){
  units/hadoop3/script-deb10.sh install
}

install_hive3(){
  units/hive3/script-deb10.sh install
}
# Main function
#
clear
echo Welcome to the OSBDET installer...
echo You\'re about to deploy OSBDET $OSBDET_VER in this machine.
pause Press any key to start

# 1. Setting up the foundations
install_foundation

# 2. Deploying Jupyter
install_jupyter

# 3. Deploying Spark 3
install_spark3

# 4. Deploying Hadoop 3
install_hadoop3

# 5. Deploying Hive 3
install_hive3
