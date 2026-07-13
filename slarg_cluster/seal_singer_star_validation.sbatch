#!/bin/bash
#SBATCH --job-name=singer-star-validation
#SBATCH --account=smathi-cohort
#SBATCH --partition=genoa-std-mem
#SBATCH --qos=genoa-std
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:10:00
#SBATCH --no-requeue
#SBATCH --output=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.out
#SBATCH --error=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.err

set -Eeuo pipefail
umask 0027
: "${SINGER_STAR_VALIDATION_ROOT:?}"
: "${SLURM_JOB_ID:?SINGER* validation seal must run in Slurm}"

test "$(grep -c '^status=build_complete$' "$SINGER_STAR_VALIDATION_ROOT/build/build.txt")" = 1
test "$(grep -c '^status=exact_scientific_output_parity$' "$SINGER_STAR_VALIDATION_ROOT/parity/parity.txt")" = 1
for INDEX in 0 1 2 3; do
  test "$(grep -c '^status=complete_recovery_exercised$' \
    "$SINGER_STAR_VALIDATION_ROOT/replay/chain_$INDEX/replay.txt")" = 1
done
test ! -e "$SINGER_STAR_VALIDATION_ROOT/validation.txt"
printf '%s\n' \
  "status=validated_minimal_numerical_recovery" \
  "label=SINGER*" \
  "normal_path_exact_scientific_output_parity=true" \
  "frozen_failure_seeds_completed=4" \
  "official_singer_replaced=false" \
  "slurm_job_id=$SLURM_JOB_ID" \
  >"$SINGER_STAR_VALIDATION_ROOT/validation.txt"
