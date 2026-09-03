SEVERITIES = HIGH,CRITICAL

UNAME_M = $(shell uname -m)
ifndef TARGET_PLATFORMS
	ifeq ($(UNAME_M), x86_64)
		TARGET_PLATFORMS:=linux/amd64
	else ifeq ($(UNAME_M), aarch64)
		TARGET_PLATFORMS:=linux/arm64
	else
		TARGET_PLATFORMS:=linux/$(UNAME_M)
	endif
endif

BUILD_META=-build$(shell TZ=UTC date +%Y%m%d)
ORG ?= rancher
TAG ?= ${GITHUB_ACTION_TAG}

ifeq ($(TAG),)
TAG := $(shell head -n1 TAG)$(BUILD_META)
endif

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG needs to end with build metadata: $(BUILD_META))
endif

GOLANG_VERSION := $(shell ./scripts/golang-version.sh $(TAG))

.PHONY: image-build
image-build:
	docker buildx build \
		--progress=plain \
		--platform=$(TARGET_PLATFORMS) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--build-arg GO_IMAGE=rancher/hardened-build-base:$(GOLANG_VERSION) \
		--tag $(ORG)/hardened-crictl:$(TAG) \
		--load \
	.

.PHONY: image-build-all
image-build-all:
	@for tag in $(shell cat TAG); do \
		TAG=$$tag$(BUILD_META) $(MAKE) image-build; \
	done

.PHONY: image-push
image-push:
	docker push $(ORG)/hardened-crictl:$(TAG)

.PHONY: image-scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-crictl:$(TAG)

.PHONY: log
log:
	@echo "ARCH=$(ARCH)"
	@echo "TAG=$(TAG:$(BUILD_META)=)"
	@echo "ORG=$(ORG)"
	@echo "BUILD_META=$(BUILD_META)"
	@echo "UNAME_M=$(UNAME_M)"
	@echo "GOLANG_VERSION=$(GOLANG_VERSION)"
