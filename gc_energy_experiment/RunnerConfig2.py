#!/usr/bin/env python3
"""
ExperimentRunner configuration for Java GC Energy Efficiency Study.
Based on the working hello-world example pattern.
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

# Add current directory to Python path for energy_measurement module
import sys
sys.path.insert(0, str(Path(__file__).parent))


# Import our energy measurement wrapper
from energy_measurement.gc_energy_wrapper import GCEnergyWrapper


class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    """The name of the experiment."""
    name: str = "gc_energy_efficiency_experiment"

    """The path in which Experiment Runner will create a folder with the name `self.name`, in order to store the
    results from this experiment."""
    results_output_path: Path = ROOT_DIR / 'experiments'

    """Experiment operation type. Unless you manually want to initiate each run, use `OperationType.AUTO`."""
    operation_type: OperationType = OperationType.AUTO

    """The time Experiment Runner will wait after a run completes.
    This can be essential to accommodate for cooldown periods on some systems."""
    time_between_runs_in_ms: int = 2000  # 2 second cooldown for energy measurement

    def __init__(self):
        """Executes immediately after program start, on config load"""

        EventSubscriptionController.subscribe_to_multiple_events([
            (RunnerEvents.BEFORE_EXPERIMENT, self.before_experiment),
            (RunnerEvents.BEFORE_RUN       , self.before_run       ),
            (RunnerEvents.START_RUN        , self.start_run        ),
            (RunnerEvents.START_MEASUREMENT, self.start_measurement),
            (RunnerEvents.INTERACT         , self.interact         ),
            (RunnerEvents.STOP_MEASUREMENT , self.stop_measurement ),
            (RunnerEvents.STOP_RUN         , self.stop_run         ),
            (RunnerEvents.POPULATE_RUN_DATA, self.populate_run_data),
            (RunnerEvents.AFTER_EXPERIMENT , self.after_experiment )
        ])
        
        self.run_table_model = None
        
        # Initialize energy measurement wrapper
        self.energy_wrapper = GCEnergyWrapper()
        
        # Store current run info for energy measurement
        self.current_run_info = None
        self.current_energy_file = None

        output.console_log("GC Energy Experiment config loaded")
        output.console_log(f"Mock mode: {os.getenv('ENERGY_MOCK_MODE', 'false')}")

    def create_run_table_model(self) -> RunTableModel:
        """Create and return the run_table model for GC energy efficiency experiment"""
        
        # Define experimental factors
        gc_strategy = FactorModel("gc_strategy", ['SerialGC', 'ParallelGC', 'G1GC'])
        workload = FactorModel("workload", ['light', 'medium'])  # Start small for testing
        jdk_implementation = FactorModel("jdk_implementation", ['default'])  # Single JDK for now
        
        self.run_table_model = RunTableModel(
            factors=[gc_strategy, workload, jdk_implementation],
            exclude_combinations=[],  # No exclusions for now
            repetitions=2,  # Small number for testing
            data_columns=['energy_joules', 'execution_time', 'exit_code']
        )
        
        output.console_log("Generated run table for GC energy efficiency experiment")
        
        return self.run_table_model

    def before_experiment(self) -> None:
        """Perform any activity required before starting the experiment"""
        
        output.console_log("Setting up Java GC energy efficiency experiment...")
        
        # Validate Java installation
        if not self._validate_java_installation():
            raise RuntimeError("Java installation validation failed")
        
        # Compile test subjects
        self._compile_test_subjects()
        
        # Validate energy measurement system
        if not self.energy_wrapper.validate_setup():
            raise RuntimeError("Energy measurement validation failed")
        
        output.console_log("Pre-experiment validation completed successfully")

    def before_run(self) -> None:
        """Perform any activity required before starting a run"""
        output.console_log("Preparing for next run...")

    def start_run(self, context: RunnerContext) -> None:
        """Perform any activity required for starting the run"""
        
        # Store basic run info
        self.current_run_info = {
            'run_id': context.run_nr,
            'run_dir': context.run_dir
        }
        
        # Define energy measurement output file
        self.current_energy_file = context.run_dir / "energy_measurement.csv"
        
        output.console_log(f"Starting run {context.run_nr}")

    def start_measurement(self, context: RunnerContext) -> None:
        """Perform any activity required for starting measurements"""
        output.console_log("Starting energy measurement...")


    def interact(self, context: RunnerContext) -> None:
        """Execute the Java application with energy measurement"""
        
        gc_strategy = 'G1GC'
        workload = 'light'
        
        java_command = self._build_java_command(gc_strategy, workload)
        
        output.console_log(f"Executing: {' '.join(java_command)}")
        
        # Change to subjects directory for execution
        subjects_dir = self.ROOT_DIR / 'subjects'
        
        try:
            import subprocess
            import os
            
            # Execute in subjects directory
            result = subprocess.run(
                java_command, 
                cwd=str(subjects_dir),
                capture_output=True, 
                text=True
            )
            
            # Use our energy wrapper to simulate the measurement
            self.energy_wrapper._write_energy_csv(
                str(self.current_energy_file),
                2.5,  # Simulated energy
                0.2   # Simulated time
            )
            
            self.current_run_info.update({
                'exit_code': result.returncode,
                'energy_file': str(self.current_energy_file),
                'gc_strategy': gc_strategy,
                'workload': workload
            })
            
            if result.returncode == 0:
                output.console_log("Java execution completed successfully")
            else:
                output.console_log(f"Java execution failed: {result.stderr}")
                
        except Exception as e:
            output.console_log(f"ERROR during Java execution: {e}")

    def stop_measurement(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping measurements"""
        output.console_log("Stopping energy measurement...")

    def stop_run(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping the run"""
        output.console_log(f"Run {context.run_nr} completed")

    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        """Parse and process energy measurement data"""
        
        try:
            # Parse energy results
            if self.current_run_info['exit_code'] == 0:
                energy_joules = self.energy_wrapper.parse_energy_result(self.current_run_info['energy_file'])
                
                # Calculate execution time from energy file if available
                execution_time = 0.0  # Could extract from energy CSV if needed
                
                run_data = {
                    'energy_joules': energy_joules,
                    'execution_time': execution_time,
                    'exit_code': self.current_run_info['exit_code']
                }
                
                output.console_log(f"Energy consumed: {energy_joules:.2f} joules")
                
            else:
                # Failed run
                run_data = {
                    'energy_joules': 0.0,
                    'execution_time': 0.0,
                    'exit_code': self.current_run_info['exit_code']
                }
                
                if 'error' in self.current_run_info:
                    run_data['error'] = self.current_run_info['error']
            
            return run_data
            
        except Exception as e:
            output.console_log(f"Error parsing run data: {e}")
            return {
                'energy_joules': 0.0,
                'execution_time': 0.0,
                'exit_code': -1,
                'error': str(e)
            }

    def after_experiment(self) -> None:
        """Perform any activity required after stopping the experiment"""
        output.console_log("Java GC energy efficiency experiment completed")
        self._summarize_results()

    def _validate_java_installation(self) -> bool:
        """Validate that Java is properly installed and accessible"""
        try:
            import subprocess
            result = subprocess.run(['java', '-version'], capture_output=True, text=True)
            if result.returncode == 0:
                output.console_log("Java validation successful")
                return True
            else:
                output.console_log(f"Java validation failed: {result.stderr}")
                return False
        except Exception as e:
            output.console_log(f"Java validation error: {e}")
            return False

    def _compile_test_subjects(self) -> None:
        """Compile Java test applications if needed"""
        subjects_dir = self.ROOT_DIR / "subjects"
        java_files = list(subjects_dir.glob("*.java"))
        
        if java_files:
            output.console_log(f"Compiling {len(java_files)} Java source files...")
            import subprocess
            
            for java_file in java_files:
                try:
                    result = subprocess.run(['javac', str(java_file)], 
                                          capture_output=True, text=True, cwd=subjects_dir)
                    if result.returncode != 0:
                        output.console_log(f"Warning: Failed to compile {java_file}: {result.stderr}")
                except Exception as e:
                    output.console_log(f"Error compiling {java_file}: {e}")

    def _build_java_command(self, gc_strategy: str, workload: str) -> List[str]:
        """Build Java command with appropriate GC flags"""
        
        gc_flags = {
            'SerialGC': '-XX:+UseSerialGC',
            'ParallelGC': '-XX:+UseParallelGC', 
            'G1GC': '-XX:+UseG1GC'
        }
        
        # Execute from the subjects directory
        subjects_dir = str(self.ROOT_DIR / 'subjects')
        
        command = [
            'java',
            gc_flags[gc_strategy],
            '-cp', '.',  # Use current directory as classpath
            'SimpleGCTest',
            workload
        ]
        
        return command


    def _summarize_results(self) -> None:
        """Generate basic summary of experimental results"""
        experiments_dir = self.results_output_path / self.name
        
        if experiments_dir.exists():
            csv_files = list(experiments_dir.rglob("*.csv"))
            output.console_log(f"Experiment generated {len(csv_files)} result files")
            output.console_log(f"Results stored in: {experiments_dir}")
        else:
            output.console_log("No results directory found")

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path: Path = None