BACKEND?=dockerv3
CONCURRENCY?=1

# Abs path only. It gets copied in chroot in pre-seed stages
LUET?=/usr/bin/luet-build
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/output
COMPRESSION?=zstd

export TREE?=$(ROOT_DIR)/packages
REPO_CACHE?=quay.io/geaaru/macaroni-distfiles-amd64-cache
export REPO_CACHE
BUILD_ARGS?=--pull --no-spinner --only-target-package
GENIDX_ARGS?=--only-upper-level --compress=false
SUDO?=
VALIDATE_OPTIONS?=
ARCH?=amd64
REPO_NAME?=macaroni-distfiles
REPO_DESC?=Macaroni OS Distiles
REPO_URL?=https://dl.macaronios.org/repos/macaroni-distfiles/
REPO_VALUES?=
export REPO_VALUES

ifneq ($(strip $(REPO_CACHE)),)
	BUILD_ARGS+=--image-repository $(REPO_CACHE)
endif

ifneq ($(strip $(REPO_VALUES)),)
  BUILD_ARGS+=--values $(REPO_VALUES)
endif

CONFIG?= --config conf/luet.yaml

.PHONY: all
all: build

.PHONY: clean
clean:
	$(SUDO) rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(DESTINATION)
	$(SUDO) $(LUET) $(CONFIG) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(DESTINATION)
	$(SUDO) $(LUET) $(CONFIG) build $(BUILD_ARGS) --tree=$(TREE) --full --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild
rebuild:
	$(SUDO) $(LUET) $(CONFIG) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(SUDO) $(LUET) $(CONFIG) build $(BUILD_ARGS) --tree=$(TREE) --full --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: genidx
genidx:
	$(SUDO) $(LUET) tree genidx $(GENIDX_ARGS) --tree=$(TREE)

.PHONY: create-repo
create-repo: genidx
	$(SUDO) $(LUET) $(CONFIG) create-repo --tree "$(TREE)" \
    --output $(DESTINATION) \
    --packages $(DESTINATION) \
    --name "$(REPO_NAME)" \
    --descr "$(REPO_DESC) $(ARCH)" \
    --urls "$(REPO_URL)" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar.zst \
    --with-compilertree \
    --type http

.PHONY: serve-repo
serve-repo:
	LUET_NOLOCK=true $(LUET) $(CONFIG) serve-repo --port 8000 --dir $(DESTINATION)

.PHONY: validate
validate:
	$(LUET) tree validate -t $(TREE) $(VALIDATE_OPTIONS)
