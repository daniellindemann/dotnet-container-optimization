#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

IMAGE_NAME="sample-app:1.0.0"
IMAGE_BUILD_SCRIPT="$SCRIPT_DIR/../docker/docker-build-default.sh"

# check if image base image exists, otherwise build it via script
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "Base image not found, building image"
  . $IMAGE_BUILD_SCRIPT
else
  echo "Image found, skipping base image build"
fi

# check if required tools are available
if ! command -v trivy >/dev/null 2>&1; then
  echo "ERROR trivy is not available Exiting."
  exit 1
fi
if ! command -v copa >/dev/null 2>&1; then
  echo "ERROR copa is not available Exiting."
  exit 1
fi

# replace / and : with -
trivyReportName=${IMAGE_NAME//\//-}
trivyReportName=${trivyReportName//:/-}

# patch image
trivy image --vuln-type os --ignore-unfixed -f json -o ${trivyReportName}.json $IMAGE_NAME
copa patch -i $IMAGE_NAME -r ${trivyReportName}.json
