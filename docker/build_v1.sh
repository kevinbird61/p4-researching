# build the image fro Dockerfile
docker build -f v1.Dockerfile -t v1 .
# build the container from this image
docker run -d -p 9487:22 --privileged --name v1_c v1 > /dev/null
# find which port mapping to 22
docker port v1_c 22
