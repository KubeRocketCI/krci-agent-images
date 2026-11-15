#!/usr/bin/env bash
# Usage: hack/release-notes.sh <registry> <image>...
# Creates the GitHub release <image>/v<VERSION> for every image with <registry>/<image>:<VERSION> published
# and no git tag <image>/v<VERSION>. Skips the rest; a later run creates a release a failed run left out.
# Release target: the last commit that changed images/<image>/.
# Notes: pull reference, digest, platforms, commits under images/<image>/ since the previous <image>/v* tag.
# Needs: full history and tags; docker buildx; jq; gh with GH_TOKEN, contents: write.
# DRY_RUN=1: prints the notes, creates nothing.
set -euo pipefail

registry=${1:?usage: hack/release-notes.sh <registry> <image>...}
shift

for image in "$@"; do
  dir=images/$image
  version=$(tr -d '[:space:]' <"$dir/VERSION")
  tag=$image/v$version
  ref=$registry/$image:$version

  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    echo "skip $tag: release exists"
    continue
  fi
  if ! digest=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' "$ref" 2>/dev/null); then
    echo "skip $tag: $ref not in the registry"
    continue
  fi
  platforms=$(docker buildx imagetools inspect --raw "$ref" |
    jq -r '[.manifests[]? | select(.platform.os != "unknown") | "\(.platform.os)/\(.platform.architecture)"] | join(", ")')

  target=$(git log -1 --format=%H -- "$dir")
  previous=$(git tag --list "$image/v*" --sort=-v:refname | head -n 1)
  if [ -n "$previous" ]; then
    range=$previous..$target
    since="since $previous"
  else
    range=$target
    since="(first release)"
  fi
  changes=$(git log --format='- %s (%h)' "$range" -- "$dir")

  notes=$(mktemp)
  cat >"$notes" <<EOF
## Image

\`\`\`
docker pull $ref
\`\`\`

| | |
|---|---|
| Pinned | \`$ref@$digest\` |
| Platforms | ${platforms:-unknown} |
| Docker Hub | https://hub.docker.com/r/$registry/$image/tags?name=$version |

## Changes $since

${changes:-- no changes under $dir}
EOF

  if [ -n "${DRY_RUN:-}" ]; then
    echo "--- $tag on $target"
    cat "$notes"
  else
    gh release create "$tag" --target "$target" --title "$image $version" --notes-file "$notes"
    echo "created $tag: $ref@$digest"
  fi
  rm -f "$notes"
done
