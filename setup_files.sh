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
BASEDIR=$(cd $(dirname $0) && pwd && cd - > /dev/null)
read -p "this will overwrite files. proceed? (y/N) " OVERWRITE
OVERWRITE=$(echo $OVERWRITE | tr '[a-z]' '[A-Z]')

if [ "$OVERWRITE" != "Y" ]; then
exit
fi

FOLDERS="im/onedock.d im/onedock-probes.d vmm/onedock \
    tm/onedock datastore/onedock"
for F in $FOLDERS; do
    if [ ! -d "/var/lib/one/remotes/$F" ]; then
        cp -r "$BASEDIR/$F" /var/lib/one/remotes/$(dirname $F)
    else
        cp $BASEDIR/$F/* "/var/lib/one/remotes/$F/"
    fi
done

cp $BASEDIR/onedock.sh /var/lib/one/remotes/
cp $BASEDIR/docker-manage-network /var/lib/one/remotes/

if [ ! -e /var/lib/one/remotes/onedock.conf ]; then
    cp onedock.conf /var/lib/one/remotes/onedock.conf
    sed -i.bkp -e "s/export LOCAL_SERVER=.*/export LOCAL_SERVER=$(hostname):5000/g" /var/lib/one/remotes/onedock.conf
else
echo "Configuration file /var/lib/one/remotes/onedock.conf exists. \
    Please check that the variables are properly set."
fi
touch /var/log/onedock.log && chown oneadmin:oneadmin /var/log/onedock.log
chown -R oneadmin:oneadmin /var/lib/one/remotes
