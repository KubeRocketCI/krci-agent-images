# krci-agent-images

Agent images for KubeRocketCI issue agents, run by [krci-agent-dispatcher](https://github.com/KubeRocketCI/krci-agent-dispatcher). Published as `epamedp/<name>:<VERSION>`.

> [!IMPORTANT]
> Any change under `images/<name>/` must bump `images/<name>/VERSION` in the same pull request. Without a bump, CI fails and the image is not published.

## Images

| Image | Toolchain | Latest | Release notes |
|---|---|---|---|
| [`krci-agent-baseline`](images/krci-agent-baseline/) | none; base of the images below | [![krci-agent-baseline](https://img.shields.io/docker/v/epamedp/krci-agent-baseline?sort=semver&label=epamedp%2Fkrci-agent-baseline)](https://hub.docker.com/r/epamedp/krci-agent-baseline/tags) | [krci-agent-baseline](https://github.com/KubeRocketCI/krci-agent-images/releases?q=krci-agent-baseline) |
| [`krci-agent-go`](images/krci-agent-go/) | Go | [![krci-agent-go](https://img.shields.io/docker/v/epamedp/krci-agent-go?sort=semver&label=epamedp%2Fkrci-agent-go)](https://hub.docker.com/r/epamedp/krci-agent-go/tags) | [krci-agent-go](https://github.com/KubeRocketCI/krci-agent-images/releases?q=krci-agent-go) |
| [`krci-agent-node`](images/krci-agent-node/) | Node.js, npm | [![krci-agent-node](https://img.shields.io/docker/v/epamedp/krci-agent-node?sort=semver&label=epamedp%2Fkrci-agent-node)](https://hub.docker.com/r/epamedp/krci-agent-node/tags) | [krci-agent-node](https://github.com/KubeRocketCI/krci-agent-images/releases?q=krci-agent-node) |
| [`krci-agent-python`](images/krci-agent-python/) | Python, uv | [![krci-agent-python](https://img.shields.io/docker/v/epamedp/krci-agent-python?sort=semver&label=epamedp%2Fkrci-agent-python)](https://hub.docker.com/r/epamedp/krci-agent-python/tags) | [krci-agent-python](https://github.com/KubeRocketCI/krci-agent-images/releases?q=krci-agent-python) |

## Build

```
make list                                   # images and versions
make build IMAGE=krci-agent-go              # local Docker, host platform
make build ALL=1                            # every image
make check-build IMAGE="krci-agent-go"      # linux/amd64 + linux/arm64, no push
make selftest IMAGE=krci-agent-go           # linux/amd64: build, krci-agent-harness selftest
make lint                                   # hadolint
```

## Release

1. Change `images/<name>/`.
2. Bump `images/<name>/VERSION`: MAJOR contract break, MINOR tool upgrade or new tool, PATCH fix. CI fails without a bump.
3. Merge to `main`. CI publishes `epamedp/<name>:<VERSION>` for every image whose version is not published yet, and creates the GitHub release `<name>/v<VERSION>`: pull reference, digest, commits since the previous release.

## Add an image

1. Create the Docker Hub repository `epamedp/krci-agent-<toolchain>`.
2. Add `images/krci-agent-<toolchain>/`:

   ```
   Dockerfile      # FROM the pinned krci-agent-baseline; adds the toolchain only
   VERSION         # 0.1.0
   profile.yaml    # optional; copied to /etc/krci-agent/profile.yaml
   ```

3. Add a row to [Images](#images): copy the `krci-agent-go` row, replace the name.

Agent image contract ([details](https://github.com/KubeRocketCI/krci-agent-dispatcher/blob/main/docs/agent-harness.md#agent-image)):

- `claude`, `git`, `sh` on `PATH`;
- `USER 1000:1000`, writable `/home/agent` and `/work`;
- `/opt/krci-agent` absent;
- no `CMD`, no `ENTRYPOINT`;
- no credentials.

`make selftest` checks the contract on linux/amd64; CI runs it for every changed image.

`profile.yaml`:

```yaml
setup: <command, once after clone>
verify: <command, before publish>
prompt: <text added to the system prompt>
```
