#!/usr/bin/env bash
# Assemble a working tree from the public core and this overlay.
#
#   public goat-transformers (at core.ref)  +  this overlay's model/ and packs/
#      = an assembled tree where the engines run the overlay's formats.
#
# The same shape a real private overlay uses: the engine code is public and
# pinned; the packs (and, in a real overlay, their provenance) are the overlay.
set -euo pipefail
OVERLAY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_URL="${CORE_URL:-https://github.com/DesertGOAT/goat-transformers}"
usage() { echo "usage: assemble.sh [--core-dir DIR] <output-dir>" >&2; exit 2; }

CORE_DIR=""; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --core-dir) [ $# -ge 2 ] || usage; CORE_DIR="$2"; shift 2 ;;
    -h|--help)  usage ;;
    -*)         usage ;;
    *)          [ -z "$OUT" ] || usage; OUT="$1"; shift ;;
  esac
done
[ -n "$OUT" ] || usage

ref="$(tr -d '[:space:]' < "$OVERLAY/core.ref")"
case "$ref" in *[!0-9a-f]*|"") echo "assemble: core.ref is not a commit sha" >&2; exit 1 ;; esac
[ "${#ref}" -eq 40 ] || { echo "assemble: core.ref must be a full 40-char sha" >&2; exit 1; }

mkdir -p "$OUT"
if [ -n "$CORE_DIR" ]; then
  echo "assemble: copying core from $CORE_DIR"
  ( cd "$CORE_DIR" && git archive "$ref" 2>/dev/null || git archive HEAD ) | tar -x -C "$OUT"
else
  echo "assemble: fetching core $CORE_URL @ $ref"
  tmp="$(mktemp -d)"; git -C "$tmp" init -q
  git -C "$tmp" remote add origin "$CORE_URL"
  git -C "$tmp" fetch -q --depth 1 origin "$ref"
  git -C "$tmp" archive FETCH_HEAD | tar -x -C "$OUT"
  rm -rf "$tmp"
fi

# Overlay the private model modules and packs on top of the public ones. An
# overlay file may not replace a core file: a module or pack name is used once.
for d in model packs; do
  [ -d "$OVERLAY/$d" ] || continue
  for src in "$OVERLAY/$d"/*; do
    name="$(basename "$src")"
    if [ -e "$OUT/$d/$name" ]; then
      echo "assemble: $d/$name exists in the core; an overlay may not replace it" >&2; exit 1
    fi
  done
  echo "assemble: overlaying $d/"
  cp -R "$OVERLAY/$d/." "$OUT/$d/"
done
echo "$ref" > "$OUT/.goat-transformers-assembled"
echo "assemble: done -> $OUT"
echo "  run the reference engine's vectors:"
echo "    (cd $OUT/engines/rust && cargo test)"
echo "  show that a public-only engine refuses the overlay:"
echo "    (cd $OUT/engines/rust && cargo run -q -- list-formats --packs ../../packs --max-distribution public)"
