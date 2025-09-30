#!/usr/bin/env python3
"""
ExperimentRunner configuration for Java GC Energy Efficiency Study.
Covers 4 subjects × 3 GC strategies × 3 workloads × 2 JDKs × 3 reps = 216 runs.
"""

from EventManager.Models.RunnerEvents import RunnerEvents
from EventManager.EventSubscriptionController import EventSubscriptionController
from ConfigValidator.Config.Models.RunTableModel import RunTableModel
from ConfigValidator.Config.Models.FactorModel import FactorModel
from ConfigValidator.Config.Models.RunnerContext import RunnerContext
from ConfigValidator.Config.Models.OperationType import OperationType
from ProgressManager.Output.OutputProcedure import OutputProcedure as output

from typing import Dict, Any, Optional
from pathlib import Path
from os.path import dirname, realpath
import os
import time
import random
import subprocess

class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER CONFIG ================================
    name: str = "gc_energy_experiment"
    results_output_path: Path = ROOT_DIR / 'experiments'
    operation_type: OperationType = OperationType.AUTO
    time_between_runs_in_ms: int = 1000

    def __init__(self):
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
        self.mock_enabled = True  # toggle later for real EnergiBridge
        output.console_log("Java GC Energy Experiment initialized")

        # Subject → Path mapping
        self.subjects = {
            "dacapo": self.ROOT_DIR / "jars" / "dacapo.jar",
            "imageproc": self.ROOT_DIR / "jars" / "image-process-tool-1.0.jar",
            "petclinic": self.ROOT_DIR / "jars" / "spring-petclinic-3.5.0-SNAPSHOT.jar",
            "todoapp": self.ROOT_DIR / "jars" / "todoappbackend-0.0.1-SNAPSHOT.jar"
        }

        # JDK paths (update if needed)
        self.jdks = {
            "oraclejdk11": "/Library/Java/JavaVirtualMachines/jdk-11.0.16.jdk/Contents/Home",
            "openjdk17": "/Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home"
        }

    def create_run_table_model(self) -> RunTableModel:
        subject = FactorModel("subject", list(self.subjects.keys()))
        gc_strategy = FactorModel("gc_strategy", ['SerialGC', 'ParallelGC', 'G1GC'])
        workload = FactorModel("workload", ['light', 'medium', 'heavy'])
        jdk = FactorModel("jdk", list(self.jdks.keys()))

        self.run_table_model = RunTableModel(
            factors=[subject, gc_strategy, workload, jdk],
            repetitions=3,
            data_columns=['energy_joules', 'execution_time', 'power_watts', 'exit_code']

        )
        return self.run_table_model

    def before_experiment(self) -> None:
        output.console_log("Setting up Java GC experiment...")

    def before_run(self) -> None:
        pass

    def start_run(self, context: RunnerContext) -> None:
        self.current_run_data = {
            'run_id': context.run_nr,
            'run_dir': context.run_dir
        }
        output.console_log(f"Starting run {context.run_nr}")

    def start_measurement(self, context: RunnerContext) -> None:
        pass

    def interact(self, context: RunnerContext) -> None:
        # Factors are in context.execute_run dictionary
        subject = context.execute_run['subject']
        gc_strategy = context.execute_run['gc_strategy']
        workload = context.execute_run['workload']
        jdk = context.execute_run['jdk']
        
        output.console_log(f"Executing {subject} | {gc_strategy} | {workload} | {jdk}")
        
        jar_path = self.subjects[subject]
        jdk_path = self.jdks[jdk]

        java_cmd = [
            f"{jdk_path}/bin/java",
            f"-XX:+Use{gc_strategy}",
            "-jar", str(jar_path),
            f"--workload={workload}"
        ]

        output.console_log(f"[Run {context.run_nr}] Command: {' '.join(java_cmd)}")

        if self.mock_enabled:
            energy_joules, execution_time, power_watts = self._mock_energy_measurement(gc_strategy, workload, jdk)
            exit_code = 0
            time.sleep(min(execution_time, 0.2))
        else:
            energy_joules, execution_time, power_watts, exit_code = 0.0, 0.0, 0.0, 0

        self.current_run_data.update({
            'energy_joules': energy_joules,
            'execution_time': execution_time,
            'power_watts': power_watts,
            'exit_code': exit_code
        })

        output.console_log(f"Completed: {energy_joules:.3f}J in {execution_time:.3f}s")



    def stop_measurement(self, context: RunnerContext) -> None:
        pass

    def stop_run(self, context: RunnerContext) -> None:
        pass

    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        return self.current_run_data

    def after_experiment(self) -> None:
        output.console_log("Java GC experiment completed")

    def _mock_energy_measurement(self, gc_strategy: str, workload: str, jdk: str) -> tuple:
        base_values = {
            'SerialGC': {'energy': 3.2, 'time': 0.35, 'variance': 0.15},
            'ParallelGC': {'energy': 4.1, 'time': 0.22, 'variance': 0.25},
            'G1GC': {'energy': 3.8, 'time': 0.28, 'variance': 0.35}
        }
        workload_multiplier = {'light': 1.0, 'medium': 2.3, 'heavy': 3.5}.get(workload, 1.0)
        jdk_factor = 1.05 if "oracle" in jdk else 1.0
        base = base_values.get(gc_strategy, base_values['G1GC'])

        energy_base = base['energy'] * workload_multiplier * jdk_factor
        time_base = base['time'] * (workload_multiplier ** 0.8)

        energy_joules = energy_base * random.gauss(1.0, base['variance'])
        execution_time = time_base * random.gauss(1.0, base['variance'] * 0.8)
        energy_joules = max(0.1, energy_joules)
        execution_time = max(0.05, execution_time)
        power_watts = energy_joules / execution_time

        return round(energy_joules, 6), round(execution_time, 6), round(power_watts, 6)

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path: Path = None
