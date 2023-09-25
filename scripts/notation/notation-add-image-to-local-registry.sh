#!/bin/bash

IMAGE_TO_SIGN='sample-app:1.0.0'

SCRIPT_DIR=$(dirname "$0")

echo "--- Build image ---"
$SCRIPT_DIR/../docker/docker-build-default.sh -t localhost:5001/$IMAGE_TO_SIGN

echo "--- Push image ---"
docker push localhost:5001/$IMAGE_TO_SIGN

echo "--- Get image digest ---"
IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' localhost:5001/$IMAGE_TO_SIGN)
echo $IMAGE_DIGEST

echo "--- Ensure no signatures ---"
notation ls $IMAGE_DIGEST
