#!/usr/bin/env bash
# Usage: hack/changed-images.sh <base-ref>
# Prints the images under images/ changed since the merge base with <base-ref>, space-separated.
# A Makefile change prints every image. A removed image is not printed.
# Changes: committed and uncommitted tracked files. Needs the history to the merge base.
set -euo pipefail
shopt -s nullglob

base=${1:?usage: hack/changed-images.sh <base-ref>}
merge_base=$(git merge-base "$base" HEAD) || { echo "no merge base with $base; fetch the full history" >&2; exit 1; }

if git diff --quiet "$merge_base" -- Makefile; then
  names=$(git diff --name-only "$merge_base" -- images/ | cut -d/ -f2 | sort -u)
else
  names=$(for dir in images/*/; do basename "$dir"; done)
fi

out=
for name in $names; do
  [ -f "images/$name/Dockerfile" ] && out="${out:+$out }$name"
done
echo "$out"
