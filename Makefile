.PHONY: dev build image release test deps clean

CGO_ENABLED=0
COMMIT=`git rev-parse --short HEAD`
VERSION=`git describe --abbrev=0 --tags`
APP=golinks
REPO?=prologic/$(APP)
TAG?=latest
BUILD?=-dev

all: dev

dev: build
	@./$(APP)

deps:
	@go get github.com/GeertJohan/go.rice/rice
	@go get ./...
	@rice embed-go

build: clean deps
	@echo " -> Building $(TAG)$(BUILD)"
	@go build -tags "netgo static_build" -installsuffix netgo \
		-ldflags "-s -w -X main.Commit=$(COMMIT) -X main.Version=${VERSION}" .
	@echo "Built $$(./$(APP) -v)"

image:
	@docker build --build-arg TAG=$(TAG) --build-arg BUILD=$(BUILD) -t $(REPO):$(TAG) .
	@echo "Image created: $(REPO):$(TAG)"

release:
	@./tools/release.sh

profile:
	@go test -cpuprofile cpu.prof -memprofile mem.prof -v -bench ./...

bench:
	@go test -v -bench ./...

test: build
	@go test -v \
		-cover -coverprofile=coverage.txt -covermode=atomic \
		-coverpkg=$(shell go list) \
		-race \
		.

clean:
	@git clean -f -d -X
