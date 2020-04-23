#!/bin/bash

FILENAME_PREFIX=$1

# TODO modify this to point to your ALCF home directory with the CANDLE benchmark suite
SCRIPTPREFIX=/home/mcorneli/Benchmarks/
# Index controls how many repititions of each test are completed
# Note - this currently isn't used
INDEX=(0 1 2 3 4 5 6 7)
# Tests are the named prefix for tests -- it's shorter/simpler than the full pathname for file-naming purposes
TESTS=("p1b1" "p1b2" "p1b3" "p2b1" "p3b1" "p3b2" "p3b3" "p3b4")
# Each above test should have an associated path to an actual python file to run
SCRIPTSUFFIX=("Pilot1/P1B1/p1b1_baseline_keras2.py" "Pilot1/P1B2/p1b2_baseline_keras2.py" "Pilot1/P1B3/p1b3_baseline_keras2.py" "Pilot2/P2B1/p2b1_baseline_keras2.py" "Pilot3/P3B1/p3b1_baseline_keras2.py" "Pilot3/P3B2/p3b2_baseline_keras2.py" "Pilot3/P3B3/p3b3_baseline_keras2.py" "Pilot3/P3B4/p3b4_baseline_keras2.py")


# This is where repititions are *actually* controlled
for i in 0 1 2 3 4 5 6 7
do
    FILENAME=${FILENAME_PREFIX}_local_${TESTS[i]}
    SCRIPT=${SCRIPTPREFIX}${SCRIPTSUFFIX[i]}
    PYTHON_COMMAND="python3 $SCRIPT"

    # Do not modify this -- this is what collects the PERF information
    PERF_COMMAND="perf stat -e rff24 -e r3f24 -e cycles,instructions,major-faults,minor-faults,L1-dcache-loads,L1-dcache-stores,L1-dcache-load-misses,LLC-loads,LLC-stores,LLC-load-misses,LLC-store-misses,context-switches,migrations -I 1000 -o ${FILENAME}.perf"

    # This activates our shared Tensorflow environment
    source activate /projects/RAN/tensorflow_rhel7

    # This prints the jobid to all files - do not remove this step, it gets highly confusing without this
    echo $COBALT_JOBID > "${FILENAME}_info.log"
    echo $COBALT_JOBID > "${FILENAME}.log"
    echo $COBALT_JOBID > "${FILENAME}.mem"
    echo $COBALT_JOBID > "${FILENAME}.perf"

    # This is what we actually run
    $PERF_COMMAND $PYTHON_COMMAND | tee "${FILENAME}.log" &

    # This collects per-second memory-in-use data
    (
    while pgrep -n -f $SCRIPT > /dev/null
    do
        sleep 1
        echo -n "`date`|"
        cat /proc/`pgrep -n -f $SCRIPT`/status | grep RSS | awk '{print $2}'
    done
    # This pipes all the measured memory stats to a file
    ) >> "${FILENAME}.mem"

done

