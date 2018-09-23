build: latest
	docker image ls 'keqiongpan/taiga:latest'
	echo 'Build dokcer image [keqiongpan/taiga:latest] Finish!'

push: build
	docker image push 'keqiongpan/taiga:latest'
	echo 'Push dokcer image [keqiongpan/taiga:latest] Finish!'

latest:
	docker image build --no-cache -t 'keqiongpan/taiga:latest' -f ./Dockerfile .

all: build push
