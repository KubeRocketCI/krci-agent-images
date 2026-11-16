ARG PYTHON_VERSION=3.14.10

FROM python:${PYTHON_VERSION}-slim-trixie

ARG TARGETARCH
ARG UV_VERSION=0.13.8
# SHA-256 of the uv release tarballs: https://github.com/astral-sh/uv/releases/download/<UV_VERSION>/sha256.sum
ARG UV_SHA256_AMD64=5acfd9177cfecf0bf87578f059728215ccc884388988f55f7a65041b57387d91
ARG UV_SHA256_ARM64=74f2f5c6024d397481db228db8fc25eed420db192243f88438c118e7e013e585
ARG CLAUDE_VERSION=2.1.325

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*

# uv is the only package and project tool: pip is removed from the base image.
RUN python -m pip uninstall -y --root-user-action=ignore pip \
 && ! python -m pip --version 2>/dev/null

RUN case "${TARGETARCH}" in \
      amd64) arch=x86_64;  sum="${UV_SHA256_AMD64}" ;; \
      arm64) arch=aarch64; sum="${UV_SHA256_ARM64}" ;; \
      *) echo "unsupported TARGETARCH ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSLo /tmp/uv.tar.gz "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${arch}-unknown-linux-gnu.tar.gz" \
 && echo "${sum}  /tmp/uv.tar.gz" | sha256sum -c - \
 && tar -C /usr/local/bin --strip-components=1 -xzf /tmp/uv.tar.gz "uv-${arch}-unknown-linux-gnu/uv" \
 && rm /tmp/uv.tar.gz \
 && uv --version | grep -F "uv ${UV_VERSION}"

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

# UV_PYTHON_DOWNLOADS=never: uv uses the image's Python and fetches no interpreter.
# UV_LINK_MODE=copy: uv cache (HOME) and checkout (/work) may be on different filesystems.
ENV PATH=/usr/local/bin:/usr/bin:/bin \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    UV_NO_PROGRESS=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DISABLE_AUTOUPDATER=1

# Actor command: /opt/krci-agent/krci-agent-harness run, set by the dispatcher's actor template.
USER 1000:1000
WORKDIR /work
