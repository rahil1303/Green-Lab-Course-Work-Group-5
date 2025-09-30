#!/usr/bin/env python3
"""
Simplified ExperimentRunner configuration for Java GC Energy Efficiency Study.
Based directly on the hello-world example pattern.
"""

from EventManager.Models.RunnerEvents import RunnerEvents
from EventManager.EventSubscriptionController import EventSubscriptionController
from ConfigValidator.Config.Models.RunTableModel import RunTableModel
from ConfigValidator.Config.Models.FactorModel import FactorModel
from ConfigValidator.Config.Models.RunnerContext import RunnerContext
from ConfigValidator.Config.Models.OperationType import OperationType
from ProgressManager.Output.OutputProcedure import OutputProcedure as output

from typing import Dict, List, Any, Optional
from pathlib import Path
from os.path import dirname, realpath
import os
import subprocess
import time
import csv
import random

class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    name: str = "gc_energy_experiment"
    results_output_path: Path = ROOT_DIR / 'experiments'
    operation_type: OperationType = OperationType.AUTO
    time_between_runs_in_ms: int = 1000

    def __init__(self):
        """Executes immediately after program start, on config load"""
        EventSubscriptionController.subscribe_to_multiple_events([
            (RunnerEvents.BEFORE_EXPERIMENT, self.before_experiment),
            (RunnerEvents.BEFORE_RUN, self.before_run),
            (RunnerEvents.START_RUN, self.start_run),
            (RunnerEvents.START_MEASUREMENT, self.start_measurement),
            (RunnerEvents.INTERACT, self.interact),
            (RunnerEvents.STOP_MEASUREMENT, self.stop_measurement),
            (RunnerEvents.STOP_RUN, self.stop_run),
            (RunnerEvents.POPULATE_RUN_DATA, self.populate_run_data),
            (RunnerEvents.AFTER_EXPERIMENT, self.after_experiment)
        ])
        
        self.run_table_model = None
        self.current_run_data = {}
        self.mock_enabled = os.getenv('ENERGY_MOCK_MODE', 'false').lower() == 'true'
        
        output.console_log("Java GC Energy Experiment initialized")

    def create_run_table_model(self) -> RunTableModel:
        """Create the run table model"""
        gc_strategy = FactorModel("gc_strategy", ['SerialGC', 'ParallelGC', 'G1GC'])
        workload = FactorModel("workload", ['light', 'medium'])
        
        self.run_table_model = RunTableModel(
            factors=[gc_strategy, workload],
            repetitions=2,
            data_columns=['energy_joules', 'execution_time', 'power_watts', 'exit_code']
        )
        
        return self.run_table_model

    def before_experiment(self) -> None:
        """Called before the experiment starts"""
        output.console_log("Setting up Java GC experiment...")
        self._setup_java_test()

    def before_run(self) -> None:
        """Called before each run"""
        pass

    def start_run(self, context: RunnerContext) -> None:
        """Called at the start of each run"""
        self.current_run_data = {
            'run_id': context.run_nr,
            'run_dir': context.run_dir
        }
        output.console_log(f"Starting run {context.run_nr}")

    def start_measurement(self, context: RunnerContext) -> None:
        """Called when measurements should start"""
        pass

    def interact(self, context: RunnerContext) -> None:
        """Main execution phase - this is where the work happens"""

        output.console_log(f"Context attributes: {dir(context)}")
        output.console_log(f"Context dict: {context.__dict__}")
        
            
        # Simple mapping based on run number since we can't access factors directly
        run_configs = [
            ('SerialGC', 'light'),
            ('SerialGC', 'medium'), 
            ('ParallelGC', 'light'),
            ('ParallelGC', 'medium'),
            ('G1GC', 'light'),
            ('G1GC', 'medium')
        ]
        
        config_index = (context.run_nr - 1) % len(run_configs)

        gc_strategy, workload = run_configs[config_index]
        
        output.console_log(f"Executing {gc_strategy} with {workload} workload")
        
        if self.mock_enabled:
            # Mock execution with realistic patterns
            energy_joules, execution_time, power_watts = self._mock_energy_measurement(gc_strategy, workload)
            exit_code = 0
            
            # Simulate execution time
            time.sleep(min(execution_time, 0.2))
            
        else:
            # Real execution (placeholder for now)
            energy_joules = 2.5
            execution_time = 0.3
            power_watts = energy_joules / execution_time
            exit_code = 0
        
        # Store results for populate_run_data
        self.current_run_data.update({
            'energy_joules': energy_joules,
            'execution_time': execution_time,
            'power_watts': power_watts,
            'exit_code': exit_code,
            'gc_strategy': gc_strategy,
            'workload': workload
        })
        
        output.console_log(f"Completed: {energy_joules:.3f}J in {execution_time:.3f}s")

    def stop_measurement(self, context: RunnerContext) -> None:
        """Called when measurements should stop"""
        pass

    def stop_run(self, context: RunnerContext) -> None:
        """Called when the run ends"""
        pass

    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        """Return data to be written to the results CSV"""
        return {
            'energy_joules': self.current_run_data.get('energy_joules', 0.0),
            'execution_time': self.current_run_data.get('execution_time', 0.0),
            'power_watts': self.current_run_data.get('power_watts', 0.0),
            'exit_code': self.current_run_data.get('exit_code', -1)
        }

    def after_experiment(self) -> None:
        """Called after the experiment completes"""
        output.console_log("Java GC experiment completed")
        self._analyze_results()

    def _mock_energy_measurement(self, gc_strategy: str, workload: str) -> tuple:
        """Generate realistic mock energy measurements"""
        
        # Base characteristics for each GC
        base_values = {
            'SerialGC': {'energy': 3.2, 'time': 0.35, 'variance': 0.15},
            'ParallelGC': {'energy': 4.1, 'time': 0.22, 'variance': 0.25},
            'G1GC': {'energy': 3.8, 'time': 0.28, 'variance': 0.35}
        }
        
        workload_multiplier = {'light': 1.0, 'medium': 2.3}.get(workload, 1.0)
        scaling_factor = {'SerialGC': 1.8, 'ParallelGC': 1.3, 'G1GC': 1.1}.get(gc_strategy, 1.0)
        
        base = base_values.get(gc_strategy, base_values['G1GC'])
        
        # Apply workload scaling
        energy_base = base['energy'] * (workload_multiplier ** scaling_factor)
        time_base = base['time'] * (workload_multiplier ** (scaling_factor * 0.7))
        
        # Add variance
        energy_joules = energy_base * random.gauss(1.0, base['variance'])
        execution_time = time_base * random.gauss(1.0, base['variance'] * 0.8)
        
        # Ensure positive values
        energy_joules = max(0.1, energy_joules)
        execution_time = max(0.05, execution_time)
        power_watts = energy_joules / execution_time
        
        return round(energy_joules, 6), round(execution_time, 6), round(power_watts, 6)

    def _setup_java_test(self) -> None:
        """Set up Java test application"""
        subjects_dir = self.ROOT_DIR / "subjects"
        subjects_dir.mkdir(exist_ok=True)
        
        # Create a simple test if it doesn't exist
        test_file = subjects_dir / "SimpleGCTest.java"
        if not test_file.exists():
            java_code = '''
public class SimpleGCTest {
    public static void main(String[] args) {
        String workload = args.length > 0 ? args[0] : "light";
        int iterations = workload.equals("medium") ? 5000 : 1000;
        
        for (int i = 0; i < iterations; i++) {
            java.util.List<String> list = new java.util.ArrayList<>();
            for (int j = 0; j < 100; j++) {
                list.add("Test " + i + "_" + j);
            }
        }
        System.out.println("Completed " + workload + " workload");
    }
}
'''
            with open(test_file, 'w') as f:
                f.write(java_code)
            
            # Compile it
            try:
                subprocess.run(['javac', str(test_file)], 
                             cwd=str(subjects_dir), check=True)
                output.console_log("Java test compiled successfully")
            except subprocess.CalledProcessError:
                output.console_log("Warning: Failed to compile Java test")

    def _analyze_results(self) -> None:
        """Basic analysis of results"""
        results_path = self.results_output_path / self.name / "run_table.csv"
        
        if results_path.exists():
            try:
                with open(results_path, 'r') as f:
                    reader = csv.DictReader(f)
                    rows = list(reader)
                
                completed_runs = [r for r in rows if r.get('__done') == 'DONE']
                output.console_log(f"Completed {len(completed_runs)} runs out of {len(rows)} total")
                
                if completed_runs:
                    energies = [float(r['energy_joules']) for r in completed_runs if r['energy_joules']]
                    if energies:
                        avg_energy = sum(energies) / len(energies)
                        output.console_log(f"Average energy consumption: {avg_energy:.3f}J")
                
            except Exception as e:
                output.console_log(f"Error analyzing results: {e}")

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path: Path = None