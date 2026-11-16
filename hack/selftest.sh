#!/usr/bin/env bash
# Usage: hack/selftest.sh <image-dir> <image-ref> <harness-image> <platform>
# - builds <image-dir> for <platform> (e.g. linux/amd64) into local Docker as <image-ref>;
# - exports /krci-agent-harness from <harness-image> for <platform>;
# - runs krci-agent-harness selftest in the built image, binary outside /opt/krci-agent.
# A platform other than the host's needs QEMU.
set -euo pipefail

usage="usage: hack/selftest.sh <image-dir> <image-ref> <harness-image> <platform>"
dir=${1:?$usage}
ref=${2:?$usage}
harness=${3:?$usage}
platform=${4:?$usage}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

docker buildx build --platform "$platform" -t "$ref" --load "$dir"

# Local exporter: no container, no harness image in the local store.
printf 'FROM %s\n' "$harness" | docker buildx build --platform "$platform" --output "type=local,dest=$tmp" -

echo "selftest $ref"
docker run --rm --platform "$platform" \
  -v "$tmp/krci-agent-harness:/tmp/krci-agent-harness:ro" \
  "$ref" /tmp/krci-agent-harness selftest
