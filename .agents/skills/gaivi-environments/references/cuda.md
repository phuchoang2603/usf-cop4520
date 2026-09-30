# CUDA coursework on GAIVI

## Official course workflow

The course instructions (e.g. `projects/proj1/Project1_Spatial_Distance_Histogram.md`) compile and run with the provided script, and grading uses the same command:

```sh
ssh gaivi 'cd /home/p/phuchoang/usf-cop4520/projects/proj1 && /apps/GPU_course/runScript.sh SDH_base.cu 10000 500'
```

Arguments after the `.cu` file are passed to the program. The script (read 2026-09-30) does:

```bash
nvcc --version
mkdir -p "$HOME/tmp"
export TMPDIR=${SLURM_TMPDIR:-$HOME/tmp}
nvcc "$SCRIPT" -o exe --ptxas-options=-v
srun -v --exclusive -p ClsParSystems --time=1:00:00 --gres=gpu:1080Ti:1 ./exe "$@"
```

Consequences:

- It compiles on the login node with plain `nvcc` (CUDA 11.4, host GCC 8.5) and no extra flags. Submitted code must compile exactly this way: no required `-arch`, `-std`, `-I`, or `-l` flags. The default target is embedded `sm_52`/`compute_52` code, which runs on the GTX 1080 Ti (`sm_61`).
- It writes `exe` into the current directory, overwriting any existing `exe`. Run it from the source's directory or a scratch directory, and do not commit `exe`.
- `srun --exclusive` allocates the whole node (32 CPUs, all 4 GPUs) for the run, and the program sees one GPU. It blocks until the node is free and the program exits, with a one-hour limit. Keep runs short, and don't run several at once.
- The script is maintained by the course TA and may change; re-read it with `cat /apps/GPU_course/runScript.sh` if behavior differs.

Verified 2026-09-30: `runScript.sh SDH_base.cu 10000 500` compiled and ran on `GPU8` (job 496665, `COMPLETED 0:0`) and printed the CPU histogram with total `49995000` (= 10000·9999/2).

## Host toolchain facts

- `nvcc`: `/apps/cuda/cuda-11.4/bin/nvcc` (11.4.48), already first on the default `PATH`.
- Host compiler: `/usr/bin/gcc`/`g++` 8.5.0.
- GPUs on `GPU8`/`GPU9`: GTX 1080 Ti, 11 GB, compute capability 6.1; driver 530.30.02.

Use only this host toolchain on GAIVI. Do not use the Nix chroot or devenv there for building or running anything.

For debugging outside the script (e.g. `cuda-gdb`, `compute-sanitizer`, or a longer batch run), compile with `nvcc` directly and run in a GPU allocation from `$gaivi-slurm`. Still confirm the final file builds and runs with `runScript.sh` before submission.

## Runtime verification and diagnosis

- Check `nvidia-smi` and the allocated GPU model inside the job, not on the login node.
- Preserve `CUDA_VISIBLE_DEVICES`. Device ordinal 0 is the first GPU visible to the process, not necessarily physical GPU 0. Do not hardcode physical GPU indices.
- Requesting multiple GPUs does not make a single-GPU program use them.
- For missing libraries, run `ldd` on the binary inside the allocation. CUDA runtime libraries and the host driver library `libcuda.so` (in `/lib64`) have different roles.
- `no kernel image is available` suggests incompatible target code; check any `-arch` flags. Check both kernel-launch errors (`cudaGetLastError`) and synchronization errors.
- For performance measurements, time kernels consistently (e.g. CUDA events around the launch and synchronize) and keep compilation, queue time, host transfers, and kernel execution separate. Retrieve validation output (e.g. `PASS`/`FAIL`) and the Slurm exit status before claiming success.

Sources: course project instructions, `/apps/GPU_course/runScript.sh`, [GAIVI CUDA compilation](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:2.job_submission#compile_and_submit_cuda_jobs), [CUDA runtime device API](https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__DEVICE.html).
