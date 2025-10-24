from EventManager.Models.RunnerEvents import RunnerEvents
from EventManager.EventSubscriptionController import EventSubscriptionController
from ConfigValidator.Config.Models.RunTableModel import RunTableModel
from ConfigValidator.Config.Models.FactorModel import FactorModel
from ConfigValidator.Config.Models.RunnerContext import RunnerContext
from ConfigValidator.Config.Models.OperationType import OperationType
from ProgressManager.Output.OutputProcedure import OutputProcedure as output
from Plugins.Profilers.Ps import Ps

from typing import Dict, List, Any, Optional
from pathlib import Path
from os.path import dirname, realpath

import numpy as np
import time
import subprocess
import shlex


class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    """The name of the experiment."""
    name:                       str             = "new_runner_experiment"

    """The path in which Experiment Runner will create a folder with the name `self.name`, in order to store the
    results from this experiment. (Path does not need to exist - it will be created if necessary.)
    Output path defaults to the config file's path, inside the folder 'experiments'"""
    results_output_path:        Path             = ROOT_DIR / 'experiments'

    """Experiment operation type. Unless you manually want to initiate each run, use `OperationType.AUTO`."""
    operation_type:             OperationType   = OperationType.AUTO

    """The time Experiment Runner will wait after a run completes.
    This can be essential to accommodate for cooldown periods on some systems."""
    time_between_runs_in_ms:    int             = 1000

    # Dynamic configurations can be one-time satisfied here before the program takes the config as-is
    # e.g. Setting some variable based on some criteria
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
        self.run_table_model = None  # Initialized later
        output.console_log("Custom config loaded")

    def create_run_table_model(self) -> RunTableModel:
        """Create and return the run_table model here. A run_table is a List (rows) of tuples (columns),
        representing each run performed"""
        cpu_limit_factor = FactorModel("cpu_limit", [20, 50, 70 ])
        pin_core_factor  = FactorModel("pin_core" , [True, False])
        self.run_table_model = RunTableModel(
            factors = [cpu_limit_factor, pin_core_factor],
            exclude_combinations = [
                {cpu_limit_factor: [70], pin_core_factor: [False]} # all runs having the combination <'70', 'False'> will be excluded
            ],
            data_columns=["avg_cpu", "avg_mem"]
        )
        return self.run_table_model

    def before_experiment(self) -> None:
        """Perform any activity required before starting the experiment here
        Invoked only once during the lifetime of the program."""

        # compile the target program
        subprocess.check_call(['make'], cwd=self.ROOT_DIR)

    def before_run(self) -> None:
        """Perform any activity required before starting a run.
        No context is available here as the run is not yet active (BEFORE RUN)"""
        pass

    def start_run(self, context: RunnerContext) -> None:
        """Perform any activity required for starting the run"""
        
        # Debug: Print available context attributes
        output.console_log(f"Context attributes: {dir(context)}")
        
        # Try different ways to access run configuration
        try:
            # Method 1: Check if there's a run_variation attribute
            if hasattr(context, 'run_variation'):
                gc_strategy = context.run_variation['gc_strategy']
                workload = context.run_variation['workload'] 
                jdk_impl = context.run_variation['jdk_implementation']
            # Method 2: Check if there's experiment_variation
            elif hasattr(context, 'experiment_variation'):
                gc_strategy = context.experiment_variation['gc_strategy']
                workload = context.experiment_variation['workload']
                jdk_impl = context.experiment_variation['jdk_implementation']
            # Method 3: Check if parameters are direct attributes
            else:
                output.console_log("Available context attributes:")
                for attr in dir(context):
                    if not attr.startswith('_'):
                        output.console_log(f"  {attr}: {getattr(context, attr, 'N/A')}")
                # Use defaults for now
                gc_strategy = 'G1GC'
                workload = 'light'
                jdk_impl = 'default'
                
        except Exception as e:
            output.console_log(f"Error accessing run configuration: {e}")
            # Use defaults
            gc_strategy = 'G1GC'
            workload = 'light'
            jdk_impl = 'default'
        
        # Store current run info for energy measurement
        self.current_run_info = {
            'gc_strategy': gc_strategy,
            'workload': workload,
            'jdk_implementation': jdk_impl,
            'run_id': getattr(context, 'run_nr', 0)
        }
        
        # Define energy measurement output file
        self.current_energy_file = context.run_dir / f"energy_{gc_strategy}_{workload}.csv"
        
        output.console_log(f"Starting run: {gc_strategy} with {workload} workload")

    def start_measurement(self, context: RunnerContext) -> None:
        """Perform any activity required for starting measurements."""
        
        # Set up the ps object, provide an (optional) target and output file name
        self.meter = Ps(out_file=context.run_dir / "ps.csv",
                        target_pid=[self.target.pid])
        # Start measuring with ps
        self.meter.start()

    def interact(self, context: RunnerContext) -> None:
        """Perform any interaction with the running target system here, or block here until the target finishes."""

        # No interaction. We just run it for XX seconds.
        # Another example would be to wait for the target to finish, e.g. via `self.target.wait()`
        output.console_log("Running program for 20 seconds")
        time.sleep(20)

    def stop_measurement(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping measurements."""

        # Stop the measurements
        stdout = self.meter.stop()

    def stop_run(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping the run.
        Activities after stopping the run should also be performed here."""
        
        self.target.kill()
        self.target.wait()
    
    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        """Parse and process any measurement data here.
        You can also store the raw measurement data under `context.run_dir`
        Returns a dictionary with keys `self.run_table_model.data_columns` and their values populated"""

        results = self.meter.parse_log(context.run_dir / "ps.csv", 
                                       column_names=["cpu_usage", "memory_usage"])

        return {
            "avg_cpu": round(np.mean(list(results['cpu_usage'].values())), 3),
            "avg_mem": round(np.mean(list(results['memory_usage'].values())), 3)
        }

    def after_experiment(self) -> None:
        """Perform any activity required after stopping the experiment here
        Invoked only once during the lifetime of the program."""
        pass

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path:            Path             = None
