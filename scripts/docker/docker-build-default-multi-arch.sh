#!/bin/bash

# to push to azure container registry do the following:
#  - login to azure container registry: az acr login --name <acrName>
#  - build the image with acr tag with the following command:
#       BUILDKIT_NO_CLIENT_TOKEN=true docker buildx build --push --platform linux/amd64,linux/arm64 -t <acrLoginServer>/sample-app:1.0.0 -f $SCRIPT_DIR/Dockerfile.default-multi-arch $SCRIPT_DIR


SCRIPT_DIR=$(dirname "$0")
APP_DIR=$SCRIPT_DIR/../../src/DotnetContainerOptimization.SampleApp
docker buildx build $@ \
    --platform linux/amd64,linux/arm64 \
    -t sample-app:1.0.0 -t sample-app:latest -f $APP_DIR/Dockerfile.default-multi-arch $APP_DIR
