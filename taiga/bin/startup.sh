#!/bin/bash

if [ -f ~/.bashrc ]
  then
    source ~/.bashrc
  fi

if [ -f ~/.profile ]
  then
    source ~/.profile
  fi

WORKDIR=/home/taiga/taiga
cd "${WORKDIR}"

if [ ! -f ./conf/nginx.conf ]
  then
    ./bin/initialize.sh
  fi

service redis-server start
service rabbitmq-server start
service postgresql start
service circusd start
service nginx start
service --status-all
