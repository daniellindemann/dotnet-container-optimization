#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
APP_DIR=$SCRIPT_DIR/../../src/DotnetContainerOptimization.SampleApp
docker build $@ -t sample-app:1.0.0 -t sample-app:latest -f $APP_DIR/Dockerfile.default $APP_DIR
