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

testDocker() {
    RESULT="$($TESTING_LOCATION/im/onedock-probes.d/docker.sh | sed 's/"[^"]*"/_/g')"
    for l in $RESULT; do
        IFS='=' read K V <<<$l
        assertFalse "variable $K has no value" "[ -z \"$V\" ]"
    done
}

testMonitor_ds() {
    RESULT="$($TESTING_LOCATION/im/onedock-probes.d/monitor_ds.sh docker $ONE_LOCATION/var/datastores/)"
    for l in $RESULT; do
        IFS='=' read K V <<<$l
        assertFalse "variable $K has no value" "[ -z \"$V\" ]"
    done
}

testPoll() {
    cd $TESTING_LOCATION/im/onedock-probes.d/
    RESULT="$(./poll.sh)"
    cd - > /dev/null
    VM_POLL=$(echo "$RESULT" | grep "VM_POLL=YES" | wc -l)
    assertTrue "failed in poll: ($RESULT)" "[ $VM_POLL -eq 1 ]"
    VM_COUNT=$(echo "$RESULT" | grep "VM=\[" | wc -l)
    assertTrue "failed in poll: no VM found ($RESULT)" "[ $VM_COUNT -ge 1 ]"
    VM_ID=$(echo "$RESULT" | grep "ID=-1" | wc -l)
    assertTrue "failed in poll: found VMs with ID=-1 ($RESULT)" "[ $VM_ID -eq 0 ]"
}

. shunit2
