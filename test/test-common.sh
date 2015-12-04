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


