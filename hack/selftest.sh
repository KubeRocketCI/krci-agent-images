#!/usr/bin/env bash
# Usage: hack/selftest.sh <image-dir> <image-ref> <harness-image> <platforms>
# Per platform in <platforms> (comma-separated, e.g. linux/amd64,linux/arm64):
# - builds <image-dir> into local Docker as <image-ref>-<os>-<arch>;
# - exports /krci-agent-harness from <harness-image> for that platform;
# - runs krci-agent-harness selftest in the built image, binary outside /opt/krci-agent.
# Stops at the first failed build or selftest. A platform other than the host's needs QEMU.
set -euo pipefail

usage="usage: hack/selftest.sh <image-dir> <image-ref> <harness-image> <platforms>"
dir=${1:?$usage}
ref=${2:?$usage}
harness=${3:?$usage}
platforms=${4:?$usage}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

IFS=, read -ra list <<<"$platforms"
for platform in "${list[@]}"; do
  tag="$ref-${platform//\//-}"
  docker buildx build --platform "$platform" -t "$tag" --load "$dir"

  # Local exporter: the classic image store holds one platform per digest reference.
  printf 'FROM %s\n' "$harness" | docker buildx build --platform "$platform" --output "type=local,dest=$tmp/harness" -

  echo "selftest $tag"
  docker run --rm --platform "$platform" \
    -v "$tmp/harness/krci-agent-harness:/tmp/krci-agent-harness:ro" \
    "$tag" /tmp/krci-agent-harness selftest
  rm -rf "$tmp/harness"
done
