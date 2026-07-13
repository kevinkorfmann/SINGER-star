#!/bin/bash
#SBATCH --job-name=singer-star-regression
#SBATCH --account=smathi-cohort
#SBATCH --partition=genoa-std-mem
#SBATCH --qos=genoa-std
#SBATCH --cpus-per-task=4
#SBATCH --mem=22G
#SBATCH --time=00:45:00
#SBATCH --no-requeue
#SBATCH --output=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%A_%a.out
#SBATCH --error=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%A_%a.err

set -Eeuo pipefail
umask 0027
: "${SINGER_STAR_BINARY:?}"
: "${SINGER_STAR_INPUT_PREFIX:?}"
: "${SINGER_STAR_REPLAY_ROOT:?}"
: "${SLURM_ARRAY_TASK_ID:?SINGER* regression must run as a Slurm array}"

EXPECTED_VCF_SHA256=ad6307b1e0030803baf65185afcd59dc2b42c301ff7239246e52bbcf5bd55784
SEEDS=(423291174 423301186 423311190 423321204)
INDEX=$SLURM_ARRAY_TASK_ID
(( INDEX >= 0 && INDEX < ${#SEEDS[@]} ))
SEED=${SEEDS[$INDEX]}
test -x "$SINGER_STAR_BINARY"
test -s "$SINGER_STAR_INPUT_PREFIX.vcf"
test "$(sha256sum "$SINGER_STAR_INPUT_PREFIX.vcf" | awk '{print $1}')" = "$EXPECTED_VCF_SHA256"
OUTPUT=$SINGER_STAR_REPLAY_ROOT/chain_$INDEX
mkdir -p "$SINGER_STAR_REPLAY_ROOT"
test ! -e "$OUTPUT"
mkdir "$OUTPUT"

set +e
"$SINGER_STAR_BINARY" \
  -m 3.5e-09 \
  -r 2.6334807576118993e-10 \
  -Ne 5000.0 \
  -input "$SINGER_STAR_INPUT_PREFIX" \
  -output "$OUTPUT/posterior" \
  -start 0 \
  -end 1000000 \
  -n 12 \
  -thin 20 \
  -seed "$SEED" \
  -polar 0.99 \
  >"$OUTPUT/stdout.txt" \
  2>"$OUTPUT/stderr.txt"
RETURN_CODE=$?
set -e
RECOVERIES=$(grep -c '^SINGER_STAR_RECOVERY ' "$OUTPUT/stderr.txt" || true)
FAILURES=$(grep -c '^SINGER_STAR_RECOVERY_FAILED ' "$OUTPUT/stderr.txt" || true)
STATUS=failed
if (( RETURN_CODE == 0 && RECOVERIES >= 1 && FAILURES == 0 )); then
  STATUS=complete_recovery_exercised
fi
sha256sum "$SINGER_STAR_BINARY" "$SINGER_STAR_INPUT_PREFIX.vcf" \
  "$OUTPUT/stdout.txt" "$OUTPUT/stderr.txt" >"$OUTPUT/SHA256SUMS"
printf '%s\n' \
  "status=$STATUS" \
  "label=SINGER*" \
  "input_vcf_sha256=$EXPECTED_VCF_SHA256" \
  "seed=$SEED" \
  "posterior_samples=12" \
  "thin=20" \
  "return_code=$RETURN_CODE" \
  "recovery_events=$RECOVERIES" \
  "recovery_failures=$FAILURES" \
  "slurm_job_id=$SLURM_JOB_ID" \
  >"$OUTPUT/replay.txt"
test "$STATUS" = complete_recovery_exercised
