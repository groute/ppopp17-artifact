#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..
OUTPATH=$AEROOT/output
DATPATH=$AEROOT/dataset

source $AEROOT/figures/common.sh

echo "==== Groute: Table 5 (Scheduler Progression, SSSP) ===="

# Requirements
require groute
require dataset

# Test binaries
SSSP=$AEROOT/code/groute/build/sssp

# Clean outputs
rm -f $OUTPATH/table5.csv


# Function that runs SSSP once
run_sssp() {
    numgpus=$1
    graphfile=$2
    graph_flags=${@:3}
    
    date >> groute-progression.log
    echo "$SSSP -num_gpus $numgpus -startwith $numgpus -graphfile $graphfile $graph_flags" >> groute-progression.log
    
    RET=`$TIMEOUT $SSSP -num_gpus $numgpus -startwith $numgpus -graphfile $graphfile $graph_flags 2>&1 | tee -a groute-progression.log | grep --color=none '<filter>' | awk '{print $(NF-2)}'`

    if [ $? -eq 124 ]; then
	echo "WARNING: Command timed out" | tee -a groute-progression.log
    fi

    
    # Check if run was successful
    if [ "x$RET" = "x" ]; then
        RET="-1"
    fi
}




##########################################

echo "Graph,GPUs,Unoptimized (ms),Soft Priority Scheduler (ms),Fused Worker (ms)" | tee -a $OUTPATH/table5.csv

for graph in "soc-LiveJournal1" "kron21.sym" "USA"; do
    file=`basename $AEROOT/dataset/$graph/*.gr`
        
    # Full path to graph
    fullpath=$DATPATH/$graph/$file
    
    # Load graph metadata
    use_metis="" # Reset variable
    source $DATPATH/$graph/$file.metadata

    # For each number of GPUs
    for numgpus in 1 2 4 8; do
        # Print line header
        echo -n "$graph,$numgpus," | tee -a $OUTPATH/table5.csv 
        
        # Run unoptimized
        runavg run_sssp $numgpus $fullpath "$use_metis --opt=false --iteration_fusion=false"
        echo -n "$RUNAVG_RET," | tee -a $OUTPATH/table5.csv
        

        # Run soft-priority scheduler
        runavg run_sssp $numgpus $fullpath "$use_metis --opt=true --iteration_fusion=false --prio_delta=$sssp_prio_delta_softprio"
        echo -n "$RUNAVG_RET," | tee -a $OUTPATH/table5.csv
        
        
        # Run fused soft-priority scheduler
        runavg run_sssp $numgpus $fullpath "$use_metis --opt=true --iteration_fusion=true --prio_delta=$sssp_prio_delta_fused"
        echo "$RUNAVG_RET" | tee -a $OUTPATH/table5.csv
    done
done

echo "==== Done. Table available at output/table5.csv ===="
