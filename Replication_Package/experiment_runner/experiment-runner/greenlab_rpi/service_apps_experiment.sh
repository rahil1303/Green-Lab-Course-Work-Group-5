#!/bin/bash

################################################################################
# RAPL Energy Sampler - Simplified (no associative arrays)
################################################################################

# Configuration
SUBJECTS_DIR="/home/vivekbharadwaj99/greenlab-dut/Subjects"
OUTPUT_DIR="/home/vivekbharadwaj99"
RAPL_PATH="/sys/class/powercap/intel-rapl:0/energy_uj"
JVM_WARMUP_DELAY=5
COOLDOWN_TIME=120
INITIAL_COOLDOWN=180

# Timestamp-based unique filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/energy_results_rapl_batch_${TIMESTAMP}.csv"
# OUTPUT_FILE="$OUTPUT_DIR/energy_results_rapl.csv"
RUN_ID=0

log_info() { echo "[INFO] $1"; }
log_success() { echo "✓ $1"; }
log_error() { echo "[ERROR] $1" >&2; }

check_rapl_access() {
    log_info "Checking RAPL access..."
    sudo cat "$RAPL_PATH" > /dev/null 2>&1 && log_success "RAPL accessible" && return 0
    log_error "RAPL not accessible"
    return 1
}

read_rapl_energy() {
    sudo cat "$RAPL_PATH" 2>/dev/null || echo "0"
}

get_jar_path() {
    case $1 in
        "PetClinic") echo "$SUBJECTS_DIR/petclinic.jar" ;;
        "TodoApp")   echo "$SUBJECTS_DIR/todoapp.jar" ;;
        "ANDIE")     echo "$SUBJECTS_DIR/imageapp.jar" ;;
    esac
}

get_jdk_home() {
    case $1 in
        "openjdk") echo "/usr/lib/jvm/java-17-openjdk-amd64" ;;
        "oracle")  echo "/usr/lib/jvm/jdk-17-oracle-x64" ;;
    esac
}

get_gc_flag() {
    case $1 in
        "Serial")   echo "-XX:+UseSerialGC" ;;
        "Parallel") echo "-XX:+UseParallelGC" ;;
        "G1")       echo "-XX:+UseG1GC" ;;
    esac
}

collect_energy_data() {
    local duration_seconds=$1
    local jar_path=$2
    local gc_name=$3
    local jdk_home=$4
    
    local start_time=$(date +%s%N)
    local start_energy=$(read_rapl_energy)
    
    [ "$start_energy" = "0" ] && echo "0|0" && return
    
    local gc_flag=$(get_gc_flag "$gc_name")
    local java_cmd="$jdk_home/bin/java"
    
    log_info "Starting with $gc_name..."
    $java_cmd $gc_flag -jar "$jar_path" > /dev/null 2>&1 &
    local pid=$!
    
    sleep $JVM_WARMUP_DELAY
    sleep $((duration_seconds - JVM_WARMUP_DELAY))
    
    local end_time=$(date +%s%N)
    local end_energy=$(read_rapl_energy)
    
    kill $pid 2>/dev/null || true
    sleep 1
    kill -9 $pid 2>/dev/null || true
    
    [ "$end_energy" = "0" ] && echo "0|0" && return
    
    local delta_energy_uj=$((end_energy - start_energy))
    local delta_energy_j=$(echo "scale=6; $delta_energy_uj / 1000000" | bc)
    local actual_duration=$(echo "scale=2; ($end_time - $start_time) / 1000000000" | bc)
    
    echo "$delta_energy_j|$actual_duration"
}

cooldown() {
    local seconds=$1
    log_info "Cooling down ${seconds}s..."
    sleep $seconds
}

init_csv() {
    echo "run_id,done,subject,gc,workload,jdk,energy_j,runtime_s,status,batch_num" > "$OUTPUT_FILE"
    log_success "CSV initialized"
}

save_result() {
    echo "run_$1,DONE,$2,$3,$4,$5,$6,$7,$8,1" >> "$OUTPUT_FILE"
}

main() {
    echo ""
    echo "================================================================================"
    echo "RAPL Energy Sampler - Service Applications"
    echo "================================================================================"
    echo ""
    
    check_rapl_access || exit 1
    init_csv
    
    log_info "Initial cooldown ${INITIAL_COOLDOWN}s..."
    cooldown $INITIAL_COOLDOWN
    
    local total=54
    local current=0
    
    log_info "Starting 54 tests..."
    echo ""
    
    # Manual loop - no arrays, just explicit iteration
    for subject in PetClinic TodoApp ANDIE; do
        for gc in Serial Parallel G1; do
            for jdk in openjdk oracle; do
                for duration in 2min:120 3min:180 5min:300; do
                    ((current++))
                    ((RUN_ID++))
                    
                    local dur_name="${duration%%:*}"
                    local dur_sec="${duration##*:}"
                    
                    echo "[$current/$total] Run $RUN_ID: $subject | $gc | $jdk | $dur_name"
                    
                    local jar_path=$(get_jar_path "$subject")
                    local jdk_home=$(get_jdk_home "$jdk")
                    
                    if [ ! -f "$jar_path" ]; then
                        log_error "JAR not found: $jar_path"
                        save_result "$RUN_ID" "$subject" "$gc" "$dur_name" "$jdk" "0.0" "0.0" "FAILED"
                        continue
                    fi
                    
                    if [ ! -d "$jdk_home" ]; then
                        log_error "JDK not found: $jdk_home"
                        save_result "$RUN_ID" "$subject" "$gc" "$dur_name" "$jdk" "0.0" "0.0" "FAILED"
                        continue
                    fi
                    
                    local result=$(collect_energy_data "$dur_sec" "$jar_path" "$gc" "$jdk_home")
                    local energy_j="${result%%|*}"
                    local runtime_s="${result##*|}"
                    
                    if [ -z "$energy_j" ] || [ "$energy_j" = "0" ]; then
                        log_error "Collection failed"
                        save_result "$RUN_ID" "$subject" "$gc" "$dur_name" "$jdk" "0.0" "0.0" "FAILED"
                    else
                        log_success "Energy: $energy_j J"
                        save_result "$RUN_ID" "$subject" "$gc" "$dur_name" "$jdk" "$energy_j" "$runtime_s" "SUCCESS"
                    fi
                    
                    [ $current -lt $total ] && cooldown $COOLDOWN_TIME
                done
            done
        done
    done
    
    echo ""
    echo "================================================================================"
    log_success "Complete! Results:"
    cat "$OUTPUT_FILE"
    echo "================================================================================"
}

main "$@"