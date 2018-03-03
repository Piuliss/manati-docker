# manati-docker
This repository contains the Dockerfile and others configurations file of the [ManaTI Project](https://github.com/stratosphereips/Manati).

The docker cloud image is maintained by me.

### For building ManaTI from scratch
    docker build -t honeyjack/manati:latest .

### For pulling it from docker cloud
    docker pull honeyjack/manati:latest

### For running it the first time. If you want, with the parameter -v you can map volume sections
    docker run --name manati -p 8888:8888 -dti honeyjack/manati:latest bash

### For stopping the ManaTI container, the data will  not be lost
    docker stop manati

### For starting it again
    docker start manati 
