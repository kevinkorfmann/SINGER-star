#!/bin/bash
#SBATCH --job-name=singer-star-build
#SBATCH --account=smathi-cohort
#SBATCH --partition=genoa-std-mem
#SBATCH --qos=genoa-std
#SBATCH --cpus-per-task=4
#SBATCH --mem=22G
#SBATCH --time=00:45:00
#SBATCH --no-requeue
#SBATCH --output=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.out
#SBATCH --error=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.err

set -Eeuo pipefail
umask 0027
: "${SINGER_STAR_SOURCE:?}"
: "${SINGER_STAR_COMMIT:?}"
: "${SINGER_STAR_OUTPUT:?}"
: "${SLURM_JOB_ID:?SINGER* build must run in Slurm}"

test "$(git -C "$SINGER_STAR_SOURCE" rev-parse HEAD)" = "$SINGER_STAR_COMMIT"
test -z "$(git -C "$SINGER_STAR_SOURCE" status --porcelain --untracked-files=all)"
test ! -e "$SINGER_STAR_OUTPUT"
mkdir -p "$SINGER_STAR_OUTPUT"
WORK=${SLURM_TMPDIR:-/tmp}/singer-star-$SLURM_JOB_ID
cp -R "$SINGER_STAR_SOURCE/SINGER/SINGER" "$WORK"
cd "$WORK"
g++ -std=c++17 -O3 -g -static ./*.cpp -o singer_star
cp singer_star "$SINGER_STAR_OUTPUT/singer_star"
sha256sum "$SINGER_STAR_OUTPUT/singer_star" >"$SINGER_STAR_OUTPUT/SHA256SUMS"
printf '%s\n' \
  "status=build_complete" \
  "label=SINGER*" \
  "upstream_tag=v0.1.8-beta" \
  "upstream_commit=013fe1bc136f16386d25d98e87107a71f7ce97df" \
  "patch_commit=$SINGER_STAR_COMMIT" \
  "behavior_change=numerical_recovery_only" \
  "slurm_job_id=$SLURM_JOB_ID" \
  >"$SINGER_STAR_OUTPUT/build.txt"
