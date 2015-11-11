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

read -p "this will overwrite files. proceed? (y/N) " OVERWRITE
OVERWRITE=$(echo $OVERWRITE | tr '[a-z]' '[A-Z]')

if [ "$OVERWRITE" != "Y" ]; then
exit
fi

FOLDERS="im/onedock* vmm/onedock tm/onedock datastore/onedock"
for F in $FOLDERS; do
    if [ ! -d "/var/lib/one/remotes/$F" ]; then
        cp -r "./$F" /var/lib/one/remotes/$(dirname $F)
    else
        cp ./$F/* "/var/lib/one/remotes/$F/"
    fi
done
        
cp onedock.sh /var/lib/one/remotes/
cp docker-manage-network /var/lib/one/remotes/

if [ ! -e /var/lib/one/remotes/onedock.conf ]; then
cat > /var/lib/one/remotes/onedock.conf << EOF
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
export LOCAL_SERVER=$(hostname):5000
export DATASTORE_DATA_PATH=/var/lib/docker-registry/data/
export ONEDOCK_LOGFILE=/var/log/onedock.log
export IMAGE_BASENAME=image4one
export ONEDOCK_DEBUG=True
export ONEDOCK_DEFAULT_NETMASK=24
export ONEDOCK_DEFAULT_DHCP=yes
EOF
else
echo "Configuration file /var/lib/one/remotes/onedock.conf exists. Please check that the variables are properly set."
fi
touch /var/log/onedock.log && chown oneadmin:oneadmin /var/log/onedock.log
chown -R oneadmin:oneadmin /var/lib/one/remotes
