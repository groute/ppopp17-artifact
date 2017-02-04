#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH

if ! [ -f $AEROOT/setup.complete ]; then
    echo "ERROR: Setup was not run. Please run ./setup.sh"
    exit 1
fi

$AEROOT/figures/figure2.sh  # (will output 4 csvs corresponding to Figures 2a-2d)
$AEROOT/figures/figure10a.sh # (will output csv for BFS)
$AEROOT/figures/figure10b.sh # (will output csv for SSSP)
$AEROOT/figures/figure11.sh # (will output csv for PR)
$AEROOT/figures/figure12.sh # (will output csv for CC)
$AEROOT/figures/table5.sh   # (will output csv for SSSP unopt vs. softprio vs. fused-sp)
$AEROOT/figures/table6.sh   # (will output csv for PBF)
