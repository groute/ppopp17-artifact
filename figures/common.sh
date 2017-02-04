#!/bin/sh

# Set timeout for benchmarks
TIMEOUT="timeout 2h"

require() {
    REQUIREMENT=$1

    if ! [ -f $AEROOT/$REQUIREMENT.exists ]; then
        echo "==== ERROR: This script requires $REQUIREMENT to run. Please rerun setup.sh ===="
        exit 1
    fi
}

checkret() {
    RRRET=$1
    case "$RRRET" in
        *FAIL*)
            RUNAVG_RET=$RRRET
            return 0
            ;;
        *TIMEOUT*)
            RUNAVG_RET=$RRRET
            return 0
            ;;
        *DIFF*)
            RUNAVG_RET=$RRRET
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Runs a function thrice and compute average
RUNAVG_RET="UNKNOWN"
runavg() {
    CMD=$*
    $CMD
    if checkret $RET; then return; fi
    RUNONE=$RET
    $CMD
    if checkret $RET; then return; fi
    RUNTWO=$RET
    $CMD
    if checkret $RET; then return; fi
    RUNTHREE=$RET

    RUNAVG_RET=`echo "($RUNONE + $RUNTWO + $RUNTHREE) / 3" | bc -l`
}


# Runs a function for each graph in the dataset
for_each_graph() {
    CALLBACK=$*
    
    for graph in $AEROOT/dataset/*; do
        if [ -d "$graph" ]; then
            graphname=`basename $graph`
            graphfile=`basename $AEROOT/dataset/$graphname/*.gr`
            $CALLBACK $graphname $graphfile
        fi
    done
}

# Runs a graph algorithm for all GPU configurations
run_allgpus() {
    cmd=$1
    title=$2
    outfile=$3
    name=$4
    file=$5

    for i in `seq 1 $NUMGPUS`; do
        echo -n "$title,$name,$i," | tee -a $outfile
        runavg $cmd $name $file $i
        echo "$RUNAVG_RET" | tee -a $outfile
    done
}

# Runs a graph algorithm for a single GPU
run_singlegpu() {
    cmd=$1
    title=$2
    outfile=$3
    name=$4
    file=$5

    echo -n "$title,$name,1," | tee -a $outfile
    runavg $cmd $name $file
    echo "$RUNAVG_RET" | tee -a $outfile
}



# Determine number of GPUs
require mgbench
NUMGPUS=`$AEROOT/code/mgbench/build/numgpus`
NUMGPUS=${NUMGPUS:-0}

       
if [ $NUMGPUS -le 0 ]; then
    echo "==== ERROR: The test requires at least one GPU ===="
    exit 1
fi


LASTGPU=`expr $NUMGPUS - 1`


