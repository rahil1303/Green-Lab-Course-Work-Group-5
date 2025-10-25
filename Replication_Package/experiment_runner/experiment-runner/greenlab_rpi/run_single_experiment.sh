#!/bin/bash

#############################################
# SINGLE EXPERIMENT EXECUTION SCRIPT
# Runs ON LINUX LAPTOP (triggered by Pi via SSH)
# Called with: ./run_single_experiment.sh <subject> <gc> <workload> <jdk> <rep> <run_num>
#############################################

# SINGLE EXPERIMENT EXECUTION SCRIPT
# Usage: ./run_single_experiment.sh <subject> <gc> <workload> <jdk> <rep> <run_num>

set -e

if [ $# -ne 6 ]; then
    echo "Error: Expected 6 arguments"
    echo "Usage: $0 <subject> <gc> <workload> <jdk> <rep> <run_num>"
    exit 1
fi

# --- DRY RUN MODE ---
if [[ "$1" == "--dry" ]]; then
    shift
    if [ $# -eq 0 ]; then
        echo "[DRY RUN] Example usage: ./run_single_experiment.sh <subject> <gc> <workload> <jdk> <rep> <run_num>"
        echo "[DRY RUN] Subjects dir: ./Subjects"
        ls -1 ./Subjects
        exit 0
    elif [ $# -eq 6 ]; then
        SUBJECT=$1; GC=$2; WORKLOAD=$3; JDK=$4; REP=$5; RUN_NUM=$6

        # Fixed heap sizes
        HEAP_MIN="3G"
        HEAP_MAX="3G"

        # Map GC flag
        GC_FLAG=""
        case $GC in
            "Serial")   GC_FLAG="-XX:+UseSerialGC" ;;
            "Parallel") GC_FLAG="-XX:+UseParallelGC" ;;
            "G1")       GC_FLAG="-XX:+UseG1GC" ;;
        esac

        SUBJECTS_DIR="./Subjects"
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
            *)
                echo "[DRY RUN] ✗ ERROR: Unknown subject: $SUBJECT"
                exit 1
                ;;
        esac

        echo "[DRY RUN] Would execute:"
        echo "energibridge --summary --output ./results/run_${RUN_NUM}/energy.csv \\"
        echo "    java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar $JAR_FILE $APP_ARGS"
        exit 0
    else
        echo "[DRY RUN] Error: Expected either no args or 6 args after --dry"
        exit 1
    fi
fi

SUBJECT=$1
GC=$2
WORKLOAD=$3
JDK=$4
REP=$5
RUN_NUM=$6

if [[ "$REP" =~ repetition_([0-9]+)$ ]]; then
    REP="${BASH_REMATCH[1]}"
fi

SUBJECTS_DIR="./Subjects"
RESULTS_DIR="./results/run_${RUN_NUM}"
HEAP_MIN="3G"
HEAP_MAX="3G"
TEMP_THRESHOLD=52
BASELINE_TEMP=48
MAX_TIME=120s
mkdir -p "$RESULTS_DIR"

# Helper functions
cleanup_processes() {
    pkill -f java || true
    pkill -f energibridge || true
}

get_temperature() {
    if command -v vcgencmd &> /dev/null; then
        vcgencmd measure_temp | grep -oE '[0-9.]+'
    elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp
    else
        echo "0"
    fi
}

wait_for_cooldown() {
    while true; do
        TEMP=$(get_temperature)
        if (( $(echo "$TEMP < $TEMP_THRESHOLD" | bc -l) )); then
            echo "Temperature cooled: $TEMP°C"
            break
        else
            echo "Cooling... Current: $TEMP°C (Threshold: $TEMP_THRESHOLD°C)"
            sleep 10
        fi
    done
}

# JDK setup
if [ "$JDK" == "oracle" ]; then
    export JAVA_HOME="/usr/lib/jvm/jdk-17-oracle-x64"
else
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
fi
export PATH="$JAVA_HOME/bin:$PATH"

GC_FLAG=""
case $GC in
    "Serial")   GC_FLAG="-XX:+UseSerialGC" ;;
    "Parallel") GC_FLAG="-XX:+UseParallelGC" ;;
    "G1")       GC_FLAG="-XX:+UseG1GC" ;;
esac

# Determine JAR & Args
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
    *)
        echo "✗ ERROR: Unknown subject: $SUBJECT"
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

# Check if this is a Spring application that needs special handling
# if [[ "$SUBJECT" == "PetClinic" || "$SUBJECT" == "TodoApp" || "$SUBJECT" == "ANDIE" ]]; then
#     echo "Detected Spring application - measuring startup energy"
    
#     # Start energibridge in background
#     sudo energibridge --summary --output "$ENERGY_FILE" &
#     ENERGY_PID=$!
#     sleep 1  # Give energibridge time to start
    
#     # Start the Spring app in background
#     java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar "$JAR_FILE" $APP_ARGS \
#         > "$STDOUT_FILE" 2> "$STDERR_FILE" &
#     JAVA_PID=$!
    
#     # Wait for Spring Boot to be ready (parse logs for startup message)
#     STARTUP_TIMEOUT=60
#     ELAPSED=0
#     while [ $ELAPSED -lt $STARTUP_TIMEOUT ]; do
#         if grep -q "Started" "$STDOUT_FILE"; then
#             echo "✓ Spring Boot application started successfully"
#             sleep 2  # Brief pause to capture steady-state
#             break
#         fi
#         sleep 1
#         ELAPSED=$((ELAPSED + 1))
#     done

# Check if this is a Spring application that needs special handling
# if [[ "$SUBJECT" == "PetClinic" || "$SUBJECT" == "TodoApp" || "$SUBJECT" == "ANDIE" ]]; then
#     echo "Detected Spring application - measuring startup energy"

#     # Ensure output directory exists
#     mkdir -p "$RESULTS_DIR"

#     # Run EnergiBridge by directly wrapping the Java process
#     echo "Starting EnergiBridge and Java application..."
#     sudo energibridge --summary --output "$ENERGY_FILE" \
#         java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar "$JAR_FILE" $APP_ARGS \
#         > "$STDOUT_FILE" 2> "$STDERR_FILE"

#     # EnergiBridge returns automatically after Java finishes
#     echo "✓ Spring Boot application run complete"

#     # Give EnergiBridge a few seconds to finalize the energy file
#     sleep 10

#     END_TIME=$(date +%s.%N 2>/dev/null || date +%s)
#     RUNTIME_SUCCESS=true
    
#     # Stop both processes
#     # kill $JAVA_PID 2>/dev/null || true
#     # sudo kill $ENERGY_PID 2>/dev/null || true
#     # wait $JAVA_PID 2>/dev/null || true
#     # wait $ENERGY_PID 2>/dev/null || true
#     echo "Stopping processes (allowing EnergiBridge to flush)..."

#     # Gracefully terminate the Spring Boot app first
#     kill -TERM $JAVA_PID 2>/dev/null || true

#     # Give EnergiBridge a generous window to write the summary
#     sleep 10

#     # Now gently terminate EnergiBridge
#     kill -TERM $ENERGY_PID 2>/dev/null || true

#     # Wait to ensure both have finished
#     sleep 2
#     wait $JAVA_PID 2>/dev/null || true
#     wait $ENERGY_PID 2>/dev/null || true
    
#     END_TIME=$(date +%s.%N 2>/dev/null || date +%s)
    
#     # Check if startup was successful
#     if [ $ELAPSED -ge $STARTUP_TIMEOUT ]; then
#         echo "⚠ Spring app startup timeout"
#         RUNTIME=$ELAPSED
#         echo "$RUN_NUM,$SUBJECT,$GC,$WORKLOAD,$JDK,$REP,TIMEOUT,TIMEOUT,TIMEOUT,$(date '+%Y-%m-%d %H:%M:%S')" \
#             > "$RESULTS_DIR/result.csv"
#         wait_for_cooldown
#         exit 1
#     else
#         # Success case
#         RUNTIME_SUCCESS=true
#     fi
    
# else
    # Original behavior for benchmark JARs remains unchanged
if sudo timeout --preserve-status -k 10s $MAX_TIME \
    energibridge --summary --output "$ENERGY_FILE" \
    java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar "$JAR_FILE" $APP_ARGS \
    > "$STDOUT_FILE" 2> "$STDERR_FILE"; then
    
    END_TIME=$(date +%s.%N 2>/dev/null || date +%s)
    RUNTIME_SUCCESS=true
else
    EXIT_CODE=$?
    END_TIME=$(date +%s.%N 2>/dev/null || date +%s)
    RUNTIME_SUCCESS=false
    STORED_EXIT_CODE=$EXIT_CODE
fi
# fi

# Common success/failure handling
if [[ "$RUNTIME_SUCCESS" == "true" ]]; then
    # Calculate runtime
    if [[ $START_TIME == *.* ]] && [[ $END_TIME == *.* ]]; then
        RUNTIME=$(awk "BEGIN {print $END_TIME - $START_TIME}")
    else
        RUNTIME=$((END_TIME - START_TIME))
    fi
    
    echo "✓ Run completed successfully"
    echo "  Runtime: ${RUNTIME}s"
    
    # Extract energy from EnergiBridge with validation
    if [ -f "$ENERGY_FILE" ]; then
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
    # Use stored exit code if available
    if [ -z "$STORED_EXIT_CODE" ]; then
        EXIT_CODE=$?
    else
        EXIT_CODE=$STORED_EXIT_CODE
    fi
    
    if [ $EXIT_CODE -eq 124 ]; then
        echo "⚠ Run killed after reaching timeout (${MAX_TIME}s)"
        STATUS="TIMEOUT"
    else
        echo "✗ Run FAILED (exit code: $EXIT_CODE)"
        echo "  Check: $STDOUT_FILE and $STDERR_FILE"
        STATUS="FAILED_$EXIT_CODE"
    fi

    # Try to capture any partial output
    if [ -f "$STDERR_FILE" ]; then
        echo "  Error preview:"
        head -5 "$STDERR_FILE" | sed 's/^/    /'
    fi

    echo "$RUN_NUM,$SUBJECT,$GC,$WORKLOAD,$JDK,$REP,FAILED,FAILED,$STATUS,$(date '+%Y-%m-%d %H:%M:%S')" \
        > "$RESULTS_DIR/result.csv"

    # Still cooldown even after failure/timeout
    wait_for_cooldown

    exit 1
fi