# taiga-docker
Generate a docker image for taiga.

# Build

Remove the container named `taiga` and the image named `keqiongpan/taiga:latest`, and then rebuild the image.

``` bash
make clean && make build
```

# Run

Startup a new container named `taiga` base on the image named `keqiongpan/taiga:latest`.

``` bash
make run
```
