ARG BASELINE_IMAGE=epamedp/krci-agent-baseline:0.1.0@sha256:8ca970ac43d597973516577bd9e481b05e54ffe131ef234fb2e981c613e3f6e8

FROM ${BASELINE_IMAGE}

ARG TARGETARCH
ARG GO_VERSION=1.27.4
# SHA-256 of the Go release tarballs: https://go.dev/dl/?mode=json
ARG GO_SHA256_AMD64=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840
ARG GO_SHA256_ARM64=3392582988a273a87ab5043ee1b2c9c17a2c3c00580bf9326c47a2e0aaaeac92

USER 0:0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN case "${TARGETARCH}" in \
      amd64) sum="${GO_SHA256_AMD64}" ;; \
      arm64) sum="${GO_SHA256_ARM64}" ;; \
      *) echo "unsupported TARGETARCH ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSLo /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
 && echo "${sum}  /tmp/go.tar.gz" | sha256sum -c - \
 && tar -C /usr/local -xzf /tmp/go.tar.gz \
 && rm /tmp/go.tar.gz \
 && /usr/local/go/bin/go version | grep -F "go${GO_VERSION} "

COPY --chmod=0644 profile.yaml /etc/krci-agent/profile.yaml

ENV PATH=/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin \
    GOTOOLCHAIN=local \
    GOPATH=/home/agent/go

# Actor command: /opt/krci-agent/krci-agent-harness run, set by the dispatcher's actor template.
USER 1000:1000
WORKDIR /work
