# Entry-points

default: build

clean:
	-docker container rm 'keqiongpan_taiga'
	-docker image rm 'keqiongpan/taiga:latest'
	@echo 'Clean Finish!'

all: build push

# Docker-operations.

build: latest
	@docker image ls 'keqiongpan/taiga:latest'
	@echo 'Build dokcer image [keqiongpan/taiga:latest] Finish!'

push: build
	docker image push 'keqiongpan/taiga:latest'
	@echo 'Push dokcer image [keqiongpan/taiga:latest] Finish!'

run:
	docker run -ti --name 'keqiongpan_taiga' 'keqiongpan/taiga:latest'

# Builds

latest:
	docker image build --no-cache -t 'keqiongpan/taiga:latest' -f ./Dockerfile .
