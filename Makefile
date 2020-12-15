# Copyright 2019 The Caicloud Authors.
#
# The old school Makefile, following are required targets. The Makefile is written
# to allow building multiple binaries. You are free to add more targets or change
# existing implementations, as long as the semantics are preserved.
#
#   make              - default to 'build' target
#   make lint         - code analysis
#   make test         - run unit test (or plus integration test)
#   make build        - alias to build-local target
#   make build-local  - build local binary targets
#   make build-linux  - build linux binary targets
#   make container    - build containers
#   $ docker login registry -u username -p xxxxx
#   make push         - push containers
#   make clean        - clean up targets
#
# Not included but recommended targets:
#   make e2e-test
#
# The makefile is also responsible to populate project version information.
#

#
# Tweak the variables based on your project.
#
VERSION ?= $(shell git describe --tags --always --dirty)
OFFLINE_VERSION ?= v0.0.1

# Container registries.
REGISTRY ?= cargo.dev.caicloud.xyz/release

# Container registry for base images.
BASE_REGISTRY ?= cargo.caicloud.xyz/library

#
# These variables should not need tweaking.
#

# Current version of the project.
SAVE_PATH ?= /tmp

# Track code version with Docker Label.
DOCKER_LABELS ?= git-describe="$(shell date -u +v%Y%m%d)-$(shell git describe --tags --always --dirty)"

#
# Define all targets. At least the following commands are required:
#

# All targets.
.PHONY: offline-source-container download-kubectl container push save

offline-source-container:e
	docker build --no-cache -t "offline-source-nginx:${OFFLINE_VERSION}" -f ./build/infra-nginx-image/Dockerfile .

container:
	docker build --no-cache -t "cluster-deploy-job:$(VERSION)" --label $(DOCKER_LABELS) -f ./build/cluster-deploy-job/Dockerfile .

push: container
	docker tag cluster-deploy-job:$(VERSION) $(REGISTRY)/cluster-deploy-job:$(VERSION)
	docker push "$(REGISTRY)/cluster-deploy-job:$(VERSION)"

save: push
	docker save cluster-deploy-job:$(VERSION) -o $(SAVE_PATH)/cluster-deploy-job-$(VERSION).tar.gz

# Need to sync with k8s version
download-kubectl:
	curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

clean:
	rm -rf dist/
	rm *.retry

mitogen:
	ansible-playbook -c local mitogen.yml -vv
