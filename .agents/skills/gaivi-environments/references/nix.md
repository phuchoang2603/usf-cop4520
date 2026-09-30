# Rootless Nix and devenv on this account

## Verified layout and shell behavior

The user's `.bashrc` contains:

```bash
if [ -t 0 ] && [ -z "$NIX_CHROOT_ACTIVE" ]; then
    export NIX_CHROOT_ACTIVE=1
    exec ~/.local/bin/nix-user-chroot ~/.nix bash --login
fi
```

`.bash_profile` sources `.bashrc` and the profile's `etc/profile.d/nix.sh`. An interactive `ssh gaivi` therefore enters the chroot automatically. A scripted `ssh gaivi '...'` has no terminal and does not enter it. Setting `NIX_CHROOT_ACTIVE=1` prevents recursive entry; it does not itself create the chroot.

Verified paths:

- Wrapper: `$HOME/.local/bin/nix-user-chroot`.
- User store backing directory: `$HOME/.nix`; visible as `/nix` inside the chroot.
- Nix/devenv: `$HOME/.nix-profile/bin/{nix,devenv}` inside the chroot.
- Remote repo: `/home/p/phuchoang/usf-cop4520`.
- Nix configuration enables `nix-command flakes`.

## Noninteractive SSH

Use an explicit wrapper and a login shell, with remote `$HOME` expansion preserved by quoting:

```sh
ssh gaivi 'NIX_CHROOT_ACTIVE=1 "$HOME/.local/bin/nix-user-chroot" "$HOME/.nix" bash -lc '\''nix --version; devenv --version'\'''
```

For a repo command replace the inner command with:

```bash
cd /home/p/phuchoang/usf-cop4520
devenv shell -- command arg1 arg2
```

Run `devenv allow` only if the installed version or project actually requests it. Preserve the checked-in lockfile; do not update it to suppress a version notice. If devenv fails, identify whether the wrapper, package download/build, sandbox, or CUDA compatibility failed. Explain the limitation and use the verified host tools or an appropriate user container when they can satisfy the task.

## Slurm placement

Launch `srun` in the ordinary host environment and enter the Nix chroot inside the allocated step. This keeps workload execution under Slurm. For example, in an sbatch script after its directives:

```bash
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:?}"
srun env NIX_CHROOT_ACTIVE=1 \
  "$HOME/.local/bin/nix-user-chroot" "$HOME/.nix" \
  bash -lc 'cd "$1"; shift; exec devenv shell -- "$@"' \
  bash "$PWD" ./week2/vector_add
```

The binary in this example must already exist and have been built for the target GPU. To compile in the allocation, substitute a version-compatible compiler command or a checked-in build script.

On the first usable compute allocation, check wrapper availability, shared home/store access, `CUDA_VISIBLE_DEVICES`, GPU driver libraries, and `nvidia-smi`. Chroot visibility on the login node does not prove the compute-node namespace permits rootless chroot or exposes the GPUs. Preserve Slurm's device visibility; do not invent or override physical GPU IDs.

The repo's `/run/opengl-driver/lib` runtime path is a NixOS convention and was not verified on GAIVI's RHEL hosts. If CUDA driver loading fails, inspect actual host driver library paths inside the allocation rather than assuming that path exists. Host `/apps` is visible in the login chroot, allowing the verified host toolkit as a fallback.
