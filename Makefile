IMAGE_REGISTRY ?= epamedp
IMAGE ?= krci-agent-go
PLATFORMS ?= linux/amd64,linux/arm64
HADOLINT_IMAGE ?= hadolint/hadolint:v2.15.1
# Harness binary for make selftest; same as the krci-agent-dispatcher chart value harnessImage.
SELFTEST_PLATFORM ?= linux/amd64
HARNESS_IMAGE ?= epamedp/krci-agent-harness:0.1.0-SNAPSHOT.33@sha256:984dd2faac64222626a7ea65828fc6c9ae861967c17d2eca50f2bda331f17519

SOURCE_URL := https://github.com/KubeRocketCI/krci-agent-images
IMAGES := $(patsubst images/%/Dockerfile,%,$(wildcard images/*/Dockerfile))
# ALL=1: every image under images/. Otherwise IMAGE: one name or a space-separated list.
SELECTED := $(if $(ALL),$(IMAGES),$(IMAGE))
# Checks every selected name first, then runs <target>-one once per image; stops at the first failure.
each = set -e; \
  test -n "$(strip $(SELECTED))" || { echo "no image selected: set IMAGE or ALL=1" >&2; exit 1; }; \
  for i in $(SELECTED); do test -f "images/$$i/Dockerfile" || { echo "unknown image $$i; see make list" >&2; exit 1; }; done; \
  for i in $(SELECTED); do $(MAKE) --no-print-directory $(1)-one IMAGE=$$i; done

IMAGE_DIR := images/$(IMAGE)
VERSION := $(strip $(shell cat $(IMAGE_DIR)/VERSION 2>/dev/null))

GIT_COMMIT := $(shell git rev-parse HEAD 2>/dev/null)
GIT_SHORT := $(or $(shell git rev-parse --short=7 HEAD 2>/dev/null),unknown)
GIT_DIRTY := $(if $(shell git status --porcelain 2>/dev/null),1)

# RELEASE=1: <VERSION>. Otherwise: <VERSION>-dev-<commit>[-dirty].
TAG ?= $(if $(RELEASE),$(VERSION),$(VERSION)-dev-$(GIT_SHORT)$(if $(GIT_DIRTY),-dirty))
IMAGE_REF := $(IMAGE_REGISTRY)/$(IMAGE):$(TAG)

LABELS := \
  --label org.opencontainers.image.title=$(IMAGE) \
  --label org.opencontainers.image.version=$(TAG) \
  --label org.opencontainers.image.revision=$(GIT_COMMIT) \
  --label org.opencontainers.image.source=$(SOURCE_URL) \
  --label org.opencontainers.image.licenses=Apache-2.0

.PHONY: help
help: ## Show the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "%-15s %s\n", $$1, $$2}'

.PHONY: list
list: ## List the images and their versions
	@for i in $(IMAGES); do printf '%s %s\n' "$$i" "$$(cat images/$$i/VERSION 2>/dev/null)"; done

.PHONY: check-image
check-image:
	@test -f $(IMAGE_DIR)/Dockerfile || { echo "unknown image $(IMAGE); see make list" >&2; exit 1; }
	@echo '$(VERSION)' | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$' || { echo "$(IMAGE_DIR)/VERSION: want MAJOR.MINOR.PATCH, got '$(VERSION)'" >&2; exit 1; }

.PHONY: ref build check-build selftest push
ref: ## Print the image references: IMAGE or ALL=1, TAG, RELEASE
	@$(call each,ref)
build: ## Build images for the host platform into local Docker: IMAGE or ALL=1, TAG
	@$(call each,build)
check-build: ## Build images for every platform in PLATFORMS; no load, no push: IMAGE or ALL=1
	@$(call each,check-build)
selftest: ## Build images for SELFTEST_PLATFORM into local Docker, run krci-agent-harness selftest: IMAGE or ALL=1, HARNESS_IMAGE
	@$(call each,selftest)
push: ## Build and push multi-platform images, print digests; skip existing tags: IMAGE or ALL=1, TAG, RELEASE, PLATFORMS
	@$(call each,push)

.PHONY: ref-one build-one check-build-one selftest-one push-one
ref-one: check-image
	@echo $(IMAGE_REF)

build-one: check-image
	docker buildx build $(LABELS) -t $(IMAGE_REF) --load $(IMAGE_DIR)

check-build-one: check-image
	docker buildx build --platform $(PLATFORMS) $(LABELS) --output type=cacheonly $(IMAGE_DIR)

selftest-one: check-image
	./hack/selftest.sh $(IMAGE_DIR) $(IMAGE_REF) $(HARNESS_IMAGE) $(SELFTEST_PLATFORM)

# Registry answer "not found": build and push. Tag exists: skip. Any other error: fail.
push-one: check-image
	@test -z "$(GIT_DIRTY)" || { echo "refusing to push $(IMAGE_REF): uncommitted changes" >&2; exit 1; }
	@if out=$$(docker buildx imagetools inspect $(IMAGE_REF) 2>&1); then \
	  echo "skip $(IMAGE_REF): exists in $(IMAGE_REGISTRY)"; \
	elif ! printf '%s' "$$out" | grep -q 'not found'; then \
	  echo "$(IMAGE_REF): registry check failed: $$out" >&2; exit 1; \
	else \
	  echo "docker buildx build --platform $(PLATFORMS) ... -t $(IMAGE_REF) --push $(IMAGE_DIR)"; \
	  docker buildx build --platform $(PLATFORMS) $(LABELS) -t $(IMAGE_REF) --push $(IMAGE_DIR) && \
	  echo "$(IMAGE_REF)@$$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' $(IMAGE_REF))"; \
	fi

.PHONY: release-notes
release-notes: ## Create the missing GitHub releases <image>/v<VERSION> of published images; DRY_RUN=1 prints only
	DRY_RUN=$(DRY_RUN) ./hack/release-notes.sh $(IMAGE_REGISTRY) $(IMAGES)

.PHONY: lint
lint: ## Run hadolint on every image Dockerfile; config .hadolint.yaml
	docker run --rm -v "$(CURDIR):/src:ro" -w /src $(HADOLINT_IMAGE) hadolint $(addsuffix /Dockerfile,$(addprefix images/,$(IMAGES)))

.PHONY: check-versions
check-versions: ## Fail if an image changed since BASE without a VERSION bump: BASE (default origin/main)
	./hack/check-versions.sh $(or $(BASE),origin/main)

.PHONY: changed
changed: ## Print the images changed since BASE: BASE (default origin/main)
	@./hack/changed-images.sh $(or $(BASE),origin/main)
