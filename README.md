Groute: An Asynchronous Multi-GPU Programming Model for Irregular Computations - Paper Artifact
===============================================================================================

This artifact contains all the source code necessary to compile
the Groute executables and repeat the results of the PPoPP 2017 paper with the same title.
The package also contains shell scripts to generate the figures and tables as 
CSVs, obtain code dependencies, and download input graphs for the benchmarks.

Information and sources for input graphs can be found [here](dataset/README.md).

Contents
--------

 * `code`: Folder containing submodules of the Groute code and dependencies.
 * `dataset`: Folder containing graph dataset downloader and metadata for each graph.
 * `figures/common.sh`: Script with default values and common procedures.
 * `figures/figure*.sh`, `figures/table*.sh`: Figure- and table- generating scripts.
 * `setup.sh`: Setup script that obtains and compiles code, as well as downloads
   the graph dataset.
 * `clean.sh`: Resets artifact to original state.
 * `runall.sh`: Measures all figures and tables sequentially.
 * `paper-artifacts.zip`: Results and log files of an artifact run on the 
   HUJI Cortex cluster.

Requirements
------------
 * CMake 3.2 or newer
 * GCC 4.9 or newer
 * CUDA 7.5 or newer

Workflow
--------

1. Clone the repository recursively (including submodules)
2. Set up the environment by running `setup.sh`. This includes obtaining and 
   compiling the code, as well as downloading the graph dataset.
3. Either call `runall.sh` or run individual figures separately by calling
   the scripts in the `figures` subdirectory.
4. Review results in the `output` subdirectory.

A typical shell command workflow may look like this:

```bash
$ git clone --recursive https://github.com/groute/ppopp17-artifact.git
$ cd ppopp17-artifact/
$ ./setup.sh
$ ./runall.sh
$ cat output/figure10b.csv
```

Notes
-----
 * Gunrock execution is not enabled by default. To enable, set the 
   `RUN_GUNROCK` environment variable to 1 (e.g., run `export RUN_GUNROCK=1`).

 * Each individual test may take time, but is limited to
   2 hours to avoid waiting forever for a faulty application. For
   slower GPUs, this timeout can be increased by modifying
   the TIMEOUT variable from 2h to a different value (line 4 in
   `figures/common.sh`).


Manual Setup
------------

The setup script performs the following steps, which can also be performed manually:

   1. Obtains METIS 5.1.0 from http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
   2. Extracts METIS to `code/groute/metis`
   3. Compiles METIS. If successful, creates an empty file in the root directory called `metis.exists`
   4. Compiles MGBench v1.01 and NCCL v1.2.3, creating `mgbench.exists` and `nccl.exists` if successful
   5. Patches Gunrock v0.3.1 to read .gr files and output results, creating `gunrock.patched` on successful
   6. Compiles Gunrock and outputs `gunrock.exists`
   7. Compiles Groute and outputs `groute.exists`
   8. Prompts the user whether to download the dataset, runs `dataset/download.sh`, and creates `dataset.exists`
   9. On successful setup, creates a directory called `output` and an empty file called `setup.complete`

