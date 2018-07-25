.PHONY: clean build push all

DOCKER_VERSION=latest
DOCKER_IMAGE=neowaylabs/postgres-azure-backup

clean:
	- docker rmi -f $(DOCKER_IMAGE):$(DOCKER_VERSION)
	- docker rm -f $(DOCKER_IMAGE)

build: clean
	docker build -t $(DOCKER_IMAGE):$(DOCKER_VERSION) .

push:
	docker push $(DOCKER_IMAGE):$(DOCKER_VERSION)

all: build push

