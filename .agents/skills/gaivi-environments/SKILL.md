---
name: gaivi-environments
description: Use the verified rootless Nix/devenv setup on GAIVI and build compatible CUDA coursework binaries; configure user Conda or Singularity environments when those suit the task.
---

# GAIVI development environments

Prefer this repo's Nix devenv when practical. On the remote account, Nix lives inside an existing rootless `nix-user-chroot` setup, not directly in the default noninteractive SSH environment. Do not reinstall Nix or use `sudo`.

Read the reference matching the task:

- [references/nix.md](references/nix.md): entering the verified chroot, running devenv over SSH, and using it inside Slurm steps.
- [references/cuda.md](references/cuda.md): compiling course CUDA code for accessible GPUs, avoiding the repo's architecture mismatch, and diagnosing runtime failures.
- [references/python-containers.md](references/python-containers.md): user Conda environments, Singularity jobs, and JupyterHub.

Check actual tool versions inside the chosen environment. Use Context7 MCP for current public library/SDK documentation, and match guidance to the installed version. GAIVI documentation governs site policy; live scheduler queries govern available resources.

All GPU runs and work exceeding 10 minutes, one CPU core, or 2 GB RAM must go through Slurm. A Nix shell/chroot is an environment, not a scheduler allocation. Heavy builds or environment creation also belong in allocations; if no compute capacity is available, prepare the commands and report that limitation. Use `$gaivi-slurm` for submission and `$gaivi-access` for transfers.

Verified 2026-09-30: rootless Nix 2.35.2 and devenv 2.2.2 start successfully; `/apps` and `/usr/bin/srun` remain visible in the chroot. Host CUDA is 11.4.48, host GCC is 8.5.0, and no `module` command was found in a login-shell check. Both accessible compute nodes were down, so chroot, driver access, and GPU execution on compute nodes remain unverified.

Sources: [working environment](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:4.working_environment), [CUDA/container/Jupyter jobs](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:2.job_submission), plus the account's SSH shell configuration and read-only tool checks.
