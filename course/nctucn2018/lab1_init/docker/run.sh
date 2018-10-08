# Build the container named cn2018_c from the image named cn2018
docker run -d -p 9487:22 --privileged --name cn2018_c cn2018 > /dev/null
# List port 22 mapping on cn2018_c
docker port cn2018_c 22