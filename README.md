# krci-agent-images

Agent images for KubeRocketCI issue agents, run by [krci-agent-dispatcher](https://github.com/KubeRocketCI/krci-agent-dispatcher). Published as `epamedp/<name>:<VERSION>`.

> [!IMPORTANT]
> Any change under `images/<name>/` must bump `images/<name>/VERSION` in the same pull request. Without a bump, CI fails and the image is not published.

## Images

| Image | Toolchain |
|---|---|
| [`krci-agent-go`](images/krci-agent-go/) | Go |

## Build

```
make list                                   # images and versions
make build IMAGE=krci-agent-go              # local Docker, host platform
make build ALL=1                            # every image
make check-build IMAGE="krci-agent-go"      # linux/amd64 + linux/arm64, no push
make lint                                   # hadolint
```

## Release

1. Change `images/<name>/`.
2. Bump `images/<name>/VERSION`: MAJOR contract break, MINOR tool upgrade or new tool, PATCH fix. CI fails without a bump.
3. Merge to `main`. CI publishes `epamedp/<name>:<VERSION>` for every image whose version is not published yet.

## Add an image

1. Create the Docker Hub repository `epamedp/krci-agent-<toolchain>`.
2. Add `images/krci-agent-<toolchain>/`:

   ```
   Dockerfile      # agent image contract below
   VERSION         # 0.1.0
   profile.yaml    # optional; copied to /etc/krci-agent/profile.yaml
   ```

3. Add a row to [Images](#images).

Agent image contract ([details](https://github.com/KubeRocketCI/krci-agent-dispatcher/blob/main/docs/agent-harness.md#agent-image)):

- `claude`, `git`, `sh` on `PATH`;
- `USER 1000:1000`, writable `/home/agent` and `/work`;
- `/opt/krci-agent` absent;
- no `CMD`, no `ENTRYPOINT`;
- no credentials.

`profile.yaml`:

```yaml
setup: <command, once after clone>
verify: <command, before publish>
prompt: <text added to the system prompt>
```
