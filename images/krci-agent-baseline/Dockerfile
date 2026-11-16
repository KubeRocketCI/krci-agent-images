# Base of every krci-agent-<toolchain> image: the agent image contract without a toolchain and without a profile.
FROM debian:trixie-slim

ARG CLAUDE_VERSION=2.1.325

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl git jq make \
 && rm -rf /var/lib/apt/lists/*

# Native installer into a throwaway HOME; the binary is copied to /usr/local/bin.
# /tmp is emptied and /root/.claude* removed after the version check.
RUN HOME=/tmp/claude-install bash -o pipefail -c "curl -fsSL https://claude.ai/install.sh | bash -s ${CLAUDE_VERSION}" \
 && cp -L /tmp/claude-install/.local/bin/claude /usr/local/bin/claude \
 && claude --version | grep -F "${CLAUDE_VERSION}" \
 && find /tmp -mindepth 1 -delete \
 && rm -rf /root/.claude*

RUN useradd -m -u 1000 -s /bin/bash agent \
 && install -d -o agent -g agent /work \
 && install -d -m 0755 -o root -g root /etc/krci-agent

ENV PATH=/usr/local/bin:/usr/bin:/bin \
    LANG=C.UTF-8 \
    DISABLE_AUTOUPDATER=1

# Base image CMD bash is cleared.
CMD []

# Actor command: /opt/krci-agent/krci-agent-harness run, set by the dispatcher's actor template.
USER 1000:1000
WORKDIR /work
