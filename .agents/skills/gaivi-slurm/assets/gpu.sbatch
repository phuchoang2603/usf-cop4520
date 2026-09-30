#!/bin/bash -l
#SBATCH --job-name=cop4520-gpu
#SBATCH --partition=ClsParSystems
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --gpus=1
#SBATCH --time=00:10:00
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

set -euo pipefail
if (( $# == 0 )); then
  echo 'Usage: sbatch gpu.sbatch command [args...]' >&2
  exit 2
fi
exec srun "$@"
