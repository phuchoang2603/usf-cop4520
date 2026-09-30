# CUDA coursework on GAIVI

## Choose the GPU target and toolkit together

Verified host tools on 2026-09-30:

- `/apps/cuda/cuda-11.4/bin/nvcc`: CUDA 11.4.48.
- `/usr/bin/gcc` and `/usr/bin/g++`: GCC 8.5.0.
- Visible partition `ClsParSystems`: GTX 1080 Ti GPUs, Pascal compute capability 6.1 (`sm_61`). Both nodes were down; no GPU runtime was tested.

The repo's `devenv.nix` selects `cudaPackages_12_6`, sets `CUDAARCHS=61`, and `nvccrun` targets `-arch=sm_61`; `devenv.yaml` sets `cuda_capabilities: ["6.1"]`. These settings target the accessible Pascal GPUs. `CUDAARCHS` alone will not override an explicit nvcc architecture flag. The helper also immediately executes the binary, so do not use it on a login node. Check the compute-node driver supports the selected CUDA runtime before using the Nix-built executable; the verified host toolkit is an alternative for older drivers.

For the existing Pascal access, use a compiler supporting `sm_61`. CUDA 13 removed offline compilation and library support for Pascal; use a compatible CUDA 12.x version or the verified host CUDA 11.4. Confirm with `nvcc --version` and `nvcc --list-gpu-code`. Do not blindly use the latest Nix CUDA package or pair host CUDA 11.4 with the repo's GCC 13 override. If adapting the repo environment is requested, align its toolkit, host compiler, capability setting, and build commands together.

## Small compilation with the verified host toolkit

From the remote checkout, this bounded single-process build does not require a GPU:

```sh
mkdir -p build
/apps/cuda/cuda-11.4/bin/nvcc -ccbin /usr/bin/g++ \
  -O2 -std=c++14 -arch=sm_61 week2/vector_add.cu -o build/vector_add
```

Use the language standard required by the source. If invoking host nvcc from within devenv, clear Nix-specific `NVCC_PREPEND_FLAGS`/`NVCC_APPEND_FLAGS` and incompatible include/link flags instead of mixing toolchains. For longer or larger builds use a Slurm allocation.

After preparing a GPU sbatch script and checking capacity, run `build/vector_add` with `srun` in a GPU allocation. Compile on GAIVI Linux, not macOS. Do not compile with `-arch=native` on a GPU-less login node.

Verification on 2026-09-30: the existing `week2/vector_add.cu` compiled successfully with host CUDA 11.4 and GCC 8.5. `cuobjdump --list-elf` confirmed `sm_61` cubins. A bounded `srun --immediate=5` GPU allocation attempt (job 496334) failed because the eligible nodes were down. This verifies compilation, not GPU runtime correctness. The complete Linux package list and environment in `devenv.nix` also evaluated successfully with the pinned Nix inputs; the CUDA 12.6 Nix build/runtime has not been exercised on a compute node.

## Runtime verification and diagnosis

- Check `nvidia-smi` and the allocated GPU model inside the job, not on the login node.
- Preserve `CUDA_VISIBLE_DEVICES`. Device ordinal 0 is the first GPU visible to the process, which need not be the host's physical GPU 0. Do not follow the old site example by hardcoding a physical GPU index.
- GPU resource allocation and application multi-GPU support are separate: requesting multiple GPUs does not make a single-GPU program use them.
- For missing driver/runtime libraries, inspect `ldd` on the binary and library visibility inside the actual execution environment. CUDA runtime libraries and the host driver library `libcuda.so` have different roles.
- `no kernel image is available` suggests incompatible target code; confirm architecture flags and toolkit support. `unsupported GNU version` suggests a compiler/toolkit mismatch; choose a supported compiler instead of bypassing checks by default.
- Check both kernel-launch and synchronization errors. For performance measurements distinguish compilation, allocation/queue time, host transfers, and GPU execution. Retrieve application validation output and Slurm exit status before claiming success.

Sources: [GAIVI CUDA compilation](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:2.job_submission#compile_and_submit_cuda_jobs), [NVIDIA architecture feature archive](https://docs.nvidia.com/cuda/cuda-features-archive/index.html), [CUDA environment variables](https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/environment-variables.html), [CUDA runtime device API](https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__DEVICE.html). NVIDIA guidance was checked through Context7; apply commands supported by the installed toolkit rather than newer documentation examples indiscriminately.
