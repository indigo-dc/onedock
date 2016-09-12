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

source $(dirname $0)/common.sh

testDeploy() {
    VMID=15
    DATASTORE_LOCATION=$ONE_LOCATION/var/lib/datastores/0/
    mkdir -p $DATASTORE_LOCATION/$VMID
    touch $DATASTORE_LOCATION/$VMID/disk.1
    touch $DATASTORE_LOCATION/$VMID/disk.2
    ln -s $DATASTORE_LOCATION/$VMID/disk.2 \
    $DATASTORE_LOCATION/$VMID/disk.2.iso 2> /dev/null
    RESULT=$(echo "$(echo $VM_TEMPLATE_PLAINTXT | sed "s/%%VMID%%/$VMID/g")" \
    | $TESTING_LOCATION/vmm/onedock/deploy \
    $DATASTORE_LOCATION/$VMID/deployment.0 wn1 2 wn1 2>/dev/null)

    # Now we have to ensure that we have the files to create the container and to cleanup the container
    assertTrue "failed to find bootstrap files" \
    "[ -e $ONEDOCK_FOLDER/one-$VMID/deployment.bootstrap ]"
    assertTrue "failed to find cleanup files" \
    "[ -e $ONEDOCK_FOLDER/one-$VMID/deployment.cleanup ]"
    assertTrue "failed to find VNC" \
    "[ \"$(cat $TESTLOGFILE | grep 'svncterm' | wc -l)\" == \"1\" ]"
    assertTrue "failed to find docker run " \
    "[ \"$(cat $TESTLOGFILE | grep 'docker[ ]\{1,\}run' \
    | grep -v sudo | wc -l)\" == \"1\" ]"
}

testPoll() {
    cd $TESTING_LOCATION/vmm/onedock/
    RESULT="$(./poll)"
    cd - > /dev/null
    VM_COUNT=$(echo "$RESULT" | grep "VM=\[" | wc -l)
    assertTrue "failed in poll: no VM found ($RESULT)" "[ $VM_COUNT -ge 1 ]"
    VM_ID=$(echo "$RESULT" | grep "ID=-1" | wc -l)
    assertTrue "failed in poll: found VMs with ID=-1 \
    ($RESULT)" "[ $VM_ID -eq 0 ]"
}

testCancel() {

    VMID=15
    DATASTORE_LOCATION=$ONE_LOCATION/var/lib/datastores/0/
    mkdir -p $DATASTORE_LOCATION/$VMID
    touch $DATASTORE_LOCATION/$VMID/disk.1
    touch $DATASTORE_LOCATION/$VMID/disk.2
    ln -s $DATASTORE_LOCATION/$VMID/disk.2 \
    $DATASTORE_LOCATION/$VMID/disk.2.iso 2> /dev/null

    RESULT=$($TESTING_LOCATION/vmm/onedock/cancel one-$VMID 2>/dev/null)
    assertTrue "error cancelling the VM" "[ $? -eq 0 ]"
    assertTrue "failed to find docker stop " \
    "[ \"$(cat $TESTLOGFILE | grep 'docker[ ]\{1,\}stop' \
    | grep -v sudo | wc -l)\" == \"1\" ]"
}

testShutdown() {

    VMID=15
    DATASTORE_LOCATION=$ONE_LOCATION/var/lib/datastores/0/
    mkdir -p $DATASTORE_LOCATION/$VMID
    touch $DATASTORE_LOCATION/$VMID/disk.1
    touch $DATASTORE_LOCATION/$VMID/disk.2
    ln -s $DATASTORE_LOCATION/$VMID/disk.2 \
    $DATASTORE_LOCATION/$VMID/disk.2.iso 2> /dev/null

    RESULT=$($TESTING_LOCATION/vmm/onedock/shutdown one-$VMID 2>/dev/null)
    assertTrue "error shutting down the VM" "[ $? -eq 0 ]"
    assertTrue "failed to find docker stop " \
    "[ \"$(cat $TESTLOGFILE | grep 'docker[ ]\{1,\}stop' \
    | grep -v sudo | wc -l)\" == \"1\" ]"
}

. shunit2
