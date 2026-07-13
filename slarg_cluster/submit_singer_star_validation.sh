#!/bin/bash
# Submit the disclosed SINGER* build, parity, and frozen crash regressions.
set -Eeuo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 SOURCE OUTPUT_ROOT INPUT_PREFIX OFFICIAL_BINARY" >&2
  exit 2
fi
SOURCE=$1
OUTPUT_ROOT=$2
INPUT_PREFIX=$3
OFFICIAL_BINARY=$4
COMMIT=$(git -C "$SOURCE" rev-parse HEAD)
test -z "$(git -C "$SOURCE" status --porcelain --untracked-files=all)"
test ! -e "$OUTPUT_ROOT"
test -s "$INPUT_PREFIX.vcf"
test -x "$OFFICIAL_BINARY"

submit() {
  local raw id
  raw=$(sbatch --parsable --kill-on-invalid-dep=yes "$@")
  id=${raw##*$'\n'}
  id=${id%%;*}
  [[ $id =~ ^[0-9]+$ ]] || exit 1
  printf '%s' "$id"
}

EXPORTS="ALL,SINGER_STAR_SOURCE=$SOURCE,SINGER_STAR_COMMIT=$COMMIT,SINGER_STAR_OUTPUT=$OUTPUT_ROOT/build,SINGER_STAR_VALIDATION_ROOT=$OUTPUT_ROOT,SINGER_STAR_INPUT_PREFIX=$INPUT_PREFIX,SINGER_OFFICIAL_BINARY=$OFFICIAL_BINARY"
BUILD=$(submit --export="$EXPORTS" "$SOURCE/slarg_cluster/build_singer_star.sbatch")
DOWNSTREAM="$EXPORTS,SINGER_STAR_BINARY=$OUTPUT_ROOT/build/singer_star"
PARITY=$(submit --dependency="afterok:$BUILD" --export="$DOWNSTREAM,SINGER_STAR_PARITY_DIR=$OUTPUT_ROOT/parity" \
  "$SOURCE/slarg_cluster/check_singer_star_parity.sbatch")
REPLAY=$(submit --array=0-3%4 --dependency="afterok:$BUILD" --export="$DOWNSTREAM,SINGER_STAR_REPLAY_ROOT=$OUTPUT_ROOT/replay" \
  "$SOURCE/slarg_cluster/replay_singer_star_regression.sbatch")
SEAL=$(submit --dependency="afterok:$PARITY:$REPLAY" --export="$DOWNSTREAM" \
  "$SOURCE/slarg_cluster/seal_singer_star_validation.sbatch")

printf '%s\n' "build=$BUILD" "parity=$PARITY" "replay=$REPLAY" "seal=$SEAL"
