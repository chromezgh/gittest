#!/bin/bash
# Copyright 2017 Bitland SW
# The catch flow :
#   1. capture the real data(x,y,z) by 'ectool motoinsense'
#   2. compare the real data with 0
#   3. return failed or passed and the reason
#

# use script to show UI and test 
# when boot then test

#SOURCE=/home/simon/Documents/Coral/small_board_test/g_sensor_test/ectool_motonsense.log
NUM=$1

usage() {
    echo "Usage: ${0} <SENSOR_NUM>"
    echo "       <SENSOR_NUM>: 0(lid), 1(base), 2(gyroscope)"
    echo "Function: ensure sensor works by 'ectool motionsense'"
}

if [ "$1" = "-h" ] || [ "$1" = "help" ] || [ "$1" = "" ] || \
    [ "$1" -ge "3" ]; then
        usage
        exit 1
    fi

die() {
    echo "ERROR: $*" 1>&2
    exit 1
}

info() {
    echo "INFO: $*" 1>&2
}

# TODO
# function: abs all incoming numbers
# usage: abs <val>
abs() {
    while [ "$#" -gt 0 ]; do
        while [ "$1" -lt 0 ]; do

            shift
        done

    done
}

# function: get the real data, then return (x,y,z)
# usage: capture $NUM
capture() {
    #declare -A array # the way of associate array declared
    #DATA=([x]=1 [y]=2 [z]=3) #the way of associate array defined
    declare -a DATA
    info "start capturing the real data..."
    #info data from $SOURCE
    # cat $SOURCE | grep "Sensor $NUM:" | awk '{print $3 " "$4 " "$5}'
    sleep 1
    ectool motionsense | grep "Sensor $NUM:" | awk '{print $3 " "$4 " "$5}'
    if [ "$?" = "1" ]; then
        info [FAILED] seems failed to run 'ectool motionsense' !!!
        exit 1
    fi
    # DATA=(`cat $SOURCE | grep "Sensor $NUM:" | awk '{print "x="$3 " y="$4 " z="$5}'`)
    DATA=(`ectool motionsense | grep "Sensor $NUM:" | awk '{print "x="$3 " y="$4 " z="$5}'`)
    info "[DEBUG] capture DATA: ${DATA[*]}"
}

# function: judge (x+y+z) is zero, if true return false
# usage: $0 x y z
is_full_zero() {
    data[0]=$1
    data[1]=$2
    data[2]=$3
    info "[START] full zero? let me computering ..."
    let result=${data[0]#-}+${data[1]#-}+${data[2]#-}
    info [DEBUG] total result: "$result"
    if [ "$result" = "0" ]; then
        return 0
    else
        return 1
    fi
}

# function: compare $data1 with $data1, if equal,return 0
# usage: compare data0 data1
compare() {
    info "compare starting ..."
    if [ "$1" = "$2" ]; then
        info compare end
        return 0
    fi
    info compare end
    return 1
}

main() {
    #set -n
    declare -a data
    declare -a data1
    local flag=0
    data=(`capture $NUM`)
    data1=(`capture $NUM`)
    #info "[DEBUG] get the data ${data[*]}"

    # judge weather full zero or not ?
    is_full_zero ${data[0]} ${data[1]} ${data[2]}
    if [ "$?" = "0" ]; then
        info "[FINISHED] full zero? Yes(0)"
        info [FAILED] ***g-sensor$1 maybe damaged***
        exit 1
    fi
    info "[FINISHED] full zero? No(>1)"

    # start comparing the x/y/z ...
    for i in 0 1 2; do
        compare ${data[i]} ${data1[i]}
        let flag+=$?
    done
    info [DEBUG] flag: $flag  [ok\>0 fail=0]

    # judge weather the sensor is bad or not
    if [ "$flag" = "0" ]; then
        info [FAILED] ***g-sensor$1 maybe damaged***
        exit 1
    fi
    info [PASSED] Looks g-sensor$1 is good!!!
    exit 0
    #set +n
}

# set -e
main "$@"



