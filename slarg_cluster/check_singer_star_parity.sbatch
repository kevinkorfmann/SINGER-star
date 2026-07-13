#!/bin/bash
#SBATCH --job-name=singer-star-parity
#SBATCH --account=smathi-cohort
#SBATCH --partition=genoa-std-mem
#SBATCH --qos=genoa-std
#SBATCH --cpus-per-task=4
#SBATCH --mem=22G
#SBATCH --time=00:30:00
#SBATCH --no-requeue
#SBATCH --output=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.out
#SBATCH --error=/vast/projects/smathi/cohort/kkor/slarg/logs/%x-%j.err

set -Eeuo pipefail
umask 0027
: "${SINGER_OFFICIAL_BINARY:?}"
: "${SINGER_STAR_BINARY:?}"
: "${SINGER_STAR_INPUT_PREFIX:?}"
: "${SINGER_STAR_PARITY_DIR:?}"
: "${SLURM_JOB_ID:?SINGER* parity check must run in Slurm}"

EXPECTED_VCF_SHA256=ad6307b1e0030803baf65185afcd59dc2b42c301ff7239246e52bbcf5bd55784
test -x "$SINGER_OFFICIAL_BINARY"
test -x "$SINGER_STAR_BINARY"
test "$(sha256sum "$SINGER_STAR_INPUT_PREFIX.vcf" | awk '{print $1}')" = "$EXPECTED_VCF_SHA256"
test ! -e "$SINGER_STAR_PARITY_DIR"
mkdir -p "$SINGER_STAR_PARITY_DIR/official" "$SINGER_STAR_PARITY_DIR/star"

COMMON=(
  -m 3.5e-09 -r 2.6334807576118993e-10 -Ne 5000.0
  -input "$SINGER_STAR_INPUT_PREFIX" -start 0 -end 1000000
  -n 1 -thin 1 -seed 423291174 -polar 0.99
)
"$SINGER_OFFICIAL_BINARY" "${COMMON[@]}" \
  -output "$SINGER_STAR_PARITY_DIR/official/posterior" \
  >"$SINGER_STAR_PARITY_DIR/official/stdout.txt" \
  2>"$SINGER_STAR_PARITY_DIR/official/stderr.txt"
"$SINGER_STAR_BINARY" "${COMMON[@]}" \
  -output "$SINGER_STAR_PARITY_DIR/star/posterior" \
  >"$SINGER_STAR_PARITY_DIR/star/stdout.txt" \
  2>"$SINGER_STAR_PARITY_DIR/star/stderr.txt"

test "$(grep -c '^SINGER_STAR_RECOVERY' "$SINGER_STAR_PARITY_DIR/star/stderr.txt" || true)" = 0
FILES=(coordinates.txt nodes_0.txt branches_0.txt muts_0.txt recombs_0.txt)
for SUFFIX in "${FILES[@]}"; do
  cmp \
    "$SINGER_STAR_PARITY_DIR/official/posterior_$SUFFIX" \
    "$SINGER_STAR_PARITY_DIR/star/posterior_$SUFFIX"
done
sha256sum "$SINGER_STAR_PARITY_DIR"/{official,star}/posterior_*.txt \
  >"$SINGER_STAR_PARITY_DIR/SHA256SUMS"
printf '%s\n' \
  "status=exact_scientific_output_parity" \
  "label=SINGER*" \
  "recovery_events=0" \
  "seed=423291174" \
  "posterior_samples=1" \
  "thin=1" \
  "compared_files=${FILES[*]}" \
  "slurm_job_id=$SLURM_JOB_ID" \
  >"$SINGER_STAR_PARITY_DIR/parity.txt"
