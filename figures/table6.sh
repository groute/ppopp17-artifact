#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..
OUTPATH=$AEROOT/output
DATPATH=$AEROOT/dataset

source $AEROOT/figures/common.sh

echo "==== Groute: Table 6 ===="

# Requirements
require groute

# Runs on at least 2 GPUs
if [ $NUMGPUS -lt 2 ]; then
    echo "==== ERROR: This test requires at least 2 GPUs ===="
    exit 1
fi

# Clean output
rm -f $OUTPATH/table6.csv

PBF=$AEROOT/code/groute/build/pbf

#########################################
echo "==== For best results, run on a system with heterogeneous GPUs ===="

echo "Scheduler,GPU 1 Processed Elements,GPU 2 Processed Elements,Total Time (ms)" | tee -a $OUTPATH/table6.csv

OUTPUT=`$PBF --num_gpus=2 --startwith=2 --pipeline=13 | tee /tmp/pbfout.txt | tee -a groute-pbf.log`
gtime=`grep '<filter>' /tmp/pbfout.txt | cut -f2 -d' '`
gone=`grep 'GPU0' /tmp/pbfout.txt | cut -f3 -d' ' | cut -f1 -d,`
gtwo=`grep 'GPU1' /tmp/pbfout.txt | cut -f3 -d' ' | cut -f1 -d,`
echo "Static,$gone,$gtwo,$gtime" | tee -a $OUTPATH/table6.csv

OUTPUT=`$PBF --num_gpus=2 --startwith=2 --pipeline=2 | tee /tmp/pbfout.txt | tee -a groute-pbf.log`
gtime=`grep '<filter>' /tmp/pbfout.txt | cut -f2 -d' '`
gone=`grep 'GPU0' /tmp/pbfout.txt | cut -f3 -d' ' | cut -f1 -d,`
gtwo=`grep 'GPU1' /tmp/pbfout.txt | cut -f3 -d' ' | cut -f1 -d,`
echo "Groute,$gone,$gtwo,$gtime" | tee -a $OUTPATH/table6.csv


echo "==== Done. Table available at output/table6.csv ===="

