#!/usr/bin/env bash

PROJECT_DIR='/opt/kolla-build'
LOGFILE=$PROJECT_DIR/build_kolla_containers.log
exec >> $LOGFILE 2>&1

kolla-build -b ubuntu -t source --registry ${public_ip}:5000 --push
