#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..
OUTPATH=$AEROOT/output
DATPATH=$AEROOT/dataset

source $AEROOT/figures/common.sh

echo "==== Groute: Figure 12 (CC) ===="

# Requirements
require groute
require dataset

# Test binaries
CC=$AEROOT/code/groute/build/cc
GR_CC=$AEROOT/code/gunrock/build/bin/connected_component

# Clean outputs
rm -f $OUTPATH/figure12.csv



##########################################
echo "Application,Graph,GPUs,Runtime (ms)" | tee -a $OUTPATH/figure12.csv

# Run the CC application once using Groute
cc_groute() {
    name=$1
    file=$2
    numgpus=$3

    # Full path to graph
    fullpath=$DATPATH/$name/$file
    
    # Load graph metadata
    use_metis="" # Reset variable
    source $DATPATH/$name/$file.metadata

    # Determine whether the graph is directed
    is_directed="-undirected=false"
    case "$file" in 
        *sym*)
            # Graph is already undirected
            is_directed=""
            ;;
    esac
    
    date >> groute-cc.log
    echo "$CC -num_gpus $numgpus -startwith $numgpus $is_directed -graphfile $fullpath" >> groute-cc.log

    # Running Groute
    RET=`$TIMEOUT $CC -num_gpus $numgpus -startwith $numgpus $is_directed -graphfile $fullpath 2>&1 | tee /tmp/cctmp.txt | tee -a groute-cc.log | grep --color=none '<filter>' | awk '{print $(NF-2)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a groute-cc.log
        RET="TIMEOUT"
        return
    fi
    
    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    else
        # Output validation
        FOUND_COMPONENTS=`grep --color=none 'Components:' /tmp/cctmp.txt | awk '{print $NF}'`
        if ! [ "$FOUND_COMPONENTS" = "$cc_components" ]; then
            echo "WARNING: Diff failed in $name using $numgpus GPUs" >> groute-cc.log
            RET="DIFF"
        else
            echo "DIFF PASSED" >> groute-cc.log
        fi
    fi
}

# Run the CC application once using Gunrock
cc_gunrock() {
    name=$1
    file=$2
    numgpus=$3
    lastgpu=`expr $numgpus - 1`

    # Full path to graph
    fullpath=$DATPATH/$name/$file

    # Create device list
    devices=`seq -s, 0 $lastgpu`
    
    date >> gunrock-cc.log
    echo "$GR_CC galoisgr $fullpath --quick --device=$devices" >> gunrock-cc.log

    # Running Gunrock
    RET=`$TIMEOUT $GR_CC galoisgr $fullpath --quick --device=$devices 2>&1 | tee -a gunrock-cc.log | grep --color=none 'elapsed' | awk '{print $(NF-1)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a gunrock-cc.log
        RET="TIMEOUT"
        return
    fi

    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    fi
}

# Run the benchmarks
for_each_graph run_allgpus cc_groute "Groute" $OUTPATH/figure12.csv

if ! [ "x$RUN_GUNROCK" = "x" ]; then
    # Run Gunrock only if exists
    if ! [ -f $AEROOT/gunrock.exists ]; then
	echo "==== Gunrock not compiled, skipping ===="
    else
	for_each_graph run_allgpus cc_gunrock "Gunrock" $OUTPATH/figure12.csv
    fi
fi


echo "==== Done. Figure available at output/figure12.csv ===="
