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

# Copy the new files to the proper location
FOLDERS="datastore/onedock im/onedock-probes.d tm/onedock vmm/onedock"
for F in $FOLDERS; do
    cp $F/* /var/lib/one/remotes/$F/
done
FILES="docker-manage-network onedock.sh onedock.conf"
for F in $FILES; do
    cp $F /var/lib/one/remotes/
done

# Distribute the files in the hosts
FOLDERS="datastore/onedock im/onedock-probes.d tm/onedock vmm/onedock"
for F in $FOLDERS; do
    for i in /var/lib/one/remotes/$F/*; do
        scpall $i /var/tmp/one/$F/
    done
done
FILES="docker-manage-network onedock.sh onedock.conf"
for F in $FILES; do
    scpall /var/lib/one/remotes/$F /var/tmp/one/$F
done
