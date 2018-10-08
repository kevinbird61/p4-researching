#!/bin/bash -e

function build {
    # $1: the name of docker image
    # $2: the external port
    if [ $# -lt 2 ]; then
        echo "[ERROR] The format of command is WRONG"
        echo "[INFO] ./main.sh build <IMAGE_NAME> <EXTERNAL_PORT>"
        exit
    fi

    echo "[INFO] Docker image: $1"
    echo "[INFO] External port: $2"
    # Build the image from Dockerfile
    docker build -f Dockerfile -t $1 .
    # Build the container named cn2018_c from the image named cn2018
    docker run -d -p $2:22 --privileged --name $1"_c" $1 > /dev/null
    # List port 22 mapping on cn2018_c
    docker port $1"_c" 22
}

function run {
    # Build the container named cn2018_c from the image named cn2018
    docker run -d -p 9487:22 --privileged --name cn2018_c cn2018 > /dev/null
    # List port 22 mapping on cn2018_c
    docker port cn2018_c 22
}

function clean {
    echo "[INFO] Stop and remove the container named cn2018_c"
    # Stop and remove container
    docker container stop cn2018_c 
    docker container rm cn2018_c
}

function remove {
    echo "[INFO] Remove the Docker image named "
    # Remove the docker image
    docker image rm cn2018
}

# Main
# $#: the number of parameters (receive at runtime)
# $1: the first command line argument passed

if [ $# -eq 0 ]; then
    echo "[INFO] Usage: $(basename $0) {build|run|clean|remove}"
    echo "[INFO] \t./main.sh build <IMAGE_NAME> <EXTERNAL_PORT>"
    exit
fi

if [ "$1" == "build" ]; then
    $1 $2 $3
    exit
elif [ "$1" == "clean" ]; then
    $1
    exit
elif [ "$1" == "remove" ]; then
    $1
    exit
fi

$1