#!/bin/bash

#############################################
# PRE-CHECK SCRIPT FOR LINUX LAPTOP (DUT)
# Run this ON THE LAPTOP before experiments
# Validates system is ready for measurements
#############################################

set -e

echo "╔════════════════════════════════════════╗"
echo "║  PRE-CHECK: LINUX LAPTOP (DUT)        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "════════════════════════════════════════"
echo "1. SYSTEM ENVIRONMENT"
echo "════════════════════════════════════════"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    check_pass "Running on Linux"
else
    check_fail "NOT running on Linux (detected: $OSTYPE)"
fi

KERNEL=$(uname -r)
echo "  Kernel: $KERNEL"

echo ""
echo "════════════════════════════════════════"
echo "2. JAVA INSTALLATION"
echo "════════════════════════════════════════"

if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "  Java: $JAVA_VERSION"
    
    if [[ $JAVA_VERSION == *"17"* ]] || [[ $JAVA_VERSION == *"11"* ]]; then
        check_pass "Java installed"
    else
        check_warn "Java version might not be 11/17"
    fi
else
    check_fail "Java not found in PATH"
fi

echo ""
echo "════════════════════════════════════════"
echo "3. RAPL COUNTERS"
echo "════════════════════════════════════════"

if [ -d "/sys/class/powercap/intel-rapl" ]; then
    check_pass "RAPL interface found"
    
    echo "  Available RAPL domains:"
    for domain in /sys/class/powercap/intel-rapl/intel-rapl:*; do
        if [ -f "$domain/name" ]; then
            name=$(cat "$domain/name")
            echo "    - $name"
        fi
    done
    
    if [ -r "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj" ]; then
        check_pass "Can read RAPL counters"
    else
        check_fail "Cannot read RAPL counters (permission issue?)"
        echo "    Fix: sudo chmod -R 755 /sys/class/powercap/intel-rapl"
    fi
else
    check_fail "RAPL interface not found (Intel CPU required)"
fi

echo ""
echo "════════════════════════════════════════"
echo "4. ENERGIBRIDGE"
echo "════════════════════════════════════════"

if command -v energibridge &> /dev/null; then
    check_pass "EnergiBridge installed"
    
    echo "  Testing EnergiBridge (5 second sample)..."
    if timeout 6s energibridge --duration 5 --output /tmp/eb_test.csv 2>&1 | grep -q "Measurement"; then
        check_pass "EnergiBridge test successful"
        rm -f /tmp/eb_test.csv
    else
        check_fail "EnergiBridge test failed"
    fi
else
    check_fail "EnergiBridge not found"
    echo "    Install from: https://github.com/S2-group/energibridge"
fi

echo ""
echo "════════════════════════════════════════"
echo "5. TEMPERATURE MONITORING"
echo "════════════════════════════════════════"

if command -v sensors &> /dev/null; then
    check_pass "lm-sensors installed"
    
    if sensors | grep -q "Package id 0"; then
        TEMP=$(sensors | grep "Package id 0" | awk '{print $4}' | tr -d '+°C')
        echo "  Current CPU temp: ${TEMP}°C"
        
        if (( $(echo "$TEMP < 50" | bc -l) )); then
            check_pass "Temperature below 50°C"
        else
            check_warn "Temperature above 50°C - let system cool"
        fi
    fi
else
    check_fail "lm-sensors not installed"
    echo "    Fix: sudo apt install lm-sensors && sudo sensors-detect"
fi

echo ""
echo "════════════════════════════════════════"
echo "6. CPU CONFIGURATION"
echo "════════════════════════════════════════"

if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    echo "  CPU Governor: $GOVERNOR"
    
    if [ "$GOVERNOR" == "performance" ]; then
        check_pass "Governor set to 'performance'"
    else
        check_warn "Governor is '$GOVERNOR' (should be 'performance')"
        echo "    Fix: sudo cpupower frequency-set -g performance"
    fi
fi

if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
    TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
    if [ "$TURBO" == "1" ]; then
        check_pass "Turbo Boost disabled"
    else
        check_warn "Turbo Boost enabled (should be disabled)"
        echo "    Fix: echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo"
    fi
fi

echo ""
echo "════════════════════════════════════════"
echo "7. SSH ACCESS (for Raspberry Pi)"
echo "════════════════════════════════════════"

if systemctl is-active --quiet ssh; then
    check_pass "SSH daemon running"
else
    check_fail "SSH daemon not running"
    echo "    Fix: sudo systemctl start ssh && sudo systemctl enable ssh"
fi

if [ -f "$HOME/.ssh/authorized_keys" ]; then
    check_pass "SSH authorized_keys exists"
else
    check_warn "No authorized_keys found"
    echo "    Add Raspberry Pi public key to ~/.ssh/authorized_keys"
fi

echo ""
echo "════════════════════════════════════════"
echo "8. EXPERIMENT FILES"
echo "════════════════════════════════════════"

SUBJECTS_DIR="./Subjects"
if [ -d "$SUBJECTS_DIR" ]; then
    check_pass "Subjects directory exists"
    
    declare -a REQUIRED_JARS=(
        "dacapo.jar"
        "binarytrees.jar"
        "fannkuchredux.jar"
        "nbody.jar"
        "fibonacci.jar"
        "petclinic.jar"
        "todoapp.jar"
        "andie.jar"
    )
    
    for jar in "${REQUIRED_JARS[@]}"; do
        if [ -f "$SUBJECTS_DIR/$jar" ]; then
            check_pass "Found $jar"
        else
            check_fail "Missing $jar"
        fi
    done
else
    check_fail "Subjects directory not found"
fi

# Check for run script
if [ -f "./run_single_experiment.sh" ]; then
    check_pass "Execution script found"
else
    check_warn "run_single_experiment.sh not found"
fi

echo ""
echo "════════════════════════════════════════"
echo "9. BASELINE MEASUREMENTS"
echo "════════════════════════════════════════"

echo "Taking 10-second baseline..."
mkdir -p ./baseline_readings

if command -v sensors &> /dev/null; then
    sensors > ./baseline_readings/temperature_idle.txt
    check_pass "Baseline temperature recorded"
fi

top -bn1 | head -20 > ./baseline_readings/cpu_idle.txt
check_pass "Baseline CPU load recorded"

if command -v energibridge &> /dev/null; then
    echo "  Recording 10s idle RAPL..."
    energibridge --duration 10 --output ./baseline_readings/rapl_idle.csv &> /dev/null
    check_pass "Baseline RAPL recorded"
fi

echo ""
echo "════════════════════════════════════════"
echo "SUMMARY"
echo "════════════════════════════════════════"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ LAPTOP READY FOR EXPERIMENTS!${NC}"
    echo ""
    echo "Next: Configure Raspberry Pi and start experiments"
    exit 0
else
    echo -e "${RED}✗ FIX ISSUES BEFORE RUNNING EXPERIMENTS${NC}"
    exit 1
fi