#!/bin/bash -e

function build {
    # $1 = image name, $2 = external port
    if [ $# -lt 2 ]; then
        echo "Error Format..."
        echo "./main.sh build <image_name> <external_port>"
        exit
    fi
    echo "Image name: $1"
    echo "External port: $2"
    # build the image from Dockerfile
    docker build -t $1 .
    # build the container from this image
    docker run -d -p $2:22 --privileged --name $1"_c" $1 > /dev/null
    # find which port mapping to 22
    docker port $1"_c" 22
}

function clean {
    # stop and rm
    docker container stop u109_c 
    docker container rm u109_c
    # rm this image
    docker image rm u109
}

function run {
    # build from existed image
    docker run -d -p 9487:22 --privileged --name u109_c u109 > /dev/null
    # find which port mapping to 22
    docker port u109_c 22
}

function cleanall {
    # stop all container
    docker stop $(docker ps -a -q)
    # remove all container
    docker rm $(docker ps -a -q)
}

# main
# '$#' refer to the number of parameters (receive at runtime)
# '$1' denote the first command line argument passed

if [ $# -eq 0 ]; then
    echo "Usage: $(basename $0) {build|run|clean|cleanall}"
    echo "\t./main.sh build <image_name> <external_port>"
    exit
fi

if [ "$1" == "build" ]; then
    # $2 = image name
    # $3 = external port
    $1 $2 $3
    exit
fi

$1
