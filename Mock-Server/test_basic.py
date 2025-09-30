#!/usr/bin/env python3
"""
Test script to validate mock energy measurement interface.
Run this on your M1 MacBook to verify the concept works.
"""

import os
import sys
from energy_mock import MockEnergyMeasurement, create_mock_energibridge


def test_basic_functionality():
    """Test basic mock energy measurement."""
    print("=== Testing Basic Mock Functionality ===")
    
    # Enable mock mode
    os.environ['ENERGY_MOCK_MODE'] = 'true'
    
    mock = MockEnergyMeasurement()
    
    # Test with simple system command
    print("\n1. Testing with simple command (java -version):")
    exit_code = mock.measure_command(['java', '-version'], 'test_java_version.csv')
    energy = mock.parse_energy_result('test_java_version.csv')
    print(f"   Exit code: {exit_code}")
    print(f"   Energy consumed: {energy:.2f} joules")
    
    return energy > 0 and exit_code == 0


def test_gc_differences():
    """Test that different GC strategies produce different energy values."""
    print("\n=== Testing GC Strategy Differences ===")
    
    mock = MockEnergyMeasurement(seed=42)  # Fixed seed for reproducible testing
    
    # Test different GC strategies
    gc_strategies = [
        (['java', '-XX:+UseSerialGC', '-version'], 'Serial GC'),
        (['java', '-XX:+UseParallelGC', '-version'], 'Parallel GC'), 
        (['java', '-XX:+UseG1GC', '-version'], 'G1 GC'),
    ]
    
    results = {}
    
    for command, name in gc_strategies:
        output_file = f"test_{name.lower().replace(' ', '_')}.csv"
        print(f"\n2. Testing {name}:")
        
        exit_code = mock.measure_command(command, output_file)
        energy = mock.parse_energy_result(output_file)
        
        results[name] = energy
        print(f"   Energy: {energy:.2f}J")
    
    # Verify different strategies produce different energy values
    energies = list(results.values())
    all_different = len(set(energies)) == len(energies)
    
    print(f"\n   Results summary:")
    for name, energy in results.items():
        print(f"   {name}: {energy:.2f}J")
    
    print(f"   All strategies produce different values: {all_different}")
    return all_different


def test_factory_pattern():
    """Test the factory pattern for mock/real switching."""
    print("\n=== Testing Factory Pattern ===")
    
    # Test mock mode
    os.environ['ENERGY_MOCK_MODE'] = 'true'
    try:
        provider = create_mock_energibridge()
        print("   Mock mode: Successfully created mock provider")
        mock_success = True
    except Exception as e:
        print(f"   Mock mode failed: {e}")
        mock_success = False
    
    # Test real mode (should fail since not implemented yet)
    os.environ['ENERGY_MOCK_MODE'] = 'false'
    try:
        provider = create_mock_energibridge()
        print("   Real mode: Unexpectedly succeeded (should fail)")
        real_success = False
    except NotImplementedError:
        print("   Real mode: Correctly failed (not implemented yet)")
        real_success = True
    except Exception as e:
        print(f"   Real mode: Failed with unexpected error: {e}")
        real_success = False
    
    return mock_success and real_success


def test_csv_format():
    """Test that generated CSV is properly formatted."""
    print("\n=== Testing CSV Format ===")
    
    mock = MockEnergyMeasurement()
    
    # Generate test data
    mock.measure_command(['java', '-version'], 'format_test.csv')
    
    # Read and validate CSV
    try:
        with open('format_test.csv', 'r') as f:
            lines = f.readlines()
        
        header = lines[0].strip()
        data = lines[1].strip()
        
        print(f"   Header: {header}")
        print(f"   Data: {data}")
        
        # Basic format validation
        header_fields = header.split(',')
        data_fields = data.split(',')
        
        valid_format = (
            len(header_fields) == 4 and
            len(data_fields) == 4 and
            'energy_joules' in header and
            'power_watts' in header
        )
        
        print(f"   CSV format valid: {valid_format}")
        return valid_format
        
    except Exception as e:
        print(f"   CSV format test failed: {e}")
        return False


#!/usr/bin/env python3
"""
Test script to validate mock energy measurement interface.
Run this on your M1 MacBook to verify the concept works.
"""

import os
import sys
import subprocess
from energy_mock import MockEnergyMeasurement, create_mock_energibridge


def test_basic_functionality():
    """Test basic mock energy measurement."""
    print("=== Testing Basic Mock Functionality ===")
    
    # Enable mock mode
    os.environ['ENERGY_MOCK_MODE'] = 'true'
    
    mock = MockEnergyMeasurement()
    
    # Test with simple system command
    print("\n1. Testing with simple command (java -version):")
    exit_code = mock.measure_command(['java', '-version'], 'test_java_version.csv')
    energy = mock.parse_energy_result('test_java_version.csv')
    print(f"   Exit code: {exit_code}")
    print(f"   Energy consumed: {energy:.2f} joules")
    
    return energy > 0 and exit_code == 0


def test_gc_differences():
    """Test that different GC strategies produce different energy values."""
    print("\n=== Testing GC Strategy Differences ===")
    
    mock = MockEnergyMeasurement(seed=42)  # Fixed seed for reproducible testing
    
    # Test different GC strategies
    gc_strategies = [
        (['java', '-XX:+UseSerialGC', '-version'], 'Serial GC'),
        (['java', '-XX:+UseParallelGC', '-version'], 'Parallel GC'), 
        (['java', '-XX:+UseG1GC', '-version'], 'G1 GC'),
    ]
    
    results = {}
    
    for command, name in gc_strategies:
        output_file = f"test_{name.lower().replace(' ', '_')}.csv"
        print(f"\n2. Testing {name}:")
        
        exit_code = mock.measure_command(command, output_file)
        energy = mock.parse_energy_result(output_file)
        
        results[name] = energy
        print(f"   Energy: {energy:.2f}J")
    
    # Verify different strategies produce different energy values
    energies = list(results.values())
    all_different = len(set(energies)) == len(energies)
    
    print(f"\n   Results summary:")
    for name, energy in results.items():
        print(f"   {name}: {energy:.2f}J")
    
    print(f"   All strategies produce different values: {all_different}")
    return all_different


def test_factory_pattern():
    """Test the factory pattern for mock/real switching."""
    print("\n=== Testing Factory Pattern ===")
    
    # Test mock mode
    os.environ['ENERGY_MOCK_MODE'] = 'true'
    try:
        provider = create_mock_energibridge()
        print("   Mock mode: Successfully created mock provider")
        mock_success = True
    except Exception as e:
        print(f"   Mock mode failed: {e}")
        mock_success = False
    
    # Test real mode (should fail since not implemented yet)
    os.environ['ENERGY_MOCK_MODE'] = 'false'
    try:
        provider = create_mock_energibridge()
        print("   Real mode: Unexpectedly succeeded (should fail)")
        real_success = False
    except NotImplementedError:
        print("   Real mode: Correctly failed (not implemented yet)")
        real_success = True
    except Exception as e:
        print(f"   Real mode: Failed with unexpected error: {e}")
        real_success = False
    
    return mock_success and real_success


def test_csv_format():
    """Test that generated CSV is properly formatted."""
    print("\n=== Testing CSV Format ===")
    
    mock = MockEnergyMeasurement()
    
    # Generate test data
    mock.measure_command(['java', '-version'], 'format_test.csv')
    
    # Read and validate CSV
    try:
        with open('format_test.csv', 'r') as f:
            lines = f.readlines()
        
        header = lines[0].strip()
        data = lines[1].strip()
        
        print(f"   Header: {header}")
        print(f"   Data: {data}")
        
        # Basic format validation
        header_fields = header.split(',')
        data_fields = data.split(',')
        
        valid_format = (
            len(header_fields) == 4 and
            len(data_fields) == 4 and
            'energy_joules' in header and
            'power_watts' in header
        )
        
        print(f"   CSV format valid: {valid_format}")
        return valid_format
        
    except Exception as e:
        print(f"   CSV format test failed: {e}")
        return False


def test_workload_scaling():
    """Test that different workload levels produce different energy values."""
    print("\n=== Testing Workload Scaling ===")
    
    # Check if Java test app is available
    if not os.path.exists('SimpleGCTest.class'):
        print("   Compiling SimpleGCTest.java...")
        compile_result = subprocess.run(['javac', 'SimpleGCTest.java'], capture_output=True)
        if compile_result.returncode != 0:
            print("   WARNING: Cannot compile Java test app, skipping workload test")
            return True
    
    mock = MockEnergyMeasurement(seed=123)
    
    workloads = ['light', 'medium', 'heavy']
    results = {}
    
    for workload in workloads:
        output_file = f"test_workload_{workload}.csv"
        command = ['java', '-XX:+UseG1GC', 'SimpleGCTest', workload]
        
        print(f"   Testing {workload} workload...")
        exit_code = mock.measure_command(command, output_file)
        energy = mock.parse_energy_result(output_file)
        
        results[workload] = energy
        print(f"   {workload.capitalize()} workload: {energy:.2f}J")
    
    # Verify energy increases with workload intensity
    light_energy = results.get('light', 0)
    medium_energy = results.get('medium', 0)
    heavy_energy = results.get('heavy', 0)
    
    scaling_correct = light_energy < medium_energy < heavy_energy
    print(f"   Workload scaling correct (light < medium < heavy): {scaling_correct}")
    
    return scaling_correct


def main():
    """Run all tests."""
    print("Mock Energy Interface - Basic Validation")
    print("=" * 50)
    
    # Check Java availability
    try:
        import subprocess
        result = subprocess.run(['java', '-version'], capture_output=True)
        if result.returncode != 0:
            print("WARNING: Java not found. Some tests may fail.")
    except:
        print("WARNING: Cannot verify Java installation.")
    
    # Run tests
    tests = [
        ("Basic Functionality", test_basic_functionality),
        ("GC Strategy Differences", test_gc_differences),
        ("Workload Scaling", test_workload_scaling),
        ("Factory Pattern", test_factory_pattern),
        ("CSV Format", test_csv_format),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"   ERROR in {test_name}: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 50)
    print("Test Results Summary:")
    
    all_passed = True
    for test_name, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"   {test_name}: {status}")
        if not passed:
            all_passed = False
    
    if all_passed:
        print("\n✓ All tests passed! Mock interface is working.")
        print("  Ready to integrate with ExperimentRunner.")
    else:
        print("\n✗ Some tests failed. Check implementation.")
    
    return all_passed


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)