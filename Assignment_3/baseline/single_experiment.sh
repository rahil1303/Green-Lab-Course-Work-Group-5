#!/bin/bash

#############################################
# SINGLE EXPERIMENT EXECUTION SCRIPT
# Runs ON LINUX LAPTOP (triggered by Pi via SSH)
# Called with: ./run_single_experiment.sh <subject> <gc> <workload> <jdk> <rep> <run_num>
#############################################

set -e

# Parse arguments
SUBJECT=$1
GC=$2
WORKLOAD=$3
JDK=$4
REP=$5
RUN_NUM=$6

# Configuration
SUBJECTS_DIR="./Subjects"
RESULTS_DIR="./results/run_${RUN_NUM}"
HEAP_MIN="2G"  # Fixed heap (3x live set)
HEAP_MAX="4G"  # Fixed heap (3x live set)
TEMP_THRESHOLD=55
BASELINE_TEMP=45

mkdir -p "$RESULTS_DIR"

echo "════════════════════════════════════════"
echo "RUN #$RUN_NUM"
echo "════════════════════════════════════════"
echo "Subject:   $SUBJECT"
echo "GC:        $GC"
echo "Workload:  $WORKLOAD"
echo "JDK:       $JDK"
echo "Rep:       $REP"
echo "Time:      $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

#############################################
# HELPER FUNCTIONS
#############################################

get_temperature() {
    if command -v sensors &> /dev/null; then
        sensors | grep "Package id 0" | awk '{print $4}' | tr -d '+°C' | head -1
    else
        echo "50"
    fi
}

wait_for_cooldown() {
    echo ""
    echo "─── COOLDOWN (Run $RUN_NUM) ───"
    
    local current_temp=$(get_temperature)
    echo "Current temp: ${current_temp}°C"
    
    if (( $(echo "$current_temp > $TEMP_THRESHOLD" | bc -l) )); then
        echo "⚠ Temp above ${TEMP_THRESHOLD}°C, waiting for cooldown..."
        
        while (( $(echo "$current_temp > $BASELINE_TEMP" | bc -l) )); do
            sleep 30
            current_temp=$(get_temperature)
            echo "  Temp: ${current_temp}°C (target: ${BASELINE_TEMP}°C)"
        done
        echo "✓ Temperature stabilized"
    else
        echo "Standard cooldown: 120s"
        sleep 120
    fi
    echo ""
}

#############################################
# SET JDK
#############################################

if [ "$JDK" == "oracle" ]; then
    export JAVA_HOME="/usr/lib/jvm/jdk-17-oracle-x64"
else
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
fi
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using: $(java -version 2>&1 | head -n 1)"

#############################################
# SET GC FLAG
#############################################

GC_FLAG=""
case $GC in
    "Serial")   GC_FLAG="-XX:+UseSerialGC" ;;
    "Parallel") GC_FLAG="-XX:+UseParallelGC" ;;
    "G1")       GC_FLAG="-XX:+UseG1GC" ;;
esac

echo "GC Flag: $GC_FLAG"

#############################################
# DETERMINE JAR AND ARGS
#############################################

JAR_FILE=""
APP_ARGS=""

case $SUBJECT in
    "DaCapo")
        JAR_FILE="$SUBJECTS_DIR/dacapo.jar"
        case $WORKLOAD in
            "Light")  APP_ARGS="avrora -s small" ;;
            "Medium") APP_ARGS="avrora -s default" ;;
            "Heavy")  APP_ARGS="avrora -s large" ;;
        esac
        ;;
    "CLBG-BinaryTrees")
        JAR_FILE="$SUBJECTS_DIR/binarytrees.jar"
        case $WORKLOAD in
            "Light")  APP_ARGS="14" ;;
            "Medium") APP_ARGS="16" ;;
            "Heavy")  APP_ARGS="18" ;;
        esac
        ;;
    "CLBG-Fannkuch")
        JAR_FILE="$SUBJECTS_DIR/fannkuchredux.jar"
        case $WORKLOAD in
            "Light")  APP_ARGS="10" ;;
            "Medium") APP_ARGS="11" ;;
            "Heavy")  APP_ARGS="12" ;;
        esac
        ;;
    "CLBG-NBody")
        JAR_FILE="$SUBJECTS_DIR/nbody.jar"
        case $WORKLOAD in
            "Light")  APP_ARGS="5000000" ;;
            "Medium") APP_ARGS="25000000" ;;
            "Heavy")  APP_ARGS="50000000" ;;
        esac
        ;;
    "Rosetta")
        JAR_FILE="$SUBJECTS_DIR/fibonacci.jar"
        case $WORKLOAD in
            "Light")  APP_ARGS="35" ;;
            "Medium") APP_ARGS="40" ;;
            "Heavy")  APP_ARGS="42" ;;
        esac
        ;;
    "PetClinic")
        JAR_FILE="$SUBJECTS_DIR/petclinic.jar"
        # TODO: Add workload-specific args
        APP_ARGS=""
        ;;
    "TodoApp")
        JAR_FILE="$SUBJECTS_DIR/todoapp.jar"
        APP_ARGS=""
        ;;
    "ANDIE")
        JAR_FILE="$SUBJECTS_DIR/andie.jar"
        # Run headless with sample image
        APP_ARGS=""
        ;;
esac

if [ ! -f "$JAR_FILE" ]; then
    echo "✗ ERROR: JAR file not found: $JAR_FILE"
    exit 1
fi

#############################################
# RUN WITH ENERGIBRIDGE
#############################################

ENERGY_FILE="$RESULTS_DIR/energy.csv"
STDOUT_FILE="$RESULTS_DIR/stdout.txt"
STDERR_FILE="$RESULTS_DIR/stderr.txt"

echo "Executing: energibridge java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar $JAR_FILE $APP_ARGS"
echo ""

START_TIME=$(date +%s)

if energibridge --summary --output "$ENERGY_FILE" \
    java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar "$JAR_FILE" $APP_ARGS \
    > "$STDOUT_FILE" 2> "$STDERR_FILE"; then
    
    END_TIME=$(date +%s)
    RUNTIME=$((END_TIME - START_TIME))
    
    echo "✓ Run completed successfully"
    echo "  Runtime: ${RUNTIME}s"
    
    # Extract energy from EnergiBridge
    if [ -f "$ENERGY_FILE" ]; then
        ENERGY=$(tail -1 "$ENERGY_FILE" | cut -d',' -f2)
        echo "  Energy: ${ENERGY}J"
        
        # Write result line
        echo "$RUN_NUM,$SUBJECT,$GC,$WORKLOAD,$JDK,$REP,$RUNTIME,$ENERGY,SUCCESS,$(date '+%Y-%m-%d %H:%M:%S')" \
            > "$RESULTS_DIR/result.csv"
    fi
    
    # Cooldown before next run
    wait_for_cooldown
    
    exit 0
else
    echo "✗ Run FAILED"
    echo "  Check: $STDOUT_FILE and $STDERR_FILE"
    
    echo "$RUN_NUM,$SUBJECT,$GC,$WORKLOAD,$JDK,$REP,FAILED,FAILED,FAILED,$(date '+%Y-%m-%d %H:%M:%S')" \
        > "$RESULTS_DIR/result.csv"
    
    exit 1
fi