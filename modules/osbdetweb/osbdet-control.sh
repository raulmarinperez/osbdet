#!/bin/bash

# Global variables definition
#
OSBDET_VER=26r1
OSBDET_HOME=/home/osbdet
NIFI_HOME=/opt/nifi

# Auxiliary functions
#

# status_hadoop
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_hadoop() {
  # sudo needed just in case the control script is run as root
  sudo -u osbdet bash -c ". ~/.profile && hdfs dfs -ls /"  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_hadoop
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_hadoop() {
  status=$(status_hadoop)
  if [ "$status" == "down" ]
  then
    sudo service hadoop3 start > /dev/null 2>&1
    return 0
  fi

  echo "Hadoop is already running"
  exit 1
}
# stop_hadoop
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_hadoop() {
  status=$(status_hadoop)
  if [ "$status" == "up" ]
  then
    sudo service hadoop3 stop > /dev/null 2>&1
    return 0
  fi

  echo "Hadoop is not running"
  exit 1
}

# status_nifi
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_nifi() {
  curl -sSf http://localhost:9090/nifi > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_nifi
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_nifi() {
  status=$(status_nifi)
  if [ "$status" == "down" ]
  then
    $NIFI_HOME/bin/nifi.sh start > /dev/null 2>&1
    return 0
  fi

  echo "NiFi is already running"
  exit 1
}
# stop_nifi
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_nifi() {
  status=$(status_nifi)
  if [ "$status" == "up" ]
  then
    $NIFI_HOME/bin/nifi.sh stop > /dev/null 2>&1
    return 0
  fi

  echo "NiFi is not running"
  exit 1
}

# status_kafka
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_kafka() {
  kafka_running=`ss -nlt | grep 9092 | wc -l`
  if [ $kafka_running -eq 1 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_kafka
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_kafka() {
  status=$(status_kafka)
  if [ "$status" == "down" ]
  then
    sudo service kafka start > /dev/null 2>&1
    return 0
  fi

  echo "Kafka is already running"
  exit 1
}
# stop_kafka
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_kafka() {
  status=$(status_kafka)
  if [ "$status" == "up" ]
  then
    sudo service kafka stop > /dev/null 2>&1
    return 0
  fi

  echo "Kafka is not running"
  exit 1
}

# status_truckssim
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_truckssim() {
  simulator_processes=`pgrep -f SimulationRunnerApp | wc -l`
  if [ $simulator_processes -eq 1 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_truckssim
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_truckssim() {
  status=$(status_truckssim)
  if [ "$status" == "down" ]
  then
    sudo service truckfleet-sim start > /dev/null 2>&1
    return 0
  fi

  echo "The truck fleet simulator is already running"
  exit 1
}
# stop_truckssim
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_truckssim() {
  status=$(status_truckssim)
  if [ "$status" == "up" ]
  then
    sudo service truckfleet-sim stop > /dev/null 2>&1
    return 0
  fi

  echo "The truck fleet simulator is not running"
  exit 1
}

# status_minio
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_minio() {
  curl -sSf http://localhost:9001/login > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_minio
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_minio() {
  status=$(status_minio)
  if [ "$status" == "down" ]
  then
    sudo service minio start > /dev/null 2>&1
    return 0
  fi

  echo "MinIO is already running"
  exit 1
}
# stop_minio
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_minio() {
  status=$(status_minio)
  if [ "$status" == "up" ]
  then
    sudo service minio stop > /dev/null 2>&1
    return 0
  fi

  echo "MinIO is not running"
  exit 1
}

# status_mariadb
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_mariadb() {
  mariadb -u osbdet --password='osbdet123$' -e "select 'am i alive?';"  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_mariadb
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_mariadb() {
  status=$(status_mariadb)
  if [ "$status" == "down" ]
  then
    sudo service mariadb start > /dev/null 2>&1
    return 0
  fi

  echo "MariaDB is already running"
  exit 1
}
# stop_mariadb
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_mariadb() {
  status=$(status_mariadb)
  if [ "$status" == "up" ]
  then
    sudo service mariadb stop > /dev/null 2>&1
    return 0
  fi

  echo "MariaDB is not running"
  exit 1
}

# status_mongodb
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_mongodb() {
  mongosh --eval "db.runCommand({ serverStatus: 1}).metrics"  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_mongodb
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_mongodb() {
  status=$(status_mongodb)
  if [ "$status" == "down" ]
  then
    sudo service mongod start > /dev/null 2>&1
    return 0
  fi

  echo "MongoDB is already running"
  exit 1
}
# stop_mongodb
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_mongodb() {
  status=$(status_mongodb)
  if [ "$status" == "up" ]
  then
    sudo service mongod stop > /dev/null 2>&1
    return 0
  fi

  echo "MongoDB is not running"
  exit 1
}

# status_kestra
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_kestra() {
  curl -sSf http://localhost:8080/ui/welcome  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_kestra
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_kestra() {
  status=$(status_kestra)
  if [ "$status" == "down" ]
  then
    sudo service kestra start > /dev/null 2>&1
    return 0
  fi

  echo "Kestra is already running"
  exit 1
}
# stop_kestra
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_kestra() {
  status=$(status_kestra)
  if [ "$status" == "up" ]
  then
    sudo service kestra stop > /dev/null 2>&1
    return 0
  fi

  echo "Kestra is not running"
  exit 1
}

# status_superset
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_superset() {
  curl -sSf http://localhost:8880/login/  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_superset
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_superset() {
  status=$(status_superset)
  if [ "$status" == "down" ]
  then
    sudo service superset start > /dev/null 2>&1
    return 0
  fi

  echo "Superset is already running"
  exit 1
}
# stop_superset
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_superset() {
  status=$(status_superset)
  if [ "$status" == "up" ]
  then
    sudo service superset stop > /dev/null 2>&1
    return 0
  fi

  echo "Superset is not running"
  exit 1
}

# status_grafana
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_grafana() {
  curl -sSf http://localhost:3000/login/  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_grafana
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_grafana() {
  status=$(status_grafana)
  if [ "$status" == "down" ]
  then
    sudo service grafana-server start > /dev/null 2>&1
    return 0
  fi

  echo "Grafana is already running"
  exit 1
}
# stop_grafana
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_grafana() {
  status=$(status_grafana)
  if [ "$status" == "up" ]
  then
    sudo service grafana-server stop > /dev/null 2>&1
    return 0
  fi

  echo "Grafana is not running"
  exit 1
}

# status_clickhouse
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_clickhouse() {
  curl -sSf http://localhost:3000/login/  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_clickhouse
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_clickhouse() {
  status=$(status_clickhouse)
  if [ "$status" == "down" ]
  then
    sudo service clickhouse-server start > /dev/null 2>&1
    return 0
  fi

  echo "Clickhouse is already running"
  exit 1
}
# stop_clickhouse
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_clickhouse() {
  status=$(status_clickhouse)
  if [ "$status" == "up" ]
  then
    sudo service clickhouse-server stop > /dev/null 2>&1
    return 0
  fi

  echo "Clickhouse is not running"
  exit 1
}

# status_openmetadata
#   desc: Identify if the module is up and running
#   params:
#     none
#   return (status code/stdout):
#     0/up message - module is up and running
#     1/down message - module is not running
status_openmetadata() {
  curl -sSf http://localhost:8585/  > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "up"
    return 0
  fi

  echo "down"
  return 1
}
# start_openmetadata
#   desc: Start the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_openmetadata() {
  status=$(status_openmetadata)
  if [ "$status" == "down" ]
  then
    sudo service openmetadata start > /dev/null 2>&1
    return 0
  fi

  echo "OpenMetadata is already running"
  exit 1
}
# stop_openmetadata
#   desc: Stop the specified module if it wasn't running already
#   params:
#     none
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
stop_openmetadata() {
  status=$(status_openmetadata)
  if [ "$status" == "up" ]
  then
    sudo service openmetadata stop > /dev/null 2>&1
    return 0
  fi

  echo "OpenMetadata is not running"
  exit 1
}

# Main functions
#

# module_status
#   desc: Display if the specified module is running or is stopped
#   params:
#     $1 - module to check
#   return (status code/stdout):
#     0/ok message - module specified correctly
#     1/ko message - module doesn't exists
module_status() {
    if [ "$1" == "hadoop3" ]
    then
      status_hadoop
    elif [ "$1" == "nifi" ]
    then
      status_nifi
    elif [ "$1" == "kafka3" ]
    then
      status_kafka
    elif [ "$1" == "truckssim" ]
    then
      status_truckssim
    elif [ "$1" == "minio" ]
    then
      status_minio
    elif [ "$1" == "mariadb" ]
    then
      status_mariadb
    elif [ "$1" == "mongodb" ]
    then
      status_mongodb
    elif [ "$1" == "kestra" ]
    then
      status_kestra
    elif [ "$1" == "superset" ]
    then
      status_superset
    elif [ "$1" == "grafana" ]
    then
      status_grafana
    elif [ "$1" == "openmetadata" ]
    then
      status_openmetadata
    fi

    return 0
}

# start_module
#   desc: Start the specified module if it wasn't running already
#   params:
#     $1 - module to start
#   return (status code/stdout):
#     0/ok message - module started correctly
#     1/ko message - module doesn't exists or it was already running
start_module() {
    if [ "$1" == "hadoop3" ]
    then
      start_hadoop
    elif [ "$1" == "nifi" ]
    then
      start_nifi
    elif [ "$1" == "kafka4" ]
    then
      start_kafka
    elif [ "$1" == "truckssim" ]
    then
      start_truckssim
    elif [ "$1" == "minio" ]
    then
      start_minio
    elif [ "$1" == "mariadb" ]
    then
      start_mariadb
    elif [ "$1" == "mongodb" ]
    then
      start_mongodb
    elif [ "$1" == "kestra" ]
    then
      start_kestra
    elif [ "$1" == "superset" ]
    then
      start_superset
    elif [ "$1" == "grafana" ]
    then
      start_grafana
    elif [ "$1" == "clickhouse" ]
    then
      start_clickhouse
    elif [ "$1" == "openmetadata" ]
    then
      start_openmetadata
    fi

    return 0
}

# stop_module
#   desc: Stop the specified module if it wasn't stopped already
#   params:
#     $1 - module to stop
#   return (status code/stdout):
#     0/ok message - module stopped correctly
#     1/ko message - module doesn't exists or it was already stopped
stop_module() {
    if [ "$1" == "hadoop3" ]
    then
      stop_hadoop
    elif [ "$1" == "nifi" ]
    then
      stop_nifi
    elif [ "$1" == "kafka4" ]
    then
      stop_kafka
    elif [ "$1" == "truckssim" ]
    then
      stop_truckssim
    elif [ "$1" == "minio" ]
    then
      stop_minio
    elif [ "$1" == "mariadb" ]
    then
      stop_mariadb
    elif [ "$1" == "mongodb" ]
    then
      stop_mongodb
    elif [ "$1" == "kestra" ]
    then
      stop_kestra
    elif [ "$1" == "superset" ]
    then
      stop_superset
    elif [ "$1" == "grafana" ]
    then
      stop_grafana
    elif [ "$1" == "clickhouse" ]
    then
      stop_clickhouse
    elif [ "$1" == "openmetadata" ]
    then
      stop_openmetadata
    fi

    return 0
}

# usage
#   desc: display script's syntax
#   params: None
#   return (status code/stdout): None
usage() {
  echo "Usage: osbdet_control.sh [command] [module name]"
  echo 
  echo "Available options for 'commands' and 'modules names' in osbdet_control:"
  echo "  ## commands ##"
  echo "  status              display the current status of the selected module"
  echo "  start               start the specified module if it's not running (no effect otherwise)"
  echo "  stop                stop the specified module if it's running (no effect otherwise)"
  echo
  echo "  ## modules names ##"
  echo "  hadoop3             Storage and processing at scale"
  echo "  nifi                Data ingestion"
  echo "  kafka4              Real-time storage and processing at scale"
  echo "  truckssim           Real-time data/events generator"
  echo "  minio               S3 compatible Object storage"
  echo "  mariadb             Open Source Relational Database Management System"
  echo "  mongodb             Open Source NoSQL Database"
  echo "  kestra              Unified orchestration platform"
  echo "  superset            Open Source BI visualization tool"
  echo "  grafana             Open Source operational visualization tool"
  echo "  clickhouse          Open Source Columnar Database"
  echo "  openmetadata        Open and unified metadata platform for data discovery, observability and governance"
}

# eval_args
#   desc: evaluate the arguments provided to the script
#   params:
#     $1 - command to execute
#   return (status code/stdout):
#     0/ok message - the option is executed properly
#     1/ko message - display usage due to a syntax error
eval_args(){
  if [ $# -eq 2 ]
  then
    if [ "$1" == "status" ]
    then
      module_status $2
    elif [ "$1" == "start" ]
    then
      start_module $2
    elif [ "$1" == "stop" ]
    then
      stop_module $2
    else
      echo "Error: bad command specified"
      usage
      exit 1
    fi
  else
    echo "Error: bad number of arguments"
    usage
    exit 1
  fi
}

# OSBDET control's entry point
#

if ! [ -z "$*" ]
then
  eval_args $*
  exit 0
fi

usage
exit 1
