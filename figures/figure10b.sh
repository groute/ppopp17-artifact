#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..
OUTPATH=$AEROOT/output
DATPATH=$AEROOT/dataset

source $AEROOT/figures/common.sh

echo "==== Groute: Figure 10b (SSSP) ===="

# Requirements
require groute
require dataset

# Test binaries
SSSP=$AEROOT/code/groute/build/sssp
GR_SSSP=$AEROOT/code/gunrock/build/bin/single_source_shortest_path

# Clean outputs
rm -f $OUTPATH/figure10b.csv



##########################################
echo "Application,Graph,GPUs,Runtime (ms)" | tee -a $OUTPATH/figure10b.csv

# Run the SSSP application once using Groute
sssp_groute() {
    name=$1
    file=$2
    numgpus=$3

    # Full path to graph
    fullpath=$DATPATH/$name/$file
    
    # Load graph metadata
    use_metis="" # Reset variable
    source $DATPATH/$name/$file.metadata

    # Result file for comparison
    resultfile=$DATPATH/$name/sssp-$file.txt

    # Delete temporary file
    rm -f /tmp/sssptmp.txt
    
    date >> groute-sssp.log
    echo "$SSSP -num_gpus $numgpus -startwith $numgpus $use_metis --prio_delta=$sssp_prio_delta_fused -graphfile $fullpath -output /tmp/sssptmp.txt" >> groute-sssp.log

    # Running the fused-worker, optimized version of Groute
    RET=`$TIMEOUT $SSSP -num_gpus $numgpus -startwith $numgpus $use_metis --prio_delta=$sssp_prio_delta_fused -graphfile $fullpath -output /tmp/sssptmp.txt 2>&1 | tee -a groute-sssp.log | grep --color=none '<filter>' | awk '{print $(NF-2)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a groute-sssp.log
        RET="TIMEOUT"
        return
    fi
    
    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    else
        # Output validation
        if ! cmp -s /tmp/sssptmp.txt $resultfile; then
            echo "WARNING: Diff failed in $name using $numgpus GPUs" >> groute-sssp.log
            RET="DIFF"
        else
            echo "DIFF PASSED" >> groute-sssp.log
        fi
    fi
}

# Run the SSSP application once using Gunrock
sssp_gunrock() {
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
    resultfile=$DATPATH/$name/sssp-$file.txt

    # Create device list
    devices=`seq -s, 0 $lastgpu`
    partitioning="metis"
    if [ "$use_metis" = "-nopn" ]; then
        partitioning="random"
    fi

    # Delete temporary file
    rm -f /tmp/sssptmp.txt
    
    date >> gunrock-sssp.log
    echo "$GR_SSSP galoisgr $fullpath --quick --device=$devices --partition_method=$partitioning --output=/tmp/sssptmp.txt" >> gunrock-sssp.log

    # Running Gunrock
    RET=`$TIMEOUT $GR_SSSP galoisgr $fullpath --quick --device=$devices --partition_method=$partitioning --output=/tmp/sssptmp.txt 2>&1 | tee -a gunrock-sssp.log | grep --color=none 'elapsed' | awk '{print $(NF-1)}'`

    if [ $? -eq 124 ]; then
	    echo "WARNING: Command timed out" | tee -a gunrock-sssp.log
        RET="TIMEOUT"
        return
    fi

    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="FAIL"
    else
        # Output validation
        if ! cmp -s /tmp/sssptmp.txt $resultfile; then
            echo "WARNING: Diff failed in $name using $numgpus GPUs" >> gunrock-sssp.log
            RET="DIFF"
        else
            echo "DIFF PASSED" >> gunrock-sssp.log
        fi
    fi
}

# Run the benchmarks
for_each_graph run_allgpus sssp_groute "Groute" $OUTPATH/figure10b.csv

if ! [ "x$RUN_GUNROCK" = "x" ]; then
    # Run Gunrock only if exists
    if ! [ -f $AEROOT/gunrock.exists ]; then
	echo "==== Gunrock not compiled, skipping ===="
    else
	for_each_graph run_allgpus sssp_gunrock "Gunrock" $OUTPATH/figure10b.csv
    fi
fi

echo "==== Done. Figure available at output/figure10b.csv ===="
