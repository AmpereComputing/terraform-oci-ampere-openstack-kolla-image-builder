#!/usr/bin/env bash

PROJECT_DIR='/opt/kolla-build'
LOGFILE=$PROJECT_DIR/build_kolla_containers.log
exec >> $LOGFILE 2>&1

kolla-build -b ${kolla_base_image} -t source --registry ${public_ip}:4000 --push
