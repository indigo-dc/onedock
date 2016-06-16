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

# Need setup (appart from this):
# - install xmlstarlet, jq
# - creating the ONE fake structure
#   ./one/lib/sh/scripts_common.sh
#   ./one/var/remotes/tm/tm_common.sh
# - cheating one/lib/sh/scripts_common.sh file to not to change the PATH

function setUp {
    originalPath=$PATH
    export HOST=unit-tests
    LOCAL_SERVER=$HOST:5000
    BASEDIR=$(dirname $0)/../
    export TESTING_LOCATION=$BASEDIR/testing/build
    export TESTLOGFILE="$TESTING_LOCATION/test${RANDOM}.logfile"
    export ONE_LOCATION=$BASEDIR/testing/build/one/
    export PATH=$BASEDIR/testing/bin/:$TESTING_LOCATION:$PATH
    export ONEDOCK_FOLDER=$ONE_LOCATION/var/tmp/one/

    cat > $TESTLOGFILE <<\EOT
EOT

    FILES="datastore im tm vmm docker-manage-network onedock.conf onedock.sh"

    for f in $FILES; do
        cp -r $BASEDIR/$f $TESTING_LOCATION
    done
    cat >> $TESTING_LOCATION/onedock.conf << EOT
export ONEDOCK_LOGFILE=/dev/null
# export ONEDOCK_LOGFILE=
export LOCAL_SERVER=$LOCAL_SERVER
export DELETE_LOCAL_IMAGES=yes
export ONEDOCK_CONTAINER_FOLDER=$ONE_LOCATION
export ONEDOCK_SKIP_PRIVILEGED=no
export ONEDOCK_PRIVILEGED=True
export ONEDOCK_FOLDER=$ONE_LOCATION/var/tmp/one/
EOT
}

function tearDown {
    export PATH=$originalPath
    rm -f $TESTLOGFILE
}

DSACTION_TEMPLATE_PLAINTXT='<DS_DRIVER_ACTION_DATA><IMAGE><ID>0</ID><UID>0</UID><GID>0</GID><UNAME>oneadmin</UNAME><GNAME>oneadmin</GNAME><NAME>ubuntu</NAME><PERMISSIONS><OWNER_U>1</OWNER_U><OWNER_M>1</OWNER_M><OWNER_A>0</OWNER_A><GROUP_U>0</GROUP_U><GROUP_M>0</GROUP_M><GROUP_A>0</GROUP_A><OTHER_U>0</OTHER_U><OTHER_M>0</OTHER_M><OTHER_A>0</OTHER_A></PERMISSIONS><TYPE>0</TYPE><DISK_TYPE>0</DISK_TYPE><PERSISTENT>0</PERSISTENT><REGTIME>1464618173</REGTIME><SOURCE><![CDATA[]]></SOURCE><PATH><![CDATA[%%PATH%%]]></PATH><FSTYPE><![CDATA[]]></FSTYPE><SIZE>0</SIZE><STATE>4</STATE><RUNNING_VMS>0</RUNNING_VMS><CLONING_OPS>0</CLONING_OPS><CLONING_ID>-1</CLONING_ID><TARGET_SNAPSHOT>-1</TARGET_SNAPSHOT><DATASTORE_ID>100</DATASTORE_ID><DATASTORE>onedock</DATASTORE><VMS></VMS><CLONES></CLONES><TEMPLATE><DESCRIPTION><![CDATA[Ubuntu Trusty with SSHd]]></DESCRIPTION><DEV_PREFIX><![CDATA[hd]]></DEV_PREFIX></TEMPLATE><SNAPSHOTS></SNAPSHOTS></IMAGE><DATASTORE><ID>100</ID><UID>0</UID><GID>0</GID><UNAME>oneadmin</UNAME><GNAME>oneadmin</GNAME><NAME>onedock</NAME><PERMISSIONS><OWNER_U>1</OWNER_U><OWNER_M>1</OWNER_M><OWNER_A>0</OWNER_A><GROUP_U>1</GROUP_U><GROUP_M>0</GROUP_M><GROUP_A>0</GROUP_A><OTHER_U>0</OTHER_U><OTHER_M>0</OTHER_M><OTHER_A>0</OTHER_A></PERMISSIONS><DS_MAD><![CDATA[onedock]]></DS_MAD><TM_MAD><![CDATA[onedock]]></TM_MAD><BASE_PATH><![CDATA[/var/lib/one//datastores/100]]></BASE_PATH><TYPE>0</TYPE><DISK_TYPE>0</DISK_TYPE><STATE>0</STATE><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><TOTAL_MB>64</TOTAL_MB><FREE_MB>64</FREE_MB><USED_MB>0</USED_MB><IMAGES></IMAGES><TEMPLATE><BASE_PATH><![CDATA[/var/lib/one//datastores/]]></BASE_PATH><CLONE_TARGET><![CDATA[SYSTEM]]></CLONE_TARGET><DISK_TYPE><![CDATA[FILE]]></DISK_TYPE><DS_MAD><![CDATA[onedock]]></DS_MAD><LN_TARGET><![CDATA[SYSTEM]]></LN_TARGET><TM_MAD><![CDATA[onedock]]></TM_MAD></TEMPLATE></DATASTORE></DS_DRIVER_ACTION_DATA>'

VM_TEMPLATE_PLAINTXT='<VM>
    <ID>%%VMID%%</ID>
    <UID>0</UID>
    <GID>0</GID>
    <UNAME>oneadmin</UNAME>
    <GNAME>oneadmin</GNAME>
    <NAME>container</NAME>
    <PERMISSIONS>
        <OWNER_U>1</OWNER_U>
        <OWNER_M>1</OWNER_M>
        <OWNER_A>0</OWNER_A>
        <GROUP_U>0</GROUP_U>
        <GROUP_M>0</GROUP_M>
        <GROUP_A>0</GROUP_A>
        <OTHER_U>0</OTHER_U>
        <OTHER_M>0</OTHER_M>
        <OTHER_A>0</OTHER_A>
    </PERMISSIONS>
    <LAST_POLL>0</LAST_POLL>
    <STATE>3</STATE>
    <LCM_STATE>2</LCM_STATE>
    <PREV_STATE>3</PREV_STATE>
    <PREV_LCM_STATE>2</PREV_LCM_STATE>
    <RESCHED>0</RESCHED>
    <STIME>1465199429</STIME>
    <ETIME>0</ETIME>
    <DEPLOY_ID/>
    <MONITORING/>
    <TEMPLATE>
        <AUTOMATIC_REQUIREMENTS><![CDATA[!(PUBLIC_CLOUD = YES)]]></AUTOMATIC_REQUIREMENTS>
        <CONTEXT>
            <DISK_ID><![CDATA[2]]></DISK_ID>
            <ETH0_IP><![CDATA[172.17.10.5]]></ETH0_IP>
            <ETH0_MAC><![CDATA[02:00:ac:11:0a:05]]></ETH0_MAC>
            <ETH0_MASK><![CDATA[255.255.0.0]]></ETH0_MASK>
            <NETWORK><![CDATA[YES]]></NETWORK>
            <TARGET><![CDATA[hdb]]></TARGET>
        </CONTEXT>
        <CPU><![CDATA[1]]></CPU>
        <GRAPHICS>
            <KEYMAP><![CDATA[es]]></KEYMAP>
            <LISTEN><![CDATA[0.0.0.0]]></LISTEN>
            <PORT><![CDATA[6385]]></PORT>
            <TYPE><![CDATA[vnc]]></TYPE>
        </GRAPHICS>
        <DISK>
            <CLONE><![CDATA[YES]]></CLONE>
            <CLONE_TARGET><![CDATA[SYSTEM]]></CLONE_TARGET>
            <DATASTORE><![CDATA[onedock]]></DATASTORE>
            <DATASTORE_ID><![CDATA[100]]></DATASTORE_ID>
            <DEV_PREFIX><![CDATA[hd]]></DEV_PREFIX>
            <DISK_ID><![CDATA[0]]></DISK_ID>
            <DISK_SNAPSHOT_TOTAL_SIZE><![CDATA[0]]></DISK_SNAPSHOT_TOTAL_SIZE>
            <IMAGE><![CDATA[ubuntu]]></IMAGE>
            <IMAGE_ID><![CDATA[0]]></IMAGE_ID>
            <LN_TARGET><![CDATA[SYSTEM]]></LN_TARGET>
            <READONLY><![CDATA[NO]]></READONLY>
            <SAVE><![CDATA[NO]]></SAVE>
            <SIZE><![CDATA[0]]></SIZE>
            <SOURCE><![CDATA[docker://dockerimage:0]]></SOURCE>
            <TARGET><![CDATA[hda]]></TARGET>
            <TM_MAD><![CDATA[onedock]]></TM_MAD>
            <TYPE><![CDATA[FILE]]></TYPE>
        </DISK>
        <DISK>
            <DEV_PREFIX><![CDATA[hd]]></DEV_PREFIX>
            <DISK_ID><![CDATA[1]]></DISK_ID>
            <FORMAT><![CDATA[ext3]]></FORMAT>
            <SIZE><![CDATA[100]]></SIZE>
            <TARGET><![CDATA[hdc]]></TARGET>
            <TYPE><![CDATA[fs]]></TYPE>
        </DISK>
        <MEMORY><![CDATA[1024]]></MEMORY>
        <NIC>
            <AR_ID><![CDATA[0]]></AR_ID>
            <BRIDGE><![CDATA[docker0]]></BRIDGE>
            <IP><![CDATA[172.17.10.5]]></IP>
            <MAC><![CDATA[02:00:ac:11:0a:05]]></MAC>
            <NETWORK><![CDATA[private]]></NETWORK>
            <NETWORK_ID><![CDATA[0]]></NETWORK_ID>
            <NIC_ID><![CDATA[0]]></NIC_ID>
            <SECURITY_GROUPS><![CDATA[0]]></SECURITY_GROUPS>
            <VLAN><![CDATA[NO]]></VLAN>
        </NIC>
        <SECURITY_GROUP_RULE>
            <PROTOCOL><![CDATA[ALL]]></PROTOCOL>
            <RULE_TYPE><![CDATA[OUTBOUND]]></RULE_TYPE>
            <SECURITY_GROUP_ID><![CDATA[0]]></SECURITY_GROUP_ID>
            <SECURITY_GROUP_NAME><![CDATA[default]]></SECURITY_GROUP_NAME>
        </SECURITY_GROUP_RULE>
        <SECURITY_GROUP_RULE>
            <PROTOCOL><![CDATA[ALL]]></PROTOCOL>
            <RULE_TYPE><![CDATA[INBOUND]]></RULE_TYPE>
            <SECURITY_GROUP_ID><![CDATA[0]]></SECURITY_GROUP_ID>
            <SECURITY_GROUP_NAME><![CDATA[default]]></SECURITY_GROUP_NAME>
        </SECURITY_GROUP_RULE>
        <VMID><![CDATA[%%VMID%%]]></VMID>
    </TEMPLATE>
    <USER_TEMPLATE/>
    <HISTORY_RECORDS>
        <HISTORY>
            <OID>%%VMID%%</OID>
            <SEQ>0</SEQ>
            <HOSTNAME>wn1</HOSTNAME>
            <HID>2</HID>
            <CID>-1</CID>
            <STIME>1465199447</STIME>
            <ETIME>0</ETIME>
            <VMMMAD>onedock</VMMMAD>
            <VNMMAD>dummy</VNMMAD>
            <TMMAD>shared</TMMAD>
            <DS_LOCATION>/var/lib/one//datastores</DS_LOCATION>
            <DS_ID>0</DS_ID>
            <PSTIME>1465199447</PSTIME>
            <PETIME>1465199448</PETIME>
            <RSTIME>1465199448</RSTIME>
            <RETIME>0</RETIME>
            <ESTIME>0</ESTIME>
            <EETIME>0</EETIME>
            <REASON>0</REASON>
            <ACTION>0</ACTION>
        </HISTORY>
    </HISTORY_RECORDS>
</VM>'
