---
name: gaivi-access
description: Connect to USF GAIVI using this machine's SSH alias, verify account access, and transfer this repository or results between local and cluster storage.
---

# GAIVI access and storage

Use the existing `gaivi` SSH alias. It successfully connects to the user's GAIVI account; do not replace SSH configuration or request credentials when it already works. The documented hostname is `gaivi.cse.usf.edu`, and off-campus connections require USF VPN.

## Verify access

Run a bounded, noninteractive check:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=15 gaivi \
  'hostname; id -un; printf "HOME=%s\n" "$HOME"; sinfo -N -o "%N %P %t %c %m %G"'
```

If it fails, distinguish network/VPN failures from authentication failures. Preserve host-key verification. Consult [references/account.md](references/account.md) for the verified account paths and dated access snapshot; refresh live state before making resource decisions.

Interactive `ssh gaivi` automatically enters the user's rootless Nix chroot. `ssh gaivi 'command'` does not. For Nix/devenv work use `$gaivi-environments` and its explicit chroot procedure; ordinary Slurm queries and file transfers need no chroot.

## Transfer code and results

The verified remote checkout is `/home/p/phuchoang/usf-cop4520`. Check the destination before copying, and account for any remote work before overwriting files. Run the following from the local repo root, starting with the dry run:

```sh
rsync -av --dry-run --exclude='.git/' --exclude='.devenv*' \
  --exclude='.direnv/' ./ gaivi:/home/p/phuchoang/usf-cop4520/
rsync -av --exclude='.git/' --exclude='.devenv*' \
  --exclude='.direnv/' ./ gaivi:/home/p/phuchoang/usf-cop4520/
```

Choose narrower source paths when only an assignment needs syncing. Do not add `--delete` unless removal of destination files is explicitly part of the task. Transfer source and portable inputs; build Linux executables remotely instead of copying macOS binaries or Nix build state.

Retrieve exact output paths with `scp` or `rsync`, for example:

```sh
scp gaivi:/home/p/phuchoang/usf-cop4520/slurm-12345.out ./
```

## Storage and cluster boundaries

- Home, `/data/<NetID>`, and `/general/<NetID>` each have a documented 100 GB per-user quota. `/data` is for bulk data and `/general` for hot data. These filesystems are not backed up; keep important results externally.
- `/apps` is shared, read-only software. Install user tools in user-owned storage. Do not run `sudo` on GAIVI.
- Group NVMe storage requires membership; do not assume access.
- Do not SSH directly to compute nodes to run code. Use Slurm. Login-node tasks exceeding 10 minutes, one CPU core, or 2 GB RAM must be scheduled; GPU execution always belongs in an allocation.

Sources: [GAIVI landing page and terms](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:start), [storage](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:3.data_storage), [node types](https://docs.gaivi.cse.usf.edu/doku.php?id=main:gaivi:1.manual:start).
