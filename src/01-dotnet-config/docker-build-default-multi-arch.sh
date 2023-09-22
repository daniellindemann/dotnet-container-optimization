#!/bin/bash

# to push to azure container registry do the following:
#  - login to azure container registry: az acr login --name <acrName>
#  - build the image with acr tag with the following command:
#       BUILDKIT_NO_CLIENT_TOKEN=true docker buildx build --push --platform linux/amd64,linux/arm64 -t <acrLoginServer>/01-dotnet-config:1.0.0 -f $SCRIPT_DIR/Dockerfile.default-multi-arch $SCRIPT_DIR


SCRIPT_DIR=$(dirname "$0")
docker buildx build $@ \
    --platform linux/amd64,linux/arm64 \
    -t 01-dotnet-config:1.0.0 -t 01-dotnet-config:latest -f $SCRIPT_DIR/Dockerfile.default-multi-arch $SCRIPT_DIR
