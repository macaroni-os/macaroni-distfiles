BACKEND?=dockerv2
CONCURRENCY?=1

# Abs path only. It gets copied in chroot in pre-seed stages
LUET?=/usr/bin/luet-build
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/output
COMPRESSION?=zstd
CLEAN?=true
TREE?=./packages
BUILD_ARGS?= --pull --image-repository quay.io/geaaru/macaroni-distfiles-amd64-cache --only-target-package
CONFIG?= --config conf/luet.yaml
export LUET_BIN?=$(LUET)

.PHONY: all
all: deps build

.PHONY: deps
deps:
	@echo "Installing luet"
	go get -u github.com/mudler/luet

.PHONY: clean
clean:
	rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(ROOT_DIR)/build
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(ROOT_DIR)/build
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)
	rm -rf $(ROOT_DIR)/build/*.image.tar

.PHONY: rebuild
rebuild:
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: create-repo
create-repo:
	$(LUET) create-repo $(CONFIG) --tree "$(TREE)" \
    --output $(ROOT_DIR)/build \
    --packages $(ROOT_DIR)/build \
    --name "macaroni-distfiles" \
    --descr "Macaroni Distfiles Official Repository" \
    --urls "https://macaroni.funtoo.org/mottainai/macaroni-distfiles" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar \
    --meta-compression $(COMPRESSION) \
    --type http

.PHONY: serve-repo
serve-repo:
	LUET_NOLOCK=true $(LUET) serve-repo --port 8000 --dir $(ROOT_DIR)/build

.PHONY: autobump
autobump:
	TREE_DIR=$(ROOT_DIR) $(LUET) autobump-github
	
.PHONY: auto-bump
auto-bump: autobump

.PHONY: validate
validate:
	$(LUET) tree validate -t ${TREE}
