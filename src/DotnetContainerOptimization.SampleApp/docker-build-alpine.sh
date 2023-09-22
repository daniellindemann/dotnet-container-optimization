#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build $@ -t sample-app-alpine:1.0.0 -t sample-app-alpine:latest -f $SCRIPT_DIR/Dockerfile.alpine $SCRIPT_DIR
