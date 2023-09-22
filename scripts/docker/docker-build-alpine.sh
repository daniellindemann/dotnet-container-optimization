#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
APP_DIR=$SCRIPT_DIR/../../src/DotnetContainerOptimization.SampleApp
docker build $@ -t sample-app-alpine:1.0.0 -t sample-app-alpine:latest -f $APP_DIR/Dockerfile.alpine $APP_DIR
