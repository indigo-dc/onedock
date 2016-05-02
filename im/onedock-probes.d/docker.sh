#!/bin/bash
#
# ONEDock - Docker support for ONE (as VMs)
# Copyright (C) GRyCAP - I3M - UPV 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DRIVER_PATH=$(dirname $0)
source ${DRIVER_PATH}/../../onedock.sh
setup_wn

echo HYPERVISOR=docker
TOTALCPU=$(cat /proc/cpuinfo  | grep processor | wc -l)
echo TOTALCPU=$(( $TOTALCPU * 100 ))
echo FREECPU=$(( $ $TOTALCPU - $(docker ps -q | wc -l) ] * 100 ))
echo CPUSPEED=$(cat /proc/cpuinfo | grep MHz | \
    head -n 1 | awk -F: '{print $2}' | tr -d ' ')

TOTALMEM=$(free | awk ' /^Mem/ { print $2 }')
USEDMEM=$(free | awk '/buffers\/cache/ { print $3 }')
FREEMEM=$(free | awk '/buffers\/cache/ { print $4 }')
echo "TOTALMEMORY=$TOTALMEM"
echo "USEDMEMORY=$USEDMEM"
echo "FREEMEMORY=$FREEMEM"

echo "ARCH=$(uname -m)"
echo "HOSTNAME=$(uname -n)"

PROCMODEL=$(cat /proc/cpuinfo | grep -m 1 "model name")
echo "MODELNAME=\"${PROCMODEL##*:[[:space:]]}\""
