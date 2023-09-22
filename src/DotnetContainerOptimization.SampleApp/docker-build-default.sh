#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build $@ -t sample-app:1.0.0 -t sample-app:latest -f $SCRIPT_DIR/Dockerfile.default $SCRIPT_DIR
