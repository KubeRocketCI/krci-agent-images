#!/usr/bin/env bash
# Usage: hack/check-versions.sh <base-ref>
# Checks every image under images/:
# - VERSION exists and is MAJOR.MINOR.PATCH;
# - an image changed since the merge base with <base-ref> has a VERSION greater than at the merge base.
# Changes: committed and uncommitted tracked files. Needs the history to the merge base.
set -euo pipefail
shopt -s nullglob

base=${1:?usage: hack/check-versions.sh <base-ref>}
merge_base=$(git merge-base "$base" HEAD) || { echo "no merge base with $base; fetch the full history" >&2; exit 1; }
semver='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
fail=0

greater() { # greater <new> <old>: new > old
  local a b c x y z
  IFS=. read -r x y z <<<"$1"
  IFS=. read -r a b c <<<"$2"
  ((x > a || (x == a && (y > b || (y == b && z > c)))))
}

for dir in images/*/; do
  dir=${dir%/}
  version=$(tr -d '[:space:]' 2>/dev/null <"$dir/VERSION" || true)
  if ! [[ $version =~ $semver ]]; then
    echo "FAIL ${dir#images/}: $dir/VERSION want MAJOR.MINOR.PATCH, got '$version'"
    fail=1
  fi
done

changed=$(git diff --name-only "$merge_base" -- images/ | cut -d/ -f2 | sort -u)
for image in $changed; do
  dir=images/$image
  [ -d "$dir" ] || { echo "ok   $image: removed"; continue; }
  new=$(tr -d '[:space:]' 2>/dev/null <"$dir/VERSION" || true)
  [[ $new =~ $semver ]] || continue
  old=$(git show "$merge_base:$dir/VERSION" 2>/dev/null | tr -d '[:space:]' || true)
  if [ -n "$old" ] && ! greater "$new" "$old"; then
    echo "FAIL $image: changed since $base; bump $dir/VERSION above $old (is $new)"
    fail=1
  elif [ -z "$old" ]; then
    echo "ok   $image: new image, $new"
  else
    echo "ok   $image: $old -> $new"
  fi
done

[ -n "$changed" ] || echo "ok   no image changed since $base"
exit "$fail"
