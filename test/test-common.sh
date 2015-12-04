#!/bin/bash
set -e
set -o pipefail

export spinstr='|/-\'
function spin()
{
	[ "$spinstr" == "" ] && export spinstr='|/-\'
        local temp=${spinstr#?}
        printf "%c" "$spinstr"
        printf "\b"
        spinstr=$temp${spinstr%"$temp"}
}
function progress {
    printf "."
}
function wait_for()
{
	t1=$(date +%s)
	while [ $[ $(date +%s) - $t1 ] -lt $1 ]; do
		spin
		sleep 0.5
	done
}

function check_cmd_eq() {
	[ "$(eval $1)" == "$2" ] && return 0
	return 1
}
function check_cmd_neq() {
	[ "$(eval $1)" != "$2" ] && return 0
	return 1
}

function wait_for_timeout_equal()
{
	TIME=$1
	STEP=$2
	CONDITION=$3
	VALUE=$4

	t1=$(date +%s)
	while [ "$(eval $CONDITION)" == "$VALUE" ] && [ $[ $(date +%s) - $t1 ] -lt $TIME ]; do
                spin
                sleep $STEP
        done
}

function wait_for_timeout_nequal()
{
        TIME=$1
        STEP=$2
        CONDITION=$3
        VALUE=$4

        t1=$(date +%s)
        while [ "$(eval $CONDITION)" != "$VALUE" ] && [ $[ $(date +%s) - $t1 ] -lt $TIME ]; do
                spin
                sleep $STEP
        done
}

function create_vm() {
	FILENAME=/tmp/onedock.vm
	[ "$1" != "" ] && FILENAME=$1

	progress

	# Create a vm
	VMID=$(onevm create "$FILENAME" | awk '{print $2}')
	export VMID
	
	progress
	
	# Froce deploying just in case that it has not enough cores
	onevm deploy $VMID $HOSTNAME
	
	progress
	
	# Check pending state
	CMD="onevm show -x $VMID | /var/lib/one/remotes/datastore/xpath.rb /VM/STATE"
	wait_for_timeout_equal 60 1 "$CMD" "1"
	
	progress
	
	# Wait a little more, until running state
	wait_for_timeout_nequal 60 1 "onevm show -x $VMID | /var/lib/one/remotes/datastore/xpath.rb /VM/STATE" "3"
	
	progress
	
	# Check running state
	check_cmd_neq "$CMD" "3" && exit 1
	
	progress
	
	wait_for 10
	
	# Do a ping to check the machine
	IP=$(onevm show -x $VMID | /var/lib/one/remotes/datastore/xpath.rb /VM/TEMPLATE/NIC/IP)
	ping -c 3 $IP > /dev/null
	
	progress
	
	# Check the docker containers
	[ "$(docker ps | grep one-$VMID)" == "" ] && exit 1
	# Check the state of the container 
	[ "$(docker inspect -f '{{.State.Running}}' one-$VMID)" == "" ] && exit 1
	# Check the images repository
	[ "$(docker images | grep "one-$VMID")" == "" ] && exit 1
	return 0	
}
