#!/bin/sh

# Sets up environment for artifact evaluation

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH

echo "==== Groute Artifact Evaluation Cleanup ===="

rm -rf $AEROOT/setup.complete

rm -rf $AEROOT/code/groute/metis
rm -rf $AEROOT/code/mgbench/build
rm -rf $AEROOT/code/nccl/build
rm -rf $AEROOT/code/gunrock
rm -rf $AEROOT/code/groute/build

rm -rf $AEROOT/*.exists
rm -rf $AEROOT/*.patched

rm -rf $AEROOT/figures/*.log
rm -rf $AEROOT/*.log
rm -rf $AEROOT/output/*

echo "==== Cleanup Complete ===="
