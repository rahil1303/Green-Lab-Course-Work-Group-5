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


class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    name: str = "java_gc_energy_experiment"
    results_output_path: Path = ROOT_DIR / 'experiments'
    operation_type: OperationType = OperationType.AUTO
    time_between_runs_in_ms: int = 120000  # 2 minutes cooldown

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
        self.current_batch = 1
        self.runs_in_batch = 0
        self.BATCH_SIZE = 6 # 6 reps (manual stop at 4)
        output.console_log("Custom config loaded (Dual-script configuration)")

    # ---------------------------------------------------------------------
    # Experiment Definition
    # ---------------------------------------------------------------------
    def create_run_table_model(self) -> RunTableModel:
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

        self.run_table_model = RunTableModel(
            factors=[subject_factor, gc_factor, workload_factor, jdk_factor],
            exclude_variations=[],
            data_columns=['energy_j', 'runtime_s', 'status', 'batch_num']
        )
        return self.run_table_model

    # ---------------------------------------------------------------------
    # Before Experiment
    # ---------------------------------------------------------------------
    def before_experiment(self) -> None:
        output.console_log("="*60)
        output.console_log("JAVA GC ENERGY EXPERIMENT - GREEN LAB 2025")
        output.console_log("="*60)
        total_runs = len(self.run_table_model.get_all_rows())
        total_batches = (total_runs + self.BATCH_SIZE - 1) // self.BATCH_SIZE
        output.console_log(f"Total runs planned: {total_runs}")
        output.console_log(f"Batch size: {self.BATCH_SIZE} runs")
        output.console_log(f"Total batches: {total_batches}")
        output.console_log(f"Results path: {self.results_output_path}")
        output.console_log("")

        laptop_user = os.getenv('LAPTOP_USER', 'your_username')
        laptop_host = os.getenv('LAPTOP_HOST', '192.168.1.100')
        try:
            result = subprocess.run(
                ['ssh', f'{laptop_user}@{laptop_host}', 'echo "SSH test successful"'],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                output.console_log("✓ SSH connection to DUT successful")
            else:
                output.console_log("✗ SSH connection FAILED - check configuration!")
                output.console_log(f"  Error: {result.stderr}")
        except Exception as e:
            output.console_log(f"✗ SSH test error: {e}")

    # ---------------------------------------------------------------------
    # Before Run
    # ---------------------------------------------------------------------
    def before_run(self) -> None:
        if self.runs_in_batch >= self.BATCH_SIZE:
            output.console_log("")
            output.console_log(f"║  BATCH {self.current_batch} COMPLETE ({self.BATCH_SIZE} runs) ║")
            output.console_log("║  Press ENTER to continue ║")
            try:
                input()
                self.current_batch += 1
                self.runs_in_batch = 0
                output.console_log(f"\nStarting BATCH {self.current_batch}...")
            except KeyboardInterrupt:
                output.console_log("\n✗ Experiment stopped by user")
                raise
        output.console_log("")
        output.console_log("─"*50)
        output.console_log("Preparing for next run...")

    # ---------------------------------------------------------------------
    # Start Run
    # ---------------------------------------------------------------------
    def start_run(self, context: RunnerContext) -> None:
        self.runs_in_batch += 1
        output.console_log("")
        output.console_log("="*60)
        output.console_log(f"STARTING RUN #{context.run_nr} (Batch {self.current_batch}, Run {self.runs_in_batch}/{self.BATCH_SIZE})")
        output.console_log("="*60)
        output.console_log(f"Subject:  {context.run_variation['subject']}")
        output.console_log(f"GC:       {context.run_variation['gc']}")
        output.console_log(f"Workload: {context.run_variation['workload']}")
        output.console_log(f"JDK:      {context.run_variation['jdk']}")
        output.console_log(f"Rep:      {context.run_variation['__rep__']}")
        output.console_log("")

    # ---------------------------------------------------------------------
    # Start Measurement (Decides which shell file to execute)
    # ---------------------------------------------------------------------
    def start_measurement(self, context: RunnerContext) -> None:
        output.console_log("Starting energy measurement...")

        laptop_user = os.getenv('LAPTOP_USER', 'your_username')
        laptop_host = os.getenv('LAPTOP_HOST', '192.168.1.100')
        laptop_exp_dir = os.getenv('LAPTOP_EXPERIMENT_DIR', '/home/your_username/gc_experiment')

        subject = context.run_variation['subject']
        gc = context.run_variation['gc']
        workload = context.run_variation['workload']
        jdk = context.run_variation['jdk']
        rep = context.run_variation['__rep__']
        run_num = context.run_nr

        # Decide which script to use
        if subject in ["PetClinic", "TodoApp", "ANDIE"]:
            script_name = "Service_Apps_Run_Single_Experiment.sh"
        else:
            script_name = "Run_Single_Experiment.sh"

        remote_cmd = (
            f"cd {laptop_exp_dir} && "
            f"./{script_name} {subject} {gc} {workload} {jdk} {rep} {run_num}"
        )

        output.console_log(f"Executing on DUT: {remote_cmd}")
        context.ssh_command = remote_cmd
        context.laptop_user = laptop_user
        context.laptop_host = laptop_host
        context.laptop_exp_dir = laptop_exp_dir
        context.batch_num = self.current_batch

    # ---------------------------------------------------------------------
    # Interact (wait for DUT to finish)
    # ---------------------------------------------------------------------
    def interact(self, context: RunnerContext) -> None:
        ssh_cmd = ['ssh', f'{context.laptop_user}@{context.laptop_host}', context.ssh_command]
        output.console_log("Waiting for experiment to complete on DUT...")
        try:
            result = subprocess.run(ssh_cmd, capture_output=True, text=True, timeout=5400)  # 90 min
            context.ssh_returncode = result.returncode
            context.ssh_stdout = result.stdout
            context.ssh_stderr = result.stderr
            if result.returncode == 0:
                output.console_log("✓ Run completed successfully on DUT")
            else:
                output.console_log(f"✗ Run FAILED with return code {result.returncode}")
                output.console_log(f"  stderr: {result.stderr[:500]}")
        except subprocess.TimeoutExpired:
            output.console_log("✗ Run TIMEOUT")
            context.ssh_returncode = -1
            context.ssh_stdout = ""
            context.ssh_stderr = "TIMEOUT"

    # ---------------------------------------------------------------------
    # Stop Measurement (retrieve results)
    # ---------------------------------------------------------------------
    def stop_measurement(self, context: RunnerContext) -> None:
        output.console_log("Retrieving results from DUT...")
        if context.ssh_returncode == 0:
            remote_result_dir = f"{context.laptop_exp_dir}/results/run_{context.run_nr}"
            local_result_dir = context.run_dir / "dut_results"
            local_result_dir.mkdir(parents=True, exist_ok=True)

            for fname in ['energy.csv', 'result.csv']:
                scp_cmd = [
                    'scp',
                    f'{context.laptop_user}@{context.laptop_host}:{remote_result_dir}/{fname}',
                    str(local_result_dir / fname)
                ]
                result = subprocess.run(scp_cmd, capture_output=True)
                if result.returncode == 0:
                    output.console_log(f"  ✓ Retrieved {fname}")
                else:
                    output.console_log(f"  ✗ Failed to retrieve {fname}")

    # ---------------------------------------------------------------------
    # Stop Run
    # ---------------------------------------------------------------------
    def stop_run(self, context: RunnerContext) -> None:
        output.console_log("")
        output.console_log(f"Run #{context.run_nr} complete (Batch {self.current_batch})")
        output.console_log("─"*50)

    # ---------------------------------------------------------------------
    # Populate Run Data
    # ---------------------------------------------------------------------
    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        output.console_log("Parsing run data...")
        run_data = {'energy_j': None, 'runtime_s': None, 'status': 'FAILED', 'batch_num': self.current_batch}
        result_file = context.run_dir / "dut_results" / "result.csv"
        if result_file.exists():
            try:
                with open(result_file, 'r') as f:
                    parts = f.read().strip().split(',')
                if len(parts) >= 9:
                    run_data['runtime_s'] = float(parts[6]) if parts[6] != 'FAILED' else None
                    run_data['energy_j'] = float(parts[7]) if parts[7] != 'FAILED' else None
                    run_data['status'] = parts[8]
                    output.console_log(f"  Runtime: {run_data['runtime_s']}s")
                    output.console_log(f"  Energy:  {run_data['energy_j']}J")
                    output.console_log(f"  Status:  {run_data['status']}")
            except Exception as e:
                output.console_log(f"  ✗ Error parsing results: {e}")
        else:
            output.console_log("  ✗ Result file not found")
        return run_data

    # ---------------------------------------------------------------------
    # After Experiment
    # ---------------------------------------------------------------------
    def after_experiment(self) -> None:
        output.console_log("")
        output.console_log("="*60)
        output.console_log("EXPERIMENT COMPLETED")
        output.console_log("="*60)
        output.console_log(f"Total batches executed: {self.current_batch}")
        output.console_log(f"Results saved to: {self.results_output_path}")
        output.console_log("")
        output.console_log("Next steps:")
        output.console_log("  1. Check run_table.csv for all measurements")
        output.console_log("  2. Verify no failed runs")
        output.console_log("  3. Begin statistical analysis in R")
        output.console_log("")

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path: Path = None
