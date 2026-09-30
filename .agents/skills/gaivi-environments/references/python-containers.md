# User Python, containers, and notebooks

CUDA coursework uses the course `runScript.sh` and host toolkit (see [cuda.md](cuda.md)). Use these user-owned environments only when a task needs Python packages or a container. Do not use Nix/devenv on GAIVI.

## Conda

Verified host executable: `/apps/anaconda3/bin/conda`; shell initialization file: `/apps/anaconda3/etc/profile.d/conda.sh`.

```bash
source /apps/anaconda3/etc/profile.d/conda.sh
conda create --name cop4520 python=3.11
conda activate cop4520
# Install only the packages the task requires.
```

Select Python/package versions for the actual application rather than copying obsolete Python 3.5/TensorFlow examples from the site. Never install into shared `base`. Use `python -m pip` only inside an owned environment; do not let accidental `~/.local` packages contaminate unrelated environments. Initialize and activate the environment explicitly in batch jobs, then run computation through `srun`.

Environment creation or installation can exceed login-node limits; schedule substantial work. CUDA runtime packages do not necessarily provide `nvcc`; verify the compiler separately for `.cu` builds.

## Singularity

Verified commands: `/apps/singularity/bin/singularity` and `/apps/container_builder_client/bin/container-builder-client`. Do not assume Apptainer or Docker is installed on GAIVI.

GAIVI quickstart explicitly says `singularity pull` must run from an SSH session on a login node and does not work in a job context. Choose a versioned image suitable for the application and GPU, and follow that documented location restriction. Large pulls/builds may conflict with login-node resource limits; use a locally built Linux image or the documented container build service instead of silently violating either constraint. Do not build a macOS/ARM image for an x86_64 GAIVI workload.

The documented builder form is `container-builder-client Dockerfile myImage.sif`; only add `--overwrite` when replacing the existing image is intended. Check its current help before using service-specific options.

Execute under a GPU allocation with:

```bash
srun singularity exec --nv image.sif python script.py
```

Explicitly bind required data/working directories when not visible, and preserve Slurm's GPU visibility. A container supplies userspace dependencies, not the host NVIDIA kernel driver or a GPU allocation.

## JupyterHub

Prefer [GAIVI JupyterHub](https://jupyterhub.gaivi.cse.usf.edu/) over manually exposing a notebook. Connect through USF VPN, request actual resources, and use an owned environment/kernel. JupyterHub writes `jupyterhub_slurmspawner_<jobid>.log` in the working directory.

To register a custom kernel, install `ipykernel` in the owned environment, activate it, then run `python -m ipykernel install --user --name cop4520 --display-name "COP4520"`. Do not modify the shared default kernel. Only implement a manual notebook tunnel if requested; consult the site's tunnel guidance, including its warning about the unencrypted compute-to-login leg, rather than copying example passwords/tokens.

Sources: [working environment](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:4.working_environment), [quickstart container pull restriction](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:1.quickstart#containerized_jobs), [containers and Jupyter](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:2.job_submission).
