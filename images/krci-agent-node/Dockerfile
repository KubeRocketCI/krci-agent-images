ARG BASELINE_IMAGE=epamedp/krci-agent-baseline:0.1.0@sha256:8ca970ac43d597973516577bd9e481b05e54ffe131ef234fb2e981c613e3f6e8

FROM ${BASELINE_IMAGE}

ARG TARGETARCH
ARG NODE_VERSION=26.13.1
# npm bundled with NODE_VERSION: deps/npm/package.json at the Node.js tag v<NODE_VERSION>.
ARG NPM_VERSION=11.20.0
# Commit of https://github.com/nodejs/release-keys: keyring gpg/pubring.kbx that signs SHASUMS256.txt.asc.
ARG NODE_KEYS_COMMIT=481637f813e912c4aa3622d7964ab426c97b8e8d

USER 0:0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# libatomic1: shared library of the node binary. gpgv: release signature check.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gpgv libatomic1 \
 && rm -rf /var/lib/apt/lists/*

# Node.js README, Verifying binaries: gpgv checks SHASUMS256.txt.asc against the release keyring,
# then the tarball is checked against SHASUMS256.txt.
RUN case "${TARGETARCH}" in \
      amd64) arch=x64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "unsupported TARGETARCH ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && tarball="node-v${NODE_VERSION}-linux-${arch}.tar.gz" \
 && curl -fsSLo /tmp/node-keyring.kbx "https://github.com/nodejs/release-keys/raw/${NODE_KEYS_COMMIT}/gpg/pubring.kbx" \
 && curl -fsSLo /tmp/SHASUMS256.txt.asc "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc" \
 && curl -fsSLo "/tmp/${tarball}" "https://nodejs.org/dist/v${NODE_VERSION}/${tarball}" \
 && gpgv --keyring=/tmp/node-keyring.kbx --output /tmp/SHASUMS256.txt </tmp/SHASUMS256.txt.asc \
 && echo "$(awk -v f="${tarball}" '$2 == f {print $1}' /tmp/SHASUMS256.txt)  /tmp/${tarball}" | sha256sum -c - \
 && tar -C /usr/local --strip-components=1 --no-same-owner -xzf "/tmp/${tarball}" \
 && rm -f /tmp/node-keyring.kbx /tmp/SHASUMS256.txt.asc /tmp/SHASUMS256.txt "/tmp/${tarball}" \
 && node --version | grep -qxF "v${NODE_VERSION}" \
 && npm --version | grep -qxF "${NPM_VERSION}"

COPY --chmod=0644 profile.yaml /etc/krci-agent/profile.yaml

ENV NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_PROGRESS=false

# Actor command: /opt/krci-agent/krci-agent-harness run, set by the dispatcher's actor template.
USER 1000:1000
WORKDIR /work
