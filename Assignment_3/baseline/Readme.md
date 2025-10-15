## Notes on Files uploaded


Pre_Check Script:

-> This pre-check script = “DUT health checklist.”

-> Laptop (Linux DUT) → runs workloads & collects RAPL energy.

-> Raspberry Pi → remote orchestrator that schedules and collects runs.

-> You execute the script once before the multi-night campaign to ensure everything (Java, RAPL, EnergiBridge, SSH, CPU governor) is perfect.


Single Experiment Script: When this finishes, you’ll know for certain that:

-> Every subject JAR launches correctly.

-> EnergiBridge measures energy without permission errors.

-> Java 17 installations and GC flags work fine.

-> Logging directories are writable.

