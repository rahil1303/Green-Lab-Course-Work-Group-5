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
import signal
import pandas as pd
import time
import subprocess

class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    """The name of the experiment."""
    name:                       str             = "java_gc_energy_experiment"

    """The path in which Experiment Runner will create a folder with the name `self.name`, in order to store the
    results from this experiment. (Path does not need to exist - it will be created if necessary.)
    Output path defaults to the config file's path, inside the folder 'experiments'"""
    results_output_path:        Path            = ROOT_DIR / 'experiments'

    """Experiment operation type. Unless you manually want to initiate each run, use `OperationType.AUTO`."""
    operation_type:             OperationType   = OperationType.AUTO

    """The time Experiment Runner will wait after a run completes.
    This can be essential to accommodate for cooldown periods on some systems."""
    time_between_runs_in_ms:    int             = 120000  # 2 minutes cooldown

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
        """Create a RunTable and add our factors.

        Returns:
            RunTableModel: Model...
        """
        # Define experimental factors
        subject_factor = FactorModel("subject", [
            'DaCapo', 
            'CLBG-BinaryTrees', 
            'CLBG-Fannkuch', 
            'CLBG-NBody',
            'Rosetta', 
            'PetClinic', 
            'TodoApp', 
            'ANDIE'
        ])
        
        gc_factor = FactorModel("gc", ['Serial', 'Parallel', 'G1'])
        
        workload_factor = FactorModel("workload", ['Light', 'Medium', 'Heavy'])
        
        jdk_factor = FactorModel("jdk", ['openjdk', 'oracle'])
        
        # Create run table with 3 repetitions
        # Total runs: 8 subjects × 3 GC × 3 workload × 2 JDK × 3 reps = 432 runs
        # (Your report says 324, which means 6 subjects - adjust if needed!)
        self.run_table_model = RunTableModel(
            factors=[subject_factor, gc_factor, workload_factor, jdk_factor],
            exclude_variations=[],  # No exclusions
            data_columns=['energy_j', 'runtime_s', 'status']
        )
        
        return self.run_table_model

    def before_experiment(self) -> None:
        """Perform any activity required before starting the experiment here
        Invoked only once during the lifetime of the program."""
        
        output.console_log("="*60)
        output.console_log("JAVA GC ENERGY EXPERIMENT - GREEN LAB 2025")
        output.console_log("="*60)
        output.console_log(f"Total runs planned: {len(self.run_table_model.get_all_rows())}")
        output.console_log(f"Results path: {self.results_output_path}")
        output.console_log("")
        
        # Test SSH connection to Linux laptop
        output.console_log("Testing SSH connection to DUT (Linux laptop)...")
        
        laptop_user = os.getenv('LAPTOP_USER', 'your_username')
        laptop_host = os.getenv('LAPTOP_HOST', '192.168.1.100')
        
        try:
            result = subprocess.run(
                ['ssh', f'{laptop_user}@{laptop_host}', 'echo "SSH test successful"'],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                output.console_log("✓ SSH connection to DUT successful")
            else:
                output.console_log("✗ SSH connection FAILED - check configuration!")
                output.console_log(f"  Error: {result.stderr}")
        except Exception as e:
            output.console_log(f"✗ SSH test error: {e}")

    def before_run(self) -> None:
        """Perform any activity required before starting a run.
        No context is available here as the run is not yet active (BEFORE RUN)"""
        
        output.console_log("")
        output.console_log("─" * 50)
        output.console_log("Preparing for next run...")

    def start_run(self, context: RunnerContext) -> None:
        """Perform any activity required for starting the run here.
        For example, starting the target system to measure.
        Activities after starting the run should also be performed here."""
        
        output.console_log("")
        output.console_log("="*60)
        output.console_log(f"STARTING RUN #{context.run_nr}")
        output.console_log("="*60)
        output.console_log(f"Subject:  {context.run_variation['subject']}")
        output.console_log(f"GC:       {context.run_variation['gc']}")
        output.console_log(f"Workload: {context.run_variation['workload']}")
        output.console_log(f"JDK:      {context.run_variation['jdk']}")
        output.console_log(f"Rep:      {context.run_variation['__rep__']}")
        output.console_log("")

    def start_measurement(self, context: RunnerContext) -> None:
        """Perform any activity required for starting measurements."""
        
        output.console_log("Starting energy measurement...")
        
        # Get laptop configuration from environment
        laptop_user = os.getenv('LAPTOP_USER', 'your_username')
        laptop_host = os.getenv('LAPTOP_HOST', '192.168.1.100')
        laptop_exp_dir = os.getenv('LAPTOP_EXPERIMENT_DIR', '/home/your_username/gc_experiment')
        
        # Build command to execute on laptop
        subject = context.run_variation['subject']
        gc = context.run_variation['gc']
        workload = context.run_variation['workload']
        jdk = context.run_variation['jdk']
        rep = context.run_variation['__rep__']
        run_num = context.run_nr
        
        # Command: run_single_experiment.sh <subject> <gc> <workload> <jdk> <rep> <run_num>
        remote_cmd = (
            f"cd {laptop_exp_dir} && "
            f"./run_single_experiment.sh {subject} {gc} {workload} {jdk} {rep} {run_num}"
        )
        
        # Execute via SSH (non-blocking for now - we'll wait in interact())
        output.console_log(f"Executing on DUT: {remote_cmd}")
        
        # Store command in context for later
        context.ssh_command = remote_cmd
        context.laptop_user = laptop_user
        context.laptop_host = laptop_host
        context.laptop_exp_dir = laptop_exp_dir

    def interact(self, context: RunnerContext) -> None:
        """Perform any interaction with the running target system here, or block here until the target finishes."""
        
        # Execute the SSH command and wait for completion
        ssh_cmd = ['ssh', f'{context.laptop_user}@{context.laptop_host}', context.ssh_command]
        
        output.console_log("Waiting for experiment to complete on DUT...")
        
        try:
            # Execute with timeout (15 minutes max per run)
            result = subprocess.run(
                ssh_cmd,
                capture_output=True,
                text=True,
                timeout=900
            )
            
            context.ssh_returncode = result.returncode
            context.ssh_stdout = result.stdout
            context.ssh_stderr = result.stderr
            
            if result.returncode == 0:
                output.console_log("✓ Run completed successfully on DUT")
            else:
                output.console_log(f"✗ Run FAILED with return code {result.returncode}")
                output.console_log(f"  stderr: {result.stderr[:500]}")
                
        except subprocess.TimeoutExpired:
            output.console_log("✗ Run TIMEOUT (exceeded 15 minutes)")
            context.ssh_returncode = -1
            context.ssh_stdout = ""
            context.ssh_stderr = "TIMEOUT"

    def stop_measurement(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping measurements."""
        
        output.console_log("Stopping measurement and retrieving results...")
        
        if context.ssh_returncode == 0:
            # Copy results from laptop to Pi
            remote_result_dir = f"{context.laptop_exp_dir}/results/run_{context.run_nr}"
            local_result_dir = context.run_dir / "dut_results"
            local_result_dir.mkdir(parents=True, exist_ok=True)
            
            # Copy energy CSV
            scp_cmd = [
                'scp',
                f'{context.laptop_user}@{context.laptop_host}:{remote_result_dir}/energy.csv',
                str(local_result_dir / 'energy.csv')
            ]
            
            result = subprocess.run(scp_cmd, capture_output=True)
            
            if result.returncode == 0:
                output.console_log("  ✓ Retrieved energy.csv")
            else:
                output.console_log("  ✗ Failed to retrieve energy.csv")
            
            # Copy result summary
            scp_cmd = [
                'scp',
                f'{context.laptop_user}@{context.laptop_host}:{remote_result_dir}/result.csv',
                str(local_result_dir / 'result.csv')
            ]
            
            result = subprocess.run(scp_cmd, capture_output=True)
            
            if result.returncode == 0:
                output.console_log("  ✓ Retrieved result.csv")
            else:
                output.console_log("  ✗ Failed to retrieve result.csv")

    def stop_run(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping the run.
        Activities after stopping the run should also be performed here."""
        
        output.console_log("")
        output.console_log(f"Run #{context.run_nr} complete")
        output.console_log("─" * 50)

    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        """Parse and process any measurement data here.
        You can also store the raw measurement data under `context.run_dir`
        Returns:
            Dict[str, Any]: Dictionary containing measurements for this run."""
        
        output.console_log("Parsing run data...")
        
        # Default values
        run_data = {
            'energy_j': None,
            'runtime_s': None,
            'status': 'FAILED'
        }
        
        # Try to read result.csv from laptop
        result_file = context.run_dir / "dut_results" / "result.csv"
        
        if result_file.exists():
            try:
                # Parse the result line
                with open(result_file, 'r') as f:
                    result_line = f.read().strip()
                
                # Format: run_num,subject,gc,workload,jdk,rep,runtime_s,energy_j,status,timestamp
                parts = result_line.split(',')
                
                if len(parts) >= 9:
                    run_data['runtime_s'] = float(parts[6]) if parts[6] != 'FAILED' else None
                    run_data['energy_j'] = float(parts[7]) if parts[7] != 'FAILED' else None
                    run_data['status'] = parts[8]
                    
                    output.console_log(f"  Runtime: {run_data['runtime_s']}s")
                    output.console_log(f"  Energy:  {run_data['energy_j']}J")
                    output.console_log(f"  Status:  {run_data['status']}")
                else:
                    output.console_log("  ✗ Invalid result format")
                    
            except Exception as e:
                output.console_log(f"  ✗ Error parsing results: {e}")
        else:
            output.console_log("  ✗ Result file not found")
        
        return run_data

    def after_experiment(self) -> None:
        """Perform any activity required after stopping the experiment here
        Invoked only once during the lifetime of the program."""
        
        output.console_log("")
        output.console_log("="*60)
        output.console_log("EXPERIMENT COMPLETED")
        output.console_log("="*60)
        output.console_log(f"Results saved to: {self.results_output_path}")
        output.console_log("")
        output.console_log("Next steps:")
        output.console_log("  1. Check run_table.csv for all measurements")
        output.console_log("  2. Verify no failed runs")
        output.console_log("  3. Begin statistical analysis in R")
        output.console_log("")

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path:            Path             = None