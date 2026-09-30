# Verified account snapshot

Read this for account-specific paths or to distinguish documented defaults from this user's access. Verified through read-only SSH on 2026-09-30; transient state must be checked again.

- Local alias: `gaivi`; connected login node: `gaivi-login1.cse.usf.edu`.
- `id -un`: `phuchoang@forest.usf.edu`; NetID path component: `phuchoang`. Do not construct storage paths directly from `$USER`, which includes the domain suffix.
- Home: `/home/p/phuchoang`.
- Existing checkout: `/home/p/phuchoang/usf-cop4520`.
- Existing user storage: `/data/phuchoang`, `/general/phuchoang`.
- Visible partition: `ClsParSystems`, maximum runtime `1-00:00:00`; `Default=NO`, so select it explicitly.
- Nodes: `GPU8` and `GPU9`, each reporting 32 Slurm CPUs, approximately 128 GB RAM, and `gpu:1080Ti:4`.
- Both nodes were `down`; partition `State=UP` alone did not mean compute capacity was available. No jobs were submitted or GPU execution tested.
- Slurm version: 22.05.9. `sacctmgr show assoc` returned no rows in the check, so no account or QoS was inferred.
- Nix is available through a rootless user chroot; see `$gaivi-environments` for the verified invocation.

The public docs list many partitions and newer GPUs. Those are not proof this account can use them. Recheck with `sinfo` and `scontrol show partition ClsParSystems`.
