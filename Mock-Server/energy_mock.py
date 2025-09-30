#!/usr/bin/env python3
"""
Basic mock energy measurement interface for development on non-Linux systems.
Simulates RAPL behavior by running actual commands and generating realistic energy data.
"""

import subprocess
import time
import csv
import random
import os
from typing import List


class MockEnergyMeasurement:
    def __init__(self, seed=42):
        """Initialize mock with fixed seed for reproducible results during development."""
        random.seed(seed)
        
    def measure_command(self, command: List[str], output_file: str) -> int:
        """
        Execute command and generate mock energy measurement.
        Returns exit code of the executed command.
        """
        print(f"MOCK MODE: Executing {' '.join(command)}")
        
        # Run actual command to get real execution time and behavior
        start_time = time.time()
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=300)
            execution_time = time.time() - start_time
            exit_code = result.returncode
        except subprocess.TimeoutExpired:
            execution_time = 300.0  # Timeout case
            exit_code = 1
        except Exception as e:
            print(f"Command execution failed: {e}")
            execution_time = 0.1
            exit_code = 1
            
        # Generate realistic energy consumption
        energy_joules = self._simulate_energy(command, execution_time)
        
        # Write EnergiBridge-compatible CSV
        self._write_energibridge_csv(output_file, energy_joules, execution_time)
        
        print(f"MOCK: Executed in {execution_time:.2f}s, Energy: {energy_joules:.2f}J")
        return exit_code
    
    def _simulate_energy(self, command: List[str], execution_time: float) -> float:
        """Generate realistic energy values based on command and execution time."""
        
        # Base power consumption for M1 MacBook
        base_power_watts = 8.0
        
        # Java applications typically increase power consumption
        if any('java' in arg for arg in command):
            base_power_watts = 12.0
            
        # Workload-specific adjustments (add this)
        workload_multiplier = self._get_workload_multiplier(command)
        
        # GC-specific power adjustments
        gc_multiplier = self._get_gc_power_multiplier(command)
        
        # Add some variance but ensure workload ordering
        workload_factor = random.gauss(1.0, 0.05)  # Reduced variance
        
        # Calculate energy: Power × Time × Workload × GC
        power_watts = base_power_watts * workload_multiplier * gc_multiplier * workload_factor
        energy_joules = power_watts * execution_time
        
        # Add measurement noise
        noise = random.gauss(0, 0.5)
        return max(0.1, energy_joules + noise)

    def _get_workload_multiplier(self, command: List[str]) -> float:
        """Return power multiplier based on workload intensity."""
        command_str = ' '.join(command)
        
        if 'light' in command_str:
            return 1.0   # Baseline
        elif 'medium' in command_str:
            return 1.8   # More computation
        elif 'heavy' in command_str:
            return 2.5   # Intensive computation
        else:
            return 1.0

    def _get_gc_power_multiplier(self, command: List[str]) -> float:
        """Return power multiplier based on GC strategy."""
        command_str = ' '.join(command)
        
        if '-XX:+UseSerialGC' in command_str:
            return 0.85  # Serial GC typically more energy efficient on single core
        elif '-XX:+UseParallelGC' in command_str:
            return 1.0   # Baseline reference
        elif '-XX:+UseG1GC' in command_str:
            return 1.12  # G1 has slight overhead for concurrent operations
        else:
            return 0.95  # Default JVM GC (usually G1 in modern JVMs)
    
    def _write_energibridge_csv(self, output_file: str, energy: float, execution_time: float):
        """Write CSV file in EnergiBridge format."""
        
        # Calculate derived metrics
        power_watts = energy / execution_time if execution_time > 0 else 0
        
        # EnergiBridge CSV structure (simplified but compatible)
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            
            # Header
            writer.writerow(['timestamp', 'energy_joules', 'power_watts', 'execution_time'])
            
            # Single measurement row (EnergiBridge aggregates to summary)
            timestamp = int(time.time())
            writer.writerow([timestamp, f"{energy:.6f}", f"{power_watts:.6f}", f"{execution_time:.6f}"])
    
    def parse_energy_result(self, csv_file: str) -> float:
        """Extract energy value from mock CSV (for compatibility with analysis code)."""
        try:
            with open(csv_file, 'r') as f:
                reader = csv.DictReader(f)
                row = next(reader)
                return float(row['energy_joules'])
        except Exception as e:
            print(f"Error parsing energy result: {e}")
            return 0.0


def create_mock_energibridge(mock_mode: bool = None):
    """Factory function to create appropriate energy measurement provider."""
    
    # Check environment variable if not explicitly specified
    if mock_mode is None:
        mock_mode = os.getenv('ENERGY_MOCK_MODE', 'false').lower() == 'true'
    
    if mock_mode:
        return MockEnergyMeasurement()
    else:
        # In real implementation, this would return RealEnergyMeasurement()
        raise NotImplementedError("Real RAPL measurement not implemented yet")


if __name__ == "__main__":
    # Quick test
    mock = MockEnergyMeasurement()
    
    # Test with simple command
    exit_code = mock.measure_command(['java', '-version'], 'test_output.csv')
    energy = mock.parse_energy_result('test_output.csv')
    
    print(f"Test completed - Exit code: {exit_code}, Energy: {energy:.2f}J")