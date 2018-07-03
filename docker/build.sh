# build the image fro Dockerfile
docker build -t u109 .
# build the container from this image
docker run -d -p 9487:22 --privileged --name u109_c u109 > /dev/null
# find which port mapping to 22
docker port u109_c 22
