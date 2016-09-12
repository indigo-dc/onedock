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

testClone_Image() {
    RESULT=$($TESTING_LOCATION/tm/onedock/clone docker://dockerimage:0 \
    wn1:/var/lib/one/datastores/0/12/disk.0 12 100)
    assertTrue "failed to test clone" "[ $? -eq 0 ]"
}

testClone_File() {
    echo "not testing"
    assertTrue "failed to test clone" "[ $? -eq 0 ]"
}

. shunit2
