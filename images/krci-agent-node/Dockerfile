ARG NODE_VERSION=26.13.1

FROM node:${NODE_VERSION}-trixie-slim

# npm bundled with NODE_VERSION: deps/npm/package.json at the Node.js tag v<NODE_VERSION>.
ARG NPM_VERSION=11.20.0
ARG CLAUDE_VERSION=2.1.325

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*

RUN npm --version | grep -qxF "${NPM_VERSION}"

# Native installer into a throwaway HOME; the binary is copied to /usr/local/bin.
# /tmp is emptied and /root/.claude* removed after the version check.
RUN HOME=/tmp/claude-install bash -o pipefail -c "curl -fsSL https://claude.ai/install.sh | bash -s ${CLAUDE_VERSION}" \
 && cp -L /tmp/claude-install/.local/bin/claude /usr/local/bin/claude \
 && claude --version | grep -F "${CLAUDE_VERSION}" \
 && find /tmp -mindepth 1 -delete \
 && rm -rf /root/.claude*

# The base image user node (uid 1000, /home/node) becomes agent (uid 1000, /home/agent).
RUN groupmod -n agent node \
 && usermod -l agent -d /home/agent -m node \
 && install -d -o agent -g agent /work \
 && install -d -m 0755 -o root -g root /etc/krci-agent

COPY --chmod=0644 profile.yaml /etc/krci-agent/profile.yaml

ENV PATH=/usr/local/bin:/usr/bin:/bin \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_PROGRESS=false \
    DISABLE_AUTOUPDATER=1

# Base image ENTRYPOINT docker-entrypoint.sh and CMD node are cleared.
ENTRYPOINT []
CMD []

# Actor command: /opt/krci-agent/krci-agent-harness run, set by the dispatcher's actor template.
USER 1000:1000
WORKDIR /work
