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

# -------- Set up the environment to source common tools & conf ------------


[ -e ${DRIVER_PATH}/../../onedock.conf ] && \
    source ${DRIVER_PATH}/../../onedock.conf

function is_true {
    local V
    V=$(echo $1 | tr '[a-z]' '[A-Z]')
    [ "$V" == "TRUE" ] && return 0
    [ "$V" == "YES" ] && return 0
    [ "$V" == "1" ] && return 0
    return 1
}

function setup_frontend {
    if [ -z "${ONE_LOCATION}" ]; then
        LIB_LOCATION=/usr/lib/one
    else
        LIB_LOCATION=$ONE_LOCATION/lib
    fi

    source ${DRIVER_PATH}/../../datastore/libfs.sh
    export LIB_LOCATION
    export XPATH_APP="${DRIVER_PATH}/../../datastore/xpath.rb"

    if [ -z "${ONE_LOCATION}" ]; then
        TMCOMMON=/var/lib/one/remotes/tm/tm_common.sh
    else
        TMCOMMON=$ONE_LOCATION/var/remotes/tm/tm_common.sh
    fi

    . $TMCOMMON
    export TMCOMMON
}

function setup_wn {
    source ${DRIVER_PATH}/../../scripts_common.sh
    export XPATH_APP="${DRIVER_PATH}/../../datastore/xpath.rb"
    export ONEDOCK_LOGFILE=
}

function read_xpath {
    CONTENT=$1
    shift
    QUERY_STR=
    while [ $# -gt 0 ]; do
        QUERY_STR="$QUERY_STR$1 "
        shift
    done
    local i
    unset i XPATH_ELEMENTS

    while IFS= read -r -d '' element; do
        XPATH_ELEMENTS[i++]="$element"
    done < <(echo "$CONTENT" | $XPATH_APP --stdin $QUERY_STR)
}

function log_onedock {
    if [ "$ONEDOCK_LOGFILE" != "" ]; then
        echo "$(date -R) - $@" >> "$ONEDOCK_LOGFILE"
    else
        echo "$(date -R) - $@" >&2
    fi
}

function log_onedock_debug {
    if [ "$ONEDOCK_DEBUG" == "True" ]; then
        if [ "$ONEDOCK_LOGFILE" != "" ]; then
            echo "$(date -R) - $@" >> "$ONEDOCK_LOGFILE"
        else
            echo "$(date -R) - $@" >&2
        fi
    fi
}

function onedock_exec_and_log {
    log_onedock "$1"
    exec_and_log "$1" "$2"
}

function build_dock_name {
    SERVER=$1/
    USER=$2/
    IMAGE=$3
    TAG=:$4

    [ "$SERVER" == "/" ] && SERVER=
    [ "$USER" == "/" ] && USER=
    [ "$TAG" == ":" ] && TAG=
    echo "$SERVER$USER$IMAGE$TAG"
}

function _split_dock_name {
    IFS=
    SERVER=
    IMAGE=
    USER=
    TAG=
    IMAGE=$1

    IFS=/ read F1 F2 F3 <<< "$IMAGE"
    if [ "$F3" != "" ]; then
        # F3 es la imagen       
        IMAGE=$F3
        USER=$F2
        SERVER=$F1
    elif [ "$F2" != "" ]; then
        # solo hay dos, con lo que F2 es la imagen
        IMAGE=$F2
        _SERVER=${F1##*:}
        _PORT=${F1%%:*}
        if [ "$_SERVER" != "$_PORT" ]; then
            # F1 tiene formato servidor:puerto
            SERVER=$F1
        else
            USER=$F1
        fi
    else
        IMAGE=$F1
    fi
    _TAG=${IMAGE##*:}
    IMAGE=${IMAGE%%:*}
    [ "$_TAG" != "$IMAGE" ] && TAG=$_TAG

    echo "$SERVER/$USER/$IMAGE/$TAG"
}

function split_dock_name {
    _S2=${2:-_S2}
    _S3=${3:-_S3}
    _S4=${4:-_S4}
    _S5=${5:-_S5}
    IMAGENAME=$(IFS= _split_dock_name $1)
    IFS=/ read $_S2 $_S3 $_S4 $_S5 <<< "$IMAGENAME"
    [ "$2" != "" ] && export $2
    [ "$3" != "" ] && export $3
    [ "$4" != "" ] && export $4
    [ "$5" != "" ] && export $5
}

function get_imagename_from_file {
    FILE=$1
    CONTENT=$(tar --extract --file "$FILE" repositories -O)
    [ $? -ne 0 ] && echo "file $FILE is not a docker image \
        (does not have the proper format)" && return 1
    IMAGE_COUNT=$(echo "$CONTENT" | jq '.[] | keys | length')
    [ "$IMAGE_COUNT" != "1" ] && echo "file $FILEcontains more than one image \
        or other error has happened: $IMAGE_COUNT" && return 1
    IMAGE=$(echo "$CONTENT" |  jq 'keys | .[0]'  | sed 's/^"\(.*\)"$/\1/')
    TAG=$(echo "$CONTENT" | jq ".$IMAGE | keys | .[0]" | \
        sed 's/^"\(.*\)"$/\1/')
    echo "$IMAGE:$TAG"
    return 0
}
