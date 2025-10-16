#!/bin/bash

#############################################
# SINGLE EXPERIMENT EXECUTION SCRIPT
# Runs ON LINUX LAPTOP (triggered by Pi via SSH)
# Called with: ./run_single_experiment.sh <subject> <gc> <workload> <jdk> <rep> <run_num>
#############################################

set -e

# Validate arguments
if [ $# -ne 6 ]; then
    echo "Error: Expected 6 arguments"
    echo "Usage: $0 <subject> <gc> <workload> <jdk> <rep> <run_num>"
    exit 1
fi

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
HEAP_MIN="3G"  # Fixed heap (3x live set as per report)
HEAP_MAX="3G"  # Fixed heap (3x live set as per report)
TEMP_THRESHOLD=52  # Aligned with report (50°C ± 2°C)
BASELINE_TEMP=48   # Target cooldown temp (50°C - 2°C)

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

cleanup_processes() {
    # Kill any lingering Java processes from previous runs
    pkill -f "java.*${SUBJECT}" 2>/dev/null || true
    sleep 2
}

get_temperature() {
    if command -v sensors &> /dev/null; then
        local temp=$(sensors | grep -E "Package id 0:|Core 0:" | head -1 | grep -oP '\+\K[0-9.]+' | head -1)
        if [ -z "$temp" ]; then
            echo "50"  # Default if can't read
        else
            # Return integer part only to avoid float comparison issues
            echo "${temp%%.*}"
        fi
    else
        echo "50"  # Default if sensors not available
    fi
}

wait_for_cooldown() {
    echo ""
    echo "─── COOLDOWN (Run $RUN_NUM) ───"
    
    local current_temp=$(get_temperature)
    echo "Current temp: ${current_temp}°C"
    
    # Use integer comparison (temperature is already integer from get_temperature)
    if [ "$current_temp" -gt "$TEMP_THRESHOLD" ]; then
        echo "⚠ Temp above ${TEMP_THRESHOLD}°C, waiting for cooldown..."
        
        while [ "$current_temp" -gt "$BASELINE_TEMP" ]; do
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
# VALIDATE INPUTS
#############################################

# Validate GC
if [[ ! "$GC" =~ ^(Serial|Parallel|G1)$ ]]; then
    echo "✗ ERROR: Invalid GC: $GC (must be Serial, Parallel, or G1)"
    exit 1
fi

# Validate Workload
if [[ ! "$WORKLOAD" =~ ^(Light|Medium|Heavy)$ ]]; then
    echo "✗ ERROR: Invalid Workload: $WORKLOAD (must be Light, Medium, or Heavy)"
    exit 1
fi

# Validate JDK
if [[ ! "$JDK" =~ ^(oracle|openjdk)$ ]]; then
    echo "✗ ERROR: Invalid JDK: $JDK (must be oracle or openjdk)"
    exit 1
fi

#############################################
# SET JDK
#############################################

if [ "$JDK" == "oracle" ]; then
    export JAVA_HOME="/usr/lib/jvm/jdk-17-oracle-x64"
else
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
fi

if [ ! -d "$JAVA_HOME" ]; then
    echo "✗ ERROR: JAVA_HOME not found: $JAVA_HOME"
    exit 1
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
        case $WORKLOAD in
            "Light")  APP_ARGS="--test.iterations=100" ;;
            "Medium") APP_ARGS="--test.iterations=500" ;;
            "Heavy")  APP_ARGS="--test.iterations=1000" ;;
        esac
        ;;
    *)
        echo "✗ ERROR: Unknown subject: $SUBJECT"
        echo "Valid subjects: DaCapo, CLBG-BinaryTrees, CLBG-Fannkuch, CLBG-NBody, Rosetta, PetClinic"
        exit 1
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
METADATA_FILE="$RESULTS_DIR/metadata.json"

# Save metadata for this run
cat > "$METADATA_FILE" <<EOF
{
  "run_num": $RUN_NUM,
  "subject": "$SUBJECT",
  "gc": "$GC",
  "workload": "$WORKLOAD",
  "jdk": "$JDK",
  "replication": $REP,
  "heap_min": "$HEAP_MIN",
  "heap_max": "$HEAP_MAX",
  "start_time": "$(date -Iseconds)",
  "start_temp": "$(get_temperature)"
}
EOF

echo "Executing: energibridge --summary --output \"$ENERGY_FILE\""
echo "          java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar \"$JAR_FILE\" $APP_ARGS"
echo ""

# Clean up any lingering processes
cleanup_processes

# Record start temperature
START_TEMP=$(get_temperature)
echo "Start temperature: ${START_TEMP}°C"

START_TIME=$(date +%s.%N 2>/dev/null || date +%s)

if energibridge --summary --output "$ENERGY_FILE" \
    java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar "$JAR_FILE" $APP_ARGS \
    > "$STDOUT_FILE" 2> "$STDERR_FILE"; then
    
    END_TIME=$(date +%s.%N 2>/dev/null || date +%s)
    
    # Calculate runtime (handle both GNU date with nanoseconds and BSD date without)
    if [[ $START_TIME == *.* ]] && [[ $END_TIME == *.* ]]; then
        # Have nanosecond precision
        RUNTIME=$(awk "BEGIN {print $END_TIME - $START_TIME}")
    else
        # Only second precision
        RUNTIME=$((END_TIME - START_TIME))
    fi
    
    echo "✓ Run completed successfully"
    echo "  Runtime: ${RUNTIME}s"
    
    # Extract energy from EnergiBridge with validation
    if [ -f "$ENERGY_FILE" ]; then
        # Check if file has content
        if [ -s "$ENERGY_FILE" ]; then
            ENERGY=$(tail -1 "$ENERGY_FILE" | cut -d',' -f2)
            if [ -z "$ENERGY" ]; then
                echo "  ⚠ Warning: Could not extract energy value"
                ENERGY="ERROR"
            else
                echo "  Energy: ${ENERGY}J"
            fi
        else
            echo "  ⚠ Warning: Energy file is empty"
            ENERGY="EMPTY"
        fi
    else
        echo "  ⚠ Warning: Energy file not created"
        ENERGY="MISSING"
    fi
    
    # Write result line
    echo "$RUN_NUM,$SUBJECT,$GC,$WORKLOAD,$JDK,$REP,$RUNTIME,$ENERGY,SUCCESS,$(date '+%Y-%m-%d %H:%M:%S')" \
        > "$RESULTS_DIR/result.csv"
    
    # Cooldown before next run
    wait_for_cooldown
    
    exit 0
else
    EXIT_CODE=$?
    echo "✗ Run FAILED (exit code: $EXIT_CODE)"
    echo "  Check: $STDOUT_FILE and $STDERR_FILE"
    
    # Try to capture any partial output
    if [ -f "$STDERR_FILE" ]; then
        echo "  Error preview:"
        head -5 "$STDERR_FILE" | sed 's/^/    /'
    fi
    
    echo "$RUN_NUM,$SUBJECT,$GC,$WORKLOAD,$JDK,$REP,FAILED,FAILED,FAILED_$EXIT_CODE,$(date '+%Y-%m-%d %H:%M:%S')" \
        > "$RESULTS_DIR/result.csv"
    
    # Still cooldown even after failure
    wait_for_cooldown
    
    exit 1
fi
