---
name: gaivi-environments
description: Build and run CUDA coursework on GAIVI with the course-provided runScript and host CUDA 11.4 toolkit, and configure user Conda or Singularity environments when those suit the task. Nix/devenv is not used on GAIVI.
---

# GAIVI development environments

Use only GAIVI's host software for building and running on the cluster. For CUDA coursework follow the course instructions: `/apps/GPU_course/runScript.sh file.cu args...`. Do not use the Nix chroot or devenv on GAIVI, even though they exist in the account. Do not install system software or use `sudo`.

Run remote commands as `ssh gaivi 'command'`. An interactive `ssh gaivi` enters a rootless Nix chroot from the user's `.bashrc`; avoid running coursework from that shell. Do not edit the user's remote shell configuration unless asked.

Read the reference matching the task:

- [references/cuda.md](references/cuda.md): the official `runScript.sh` workflow, host CUDA toolchain facts, and runtime diagnosis.
- [references/python-containers.md](references/python-containers.md): user Conda environments, Singularity jobs, and JupyterHub.

Check actual tool versions on GAIVI. Use Context7 MCP for current public library/SDK documentation, and match guidance to the installed version (CUDA 11.4). Course instructions govern build/run commands, GAIVI documentation governs site policy, and live scheduler queries govern available resources.

All GPU runs and work exceeding 10 minutes, one CPU core, or 2 GB RAM must go through Slurm (`runScript.sh` already runs the program via `srun`). Use `$gaivi-slurm` for custom jobs and `$gaivi-access` for transfers.

Verified 2026-09-30: host CUDA 11.4.48, host GCC 8.5.0, compute-node driver 530.30.02 on GTX 1080 Ti nodes; no `module` command. `runScript.sh` compiled and ran the Project 1 starter code successfully.

Sources: course project instructions, [working environment](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:4.working_environment), [CUDA/container/Jupyter jobs](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:2.job_submission).
