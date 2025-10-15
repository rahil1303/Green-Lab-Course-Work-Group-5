#!/usr/bin/env bash
# SANITY CHECK MODE: one quick run per subject under EnergiBridge
# Purpose: verify that all JARs, JVMs, and energy logging work end-to-end.

set -euo pipefail

# -----------------------------------------
# GLOBAL CONFIGURATION
# -----------------------------------------
SUBJECTS_DIR="./Subjects"
RESULTS_DIR="./results_sanity"
HEAP_MIN="1G"
HEAP_MAX="2G"
DEFAULT_GC="G1"
DEFAULT_WORKLOAD="Light"
DEFAULT_JDK="openjdk"
DEFAULT_REP=1
ENERGI_DURATION=5       # seconds, short sample for verification
SLEEP_BETWEEN=10        # short gap between runs

mkdir -p "$RESULTS_DIR"

# -----------------------------------------
# SUBJECT LIST
# -----------------------------------------
SUBJECTS=(
  "DaCapo"
  "CLBG-BinaryTrees"
  "CLBG-Fannkuch"
  "CLBG-NBody"
  "Rosetta"
  "PetClinic"
  "TodoApp"
  "ANDIE"
)

# -----------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------
run_subject() {
    local SUBJECT=$1
    local RUN_NUM=$2

    echo ""
    echo "════════════════════════════════════════"
    echo "SANITY RUN #$RUN_NUM  →  $SUBJECT"
    echo "════════════════════════════════════════"

    # --- Select JDK ---
    if [ "$DEFAULT_JDK" == "oracle" ]; then
        export JAVA_HOME="/usr/lib/jvm/jdk-17-oracle-x64"
    else
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
    fi
    export PATH="$JAVA_HOME/bin:$PATH"

    # --- GC Flag ---
    GC_FLAG="-XX:+Use${DEFAULT_GC}GC"

    # --- Subject-specific jar & args ---
    local JAR_FILE=""
    local APP_ARGS=""
    case $SUBJECT in
        "DaCapo")           JAR_FILE="$SUBJECTS_DIR/dacapo.jar";         APP_ARGS="avrora -s small" ;;
        "CLBG-BinaryTrees") JAR_FILE="$SUBJECTS_DIR/binarytrees.jar";    APP_ARGS="14" ;;
        "CLBG-Fannkuch")    JAR_FILE="$SUBJECTS_DIR/fannkuchredux.jar";  APP_ARGS="10" ;;
        "CLBG-NBody")       JAR_FILE="$SUBJECTS_DIR/nbody.jar";          APP_ARGS="5000000" ;;
        "Rosetta")          JAR_FILE="$SUBJECTS_DIR/fibonacci.jar";      APP_ARGS="35" ;;
        "PetClinic")        JAR_FILE="$SUBJECTS_DIR/petclinic.jar";      APP_ARGS="" ;;
        "TodoApp")          JAR_FILE="$SUBJECTS_DIR/todoapp.jar";        APP_ARGS="" ;;
        "ANDIE")            JAR_FILE="$SUBJECTS_DIR/andie.jar";          APP_ARGS="" ;;
    esac

    if [ ! -f "$JAR_FILE" ]; then
        echo "✗ Missing JAR: $JAR_FILE"
        return 1
    fi

    local RUN_DIR="$RESULTS_DIR/run_${RUN_NUM}"
    mkdir -p "$RUN_DIR"
    local ENERGY_FILE="$RUN_DIR/energy.csv"
    local STDOUT_FILE="$RUN_DIR/stdout.txt"
    local STDERR_FILE="$RUN_DIR/stderr.txt"

    echo "Executing: energibridge (5 s) → java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar $JAR_FILE $APP_ARGS"
    echo ""

    local START=$(date +%s)
    if timeout ${ENERGI_DURATION}s energibridge --summary --output "$ENERGY_FILE" \
        java $GC_FLAG -Xms$HEAP_MIN -Xmx$HEAP_MAX -jar "$JAR_FILE" $APP_ARGS \
        >"$STDOUT_FILE" 2>"$STDERR_FILE"; then
        local END=$(date +%s)
        local RUNTIME=$((END - START))
        local ENERGY="NA"
        if [ -f "$ENERGY_FILE" ]; then
            ENERGY=$(tail -1 "$ENERGY_FILE" | cut -d',' -f2)
        fi
        echo "✓ $SUBJECT succeeded  (${RUNTIME}s, Energy=${ENERGY}J)"
        echo "$RUN_NUM,$SUBJECT,$DEFAULT_GC,$DEFAULT_WORKLOAD,$DEFAULT_JDK,$DEFAULT_REP,$RUNTIME,$ENERGY,SUCCESS,$(date '+%Y-%m-%d %H:%M:%S')" \
            >"$RUN_DIR/result.csv"
    else
        echo "✗ $SUBJECT failed (see $STDERR_FILE)"
        echo "$RUN_NUM,$SUBJECT,$DEFAULT_GC,$DEFAULT_WORKLOAD,$DEFAULT_JDK,$DEFAULT_REP,FAILED,FAILED,FAILED,$(date '+%Y-%m-%d %H:%M:%S')" \
            >"$RUN_DIR/result.csv"
    fi

    echo "Sleeping ${SLEEP_BETWEEN}s before next subject..."
    sleep "${SLEEP_BETWEEN}"
}

# -----------------------------------------
# MAIN LOOP
# -----------------------------------------
RUN_COUNTER=1
PASS=0
FAIL=0

for SUBJECT in "${SUBJECTS[@]}"; do
    if run_subject "$SUBJECT" "$RUN_COUNTER"; then
        ((PASS++))
    else
        ((FAIL++))
    fi
    ((RUN_COUNTER++))
done

echo ""
echo "════════════════════════════════════════"
echo " SANITY SUMMARY"
echo "════════════════════════════════════════"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""
if (( FAIL == 0 )); then
    echo "✅ All subjects executed successfully under EnergiBridge."
else
    echo "⚠ Some subjects failed; inspect results_sanity folders."
fi
