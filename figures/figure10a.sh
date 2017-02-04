#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..
OUTPATH=$AEROOT/output
DATPATH=$AEROOT/dataset

source $AEROOT/figures/common.sh

echo "==== Groute: Figure 10a (BFS) ===="

# Requirements
require groute
require dataset

# Test binaries
BFS=$AEROOT/code/groute/build/bfs
GR_BFS=$AEROOT/code/gunrock/build/bin/breadth_first_search

# Clean outputs
rm -f $OUTPATH/figure10a.csv



##########################################
echo "Application,Graph,GPUs,Runtime (ms)" | tee -a $OUTPATH/figure10a.csv

# Run the BFS application once using Groute
bfs_groute() {
    name=$1
    file=$2
    numgpus=$3

    # Full path to graph
    fullpath=$DATPATH/$name/$file
    
    # Load graph metadata
    use_metis="" # Reset variable
    source $DATPATH/$name/$file.metadata

    # Result file for comparison
    resultfile=$DATPATH/$name/bfs-$file.txt

    # Delete temporary file
    rm -f /tmp/bfstmp.txt
    
    date >> groute-bfs.log
    echo "$BFS -num_gpus $numgpus -startwith $numgpus $use_metis --prio_delta=$bfs_prio_delta_fused -graphfile $fullpath -output /tmp/bfstmp.txt" >> groute-bfs.log

    # Running the fused-worker, optimized version of Groute
    RET=`$TIMEOUT $BFS -num_gpus $numgpus -startwith $numgpus $use_metis --prio_delta=$bfs_prio_delta_fused -graphfile $fullpath -output /tmp/bfstmp.txt 2>&1 | tee -a groute-bfs.log | grep --color=none '<filter>' | awk '{print $(NF-2)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a groute-bfs.log
        RET="TIMEOUT"
        return
    fi
    
    
    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    else
        # Output validation
        if ! cmp -s /tmp/bfstmp.txt $resultfile; then
            echo "WARNING: Diff failed in $name using $numgpus GPUs" >> groute-bfs.log
            RET="DIFF"
        else
            echo "DIFF PASSED" >> groute-bfs.log
        fi
    fi
}

# Run the BFS application once using Gunrock
bfs_gunrock() {
    name=$1
    file=$2
    numgpus=$3
    lastgpu=`expr $numgpus - 1`

    # Full path to graph
    fullpath=$DATPATH/$name/$file
    
    # Load graph metadata
    use_metis="" # Reset variable
    source $DATPATH/$name/$file.metadata

    # Result file for comparison
    resultfile=$DATPATH/$name/bfs-$file.txt

    # Create device list
    devices=`seq -s, 0 $lastgpu`
    partitioning="metis"
    if [ "$use_metis" = "-nopn" ]; then
        partitioning="random"
    fi

    # Delete temporary file
    rm -f /tmp/bfstmp.txt
    
    date >> gunrock-bfs.log
    echo "$GR_BFS galoisgr $fullpath --quick --device=$devices --partition_method=$partitioning --output=/tmp/bfstmp.txt" >> gunrock-bfs.log

    # Running Gunrock
    RET=`$TIMEOUT $GR_BFS galoisgr $fullpath --quick --device=$devices --partition_method=$partitioning --output=/tmp/bfstmp.txt 2>&1 | tee -a gunrock-bfs.log | grep --color=none 'elapsed' | awk '{print $(NF-1)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a gunrock-bfs.log
        RET="TIMEOUT"
        return
    fi

    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    else
        # Output validation
        if ! cmp -s /tmp/bfstmp.txt $resultfile; then
            echo "WARNING: Diff failed in $name using $numgpus GPUs" >> gunrock-bfs.log
            RET="DIFF"
        else
            echo "DIFF PASSED" >> gunrock-bfs.log
        fi
    fi
}

# Run the benchmarks
for_each_graph run_allgpus bfs_groute "Groute" $OUTPATH/figure10a.csv

if ! [ "x$RUN_GUNROCK" = "x" ]; then
    # Run Gunrock only if exists
    if ! [ -f $AEROOT/gunrock.exists ]; then
	echo "==== Gunrock not compiled, skipping ===="
    else
	for_each_graph run_allgpus bfs_gunrock "Gunrock" $OUTPATH/figure10a.csv
    fi
fi

echo "==== Done. Figure available at output/figure10a.csv ===="
