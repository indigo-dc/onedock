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

NOT_SUPPORTED_testClone()
{
    RESULT=$($TESTING_LOCATION/datastore/onedock/clone \
    docker://dockerimage:0 wn1:/var/lib/one//datastores/0/0/disk.0 0 100)
    assertTrue "texto $RESULT" "[ $? -eq 0 ]"
}

NOT_SUPPORTED_testRM() {
    TEMPLATE=$(echo $DSACTION_TEMPLATE_PLAINTXT \
    | sed 's/%%PATH%%/docker:\/\/ubuntu:latest/' | base64)
    RESULT=$($TESTING_LOCATION/datastore/onedock/rm "$TEMPLATE" 0)
    assertTrue "texto $RESULT" "[ $? -eq 0 ]"
}

testCP_DockerHub() {
    TEMPLATE=$(echo $DSACTION_TEMPLATE_PLAINTXT \
    | sed 's/%%PATH%%/docker:\/\/ubuntu:latest/' | base64)
    RESULT=$($TESTING_LOCATION/datastore/onedock/cp "$TEMPLATE" 0)
    assertSame "failed to test CP" \
    "docker://$LOCAL_SERVER/dockerimage:0 0" "$RESULT"
}

testCP_DockerFile() {
    TMPDIR="/tmp/t$(date +%s)"
    PATTERN=$(echo $TMPDIR | sed 's/\//\\\//g')
    TEMPLATE=$(echo "$DSACTION_TEMPLATE_PLAINTXT" \
    | sed "s/%%PATH%%/$PATTERN.tar/" | base64)
    mkdir -p $TMPDIR
    cat > $TMPDIR/repositories <<\EOF
{"ec4docker":
    {"frontend":
    "fe6d54a00e6775012430ed4a6f14dd95b25dad0b9d58282f1f92ab0a8a7fb888"}
}
EOF
    tar -cf $TMPDIR.tar -C $TMPDIR repositories

    RESULT=$($TESTING_LOCATION/datastore/onedock/cp "$TEMPLATE" 0)
    rm -rf $TMPDIR
    rm -f $TMPDIR.tar
    assertSame "failed to test CP" \
    "docker://$LOCAL_SERVER/dockerimage:0 0" "$RESULT"
}

testMonitor() {
    RESULT=$($TESTING_LOCATION/datastore/onedock/monitor "N" 0)
    assertTrue "texto $RESULT" "[ $? -eq 0 ]"
    assertSame "failed to find USED_MB" "$(echo $RESULT \
    | grep 'USED_MB=' -c)" "1"
    assertSame "failed to find FREE_MB" "$(echo $RESULT \
    | grep 'FREE_MB=' -c)" "1"
    assertSame "failed to find TOTAL_MB" "$(echo $RESULT \
    | grep 'TOTAL_MB=' -c)" "1"
}

testStat_DockerHub() {
    TEMPLATE=$(echo $DSACTION_TEMPLATE_PLAINTXT \
    | sed 's/%%PATH%%/docker:\/\/ubuntu:latest/' | base64)
    RESULT=$($TESTING_LOCATION/datastore/onedock/stat "$TEMPLATE")
    assertSame "failed to test STAT" "0" "$RESULT"
}

testStat_DockerFile() {
    TMPDIR="/tmp/t$(date +%s)"
    PATTERN=$(echo $TMPDIR | sed 's/\//\\\//g')
    TEMPLATE=$(echo "$DSACTION_TEMPLATE_PLAINTXT" \
    | sed "s/%%PATH%%/$PATTERN.tar/" | base64)
    mkdir -p $TMPDIR
    cat > test.test <<\EOF
{"ec4docker":
    {"frontend":
    "fe6d54a00e6775012430ed4a6f14dd95b25dad0b9d58282f1f92ab0a8a7fb888"}
}
EOF
    dd if=/dev/urandom bs=1M count=4 of=$TMPDIR/file > /dev/null 2> /dev/null
    assertTrue "failed to create temporary files" "[ $? -eq 0 ]"
    tar -cf $TMPDIR.tar -C $TMPDIR repositories file > /dev/null 2> /dev/null
    assertTrue "failed to create temporary files" "[ $? -eq 0 ]"

    RESULT=$($TESTING_LOCATION/datastore/onedock/stat "$TEMPLATE")
    rm -rf $TMPDIR
    rm -f $TMPDIR.tar
    assertNotSame "failed to test STAT" "0" "$RESULT"
}


. shunit2
