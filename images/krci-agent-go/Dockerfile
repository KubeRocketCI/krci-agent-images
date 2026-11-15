FROM debian:bookworm-slim

ARG TARGETARCH
ARG GO_VERSION=1.27.0
ARG CLAUDE_VERSION=2.1.325

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl git jq make \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" | tar -C /usr/local -xz \
 && /usr/local/go/bin/go version

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

COPY --chmod=0644 profile.yaml /etc/krci-agent/profile.yaml

ENV PATH=/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin \
    GOTOOLCHAIN=local \
    GOPATH=/home/agent/go \
    DISABLE_AUTOUPDATER=1

# Actor command: /opt/krci-agent/krci-agent-harness run, set by the dispatcher's actor template.
USER 1000:1000
WORKDIR /work
