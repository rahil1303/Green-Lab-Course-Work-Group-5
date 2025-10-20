#!/usr/bin/env python3
"""
RAPL-based energy sampler for Java applications (PetClinic, TodoApp, ANDIE).
Collects energy for 2, 3, and 5 minute durations across multiple GC strategies and JDKs.
Outputs results in tabular CSV format compatible with Green Lab experiment results.
"""

import subprocess
import time
import os
import csv
import sys
from datetime import datetime
from pathlib import Path

# Configuration
SUBJECTS_DIR = "/home/vivekbharadwaj99/greenlab-dut/Subjects"
OUTPUT_DIR = "/home/vivekbharadwaj99"  # Main directory for results
RAPL_PATH = "/sys/class/powercap/intel-rapl:0/energy_uj"
JVM_WARMUP_DELAY = 5  # Seconds to wait for JVM startup
COOLDOWN_TIME = 150  # 2.5 minutes cooldown between runs
INITIAL_COOLDOWN = 180  # 3 minutes initial cooldown

# Experiment factors
JARS = {
    "PetClinic": "petclinic.jar",
    "TodoApp": "todo-app.jar",
    "ANDIE": "imageapp.jar"
}

GCS = ["Serial", "Parallel", "G1"]
GC_FLAGS = {
    "Serial": "-XX:+UseSerialGC",
    "Parallel": "-XX:+UseParallelGC",
    "G1": "-XX:+UseG1GC"
}

JDKS = ["openjdk", "oracle"]  # Will use java command; adjust if multiple JDK versions installed
DURATIONS = {
    "2min": 120,
    "3min": 180,
    "5min": 300
}

class RAPLEnergySampler:
    def __init__(self, output_dir):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.run_id = 0
        self.results = []
        
    def check_rapl_access(self):
        """Verify RAPL is accessible via sudo."""
        try:
            result = subprocess.run(
                ["sudo", "cat", RAPL_PATH],
                capture_output=True,
                timeout=5
            )
            if result.returncode == 0:
                print("✓ RAPL accessible")
                return True
            else:
                print("✗ RAPL not accessible (permission denied)")
                return False
        except Exception as e:
            print(f"✗ RAPL check failed: {e}")
            return False
    
    def read_rapl_energy(self):
        """Read current RAPL energy counter in microjoules."""
        try:
            result = subprocess.run(
                ["sudo", "cat", RAPL_PATH],
                capture_output=True,
                timeout=5,
                text=True
            )
            if result.returncode == 0:
                return int(result.stdout.strip())
            return None
        except Exception as e:
            print(f"Error reading RAPL: {e}")
            return None
    
    def start_java_app(self, jar_path, gc_name, jdk_name):
        """Start Java application with specified GC and JDK."""
        gc_flag = GC_FLAGS[gc_name]
        try:
            cmd = ["java", gc_flag, "-jar", jar_path]
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return proc
        except Exception as e:
            print(f"Error starting Java app: {e}")
            return None
    
    def collect_energy_data(self, duration_seconds, jar_path, gc_name, jdk_name):
        """Collect RAPL energy for specified duration and return total energy consumed."""
        start_time = time.time()
        start_energy = self.read_rapl_energy()
        
        if start_energy is None:
            return None, None
        
        proc = self.start_java_app(jar_path, gc_name, jdk_name)
        if proc is None:
            return None, None
        
        print(f"  App started (PID: {proc.pid}), waiting {JVM_WARMUP_DELAY}s for JVM warmup...")
        time.sleep(JVM_WARMUP_DELAY)
        
        print(f"  Collecting energy for {duration_seconds}s...")
        time.sleep(duration_seconds - JVM_WARMUP_DELAY)
        
        end_time = time.time()
        end_energy = self.read_rapl_energy()
        
        # Terminate the process
        try:
            proc.terminate()
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
        
        if end_energy is None:
            return None, None
        
        actual_duration = end_time - start_time
        delta_energy_uj = end_energy - start_energy
        delta_energy_j = delta_energy_uj / 1_000_000
        
        return delta_energy_j, actual_duration
    
    def cooldown(self, seconds):
        """Wait for system to cool down between runs."""
        print(f"  Cooling down for {seconds}s...")
        for i in range(seconds, 0, -1):
            if i % 30 == 0:
                print(f"    {i}s remaining...")
            time.sleep(1)
    
    def run_experiment(self):
        """Execute full experimental loop."""
        print("\n" + "="*70)
        print("RAPL Energy Sampler - Multi-JAR Experiment")
        print("="*70)
        
        # Check RAPL access
        if not self.check_rapl_access():
            print("Cannot proceed without RAPL access. Exiting.")
            return
        
        print(f"Initial system cooldown for {INITIAL_COOLDOWN}s...")
        self.cooldown(INITIAL_COOLDOWN)
        
        total_tests = len(JARS) * len(GCS) * len(JDKS) * len(DURATIONS)
        current_test = 0
        
        for subject, jar_filename in JARS.items():
            jar_path = os.path.join(SUBJECTS_DIR, jar_filename)
            
            if not os.path.exists(jar_path):
                print(f"⚠ JAR not found: {jar_path}")
                continue
            
            for gc_name in GCS:
                for jdk_name in JDKS:
                    for duration_name, duration_sec in DURATIONS.items():
                        current_test += 1
                        self.run_id += 1
                        
                        print(f"\n[{current_test}/{total_tests}] Run {self.run_id}")
                        print(f"  Subject: {subject} | GC: {gc_name} | JDK: {jdk_name} | Duration: {duration_name}")
                        
                        energy_j, runtime_s = self.collect_energy_data(
                            duration_sec, jar_path, gc_name, jdk_name
                        )
                        
                        if energy_j is not None:
                            status = "SUCCESS"
                            print(f"  ✓ Energy: {energy_j:.6f} J | Runtime: {runtime_s:.2f}s")
                        else:
                            energy_j = 0.0
                            runtime_s = 0.0
                            status = "FAILED"
                            print(f"  ✗ Energy collection failed")
                        
                        self.results.append({
                            "run_id": f"run_{self.run_id}",
                            "done": "DONE",
                            "subject": subject,
                            "gc": gc_name,
                            "workload": duration_name,
                            "jdk": jdk_name,
                            "energy_j": energy_j,
                            "runtime_s": runtime_s,
                            "status": status,
                            "batch_num": 1,
                            "timestamp": datetime.now().isoformat()
                        })
                        
                        # Cooldown between runs
                        if current_test < total_tests:
                            self.cooldown(COOLDOWN_TIME)
        
        # Save results
        self.save_results()
        print("\n" + "="*70)
        print("Experiment completed!")
        print("="*70)
    
    def save_results(self):
        """Save results to CSV file."""
        output_file = self.output_dir / "energy_results.csv"
        
        if not self.results:
            print("No results to save.")
            return
        
        fieldnames = [
            "run_id", "done", "subject", "gc", "workload", "jdk",
            "energy_j", "runtime_s", "status", "batch_num", "timestamp"
        ]
        
        try:
            with open(output_file, mode='w', newline='') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(self.results)
            print(f"\n✓ Results saved to: {output_file}")
        except Exception as e:
            print(f"\n✗ Error saving results: {e}")

if __name__ == "__main__":
    sampler = RAPLEnergySampler(OUTPUT_DIR)
    sampler.run_experiment()
