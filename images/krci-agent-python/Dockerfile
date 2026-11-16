ARG BASELINE_IMAGE=epamedp/krci-agent-baseline:0.1.0@sha256:8ca970ac43d597973516577bd9e481b05e54ffe131ef234fb2e981c613e3f6e8

FROM ${BASELINE_IMAGE}

ARG TARGETARCH
ARG PYTHON_VERSION=3.14.10
ARG UV_VERSION=0.13.8
# SHA-256 of the uv release tarballs: https://github.com/astral-sh/uv/releases/download/<UV_VERSION>/sha256.sum
ARG UV_SHA256_AMD64=5acfd9177cfecf0bf87578f059728215ccc884388988f55f7a65041b57387d91
ARG UV_SHA256_ARM64=74f2f5c6024d397481db228db8fc25eed420db192243f88438c118e7e013e585

USER 0:0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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

# CPython from python-build-standalone; uv checks each download against the hashes in the uv release.
# uv is the only package and project tool: pip is removed from the interpreter.
ENV UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python
RUN UV_PYTHON_BIN_DIR=/usr/local/bin uv python install "${PYTHON_VERSION}" \
 && ln -s "python${PYTHON_VERSION%.*}" /usr/local/bin/python3 \
 && ln -s python3 /usr/local/bin/python \
 && find "${UV_PYTHON_INSTALL_DIR}" \( -path '*/site-packages/pip' -o -path '*/site-packages/pip-*' -o -path '*/bin/pip*' \) -prune -exec rm -rf {} + \
 && python --version | grep -qxF "Python ${PYTHON_VERSION}" \
 && ! python -m pip --version 2>/dev/null \
 && rm -rf /root/.cache

COPY --chmod=0644 profile.yaml /etc/krci-agent/profile.yaml

# UV_PYTHON_DOWNLOADS=never: uv uses the image's Python and fetches no interpreter.
# UV_LINK_MODE=copy: uv cache (HOME) and checkout (/work) may be on different filesystems.
ENV UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    UV_NO_PROGRESS=1 \
    PYTHONDONTWRITEBYTECODE=1

# Actor command: /opt/krci-agent/krci-agent-harness run, set by the dispatcher's actor template.
USER 1000:1000
WORKDIR /work
