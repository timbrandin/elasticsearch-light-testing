# Docker image: elasticsearch-light-testing

A Docker image running Elasticsearch on Fedora, tuned for development only.

## Yet another Elasticsearch docker image?

The official image from Elastic is designed to be flexible and comes with safe defaults,
to make sure it's a reasonable starting point for many use cases.
For quick integration testing we need mostly small indexes and use "throw away" cheap storage, which leads me to reconfigure most of the official image.
Not least I don't need to run the additional plugins it comes with, and no need to waste 2G of heap for the JVM tuning.

To make sure our software behaves as intended, we'll also strictly ban deprecated features and not recommended settings, have the logger spit out a warning for anything dodgy.

Finally, we disable clustering. This image is certainly not intended for complex failure testing nor performance / scalability tests, for any of those use the official images.

The official image is based on CentOS, which is great an reliable to run services, but when developing I prefer to use Fedora so I'm ready for the next generation of CentOS / Red Hat Enterprise Linux. So this is based on Fedora Linux.

## How to run it

### Fetch it

> docker pull timbrandin/elasticsearch-light-testing

### Start it

> docker run --ulimit memlock=-1:-1 -it --net=host --rm=true --memory-swappiness=0 --name es-it timbrandin/elasticsearch-light-testing

Done!

Keep in mind that this image is meant for development in quick iterations; the above options will terminate the container on CTRL+C and remove any data stored.

### Customization & tuning

I highly recommend using tmpfs for storage as Docker is otherwise not very efficient; direct host network usage also helps with efficiency:

> docker run --ulimit memlock=-1:-1 -ti --tmpfs /run --tmpfs=/opt/elasticsearch/volatile/data:uid=1000 --tmpfs --tmpfs=/opt/elasticsearch/volatile/logs:uid=1000 --net=host --name es-it timbrandin/elasticsearch-light-testing

Unfortunately the parameters format Docker requires for `tmpfs` changes across various versions:
you might need to adapt the above suggestion.

Get rid of it after testing:

> docker stop es-it && docker rm es-it

Registered on DockerHub: https://hub.docker.com/r/timbrandin/elasticsearch-light-testing/ 

## Building the Image

### Build locally for testing (single architecture)

Use the provided script to build for your local architecture:

```bash
./build-local.sh
```

This creates an image tagged as `timbrandin/elasticsearch-light-testing:8.19.4-local` optimized for your current architecture.

### Build and push multi-architecture image

To build and push a multi-architecture image that works on both AMD64 (x86_64) and ARM64 (Apple Silicon):

```bash
# Make sure you're logged in to Docker Hub
docker login

# Build and push multi-arch image
./build-multiarch.sh
```

This will create and push:
- `timbrandin/elasticsearch-light-testing:8.19.4` - supports both linux/amd64 and linux/arm64
- `timbrandin/elasticsearch-light-testing:latest` - same multi-arch support

The multi-architecture image automatically selects the correct Elasticsearch binary based on the platform:
- `linux/amd64` (x86_64) - for CI runners, Intel/AMD machines
- `linux/arm64` (aarch64) - for Apple Silicon Macs

### Manual build (single architecture)

> docker build -t customtest .

Don't forget to change `customtest` consistently in the run script:

> docker run --ulimit memlock=-1:-1 -it --net=host --rm=true --memory-swappiness=0 --name es-it customtest

