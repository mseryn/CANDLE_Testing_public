#!/bin/bash

FILENAME_PREFIX=$1
# Note - you must provide the volume to use at the command line
VOLUME=$2

SCRIPTPREFIX=/home/mcorneli/Benchmarks/
INDEX=(0 1 2 3 4 5 6 7)
TESTS=("p1b1" "p1b2" "p1b3" "p2b1" "p3b1" "p3b2" "p3b3" "p3b4")
SCRIPTSUFFIX=("Pilot1/P1B1/p1b1_baseline_keras2.py" "Pilot1/P1B2/p1b2_baseline_keras2.py" "Pilot1/P1B3/p1b3_baseline_keras2.py" "Pilot2/P2B1/p2b1_baseline_keras2.py" "Pilot3/P3B1/p3b1_baseline_keras2.py" "Pilot3/P3B2/p3b2_baseline_keras2.py" "Pilot3/P3B3/p3b3_baseline_keras2.py" "Pilot3/P3B4/p3b4_baseline_keras2.py")

# This is the connection command
kdsa_manage connect $VOLUME xpda

for I in 0 1 2 3 4 5 6 7
do
    for PCSGB in 8 256
    do

        PCS="$((${PCSGB} * 1024 * 1024))"
        FILENAME=${FILENAME_PREFIX}_PCS${PCSGB}_${TESTS[I]}
        SCRIPT=${SCRIPTPREFIX}${SCRIPTSUFFIX[I]}

        PYTHON_COMMAND="python3 $SCRIPT"
        XMEM_COMMAND="/soft/RAN/xmem/current/bin/xmem -t xpda"
        PERF_COMMAND="perf stat -e rff24 -e r3f24 -e cycles,instructions,major-faults,minor-faults,L1-dcache-loads,L1-dcache-stores,L1-dcache-load-misses,LLC-loads,LLC-stores,LLC-load-misses,LLC-store-misses,context-switches,migrations -I 1000 -o ${FILENAME}.perf"

        source activate /projects/RAN/tensorflow_rhel7
        ran_memctl --xmem-max-page-cache-size=$PCS 
        ran_memctl >> "${FILENAME}_info.log"

        echo $COBALT_JOBID > "${FILENAME}_info.log"
        echo $COBALT_JOBID > "${FILENAME}.log"
        echo $COBALT_JOBID > "${FILENAME}.mem"
        echo $COBALT_JOBID > "${FILENAME}.perf"

        $PERF_COMMAND $XMEM_COMMAND $PYTHON_COMMAND | tee "${FILENAME}.log" &

        (
        while pgrep -n -f $SCRIPT > /dev/null
        do
            sleep 1
            echo -n "`date`|"
            cat /proc/`pgrep -n -f $SCRIPT`/status | grep RSS | awk '{print $2}'
        done
        ) > "${FILENAME}.mem"


    done
done

kdsa_manage disconnect xpda
