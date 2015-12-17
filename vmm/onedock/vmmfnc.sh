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

function find_nbd {
    for device in /sys/class/block/nbd*; do
        if [ "$(cat $device/size)" == 0 ]; then
            DEV=/dev/$(basename $device)
            if [ -b "$DEV" ]; then
                echo "$DEV"
                break
            fi
        fi
    done
}

function setup_disk {
    FOLDER=$1
    DISK_ID=$2
    TARGET=$3
    DEVICESFILE=$4
    
    NBD_TGT=$(find_nbd)
    if [ "$NBD_TGT" == "" ]; then
        echo "could not find free devices to connect disk $DISK_ID"
        return 1
    fi
    
    log_onedock_debug "connecting disk $2 in $NBD_TGT"
    log_onedock_debug "qemu-nbd -c \"$NBD_TGT\" \"${FOLDER}/disk.${DISK_ID}\""
    sudo /usr/bin/qemu-nbd -c $NBD_TGT "${FOLDER}/disk.${DISK_ID}" 2> /dev/null
    if [ $? -ne 0 ]; then
        log_onedock_debug "FAILED: connecting disk $2 in $NBD_TGT"    
        echo "could not connect the disk $DISK_ID"
        return 2
    fi
    
    echo "$NBD_TGT" >> "$DEVICESFILE"
    EXPORTED_DEVICES="--device $NBD_TGT:/dev/$TARGET"
    DEVNAME=$(basename $NBD_TGT)
    PARTITIONS=$(ls -d /sys/class/block/${DEVNAME}/${DEVNAME}p* 2> /dev/null)
    if [ $? -eq 0 ]; then
        for partition in $PARTITIONS; do
            PARTITION_NAME=$(basename $partition)
            PARTITION_ID=${PARTITION_NAME##${DEVNAME}p}
            EXPORTED_DEVICES="${EXPORTED_DEVICES} --device ${NBD_TGT}p${PARTITION_ID}:/dev/${TARGET}${PARTITION_ID}"
        done
    fi
    echo $EXPORTED_DEVICES
    return 0
}

function cleanup_disk {
    DEVICE=$1
    log_onedock_debug "asked to cleanup device $DEVICE"
    [ -b $DEVICE ] && log_onedock_debug "sudo /usr/bin/qemu-nbd -d $DEVICE" && sudo /usr/bin/qemu-nbd -d $DEVICE
}

function cleanup_disks {
    DOMXML=$1
    FOLDER=$2
    DEVICESFILE=$3
    
    for device in $(cat $DEVICESFILE); do
        cleanup_disk "$device"
    done
    return 0
}

function setup_devices {
    DOMXML=$1
    FOLDER=$2
    DEVICESFILE=$3

    cat <<EOT > $DEVICESFILE
EOT
    DEVICES_STR=
    DISKS="$(echo "$DOMXML" | xmlstarlet sel -t -m /VM/TEMPLATE/DISK -v "concat(DISK_ID,';',TARGET,';',TYPE)" -n)"
    for DISK in $DISKS; do
        DISK_ID= TARGET= TYPE=
        IFS=';' read DISK_ID TARGET TYPE <<< "$DISK"

        # We'll skip disk 0, because it is the docker image        
        [ "$DISK_ID" == "0" ] && continue

        if [ "$TYPE" == "fs" ] || [ "$TYPE" == "FILE" ]; then
            log_onedock_debug "setup_disk $FOLDER $DISK_ID $TARGET $DEVICESFILE"
            CURRENT_DEVICE_STR=$(setup_disk "$FOLDER" "$DISK_ID" "$TARGET" "$DEVICESFILE")
            if [ $? -ne 0 ]; then
                log_onedock_debug "FAILED: could not setup disk $DISK_ID ($CURRENT_DEVICE_STR)"    
                error_message "could not setup disk $DISK_ID ($CURRENT_DEVICE_STR)"
                cleanup_disks "$DOMXML" "$FOLDER" "$DEVICESFILE"
                return 2
            fi
            DEVICES_STR="$DEVICES_STR$CURRENT_DEVICE_STR "
        else
            log_onedock_debug "FAILED: wrong type for disk $DISK_ID"    
            error_message "we only support disks of type 'fs' and 'FILE'... type '$TYPE' found"
            return 1
        fi
    done
    
    if [ "$DEVICES_STR" != "" ]; then
        DEVICES_STR="$DEVICES_STR --cap-add SYS_ADMIN --security-opt apparmor:unconfined"
    fi
    
    echo $DEVICES_STR
    return 0
}

function setup_network {
    DOMXML=$1
    FOLDER=$2
    NETWORKFILE=$3
    
    cat <<EOT > $NETWORKFILE
EOT
    NICS="$(echo "$DOMXML" | xmlstarlet sel -t -m /VM/TEMPLATE/NIC -v "concat(NIC_ID,';',BRIDGE,';',IP,';',MAC)" -n)"
    for NIC in $NICS; do
        NIC_ID= BRIDGE= IP= MAC=
        IFS=';' read NIC_ID BRIDGE IP MAC <<< "$NIC"

        MAC_STR= IP_STR= BRIDGE_STR= GW_STR=

        NICNAME=eth${NIC_ID}
        NIC_STR="--create-device $NICNAME"
        [ "$BRIDGE" != "" ] && BRIDGE_STR="--bridge $BRIDGE"
        [ "$MAC" != "" ] && MAC_STR="--mac $MAC"
        if [ "$IP" != "" ]; then
            [ "$ONEDOCK_DEFAULT_NETMASK" != "" ] && IP=$IP/$ONEDOCK_DEFAULT_NETMASK
            IP_STR="--ip $IP"
        fi
        
        # Now we get the context for the network, to get the IP address
        NICNAME=ETH${NIC_ID}
        NET_CONTEXT="$(echo "$DOMXML" | xmlstarlet sel -t -m /VM/TEMPLATE/CONTEXT -v "concat(${NICNAME}_IP,';',${NICNAME}_MAC,';',${NICNAME}_MASK,';',${NICNAME}_NETWORK,';',${NICNAME}_GATEWAY,';',${NICNAME}_DNS)")"
        
        # Initialize variables
        C_IP= C_MAC= C_MASK= C_NET= C_GW= C_DNS=
        IFS=';' read C_IP C_MAC C_MASK C_NET C_GW C_DNS <<< "$NET_CONTEXT"

        if [ "$C_IP" != "" ]; then
            IP_STR="--ip $C_IP"
            [ "$C_MASK" != "" ] && IP_STR="${IP_STR}/${C_MASK}"
        else
            # If there is no context for IP address, should we set the IP using DHCP?
            is_true "$ONEDOCK_DEFAULT_DHCP" && IP_STR="--dhcp"
        fi
        
        [ "$C_MAC" != "" ] && MAC_STR="--mac $C_MAC"
        [ "$C_GW" != "" ] && GW_STR="--gateway $C_GW"
        
        echo "$SUDO $DN --container-name $CONTAINERNAME $BRIDGE_STR $MAC_STR $IP_STR $NIC_STR $GW_STR" >> $NETWORKFILE
    done
    echo '--net="none"'
    return 0
}
