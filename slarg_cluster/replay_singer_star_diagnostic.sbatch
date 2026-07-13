#!/bin/bash
#SBATCH --job-name=singer-star-diagnostic-replay
#SBATCH --account=smathi-cohort
#SBATCH --partition=genoa-lrg-mem
#SBATCH --qos=genoa-lrg
#SBATCH --cpus-per-task=4
#SBATCH --mem=62G
#SBATCH --time=02:00:00
#SBATCH --no-requeue
#SBATCH --output=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.out
#SBATCH --error=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.err

set -Eeuo pipefail
umask 0027
: "${SINGER_STAR_BINARY:?}"
: "${SINGER_STAR_INPUT_PREFIX:?}"
: "${SINGER_STAR_REPLAY_DIR:?}"
: "${SLURM_JOB_ID:?SINGER* replay must run in Slurm}"

test -x "$SINGER_STAR_BINARY"
test -s "$SINGER_STAR_INPUT_PREFIX.vcf"
test ! -e "$SINGER_STAR_REPLAY_DIR"
mkdir -p "$SINGER_STAR_REPLAY_DIR"
set +e
"$SINGER_STAR_BINARY" \
  -m 8.4e-09 \
  -r 1.0226484052836913e-09 \
  -Ne 5000.0 \
  -input "$SINGER_STAR_INPUT_PREFIX" \
  -output "$SINGER_STAR_REPLAY_DIR/posterior" \
  -start 0 \
  -end 23513712 \
  -n 200 \
  -thin 20 \
  -seed 736179205 \
  -polar 0.99 \
  >"$SINGER_STAR_REPLAY_DIR/stdout.txt" \
  2>"$SINGER_STAR_REPLAY_DIR/stderr.txt"
RETURN_CODE=$?
set -e
sha256sum "$SINGER_STAR_BINARY" "$SINGER_STAR_INPUT_PREFIX.vcf" \
  "$SINGER_STAR_REPLAY_DIR/stdout.txt" "$SINGER_STAR_REPLAY_DIR/stderr.txt" \
  >"$SINGER_STAR_REPLAY_DIR/SHA256SUMS"
printf '%s\n' \
  "status=diagnostic_replay_complete" \
  "scientific_method_outcome=false" \
  "behavior_change=false" \
  "return_code=$RETURN_CODE" \
  "slurm_job_id=$SLURM_JOB_ID" \
  >"$SINGER_STAR_REPLAY_DIR/replay.txt"
