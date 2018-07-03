# build the container from this existed image.
docker run -d -p 9487:22 --privileged --name u109_c u109 > /dev/null
# show which port mapping to 22
docker port u109_c 22
