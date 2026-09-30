---
name: gaivi-slurm
description: Prepare, submit, monitor, and diagnose CPU or GPU Slurm jobs on USF GAIVI, using the partitions accessible to this repository's user.
---

# GAIVI Slurm jobs

Use `ssh gaivi` for submission and scheduler queries. First verify live resources:

```sh
ssh gaivi 'sinfo -N -o "%N %P %t %c %m %G"; scontrol show partition ClsParSystems; squeue --me'
```

On 2026-09-30 this account saw only `ClsParSystems`, with a 24-hour limit and four GTX 1080 Ti GPUs per node on `GPU8` and `GPU9`. Both nodes were down. Refresh these facts; do not substitute documentation examples such as `general`, `Quick`, or `Contributors` without verifying access. A partition being up does not imply its nodes are usable. If all eligible nodes are down, prepare the job and report the blocker; do not launch blocking interactive probes or repeatedly resubmit.

## Prepare and submit

Use [assets/cpu.sbatch](assets/cpu.sbatch) or [assets/gpu.sbatch](assets/gpu.sbatch) as small starting points. Copy the relevant asset into the assignment directory and adjust resources to the actual program. Both accept the command and its arguments after the script name, preserve argument boundaries, and propagate the `srun` exit status.

```sh
# On GAIVI, after syncing the assignment and selected template:
cd /home/p/phuchoang/usf-cop4520
sbatch --parsable gpu.sbatch ./week2/vector_add
```

Use absolute `--chdir` when submitting from another directory. Output paths are relative to the job working directory; create any desired log subdirectory before submission. Capture the returned job ID, remote working directory, command, and output paths.

- Keep all `#SBATCH` directives before executable statements. They are not shell-expanded; use literal values or `sbatch` CLI overrides.
- Request CPU, memory, GPU, and time explicitly. `--mem` is per node. `--cpus-per-task` is threads per process; `--ntasks` is processes. A multithreaded CUDA/OpenMP program normally uses one task, while MPI uses multiple tasks.
- Run computation as `srun` steps. GPU jobs must request GPUs; do not run GPU programs on the login node or directly SSH into compute nodes.
- Only pin `--nodelist` when the task needs a verified specific node. Do not use `--exclusive` merely to run a small assignment.
- For concurrent steps in a single allocation, give each step explicit resource subsets and `--exact`; wait for every process and propagate failures. MPI additionally requires checking the installed MPI/Slurm launch compatibility.
- The manual documents six simultaneous running jobs per user. Avoid flooding the queue; verify live limits when needed.

If the user asks only for a script, stop after preparing it. Submit when running the workload is in scope. Nix/devenv commands need explicit chroot entry within the allocated step; see `$gaivi-environments`.

## Observe and diagnose

```sh
ssh gaivi 'squeue --me -o "%i %j %T %M %R"'
ssh gaivi 'scontrol show job 12345'
ssh gaivi 'sacct -j 12345 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,AllocTRES'
```

Replace example job IDs with the captured ID. Read that job's output/error files. A job disappearing from `squeue` is not proof of success; use accounting and output. If accounting is unavailable, report that limitation and use the job's logs and application exit evidence.

Pending reasons guide the response: unavailable/down nodes require capacity recovery; resource shortages require waiting or a justified smaller request; bad partition/account/QoS requires correcting the request rather than choosing an unverified partition. For failure, inspect exit status, timeout, OOM, and CUDA/compiler errors before retrying.

For live inspection, enter an existing allocation with `srun --jobid=12345 --pty /bin/bash`, then run resource tools such as `nvidia-smi` and exit promptly. Use `ssh -t gaivi` when a terminal is needed. Any step inspection must fit the job's available resources.

Cancel a specific in-scope job with `scancel 12345`; do not cancel all of the user's jobs.

## Preemption

GAIVI documents restart/requeue preemption: `SIGTERM`, followed by `SIGKILL` after five minutes. Long jobs should checkpoint regularly, handle termination in the application, and resume safely without corrupting or duplicating results. Do not claim a shell trap alone makes an application restartable. `nopreempt` is a documented option, not verified access for this account.

Sources: [quickstart](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:1.quickstart), [job submission](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:2.job_submission), [manual](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:start), [preemption and terms](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:start).
