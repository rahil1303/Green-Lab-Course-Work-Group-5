#!/usr/bin/env python3
"""
Energy measurement wrapper for Java GC experiments.
Integrates mock energy interface with ExperimentRunner framework.
"""

import os
import sys
import subprocess
import time
import csv
import random
from pathlib import Path
from typing import List, Dict, Any


class GCEnergyWrapper:
    """
    Wrapper class that provides energy measurement for Java GC experiments.
    Handles both mock mode (for development) and real mode (for actual measurements).
    """
    
    def __init__(self, mock_mode: bool = None):
        """
        Initialize energy measurement wrapper.
        
        Args:
            mock_mode: If None, determined by ENERGY_MOCK_MODE environment variable
        """
        if mock_mode is None:
            mock_mode = os.getenv('ENERGY_MOCK_MODE', 'false').lower() == 'true'
        
        self.mock_mode = mock_mode
        self.setup_random_seed()
        
        print(f"GCEnergyWrapper initialized - Mock mode: {self.mock_mode}")
    
    def setup_random_seed(self, seed: int = 42):
        """Set random seed for reproducible mock results during development."""
        random.seed(seed)
    
    def validate_setup(self) -> bool:
        """
        Validate that energy measurement system is properly configured.
        
        Returns:
            True if setup is valid, False otherwise
        """
        if self.mock_mode:
            return self._validate_mock_setup()
        else:
            return self._validate_real_setup()
    
    def measure_command(self, command: List[str], output_file: str) -> int:
        """
        Execute command with energy measurement.
        
        Args:
            command: Command to execute as list of strings
            output_file: Path where energy measurement CSV should be written
            
        Returns:
            Exit code of executed command
        """
        if self.mock_mode:
            return self._mock_measure_command(command, output_file)
        else:
            return self._real_measure_command(command, output_file)
    
    def parse_energy_result(self, csv_file: str) -> float:
        """
        Extract energy value from measurement CSV file.
        
        Args:
            csv_file: Path to energy measurement CSV file
            
        Returns:
            Energy consumption in joules
        """
        try:
            with open(csv_file, 'r') as f:
                reader = csv.DictReader(f)
                row = next(reader)
                return float(row['energy_joules'])
        except Exception as e:
            print(f"Error parsing energy result from {csv_file}: {e}")
            return 0.0
    
    def _validate_mock_setup(self) -> bool:
        """Validate mock mode setup."""
        try:
            # Test Java execution
            result = subprocess.run(['java', '-version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                print("Mock validation failed: Java not accessible")
                return False
            
            print("Mock mode validation successful")
            return True
            
        except Exception as e:
            print(f"Mock validation error: {e}")
            return False
    
    def _validate_real_setup(self) -> bool:
        """Validate real RAPL measurement setup."""
        try:
            # Check if energibridge is available
            result = subprocess.run(['energibridge', '-h'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                print("Real mode validation failed: EnergiBridge not accessible")
                return False
            
            # Check RAPL access (Linux-specific)
            rapl_path = Path('/sys/class/powercap/intel-rapl')
            if not rapl_path.exists():
                print("Warning: RAPL interface not found, may need elevated permissions")
            
            print("Real mode validation successful")
            return True
            
        except Exception as e:
            print(f"Real mode validation error: {e}")
            return False
    
    def _mock_measure_command(self, command: List[str], output_file: str) -> int:
        """Execute command with mock energy measurement."""
        print(f"MOCK: Executing {' '.join(command)}")
        
        # Run actual command to get real execution time and behavior
        start_time = time.time()
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=300)
            execution_time = time.time() - start_time
            exit_code = result.returncode
            
            if exit_code != 0:
                print(f"MOCK: Command failed with exit code {exit_code}")
                print(f"MOCK: stderr: {result.stderr}")
            
        except subprocess.TimeoutExpired:
            execution_time = 300.0
            exit_code = 1
            print("MOCK: Command timed out")
        except Exception as e:
            print(f"MOCK: Command execution failed: {e}")
            execution_time = 0.1
            exit_code = 1
        
        # Generate realistic energy consumption
        energy_joules = self._simulate_energy(command, execution_time)
        
        # Write EnergiBridge-compatible CSV
        self._write_energy_csv(output_file, energy_joules, execution_time)
        
        print(f"MOCK: Completed in {execution_time:.2f}s, Energy: {energy_joules:.2f}J")
        return exit_code
    
    def _real_measure_command(self, command: List[str], output_file: str) -> int:
        """Execute command with real EnergiBridge measurement."""
        print(f"REAL: Measuring energy for {' '.join(command)}")
        
        # Construct energibridge command
        energibridge_cmd = ['energibridge', '--summary', '-o', output_file] + command
        
        try:
            result = subprocess.run(energibridge_cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode != 0:
                print(f"REAL: EnergiBridge failed: {result.stderr}")
            else:
                print(f"REAL: Energy measurement completed")
            
            return result.returncode
            
        except subprocess.TimeoutExpired:
            print("REAL: EnergiBridge measurement timed out")
            return 1
        except Exception as e:
            print(f"REAL: EnergiBridge execution failed: {e}")
            return 1
    
    def _simulate_energy(self, command: List[str], execution_time: float) -> float:
        """
        Generate realistic energy values for mock mode.
        
        Enhanced version that considers both GC strategy and workload.
        """
        # Base power consumption for M1 MacBook
        base_power_watts = 8.0
        
        # Java applications increase power consumption
        if any('java' in arg for arg in command):
            base_power_watts = 12.0
        
        # Get multipliers for GC and workload
        gc_multiplier = self._get_gc_power_multiplier(command)
        workload_multiplier = self._get_workload_multiplier(command)
        
        # Add controlled variance for realism
        variance_factor = random.gauss(1.0, 0.08)  # 8% standard deviation
        
        # Calculate total power and energy
        total_power = base_power_watts * gc_multiplier * workload_multiplier * variance_factor
        energy_joules = total_power * execution_time
        
        # Add measurement noise (RAPL counters have limited precision)
        noise = random.gauss(0, 0.3)
        final_energy = max(0.1, energy_joules + noise)
        
        return final_energy
    
    def _get_gc_power_multiplier(self, command: List[str]) -> float:
        """Return power multiplier based on GC strategy."""
        command_str = ' '.join(command)
        
        # Based on literature: Serial often most efficient, G1 has overhead
        if '-XX:+UseSerialGC' in command_str:
            return 0.85  # Serial GC typically more energy efficient
        elif '-XX:+UseParallelGC' in command_str:
            return 1.0   # Baseline reference
        elif '-XX:+UseG1GC' in command_str:
            return 1.12  # G1 has slight overhead for concurrent operations
        else:
            return 0.95  # Default JVM GC
    
    def _get_workload_multiplier(self, command: List[str]) -> float:
        """Return power multiplier based on workload intensity."""
        command_str = ' '.join(command)
        
        if 'light' in command_str:
            return 1.0   # Baseline workload
        elif 'medium' in command_str:
            return 1.7   # Increased computation and allocation
        elif 'heavy' in command_str:
            return 2.4   # Intensive computation and memory pressure
        else:
            return 1.0   # Default
    
    def _write_energy_csv(self, output_file: str, energy: float, execution_time: float):
        """Write energy measurement in EnergiBridge-compatible CSV format."""
        
        # Calculate derived metrics
        power_watts = energy / execution_time if execution_time > 0 else 0
        timestamp = int(time.time())
        
        # Write CSV in format compatible with analysis scripts
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            
            # Header matching EnergiBridge output format
            writer.writerow(['timestamp', 'energy_joules', 'power_watts', 'execution_time'])
            
            # Data row
            writer.writerow([
                timestamp,
                f"{energy:.6f}",
                f"{power_watts:.6f}", 
                f"{execution_time:.6f}"
            ])
    
    def get_experiment_metadata(self) -> Dict[str, Any]:
        """Return metadata about current measurement configuration."""
        return {
            'mock_mode': self.mock_mode,
            'measurement_tool': 'Mock Simulation' if self.mock_mode else 'EnergiBridge',
            'platform': 'M1 MacBook' if self.mock_mode else 'Linux RAPL',
            'timestamp': time.time()
        }