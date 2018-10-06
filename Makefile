# Variables

TAIGA_IMAGE = keqiongpan/taiga:latest
TAIGA_CONTAINER = taiga
TAIGA_DOMAIN = $$(hostname -I | awk '{print $$1}' | head -1)
TAIGA_PORT = 9080

# Entry-points

default: build

clean:
	-docker container rm $(TAIGA_CONTAINER)
	-docker image rm $(TAIGA_IMAGE)
	@echo 'Clean Finish!'

all: build push

# Docker-operations

build: latest
	@docker image ls $(TAIGA_IMAGE)
	@echo 'Build dokcer image [$(TAIGA_IMAGE)] Finish!'

push: build
	docker image push $(TAIGA_IMAGE)
	@echo 'Push dokcer image [$(TAIGA_IMAGE)] Finish!'

run:
	-docker run -ti --name $(TAIGA_CONTAINER) -e "TAIGA_DOMAIN=$(TAIGA_DOMAIN):$(TAIGA_PORT)" -p $(TAIGA_PORT):80 $(TAIGA_IMAGE)

# Builds

latest:
	docker image build --no-cache -t $(TAIGA_IMAGE) -f ./Dockerfile .
