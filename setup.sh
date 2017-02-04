#!/bin/sh

# Sets up environment for artifact evaluation

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH

echo "==== Groute Artifact Evaluation Setup ===="

################################################
# DEPENDENCIES

echo "==== Downloading Dependencies ===="

# Download METIS
cd $AEROOT/code/groute
while [ 1 ]; do
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 --continue http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz && break
    sleep 1s;
done;

# Extract METIS
tar xf metis-5.1.0.tar.gz
mv metis-5.1.0 metis
rm -f metis-5.1.0.tar.gz

# Switch METIS to 64-bit mode
sed -i 's/IDXTYPEWIDTH 32/IDXTYPEWIDTH 64/g' metis/include/metis.h

# Build METIS
echo "==== Building METIS ===="
cd $AEROOT/code/groute/metis
make config BUILDDIR=build
cd build && make -j8 && echo "1" >> $AEROOT/metis.exists

cd $AEROOT/code

# Download Gunrock v0.3.1 and patch it to read binary (Galois) graph formats
read -p "Would you like to measure Gunrock as well? (Requires Boost) [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Checkout Gunrock v0.3.1
    git clone --recursive https://github.com/gunrock/gunrock.git
    cd gunrock && git checkout v0.3.1 && cd ..

    # Make sure that METIS exists
    if [ -f $AEROOT/metis.exists ]; then
        cd $AEROOT/code/gunrock
        
        # Copy metis.h to Gunrock
        cp $AEROOT/code/groute/metis/include/metis.h .

        # Patch Gunrock
        if ! [ -f $AEROOT/gunrock.patched ]; then
            patch -p1 < $AEROOT/code/gunrock-ggr.patch && patch -p1 < $AEROOT/code/gunrock-output.patch && echo "1" >> $AEROOT/gunrock.patched
        else
            echo "Gunrock already patched"
        fi
        
        # Build Gunrock and tell the system that Gunrock was downloaded and compiled successfully
        echo "==== Building Gunrock ===="
        mkdir build
        cd build && cmake -DMETIS_LIBRARY=$AEROOT/code/groute/metis/build/libmetis/libmetis.a .. && make -j8 breadth_first_search single_source_shortest_path pagerank connected_component && echo "1" >> $AEROOT/gunrock.exists
    else
        echo "Cannot build Gunrock, METIS was not built successfully"
    fi
fi

# Build MGBench
echo "==== Building MGBench ===="
cd $AEROOT/code/mgbench
mkdir build
cd build && cmake .. && make -j8 && echo "1" >> $AEROOT/mgbench.exists

# Build NCCL
echo "==== Building NCCL ===="
cd $AEROOT/code/nccl
make -j8 test && cd .. && echo "1" >> $AEROOT/nccl.exists


echo "==== Building Dependencies Complete ===="
cd ..

################################################
# BUILD PROJECT

echo "==== Building Groute ===="

cd $AEROOT/code/groute
mkdir build
cd build && cmake .. && make -j8 && echo "1" >> $AEROOT/groute.exists

echo "==== Build Complete ===="

################################################
# DATASETS

cd $AEROOT/dataset

# Download dataset
read -p "Would you like to download the dataset (10.6 GB) now? (Requires at least 35 GB. Download later by running ./dataset/download.sh) [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./download.sh
fi

cd ..

################################################

mkdir output

echo "1" >> $AEROOT/setup.complete

echo "==== Setup complete. Run all benchmarks using ./runall.sh or individually using the scripts in ./figures/ ===="
