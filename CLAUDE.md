# krci-agent-images

`github.com/KubeRocketCI/krci-agent-images`: agent images for KubeRocketCI issue agents. Each image runs as an Agent Substrate actor, started by `krci-agent-dispatcher`, with `krci-agent-harness` mounted at `/opt/krci-agent` as the actor command.

Contract with the dispatcher: `krci-agent-dispatcher` `docs/agent-harness.md`, section Agent image. Terms: `krci-agent-dispatcher` `GLOSSARY.md`. Use the glossary terms in code names, logs and notes.

## Build & Push

```
make list                                  # images and versions
make build IMAGE=krci-agent-go             # local Docker, host platform
make check-build IMAGE=krci-agent-go       # every platform in PLATFORMS; no load, no push
make selftest IMAGE=krci-agent-go          # per platform in PLATFORMS: build, load, krci-agent-harness selftest
make push  IMAGE=krci-agent-go             # linux/amd64 + linux/arm64; prints <ref>@<digest>; skips existing tags
make push  ALL=1 RELEASE=1                 # every image, tag <VERSION>; what release.yml runs
make lint                                  # hadolint, .hadolint.yaml
make changed                               # images changed since BASE (default origin/main)
make check-versions                        # a changed image must bump VERSION; BASE (default origin/main)
make release-notes DRY_RUN=1               # GitHub releases <name>/v<VERSION> of published images; DRY_RUN=1 prints only
```

- `IMAGE`: one name or a space-separated list; default `krci-agent-go`. `ALL=1`: every image under `images/`.
- `IMAGE_REGISTRY`: default `epamedp`.
- `HARNESS_IMAGE`: harness for `make selftest`; pinned to the `krci-agent-dispatcher` chart value `harnessImage`. Bump both together.
- Image tag: `<VERSION>` with `RELEASE=1`, else `<VERSION>-dev-<commit>[-dirty]`.
- `make push` never overwrites a tag and refuses uncommitted changes.

## CI

- `pr.yml`, pull request: `check-versions`, `lint`, then `selftest` for the `make changed` images, every platform (arm64 under QEMU).
- `release.yml`, merge to `main`: `make push ALL=1 RELEASE=1`; publishes every image whose `<VERSION>` is not in the registry. Then `make release-notes`: creates the GitHub release and git tag `<name>/v<VERSION>` for every published image without one, on the last commit that changed `images/<name>/`. Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`; `GITHUB_TOKEN` with `contents: write`.
- `pr-validation.yml`, pull request: commit titles.

## Layout

```
images/<name>/Dockerfile      one directory per image; directory name = image name
images/<name>/VERSION         image version, MAJOR.MINOR.PATCH
images/<name>/profile.yaml    agent profile: setup, verify, prompt; copied to /etc/krci-agent/profile.yaml
hack/check-versions.sh        make check-versions
hack/changed-images.sh        make changed; a Makefile change: every image
hack/selftest.sh              make selftest
hack/release-notes.sh         make release-notes
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
