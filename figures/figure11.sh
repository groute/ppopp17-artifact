#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..
OUTPATH=$AEROOT/output
DATPATH=$AEROOT/dataset

source $AEROOT/figures/common.sh

echo "==== Groute: Figure 11 (PageRank) ===="

# Requirements
require groute
require dataset

# Test binaries
PR=$AEROOT/code/groute/build/pr
GR_PR=$AEROOT/code/gunrock/build/bin/pagerank

# Clean outputs
rm -f $OUTPATH/figure11.csv



##########################################
echo "Application,Graph,GPUs,Runtime (ms)" | tee -a $OUTPATH/figure11.csv

# Run the PR application once using Groute
pr_groute() {
    name=$1
    file=$2
    numgpus=$3

    # Full path to graph
    fullpath=$DATPATH/$name/$file
    
    # Load graph metadata
    use_metis="" # Reset variable
    source $DATPATH/$name/$file.metadata

    pr_flags="-noopt"
    case "$name" in
        *twitter*)
            pr_flags="-noopt -wl_alloc_factor_local=0.1 -wl_alloc_factor_in=0.1 -wl_alloc_factor_out=0.3 -wl_alloc_factor_pass=0.5"
            ;;
        *)
            ;;
    esac
    
    date >> groute-pr.log
    echo "$PR -num_gpus $numgpus -startwith $numgpus $use_metis -graphfile $fullpath $pr_flags" >> groute-pr.log

    # Running the fused-worker, optimized version of Groute
    RET=`$TIMEOUT $PR -num_gpus $numgpus -startwith $numgpus $use_metis -graphfile $fullpath $pr_flags 2>&1 | tee -a groute-pr.log | grep --color=none '<filter>' | awk '{print $(NF-2)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a groute-pr.log
        RET="TIMEOUT"
        return
    fi
    
    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    fi
}

# Run the PR application once (single GPU only) using Gunrock
pr_gunrock() {
    name=$1
    file=$2

    # Full path to graph
    fullpath=$DATPATH/$name/$file
    
    # Create device list
    devices="0"
    
    date >> gunrock-pr.log
    echo "$GR_PR galoisgr $fullpath --quick --device=$devices" >> gunrock-pr.log

    # Running Gunrock
    RET=`$TIMEOUT $GR_PR galoisgr $fullpath --quick --device=$devices 2>&1 | tee -a gunrock-pr.log | grep --color=none 'elapsed' | awk '{print $(NF-1)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a gunrock-pr.log
        RET="TIMEOUT"
        return
    fi
    
    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    fi
}

# Run the benchmarks
for_each_graph run_allgpus pr_groute "Groute" $OUTPATH/figure11.csv

if ! [ "x$RUN_GUNROCK" = "x" ]; then
    # Run Gunrock only if exists
    if ! [ -f $AEROOT/gunrock.exists ]; then
	echo "==== Gunrock not compiled, skipping ===="
    else
	for_each_graph run_singlegpu pr_gunrock "Gunrock" $OUTPATH/figure11.csv
    fi
fi

echo "==== Done. Figure available at output/figure11.csv ===="
