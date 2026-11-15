# krci-agent-images

`github.com/KubeRocketCI/krci-agent-images`: agent images for KubeRocketCI issue agents. Each image runs as an Agent Substrate actor, started by `krci-agent-dispatcher`, with `krci-agent-harness` mounted at `/opt/krci-agent` as the actor command.

Contract with the dispatcher: `krci-agent-dispatcher` `docs/agent-harness.md`, section Agent image. Terms: `krci-agent-dispatcher` `GLOSSARY.md`. Use the glossary terms in code names, logs and notes.

## Build & Push

```
make list                                  # images and versions
make build IMAGE=krci-agent-go             # local Docker, host platform
make check-build IMAGE=krci-agent-go       # every platform in PLATFORMS; no load, no push
make push  IMAGE=krci-agent-go             # linux/amd64 + linux/arm64; prints <ref>@<digest>; skips existing tags
make push  ALL=1 RELEASE=1                 # every image, tag <VERSION>; what release.yml runs
make lint                                  # hadolint, .hadolint.yaml
make changed                               # images changed since BASE (default origin/main)
make check-versions                        # a changed image must bump VERSION; BASE (default origin/main)
```

- `IMAGE`: one name or a space-separated list; default `krci-agent-go`. `ALL=1`: every image under `images/`.
- `IMAGE_REGISTRY`: default `epamedp`.
- Image tag: `<VERSION>` with `RELEASE=1`, else `<VERSION>-dev-<commit>[-dirty]`.
- `make push` never overwrites a tag and refuses uncommitted changes.

## CI

- `pr.yml`, pull request: `check-versions`, `lint`, then `check-build` for the `make changed` images.
- `release.yml`, merge to `main`: `make push ALL=1 RELEASE=1`; publishes every image whose `<VERSION>` is not in the registry. Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.
- `pr-validation.yml`, pull request: commit titles.

## Layout

```
images/<name>/Dockerfile      one directory per image; directory name = image name
images/<name>/VERSION         image version, MAJOR.MINOR.PATCH
images/<name>/profile.yaml    agent profile: setup, verify, prompt; copied to /etc/krci-agent/profile.yaml
hack/check-versions.sh        make check-versions
hack/changed-images.sh        make changed; a Makefile change: every image
.hadolint.yaml                hadolint config
.github/workflows/            pr.yml, release.yml, pr-validation.yml
```

## Conventions

- Commit titles: `EPMDEDP-<id>: <type>: <description>`, 10–85 characters (`.github/workflows/pr-validation.yml`). Sign off (`git commit -s`).
- Image name: `krci-agent-<toolchain>`, published as `epamedp/<name>`.
- Any change under `images/<name>/` bumps its `VERSION` in the same pull request: MAJOR for a contract break, MINOR for a tool upgrade or a new tool, PATCH for a fix.
- Tool versions are `ARG`s in the Dockerfile with a pinned default.
- `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` before the first piped `RUN`; `make lint` must pass.
- `USER 1000:1000`, numeric.
- No `CMD` or `ENTRYPOINT`: the actor template sets the command.
- No credentials, tokens or cluster data in an image or a profile.
- No secret value in logs, argv or errors.
