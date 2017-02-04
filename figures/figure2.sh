#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..
OUTPATH=$AEROOT/output


source $AEROOT/figures/common.sh

echo "==== Groute: Figure 2 ===="

# Requirements
require mgbench
require nccl

# Test binaries
UVATEST=$AEROOT/code/mgbench/build/uva
PEERCOPYTEST=$AEROOT/code/mgbench/build/halfduplex
FRAG=$AEROOT/code/mgbench/build/halfduplex
BCAST=$AEROOT/code/mgbench/build/scatter
NCCLBCAST=$AEROOT/code/nccl/build/test/single/broadcast_test

# Set LD_LIBRARY_PATH for NCCL
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$AEROOT/code/nccl/build/lib

# Function that runs NCCL with specific parameters and returns the performance
nccl_bcast() {  
    RET=`$NCCLBCAST 104857600 $@ | grep --color=none -A1 busbw | tail -n 1 | awk '{print $5}'`
}
nccl_transfer() {  
    RET=`$NCCLBCAST 104857600 $@ | grep --color=none -A1 busbw | tail -n 1 | awk '{print $6*1000}'`
}

# Clean outputs
rm -f $OUTPATH/figure2a.csv
rm -f $OUTPATH/figure2b.csv
rm -f $OUTPATH/figure2c.csv
rm -f $OUTPATH/figure2d.csv


##########################################
# Figure 2a: Direct Memory Access Order

echo "==== Groute: Figure 2a ===="

echo "Type,Coalesced Access Rate (MB/s),Random Access Rate (MB/s)" | tee -a $OUTPATH/figure2a.csv

# Host-Device
coalesced=`$UVATEST --from=0 --to=1 | grep --color=none ms | cut -f7 -d' '`
random=`$UVATEST --from=0 --to=1 --random | grep --color=none ms | cut -f7 -d' '`
echo "Host to Device,${coalesced},${random}" | tee -a $OUTPATH/figure2a.csv

# Adjacent GPUs (on same board in paper)
if [ $NUMGPUS -ge 2 ]; then
    coalesced=`$UVATEST --from=1 --to=2 | grep --color=none ms | cut -f8 -d' '`
    random=`$UVATEST --from=1 --to=2 --random | grep --color=none ms | cut -f8 -d' '`

    # Only if UVA is enabled
    if ! [ "x$coalesced" = "x" ]; then
        echo "Same Board,${coalesced},${random}" | tee -a $OUTPATH/figure2a.csv
    fi
fi

# Direct-access non-adjacent GPUs (different boards, on same CPU in paper)
if [ $NUMGPUS -ge 3 ]; then
    coalesced=`$UVATEST --from=1 --to=3 | grep --color=none ms | cut -f8 -d' '`
    random=`$UVATEST --from=1 --to=3 --random | grep --color=none ms | cut -f8 -d' '`

    # Only if UVA is enabled
    if ! [ "x$coalesced" = "x" ]; then
        echo "Direct,${coalesced},${random}" | tee -a $OUTPATH/figure2a.csv
    fi
fi





if [ $NUMGPUS -lt 2 ]; then
    echo "==== The rest of this test requires at least 2 GPUs ===="
    echo "==== Done. Figure available at output/figure2a.csv ===="
    exit 1
fi




##########################################
# Figure 2b: Packetization Overhead

echo "==== Groute: Figure 2b ===="

echo "Type,Packet Size (bytes),Time (ms)" | tee -a $OUTPATH/figure2b.csv

# Test one packet size and configuration
runone() {
    TITLE=$1
    TO=$2
    CHUNKSIZE=$3
    RES=`$FRAG --from=1 --to=$TO --chunksize=$CHUNKSIZE | grep --color=none ms | cut -f10 -d' ' | cut -f2 -d'('`
    echo "$TITLE,$CHUNKSIZE,$RES" | tee -a $OUTPATH/figure2b.csv
}

# Run all packet sizes
runto() {
    TITLE=$1
    TO=$2
    runone $TITLE $TO 0
    runone $TITLE $TO 1024
    runone $TITLE $TO 10240
    runone $TITLE $TO 102400
    runone $TITLE $TO 1048576
    runone $TITLE $TO 10485760
    runone $TITLE $TO 104857600
}

# Run both direct and indirect copies (recommended on a machine with multiple GPUs and CPUs)
runto "Direct" 2
runto "Indirect" $LASTGPU



##########################################
# Figure 2c: Packetized Transfer Rate

echo "==== Groute: Figure 2c ===="

echo "Transfer Type,Direct Rate (MB/s),Indirect Rate (MB/s)" | tee -a $OUTPATH/figure2c.csv

# Test regular peer transfer
direct=`$PEERCOPYTEST --from=1 --to=2 | grep --color=none ms | cut -f8 -d' '`
indirect=`$PEERCOPYTEST --from=1 --to=$NUMGPUS | grep --color=none ms | cut -f8 -d' '`
echo "Peer Transfer,$direct,$indirect" | tee -a $OUTPATH/figure2c.csv

# Test packetized peer transfer (2 MB fragments)
direct=`$FRAG --from=1 --to=2 --chunksize=2097152 | grep --color=none ms | cut -f8 -d' '`
indirect=`$FRAG --from=1 --to=$NUMGPUS --chunksize=2097152 | grep --color=none ms | cut -f8 -d' '`
echo "Pkt. Peer Transfer,$direct,$indirect" | tee -a $OUTPATH/figure2c.csv

# Test packetized Direct Access (using NCCL)
runavg nccl_transfer 2 0 1
direct=$RUNAVG_RET
runavg nccl_transfer 2 0 $LASTGPU
indirect=$RUNAVG_RET

echo "Pkt. DA,$direct,$indirect" | tee -a $OUTPATH/figure2c.csv


##########################################
# Figure 2d: Peer Broadcast Performance

echo "==== Groute: Figure 2d ===="

echo "Broadcast Type,Runtime (ms)" | tee -a $OUTPATH/figure2d.csv

# Find maximal broadcast time
result=`$BCAST --source=0 | grep -A1 --color=none Scatter | tail -n 1 | cut -c6- | sed 's/, /\n/g' | sort -n | tail -n 1`
echo "One-to-All,$result" | tee -a $OUTPATH/figure2d.csv

# Peer transfer ring
result=`$BCAST --source=0 --ring | grep --color=none ms | cut -f9 -d' ' | cut -c2-`
echo "Peer Transfer Ring,$result" | tee -a $OUTPATH/figure2d.csv

# Packetized peer transfer ring
result=`$BCAST --source=0 --ring --chunksize=2097152 | grep --color=none ms | cut -f9 -d' ' | cut -c2-`
echo "Packetized Peer Transfer Ring,$result" | tee -a $OUTPATH/figure2d.csv

# DA ring
runavg nccl_bcast
result=$RUNAVG_RET
echo "DA Ring,$result" | tee -a $OUTPATH/figure2d.csv

echo "==== Done. Figures available at output/figure2{a,b,c,d}.csv ===="
