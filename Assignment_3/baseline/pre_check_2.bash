#!/usr/bin/env bash
# PRE-CHECK SCRIPT FOR LINUX LAPTOP (DUT)

set -euo pipefail

echo "╔════════════════════════════════════════╗"
echo "║  PRE-CHECK: LINUX LAPTOP (DUT)        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0

check_pass(){ echo -e "${GREEN}✓${NC} $1"; ((PASS++)); }
check_fail(){ echo -e "${RED}✗${NC} $1"; ((FAIL++)); }
check_warn(){ echo -e "${YELLOW}⚠${NC} $1"; }

echo "════════════════════════════════════════"
echo "1. SYSTEM ENVIRONMENT"
echo "════════════════════════════════════════"

if [[ "${OSTYPE:-}" == linux* ]]; then
  check_pass "Running on Linux"
else
  check_fail "NOT running on Linux (detected: ${OSTYPE:-unknown})"
fi

KERNEL=$(uname -r || true); echo "  Kernel: ${KERNEL}"

CPU_VENDOR=$(LC_ALL=C lscpu 2>/dev/null | awk -F: '/Vendor ID|Model name/{print $2}' | tr -s ' ')
echo "  CPU: ${CPU_VENDOR:-unknown}"
if ! [[ "${CPU_VENDOR}" =~ Intel|GenuineIntel ]]; then
  check_warn "Non-Intel CPU detected; RAPL availability may differ"
fi

echo ""
echo "════════════════════════════════════════"
echo "2. JAVA INSTALLATION"
echo "════════════════════════════════════════"

if command -v java >/dev/null 2>&1; then
  JAVA_LINE=$(java -version 2>&1 | head -n1)
  echo "  Java: ${JAVA_LINE}"
  if java -version 2>&1 | grep -Eq '"17\.|11\.'; then
    check_pass "Java 11/17 detected"
  else
    check_warn "Java version not 11/17; ensure OpenJDK 17 & Oracle JDK 17 are available"
  fi
  if [[ -z "${JAVA_HOME:-}" ]]; then
    check_warn "JAVA_HOME not set (not fatal, but recommended)"
  fi
else
  check_fail "Java not found in PATH"
fi

echo ""
echo "════════════════════════════════════════"
echo "3. RAPL COUNTERS"
echo "════════════════════════════════════════"

if [[ -d /sys/class/powercap/intel-rapl ]]; then
  check_pass "RAPL interface directory present"
  echo "  RAPL domains:"
  for d in /sys/class/powercap/intel-rapl/intel-rapl:*; do
    [[ -f "$d/name" ]] && echo "    - $(<"$d/name")"
  done
  if [[ -r /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj ]]; then
    check_pass "Can read RAPL counters"
  else
    check_fail "Cannot read RAPL counters as current user"
    echo "    Fix (preferred): sudo setcap cap_sys_rawio,cap_dac_read_search+ep \"$(command -v energibridge || echo /usr/bin/energibridge)\""
    echo "    Or create a udev rule to relax powercap permissions and add your user to the group."
  fi
else
  check_fail "RAPL interface not found (Intel CPU/driver required)"
fi

echo ""
echo "════════════════════════════════════════"
echo "4. ENERGIBRIDGE"
echo "════════════════════════════════════════"

if command -v energibridge >/dev/null 2>&1; then
  check_pass "EnergiBridge found ($(energibridge --version 2>/dev/null || echo version-unknown))"
  echo "  Testing EnergiBridge (5s idle sample)..."
  TMP_OUT="$(mktemp /tmp/eb_test.XXXXXX.csv)"
  if timeout 6s energibridge --duration 5 --output "$TMP_OUT" >/dev/null 2>&1; then
    if [[ -s "$TMP_OUT" ]] && [[ $(wc -l < "$TMP_OUT") -ge 2 ]]; then
      check_pass "EnergiBridge test produced CSV (${TMP_OUT})"
      rm -f "$TMP_OUT"
    else
      check_fail "EnergiBridge ran but CSV is empty/unexpected"
    fi
  else
    check_fail "EnergiBridge test failed (exit != 0)"
  fi
else
  check_fail "EnergiBridge not found"
  echo "    Install from: https://github.com/S2-group/energibridge"
fi

echo ""
echo "════════════════════════════════════════"
echo "5. TEMPERATURE MONITORING"
echo "════════════════════════════════════════"

if command -v sensors >/dev/null 2>&1; then
  check_pass "lm-sensors installed"
  RAW_SENSORS="$(sensors 2>/dev/null || true)"
  echo "$RAW_SENSORS" > /tmp/sensors_dump.txt
  # Try multiple labels; pick first Celsius numeric
  TEMP_C=$(awk '
    match($0, /\+?([0-9]+(\.[0-9]+)?)°C/, m){ print m[1]; exit }
  ' /tmp/sensors_dump.txt)
  if [[ -n "${TEMP_C:-}" ]]; then
    echo "  Current CPU temp: ${TEMP_C}°C"
    # Use bc if present, else integer compare
    if command -v bc >/dev/null 2>&1; then
      if (( $(echo "${TEMP_C} < 50.0" | bc -l) )); then
        check_pass "Temperature below 50°C"
      else
        check_warn "Temperature ≥ 50°C — let system cool before starting"
      fi
    else
      check_warn "bc not installed; skipping precise temp threshold check"
    fi
  else
    check_warn "Could not parse CPU temperature from sensors output"
  fi
else
  check_fail "lm-sensors not installed"
  echo "    Fix: sudo apt-get install -y lm-sensors && sudo sensors-detect"
fi

echo ""
echo "════════════════════════════════════════"
echo "6. CPU CONFIGURATION"
echo "════════════════════════════════════════"

# Governor (policy directories are more portable than cpu0)
GOV_PATH=$(ls /sys/devices/system/cpu/cpufreq/policy*/scaling_governor 2>/dev/null | head -n1 || true)
if [[ -n "${GOV_PATH}" ]]; then
  GOVERNOR=$(<"${GOV_PATH}")
  echo "  CPU Governor: ${GOVERNOR}"
  if [[ "${GOVERNOR}" == "performance" ]]; then
    check_pass "Governor set to 'performance'"
  else
    check_warn "Governor is '${GOVERNOR}' (recommended: 'performance')"
    if command -v cpupower >/dev/null 2>&1; then
      echo "    Fix: sudo cpupower frequency-set -g performance"
    else
      echo "    Fix: sudo apt-get install -y linux-tools-common linux-tools-$(uname -r) && sudo cpupower frequency-set -g performance"
    fi
  fi
fi

# Turbo / boost
if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
  TURBO=$(</sys/devices/system/cpu/intel_pstate/no_turbo)
  [[ "${TURBO}" == "1" ]] && check_pass "Intel Turbo Boost disabled" || \
    { check_warn "Intel Turbo Boost enabled (recommended disabled)"; echo "    Fix: echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo"; }
elif [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
  BOOST=$(</sys/devices/system/cpu/cpufreq/boost)
  [[ "${BOOST}" == "0" ]] && check_pass "CPU boost disabled" || \
    { check_warn "CPU boost enabled (recommended disabled)"; echo "    Fix: echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost"; }
else
  check_warn "No turbo/boost control file found; skip"
fi

echo ""
echo "════════════════════════════════════════"
echo "7. SSH ACCESS (Pi → DUT)"
echo "════════════════════════════════════════"

if systemctl is-active --quiet ssh; then
  check_pass "sshd running"
else
  check_fail "sshd not running"
  echo "    Fix: sudo systemctl enable --now ssh"
fi

if [[ -f "$HOME/.ssh/authorized_keys" ]]; then
  check_pass "~/.ssh/authorized_keys present (Pi can be added here)"
else
  check_warn "No ~/.ssh/authorized_keys; add Raspberry Pi public key for passwordless access"
fi

echo ""
echo "════════════════════════════════════════"
echo "8. EXPERIMENT FILES"
echo "════════════════════════════════════════"

SUBJECTS_DIR="./Subjects"
if [[ -d "${SUBJECTS_DIR}" ]]; then
  check_pass "Subjects directory exists (${SUBJECTS_DIR})"
  declare -a REQUIRED_PATTERNS=(
    "dacapo-*.jar"            # DaCapo suite JAR
    "binary*trees*.jar"       # CLBG / microbench variants
    "fannkuch*redux*.jar"
    "nbody*.jar"
    "spring-petclinic-*.jar"  # PetClinic typical artifact
    "todo*.jar"               # REST todo service
    "andie*.jar"              # ANDIE image tool
  )
  for pat in "${REQUIRED_PATTERNS[@]}"; do
    if compgen -G "${SUBJECTS_DIR}/${pat}" > /dev/null; then
      check_pass "Found ${pat}"
    else
      check_fail "Missing ${pat} in ${SUBJECTS_DIR}"
    fi
  done
else
  check_fail "Subjects directory not found (${SUBJECTS_DIR})"
fi

if [[ -f "./run_single_experiment.sh" ]]; then
  check_pass "Execution script found (run_single_experiment.sh)"
else
  check_warn "run_single_experiment.sh not found in CWD"
fi

echo ""
echo "════════════════════════════════════════"
echo "9. BASELINE MEASUREMENTS"
echo "════════════════════════════════════════"

mkdir -p ./baseline_readings
if command -v sensors >/dev/null 2>&1; then
  sensors > ./baseline_readings/temperature_idle.txt || true
  check_pass "Baseline temperature recorded"
fi
if command -v top >/dev/null 2>&1; then
  top -bn1 | head -20 > ./baseline_readings/cpu_idle.txt || true
  check_pass "Baseline CPU load recorded"
fi
if command -v energibridge >/dev/null 2>&1; then
  echo "  Recording 10s idle RAPL..."
  if energibridge --duration 10 --output ./baseline_readings/rapl_idle.csv >/dev/null 2>&1; then
    check_pass "Baseline RAPL recorded"
  else
    check_warn "EnergiBridge baseline failed (permissions or driver?)"
  fi
fi

echo ""
echo "════════════════════════════════════════"
echo "SUMMARY"
echo "════════════════════════════════════════"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}✓ LAPTOP READY FOR EXPERIMENTS!${NC}"
  echo "Next: Configure Raspberry Pi and start experiments"
  exit 0
else
  echo -e "${RED}✗ FIX ISSUES BEFORE RUNNING EXPERIMENTS${NC}"
  exit 1
fi
