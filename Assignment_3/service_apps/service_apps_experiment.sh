#!/bin/bash

################################################################################
# RAPL Energy Sampler for Java Applications (Service Apps Only)
# Collects energy for PetClinic, TodoApp, ANDIE across GC strategies, JDKs, durations
# Outputs results in CSV format matching Green Lab experiment table
# NOTE: Uses RAPL directly (no EnergiBridge) - for service apps running idle
################################################################################

set -e

# Configuration
SUBJECTS_DIR="/home/vivekbharadwaj99/greenlab-dut/Subjects"
OUTPUT_DIR="/home/vivekbharadwaj99"
RAPL_PATH="/sys/class/powercap/intel-rapl:0/energy_uj"
JVM_WARMUP_DELAY=5
COOLDOWN_TIME=150
INITIAL_COOLDOWN=180

# JDK paths (from your existing script)
declare -A JDK_HOMES=(
    [openjdk]="/usr/lib/jvm/java-17-openjdk-amd64"
    [oracle]="/usr/lib/jvm/jdk-17-oracle-x64"
)

# Service applications (idle workload)
declare -A JARS=(
    [PetClinic]="petclinic.jar"
    [TodoApp]="todoapp.jar"
    [ANDIE]="imageapp.jar"
)

GCS=("Serial" "Parallel" "G1")
declare -A GC_FLAGS=(
    [Serial]="-XX:+UseSerialGC"
    [Parallel]="-XX:+UseParallelGC"
    [G1]="-XX:+UseG1GC"
)

JDKS=("openjdk" "oracle")
DURATIONS=("2min:120" "3min:180" "5min:300")

# Output CSV file
OUTPUT_FILE="$OUTPUT_DIR/energy_results_rapl.csv"
RUN_ID=0

################################################################################
# Functions
################################################################################

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_success() {
    echo "✓ $1"
}

log_warn() {
    echo "⚠ $1"
}

check_rapl_access() {
    log_info "Checking RAPL access..."
    if sudo cat "$RAPL_PATH" > /dev/null 2>&1; then
        log_success "RAPL accessible"
        return 0
    else
        log_error "RAPL not accessible (permission denied)"
        return 1
    fi
}

read_rapl_energy() {
    sudo cat "$RAPL_PATH" 2>/dev/null || echo "0"
}

start_java_app() {
    local jar_path=$1
    local gc_name=$2
    local jdk_home=$3
    local gc_flag=${GC_FLAGS[$gc_name]}
    
    # Use the specific JDK
    local java_cmd="$jdk_home/bin/java"
    
    $java_cmd $gc_flag -jar "$jar_path" > /dev/null 2>&1 &
    echo $!
}

collect_energy_data() {
    local duration_seconds=$1
    local jar_path=$2
    local gc_name=$3
    local jdk_home=$4
    
    local start_time=$(date +%s%N)
    local start_energy=$(read_rapl_energy)
    
    if [ "$start_energy" = "0" ]; then
        log_error "Failed to read initial RAPL value"
        echo "0|0"
        return
    fi
    
    # Start Java app
    log_info "Starting Java app with $gc_name GC from $(basename $jdk_home)..."
    local pid=$(start_java_app "$jar_path" "$gc_name" "$jdk_home")
    
    if ! kill -0 $pid 2>/dev/null; then
        log_error "Failed to start Java process"
        echo "0|0"
        return
    fi
    
    log_info "App started (PID: $pid), waiting ${JVM_WARMUP_DELAY}s for JVM warmup..."
    sleep $JVM_WARMUP_DELAY
    
    # Collect energy for the specified duration
    log_info "Collecting energy for ${duration_seconds}s..."
    sleep $((duration_seconds - JVM_WARMUP_DELAY))
    
    local end_time=$(date +%s%N)
    local end_energy=$(read_rapl_energy)
    
    # Kill process gracefully
    if kill -0 $pid 2>/dev/null; then
        kill $pid 2>/dev/null || true
        sleep 2
        kill -9 $pid 2>/dev/null || true
    fi
    
    if [ "$end_energy" = "0" ]; then
        log_error "Failed to read final RAPL value"
        echo "0|0"
        return
    fi
    
    # Calculate energy consumed
    local delta_energy_uj=$((end_energy - start_energy))
    local delta_energy_j=$(echo "scale=6; $delta_energy_uj / 1000000" | bc)
    local actual_duration=$(echo "scale=2; ($end_time - $start_time) / 1000000000" | bc)
    
    echo "$delta_energy_j|$actual_duration"
}

cooldown() {
    local seconds=$1
    log_info "Cooling down for ${seconds}s..."
    for ((i=seconds; i>0; i--)); do
        if ((i % 30 == 0)); then
            echo "    ${i}s remaining..."
        fi
        sleep 1
    done
}

init_csv() {
    echo "run_id,done,subject,gc,workload,jdk,energy_j,runtime_s,status,batch_num" > "$OUTPUT_FILE"
    log_success "CSV initialized: $OUTPUT_FILE"
}

save_result() {
    local run_id=$1
    local subject=$2
    local gc=$3
    local workload=$4
    local jdk=$5
    local energy_j=$6
    local runtime_s=$7
    local status=$8
    
    echo "run_$run_id,DONE,$subject,$gc,$workload,$jdk,$energy_j,$runtime_s,$status,1" >> "$OUTPUT_FILE"
}

################################################################################
# Main Experiment Loop
################################################################################

main() {
    echo ""
    echo "================================================================================"
    echo "RAPL Energy Sampler - Service Applications (PetClinic, TodoApp, ANDIE)"
    echo "================================================================================"
    echo "Testing: 2min, 3min, 5min idle durations"
    echo "GCs: Serial, Parallel, G1"
    echo "JDKs: OpenJDK 17, Oracle JDK 17"
    echo ""
    
    # Check RAPL access
    if ! check_rapl_access; then
        log_error "Cannot proceed without RAPL access. Exiting."
        exit 1
    fi
    
    # Verify JDK installations
    log_info "Verifying JDK installations..."
    for jdk_name in "${JDKS[@]}"; do
        local jdk_home=${JDK_HOMES[$jdk_name]}
        local java_cmd="$jdk_home/bin/java"
        if [ ! -f "$java_cmd" ]; then
            log_error "JDK not found: $java_cmd"
            exit 1
        fi
        log_success "$jdk_name JDK found at $jdk_home"
    done
    
    # Verify JAR files
    log_info "Verifying JAR files..."
    for subject in "${!JARS[@]}"; do
        local jar_filename=${JARS[$subject]}
        local jar_path="$SUBJECTS_DIR/$jar_filename"
        if [ ! -f "$jar_path" ]; then
            log_error "JAR not found: $jar_path"
            exit 1
        fi
        log_success "$subject JAR found"
    done
    
    # Initialize CSV
    init_csv
    
    # Initial system cooldown
    log_info "Initial system cooldown for ${INITIAL_COOLDOWN}s..."
    cooldown $INITIAL_COOLDOWN
    
    # Calculate total tests
    local num_jars=${#JARS[@]}
    local num_gcs=${#GCS[@]}
    local num_jdks=${#JDKS[@]}
    local num_durations=${#DURATIONS[@]}
    local total_tests=$((num_jars * num_gcs * num_jdks * num_durations))
    local current_test=0
    
    log_info "Total tests to run: $total_tests"
    echo ""
    
    # Main loop
    for subject in "${!JARS[@]}"; do
        local jar_filename=${JARS[$subject]}
        local jar_path="$SUBJECTS_DIR/$jar_filename"
        
        for gc_name in "${GCS[@]}"; do
            for jdk_name in "${JDKS[@]}"; do
                local jdk_home=${JDK_HOMES[$jdk_name]}
                
                for duration_spec in "${DURATIONS[@]}"; do
                    IFS=':' read -r duration_name duration_sec <<< "$duration_spec"
                    
                    ((current_test++))
                    ((RUN_ID++))
                    
                    echo ""
                    echo "[$current_test/$total_tests] Run $RUN_ID"
                    echo "  Subject: $subject | GC: $gc_name | JDK: $jdk_name | Duration: $duration_name"
                    
                    # Collect energy
                    local result=$(collect_energy_data "$duration_sec" "$jar_path" "$gc_name" "$jdk_home" || echo "0|0")
                    IFS='|' read -r energy_j runtime_s <<< "$result"
                    
                    if [ -z "$energy_j" ] || [ "$energy_j" = "0" ]; then
                        energy_j="0.000000"
                        runtime_s="0.00"
                        local status="FAILED"
                        log_error "Energy collection failed"
                    else
                        local status="SUCCESS"
                        log_success "Energy: ${energy_j} J | Runtime: ${runtime_s}s"
                    fi
                    
                    # Save result
                    save_result "$RUN_ID" "$subject" "$gc_name" "$duration_name" "$jdk_name" "$energy_j" "$runtime_s" "$status"
                    
                    # Cooldown between runs
                    if [ $current_test -lt $total_tests ]; then
                        cooldown $COOLDOWN_TIME
                    fi
                done
            done
        done
    done
    
    echo ""
    echo "================================================================================"
    log_success "Experiment completed!"
    echo "Results saved to: $OUTPUT_FILE"
    echo "================================================================================"
    echo ""
    echo "Summary:"
    tail -n +2 "$OUTPUT_FILE" | awk -F',' '{print $3, $4, $5, $6, $7 " J"}' | sort | uniq -c
}

# Run main
main "$@"
